const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const script = fs.readFileSync('api/tools/buaabksjw.js', 'utf8');
const school = JSON.parse(fs.readFileSync('api/schoolList.json', 'utf8')).data
  .find(s => s.pinyin === 'beijinghangkonghangtiandaxuebenkejiaowu');

// Synthetic records with the field shapes observed in BUAA's term timetable.
// No student account, credentials, or real timetable is stored in these tests.
const termCode = '2026-2027-1';
const terms = [
  {itemCode: '2024-2025-1', itemName: 'Fall 2024', selected: false},
  {itemCode: termCode, itemName: 'Fall 2026', selected: true},
];
const calendar = Array.from({length: 19}, (_, i) => ({
  serialNumber: i + 1,
  startDate: new Date(Date.UTC(2026, 8, 7 + 7 * i)).toISOString().slice(0, 10) + ' 00:00:00',
}));
const course = (extra = {}) => ({
  courseName: '测试课程', courseCode: 'COURSE-A', courseSerialNo: '001',
  teachClassId: '202620271COURSEA001', dayOfWeek: 1, beginSection: 3,
  endSection: 5, beginTime: '09:50', endTime: '12:15', placeName: '教学楼101',
  weeksAndTeachers: '1-4周,6-17周[理论]/教师甲[主讲]',
  titleDetail: [], cellDetail: [], tags: [], week: null, multiCourse: null,
  ...extra,
});
const lab = (extra = {}) => course({
  courseSerialNo: null, teachClassId: '2026-2027-1-COURSE-A-001-LAB-A-1',
  dayOfWeek: 2, beginSection: 6, endSection: 8, beginTime: null, endTime: null,
  weeksAndTeachers: null,
  titleDetail: ['上课教师：教师乙,教师丙[14-16周(双)]', '实验项目名称：实验项目甲'],
  cellDetail: [{text: '（本【实验课】）测试课程'}, {text: '教师乙,教师丙[14-16周(双)]'}],
  tags: [{text: '本【实验课】', color: ''}], ...extra,
});

function run(options = {}) {
  const origin = options.origin || 'https://byxt-443.e1.buaa.edu.cn';
  const requests = [], historyCalls = [];
  const document = {documentElement: {innerHTML: 'PRIVATE_AUTHENTICATED_PORTAL'}};
  const payload = {
    code: '0', datas: {
      code: 'TEST-STUDENT', name: '测试学生[TEST-STUDENT]',
      arrangedList: options.rows || [course()],
      notArrangeList: options.unarranged || [], practiceList: [],
    },
  };
  class XHR {
    headers = {};
    open(method, url, async) {
      assert.equal(async, false, 'released WebViews require a synchronous result');
      Object.assign(this, {method, url});
    }
    setRequestHeader(key, value) { this.headers[key] = value; }
    send(body) {
      assert.ok(!document.documentElement.innerHTML.includes('PRIVATE_AUTHENTICATED_PORTAL'));
      assert.equal(historyCalls[0], '/nju-schedule-import');
      requests.push({method: this.method, url: this.url, body, headers: this.headers});
      assert.ok(this.url.startsWith(origin + '/jwapp/sys/homeapp/api/home/'));
      let result;
      if (this.url.endsWith('/student/schoolCalendars.do')) {
        assert.equal(this.method, 'GET');
        result = {code: '0', datas: options.terms || terms};
      } else if (this.url.includes('/getTermWeeks.do?')) {
        assert.equal(new URL(this.url).searchParams.get('termCode'), termCode);
        result = {code: '0', datas: options.calendar || calendar};
      } else if (this.url.endsWith('/student/getMyScheduleDetail.do')) {
        assert.equal(this.method, 'POST');
        assert.equal(body, 'termCode=2026-2027-1&campusCode=&type=term');
        result = payload;
      } else assert.fail('Unexpected endpoint: ' + this.url);
      this.status = options.status || 200;
      this.responseText = options.responseText ?? JSON.stringify(result);
    }
  }
  const context = {
    window: {location: {origin, hostname: new URL(origin).hostname},
      __NJU_SCHEDULE_IMPORT_CONFIG__: {semester_start_monday: options.monday || '2026-09-07'}},
    document, history: {replaceState: (_, __, url) => historyCalls.push(url)},
    XMLHttpRequest: XHR,
  };
  const encoded = vm.runInNewContext(script, context, {timeout: 1000});
  assert.equal(typeof encoded, 'string');
  return {result: JSON.parse(decodeURIComponent(encoded)), encoded, requests, context};
}

test('BUAA config uses the verified WebVPN login flow and one cross-platform parser', () => {
  assert.equal(school.initialUrl, 'https://byxt-443.e1.buaa.edu.cn/');
  assert.equal(school.targetUrl, school.initialUrl + 'jwapp/sys/homeapp/home/index.html');
  assert.equal(school.redirectUrl, '');
  assert.ok(!school.initialUrl.startsWith(school.targetUrl));
  assert.equal(school.extractJSfileAndroid, school.extractJSfileiOS);
  assert.equal(school.extractJSfileiOS, school.extractJSfileOHOS);
  assert.ok(school.extractJSfileAndroid.endsWith('/tools/buaabksjw.js'));
  const sandbox = {window: {}};
  vm.runInNewContext(school.preExtractJS, sandbox);
  assert.equal(sandbox.window.__NJU_SCHEDULE_IMPORT_CONFIG__.semester_start_monday,
    school.semester_start_monday);
  assert.equal(school.semester_start_monday, '2026-09-07');
  assert.equal(school.week_count, 19);
  assert.equal(school.class_time_list.length, 14);
  assert.deepEqual(school.class_time_list[13], {start: '21:30', end: '22:15'});
  assert.ok(school.banner_content.includes('未排课'));
});
test('BUAA selects the current term, requests the whole semester and respects app fields', () => {
  const {result, requests} = run();
  assert.equal(result.name, '2026-2027学年第1学期');
  assert.equal(result.semester_start_monday, '2026-09-07');
  assert.equal(requests.length, 3);
  assert.deepEqual(result.courses[0], {
    name: '测试课程', classroom: '教学楼101', class_number: '["COURSE-A","001"]',
    teacher: '教师甲', test_time: '', test_location: '', link: null,
    weeks: [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    week_time: 1, start_time: 3, time_count: 2, course_id: 1,
    import_type: 1, info: '', data: null,
  });
  assert.ok(!JSON.stringify(result).includes('TEST-STUDENT'));
});
test('BUAA only sends timetable requests to the logged-in origin', () => {
  for (const origin of ['https://byxt.buaa.edu.cn', 'https://byxt-443.e1.buaa.edu.cn']) {
    assert.equal(run({origin}).requests.length, 3);
  }
  assert.throws(() => run({origin: 'https://sso.buaa.edu.cn'}), /请先登录/);
});
test('BUAA preserves single periods, Sunday and the last evening period', () => {
  const c = run({rows: [course({dayOfWeek: 7, beginSection: 14, endSection: 14})]}).result.courses[0];
  assert.equal(c.week_time, 7);
  assert.equal(c.start_time, 14);
  assert.equal(c.time_count, 0);
});
test('BUAA parses ranges, singles, odd/even weeks, duplicates and full-width punctuation', () => {
  for (const [text, expected] of [
    ['1-6周(单),8周[理论]/教师甲[主讲]', [1, 3, 5, 8]],
    ['14－16周（双）[实验]/教师甲[主讲]', [14, 16]],
    ['8周，1-3周、3周[理论]/教师甲[主讲]', [1, 2, 3, 8]],
  ]) assert.deepEqual(run({rows: [course({weeksAndTeachers: text})]}).result.courses[0].weeks, expected);
});
test('BUAA retains multiple teachers without teaching-role labels', () => {
  const rows = [course({weeksAndTeachers: '9-16周[实验]/教师甲[主讲],教师乙[辅讲]'})];
  assert.equal(run({rows}).result.courses[0].teacher, '教师甲,教师乙');
});
test('BUAA reads all rotating teachers and their own weeks/periods from the full tooltip', () => {
  const {courses} = run({rows: [course({
    weeksAndTeachers: '1-2周[理论]/教师甲[主讲]',
    titleDetail: ['上课教师：教师甲/[1-2周]/3-5节 教师乙/[3-4周]/3-4节 教师丙/[6周]/6-7节'],
  })]}).result;
  assert.equal(courses.length, 3);
  assert.deepEqual(courses.map(c => c.weeks), [[1, 2], [3, 4], [6]]);
  assert.deepEqual(courses.map(c => [c.teacher, c.start_time, c.time_count]),
    [['教师甲', 3, 2], ['教师乙', 3, 1], ['教师丙', 6, 1]]);
  assert.equal(new Set(courses.map(c => c.course_id)).size, 1);
});
test('BUAA keeps theory and practice weeks taught by the same teacher', () => {
  const {courses} = run({rows: [course({
    weeksAndTeachers: '2-9周[理论]/教师甲[主讲]',
    titleDetail: ['上课教师：教师甲/[10-17周]/3-5节 教师甲/[2-9周]/3-5节'],
  })]}).result;
  assert.equal(courses.length, 1);
  assert.deepEqual(courses[0].weeks, Array.from({length: 16}, (_, i) => i + 2));
});
test('BUAA uses the canonical course name across localized timetable responses', () => {
  const {courses} = run({rows: [course({courseName: 'Test Course', titleDetail: ['课程名：测试课程']})]}).result;
  assert.equal(courses[0].name, '测试课程');
});
test('BUAA rejects a partially recognizable full tooltip', () => {
  assert.throws(() => run({rows: [course({titleDetail:
    ['上课教师：教师甲/[1-2周]/3-5节 教师乙/不完整安排']})]}), /完整授课安排格式异常/);
});
test('BUAA reads lab weeks and teachers when API timing text is null', () => {
  const {courses} = run({rows: [lab()]}).result;
  assert.deepEqual(courses[0].weeks, [14, 16]);
  assert.equal(courses[0].teacher, '教师乙,教师丙');
  assert.equal(courses[0].info, '实验项目名称：实验项目甲');
});
test('BUAA can read a lab teacher cell if the tooltip is absent', () => {
  assert.deepEqual(run({rows: [lab({titleDetail: []})]}).result.courses[0].weeks, [14, 16]);
});
test('BUAA groups different lab projects and teachers under the enrolled course', () => {
  const {courses} = run({rows: [course(), lab(), lab({
    teachClassId: '2026-2027-1-COURSE-A-001-LAB-B-2',
    titleDetail: ['上课教师：教师丁[9周]', '实验项目名称：实验项目乙'],
  })]}).result;
  assert.equal(courses.length, 3);
  assert.equal(new Set(courses.map(c => c.course_id)).size, 1);
  assert.equal(new Set(courses.map(c => c.class_number)).size, 1);
});
test('BUAA resolves the enrolled lab section from unscheduled registration', () => {
  const unarranged = [course({beginSection: null, endSection: null, dayOfWeek: null})];
  assert.equal(run({rows: [lab()], unarranged}).result.courses[0].class_number, '["COURSE-A","001"]');
});
test('BUAA distinguishes same-name courses, real sections and unambiguous combined lab groups', () => {
  const {courses} = run({rows: [
    course(), course({courseSerialNo: '003'}), course({courseCode: 'COURSE-B'}),
    lab({teachClassId: '2026-2027-1-COURSE-A-001002-LAB-A-1'}),
  ]}).result;
  assert.equal(new Set(courses.map(c => c.course_id)).size, 3);
  assert.equal(courses[0].course_id, courses[3].course_id);
});
test('BUAA merges repeated occurrences, preserving separate rooms, times and week-specific spans', () => {
  const rows = [course(), course(), course({weeksAndTeachers: '19周[理论]/教师甲[主讲]'}),
    course({placeName: '教学楼202'}), course({endSection: 4, weeksAndTeachers: '11周[理论]/教师甲[主讲]'})];
  const {courses} = run({rows}).result;
  assert.equal(courses.length, 3);
  assert.ok(courses[0].weeks.includes(19));
  assert.deepEqual(courses[2].weeks, [11]);
  assert.equal(courses[2].time_count, 1);
});
test('BUAA imports scheduled rows and uses unscheduled rows only to resolve sections', () => {
  assert.equal(run({unarranged: [course({courseCode: 'PENDING'})]}).result.courses.length, 1);
});
test('BUAA fails the whole import rather than dropping an invalid arrangement', () => {
  for (const bad of [
    course({weeksAndTeachers: '无周次/教师甲'}),
    course({weeksAndTeachers: '19-20周/教师甲'}),
    course({beginSection: 5, endSection: 3}), course({dayOfWeek: null}),
    course({endSection: 15}), course({courseCode: ''}), course({courseName: ''}),
    lab({titleDetail: [], cellDetail: []}),
  ]) assert.throws(() => run({rows: [course(), bad]}));
});
test('BUAA rejects ambiguous experiment sections', () => {
  assert.throws(() => run({rows: [course(), course({courseSerialNo: '002'}),
    lab({teachClassId: '2026-2027-1-COURSE-A-001002-LAB-A-1'})]}), /无法匹配/);
});
test('BUAA rejects login pages, HTTP errors and unsuccessful JSON without leaking its contents', () => {
  for (const options of [
    {status: 401}, {responseText: '<html>PRIVATE_RESPONSE</html>'},
    {responseText: '{"code":"1","msg":"PRIVATE_RESPONSE"}'},
    {responseText: 'null'},
  ]) assert.throws(() => run(options), e => !e.message.includes('PRIVATE_RESPONSE'));
});
test('BUAA rejects missing current semesters, empty schedules and mismatched calibration', () => {
  for (const options of [{terms: []}, {terms: [{...terms[1], selected: false}]},
    {terms: [terms[1], terms[1]]}, {rows: []}, {calendar: []},
    {monday: '2026-08-31'}, {calendar: [{serialNumber: 1, startDate: '2026-09-08'}]}]) {
    assert.throws(() => run(options));
  }
});
test('BUAA remains compatible with the released app URI/JSON decoding path', () => {
  const name = '测试 "引号" 100% & \\ 🙂';
  const {result, encoded} = run({rows: [course({courseName: name})]});
  assert.equal(result.courses[0].name, name);
  assert.deepEqual(JSON.parse(decodeURIComponent(encoded.replaceAll('"', ''))), result);
});
