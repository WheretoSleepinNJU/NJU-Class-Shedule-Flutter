const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const school = JSON.parse(fs.readFileSync('api/schoolList.json', 'utf8')).data
  .find(item => item.pinyin === 'nanjingshifandaxuebenkejiaowu');
const script = fs.readFileSync('api/tools/nnubksjw.js', 'utf8');

function item({name = '测试课程', teacher = '测试教师',
  detail = '1-3、8周，星期一，3-4节，测试教室', nestedName = false} = {}) {
  return {querySelector(selector) {
    if (selector === '.mtt_item_kcmc') return {
      textContent: name + (nestedName ? ' 不应混入的教师' : ''),
      childNodes: [{nodeType: 3, textContent: name},
        ...(nestedName ? [{nodeType: 1, textContent: '不应混入的教师'}] : [])],
    };
    if (selector === '.mtt_item_jxbmc') return {textContent: teacher};
    if (selector === '.mtt_item_room') return {textContent: detail};
    assert.fail('Unexpected item selector: ' + selector);
  }};
}
function cell(items = [item()], dataset = {week: '1', beginUnit: '3', endUnit: '4'}) {
  return {dataset, querySelectorAll(selector) {
    assert.equal(selector, '.mtt_arrange_item');
    return items;
  }};
}
function run({cells = [cell()], text = '2026-2027学年第1学期'} = {}) {
  const encoded = vm.runInNewContext(script, {
    document: {body: {innerText: text}, querySelectorAll(selector) {
      assert.equal(selector, 'td[data-role="item"][data-week]');
      return cells;
    }}, Node: {TEXT_NODE: 3},
  }, {timeout: 1000});
  assert.equal(typeof encoded, 'string');
  return {result: JSON.parse(decodeURIComponent(encoded)), encoded};
}

test('NNU config opens the new portal with one parser and a Monday anchor', () => {
  assert.equal(school.initialUrl, 'https://ehallapp.nnu.edu.cn/jwapp/sys/syxkjg/*default/index.do');
  assert.equal(school.targetUrl, school.initialUrl + '#/wdkb');
  assert.equal(school.extractJSfileAndroid, school.extractJSfileiOS);
  assert.equal(school.extractJSfileiOS, school.extractJSfileOHOS);
  assert.ok(school.extractJSfileAndroid.endsWith('/tools/nnubksjw.js'));
  assert.equal(new Date(school.semester_start_monday + 'T00:00:00Z').getUTCDay(), 1);
  assert.equal(school.class_time_list.length, 12);
});
test('NNU synchronously reads courses with app field and period contracts', () => {
  const {result} = run();
  assert.equal(result.name, '2026-2027学年第1学期');
  assert.deepEqual(result.courses[0], {
    name: '测试课程', classroom: '测试教室', class_number: '', teacher: '测试教师',
    test_time: '', test_location: '', link: null, weeks: [1, 2, 3, 8],
    week_time: 1, start_time: 3, time_count: 1, course_id: 0,
    import_type: 1, info: '', data: null,
  });
});
test('NNU does not merge a nested teacher into the course name', () => {
  const {result} = run({cells: [cell([item({nestedName: true})])]});
  assert.equal(result.courses[0].name, '测试课程');
  assert.equal(result.courses[0].teacher, '测试教师');
});
test('NNU understands spaced Chinese semester numbers', () => {
  assert.equal(run({text: '2026－2027 学年第 二 学期'}).result.name,
    '2026-2027学年第2学期');
});
test('NNU parses mixed ranges, odd/even weeks and repeated weeks', () => {
  for (const [detail, expected] of [
    ['1-6周（单），星期一，3-4节，教室', [1, 3, 5]],
    ['1－6周(双)，星期一，3-4节，教室', [2, 4, 6]],
    ['8，1-3、3周，星期一，3-4节，教室', [1, 2, 3, 8]],
  ]) assert.deepEqual(run({cells: [cell([item({detail})])]}).result.courses[0].weeks, expected);
});
test('NNU reads Chinese/numeric weekdays and single-period boundaries', () => {
  for (const [day, expected] of [['三', 3], ['7', 7], ['日', 7], ['天', 7]]) {
    const {result} = run({cells: [cell([item({detail: `1-2周，星期${day}，12-12节，教室`})])]});
    assert.equal(result.courses[0].week_time, expected);
    assert.equal(result.courses[0].start_time, 12);
    assert.equal(result.courses[0].time_count, 0);
  }
});
test('NNU falls back to cell coordinates when detail omits the time', () => {
  const {result} = run({cells: [cell([item({detail: '1-2周，测试教室'})],
    {week: '5', beginUnit: '7', endUnit: '9'})]});
  assert.equal(result.courses[0].week_time, 5);
  assert.equal(result.courses[0].start_time, 7);
  assert.equal(result.courses[0].time_count, 2);
  assert.equal(result.courses[0].classroom, '测试教室');
});
test('NNU deduplicates exact arrangements while keeping different rooms', () => {
  const {result} = run({cells: [cell([item(), item(),
    item({detail: '1-3、8周，星期一，3-4节，另一教室'})])]});
  assert.equal(result.courses.length, 2);
  assert.deepEqual(result.courses.map(c => c.classroom), ['测试教室', '另一教室']);
});
test('NNU keeps one course identity across meetings and separates names', () => {
  const {result} = run({cells: [cell([item(),
    item({detail: '1-3周，星期三，7-8节，另一教室', teacher: '另一教师'}),
    item({name: '另一门课'})])]});
  const [first, meeting, other] = result.courses;
  assert.equal(first.course_id, meeting.course_id);
  assert.notEqual(first.course_id, other.course_id);
  // CourseGroup prioritizes nonempty teaching-section IDs over course_id.
  // An ID derived from the period would split editing groups and colors.
  assert.equal(first.class_number, '');
  assert.equal(meeting.class_number, '');
});
test('NNU fails the whole import if any named course cannot be parsed', () => {
  assert.throws(() => run({cells: [cell([item(), item({name: '坏数据', detail: '没有周次'})])]}),
    /成功解析 1 条，但有 1 条无法识别/);
});
test('NNU rejects unloaded pages and invalid schedule coordinates', () => {
  for (const options of [{text: '登录页面'}, {cells: []}, {cells: [cell([])]},
    {cells: [cell([item({name: ''})])]},
    {cells: [cell([item({detail: '41-42周，教室'})])]},
    {cells: [cell([item({detail: '1-2周，教室'})], {week: '0', beginUnit: '3', endUnit: '4'})]},
    {cells: [cell([item({detail: '1-2周，教室'})], {week: '1', beginUnit: '4', endUnit: '3'})]}]) {
    assert.throws(() => run(options));
  }
});
test('NNU preserves Unicode through the released app decode path', () => {
  const name = '带"引号" 100% & \\ 🙂';
  const {result, encoded} = run({cells: [cell([item({name, teacher: null,
    detail: '1-2周，星期一，3-4节'})])]});
  assert.equal(result.courses[0].name, name);
  assert.equal(result.courses[0].classroom, '');
  assert.equal(result.courses[0].teacher, '');
  assert.deepEqual(JSON.parse(decodeURIComponent(encoded.replaceAll('"', ''))), result);
});
