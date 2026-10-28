const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const school = JSON.parse(fs.readFileSync('api/schoolList.json', 'utf8')).data
  .find(item => item.pinyin === 'nanjingshifandaxuebenkejiaowu');
const script = fs.readFileSync('api/tools/nnubksjw.js', 'utf8');
const endpoint = 'https://ehallapp.nnu.edu.cn/jwapp/sys/wdkb/modules/xskcb/cxxszhxqkb.do';
const sample = (extra = {}) => ({
  KCM: '测试课程', SKXQ: 1, KSJC: 3, JSJC: 4, SKZC: '10100001',
  JASMC: '测试教室', KCH: 'TEST', KXH: '01', SKJS: '测试教师',
  XNXQDM_DISPLAY: '2026-2027学年第1学期', XF: 2, ...extra,
});

function run({rows = [sample()], text = '2026-2027学年第1学期',
  resources = [{name: endpoint}], status = 200, body, code = '1'} = {}) {
  const request = {};
  class XHR {
    open(method, url, async) {Object.assign(request, {method, url, async});}
    setRequestHeader(name, value) {(request.headers ??= {})[name] = value;}
    set withCredentials(value) {request.withCredentials = value;}
    send(data) {
      request.data = data;
      this.status = status;
      this.responseText = body ?? JSON.stringify({datas: {
        cxxszhxqkb: {extParams: {code}, rows},
      }});
    }
  }
  const encoded = vm.runInNewContext(script, {
    document: {body: {innerText: text}},
    performance: {getEntriesByType(type) {assert.equal(type, 'resource'); return resources;}},
    XMLHttpRequest: XHR,
  }, {timeout: 1000});
  return {result: JSON.parse(decodeURIComponent(encoded)), request, encoded};
}

test('NNU config uses the same parser on all platforms and a Monday week anchor', () => {
  assert.ok(school);
  assert.equal(school.extractJSfileAndroid, school.extractJSfileiOS);
  assert.equal(school.extractJSfileiOS, school.extractJSfileOHOS);
  assert.ok(school.extractJSfileAndroid.endsWith('/tools/nnubksjw.js'));
  assert.equal(new Date(school.semester_start_monday + 'T00:00:00Z').getUTCDay(), 1);
  assert.equal(school.class_time_list.length, 12);
});

test('NNU synchronously returns course fields, exact week bits and inclusive period boundaries', () => {
  const {result, request} = run();
  assert.equal(request.method, 'POST');
  assert.equal(request.url, endpoint);
  assert.equal(request.async, false);
  assert.equal(request.withCredentials, true);
  assert.equal(request.data, 'XNXQDM=2026-2027-1');
  assert.deepEqual(result.courses[0], {
    name: '测试课程', classroom: '测试教室', class_number: 'TEST-01',
    teacher: '测试教师', test_time: '', test_location: '', link: null,
    week: [1, 3, 8], weeks: [1, 3, 8], week_time: 1,
    start_time: 3, time_count: 1, import_type: 1, info: '2学分', data: null,
  });
});

test('NNU keeps twelve scheduled records and skips records without usable class times', () => {
  const scheduled = Array.from({length: 12}, (_, i) => sample({KCM: '课' + i}));
  const unscheduled = [sample({SKZC: ''}), sample({SKXQ: null}),
    sample({KSJC: null}), sample({JSJC: 2}), sample({KCM: ''})];
  const {result} = run({rows: [...scheduled, ...unscheduled]});
  assert.equal(result.courses.length, 12);
  assert.deepEqual(result.courses.map(c => c.name), scheduled.map(c => c.KCM));
});

test('NNU understands Chinese term numbers and uses the last observed timetable endpoint', () => {
  const latest = endpoint + '?latest=1';
  const {request} = run({text: '2026－2027 学年第 二 学期',
    resources: [{name: endpoint}, {name: 'https://example.com/style.css'}, {name: latest}]});
  assert.equal(request.data, 'XNXQDM=2026-2027-2');
  assert.equal(request.url, latest);
});

test('NNU aborts missing semester, missing endpoint, HTTP failure and invalid API responses', () => {
  for (const options of [{text: '登录页面'}, {resources: []}, {status: 503},
    {body: '<html>登录失效</html>'}, {body: '{}'}, {code: '0'}, {rows: []}]) {
    assert.throws(() => run(options));
  }
});

test('NNU preserves punctuation and Unicode through the app import encoding', () => {
  const name = '带"引号" 100% & \\ 换行\n🙂';
  const {result, encoded} = run({rows: [sample({KCM: name, JASMC: null, SKJS: null})]});
  assert.equal(result.courses[0].name, name);
  assert.equal(result.courses[0].classroom, '');
  assert.equal(result.courses[0].teacher, '');
  assert.deepEqual(JSON.parse(decodeURIComponent(encoded.replaceAll('"', ''))), result);
});
