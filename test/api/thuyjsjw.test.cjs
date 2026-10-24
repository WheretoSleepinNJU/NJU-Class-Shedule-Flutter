const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const school = JSON.parse(fs.readFileSync('api/schoolList.json', 'utf8')).data
  .find(item => item.pinyin === 'qinghuadaxueyanjiusheng');
const script = fs.readFileSync('api/tools/'+new URL(school.extractJSfileiOS).pathname.split('/').pop(), 'utf8');
const vpnPortal = 'https://webvpn.tsinghua.edu.cn/https/77726476706e69737468656265737421f9f9479369247b59700f81b9991b2631506205de';
const vpnAcademic = '/https/77726476706e69737468656265737421eaff4b8b69336153301c9aa596522b20bc86e6e559a9b290/';
const sample = (extra = {}) => ({nr:'匿名测试课', dd:'测试教室', nq:'2026-09-14',
  kssj:'08:50', jssj:'09:35', fl:'上课', ...extra});
function run({responses, config, hostname='zhjw.cic.tsinghua.edu.cn', pathname} = {}) {
  const urls=[];
  class XHR {
    open(method,url,async) {assert.equal(method,'GET');assert.equal(async,false);urls.push(url);}
    setRequestHeader() {}
    send() {
      const item=responses ? responses[urls.length-1] : (urls.length===1 ? [sample()] : []);
      if (item instanceof Error) throw item;
      this.status=item?.status ?? 200;
      this.responseText=typeof item==='string' ? item : item?.body ?? `m(${JSON.stringify(item ?? [])});`;
    }
  }
  const document={documentElement:{innerHTML:'<body>private academic calendar</body>'}};
  const history={replaceState(_state,_title,path) {this.path=path;context.window.location.pathname=path;}};
  let navigation;
  const context=vm.createContext({window:{location:{replace(url){navigation=url;}}},
    document,history,XMLHttpRequest:XHR});
  // Follow the original released app: preExtractJS, then remote parser.
  vm.runInContext(school.preExtractJS,context);
  assert.ok(navigation.startsWith(vpnPortal+'/f/info/gxfw_fg/common/cardRoaming/JXRL_YJS#nju-schedule='));
  delete context.window.__NJU_SCHEDULE_IMPORT_CONFIG__;
  context.window.location={hostname,origin:'https://'+hostname,pathname:pathname ?? (hostname==='webvpn.tsinghua.edu.cn' ? vpnAcademic+'jxmh.do' : '/jxmh.do'),hash:new URL(navigation).hash};
  if(config !== undefined) context.window.__NJU_SCHEDULE_IMPORT_CONFIG__=config;
  const encoded=vm.runInContext(script,context);
  return {result:JSON.parse(decodeURIComponent(encoded)),encoded,urls,document,history,navigation};
}
test('remote config works with the unchanged app navigation and decode contract',()=>{
  assert.equal(school.redirectUrl,'');
  assert.equal(school.initialUrl,vpnPortal+'/f/info/gxfw_fg/common/index');
  assert.equal(school.targetUrl,vpnPortal+'/f/info_mobile/');
  assert.ok((vpnPortal+'/f/info_mobile/studentIndex').startsWith(school.targetUrl));
  assert.ok(!school.initialUrl.startsWith(school.targetUrl));
  assert.ok(!(vpnPortal+'/f/info/gxfw_fg/common/cardRoaming/JXRL_YJS').startsWith(school.targetUrl));
  // Harmony also reports a page-finished callback after replaceState. The
  // sanitized diagnostics URL must not trigger another import while SSO runs.
  assert.ok(!'https://webvpn.tsinghua.edu.cn/nju-schedule-import'.startsWith(school.targetUrl));
  for (const path of ['gxfw_fg/common/index','mb/index'])
    assert.ok(!(vpnPortal+'/f/info/'+path).startsWith(school.targetUrl));
  assert.ok(!'https://id.tsinghua.edu.cn/do/off/ui/auth/login/form/example'.startsWith(school.targetUrl));
  assert.equal(school.delayTime,8);
  assert.ok(school.preExtractJS.includes('location.replace'));
  assert.equal(school.loginTargetUrl,undefined);
  assert.equal(school.extractJSasset,undefined);
  assert.equal(school.extractJSfileAndroid,school.extractJSfileiOS);
  assert.equal(school.extractJSfileiOS,school.extractJSfileOHOS);
  const {encoded,result}=run();
  assert.deepEqual(JSON.parse(decodeURIComponent(encoded.replaceAll('"',''))),result);
});
test('preExtractJS supplies semester metadata and clears academic HTML before legacy diagnostics',()=>{
  const context=vm.createContext({window:{location:{replace(){}}},document:{documentElement:{}},history:{replaceState(){}}});
  vm.runInContext(school.preExtractJS,context);
  assert.equal(context.window.__NJU_SCHEDULE_IMPORT_CONFIG__.semester_start_monday,school.semester_start_monday);
  assert.equal(context.window.__NJU_SCHEDULE_IMPORT_CONFIG__.week_count,school.week_count);
  const {document,history}=run();
  assert.ok(!document.documentElement.innerHTML.includes('private academic calendar'));
  assert.match(document.documentElement.innerHTML,/正在读取清华研究生课表/);
  assert.equal(history.path,'/nju-schedule-import');
});
test('configured autumn dates cover all 16 weeks without overrunning final batch',()=>{
  const {result,urls}=run();
  assert.equal(urls.length,6);
  assert.match(urls[0],/p_start_date=20260914&p_end_date=20261004/);
  assert.match(urls[5],/p_start_date=20261228&p_end_date=20270103/);
  assert.match(result.name,/2026-2027.*秋季/);
  assert.equal(result.courses[0].start_time,2);
  assert.equal(result.courses[0].time_count,0);
});
test('changing semester config changes query dates and civil week numbers',()=>{
  const {result,urls}=run({config:{semester_start_monday:'2027-02-22',week_count:1},responses:[[sample({nq:'2027-02-28'})]]});
  assert.equal(urls.length,1);
  assert.match(urls[0],/20270222&p_end_date=20270228/);
  assert.equal(result.courses[0].week_time,7);
  assert.deepEqual(result.courses[0].weeks,[1]);
  assert.match(result.name,/2026-2027.*春季/);
});
test('no fixed semester fallback, invalid dates and non-Monday dates fail',()=>{
  for(const date of [undefined,'2026-02-30','2026-09-15'])
    assert.throws(()=>run({config:{semester_start_monday:date}}));
});
test('exact start/end boundaries map every Tsinghua period',()=>{
  const times=[['08:00','08:45'],['08:50','09:35'],['09:50','10:35'],['10:40','11:25'],['11:30','12:15'],['13:30','14:15'],['14:20','15:05'],['15:20','16:05'],['16:10','16:55'],['17:05','17:50'],['17:55','18:40'],['19:20','20:05'],['20:10','20:55'],['21:00','21:45']];
  const {result}=run({responses:[times.map(([kssj,jssj],i)=>sample({nr:'测试'+i,kssj,jssj}))]});
  assert.deepEqual(result.courses.map(c=>c.start_time),times.map((_,i)=>i+1));
  assert.ok(result.courses.every(c=>c.time_count===0));
});
test('full-width colon, seconds, merged weeks, duplicates and split periods',()=>{
  const {result}=run({responses:[[sample({kssj:'8：50',jssj:'09:35:00'}),sample(),
    sample({nq:'2026-09-21'}),sample({kssj:'09:50',jssj:'11:25'})]]});
  assert.equal(result.courses.length,2);
  assert.deepEqual(result.courses.map(c=>[c.start_time,c.time_count,c.weeks]),[[2,2,[1]],[2,0,[2]]]);
});
test('out-of-semester dates and personal events cannot create phantom courses',()=>{
  const {result}=run({responses:[[sample(),sample({nq:'2026-09-13'}),sample({nq:'2027-01-04'}),sample({fl:'个人日历',nr:'个人事项'})]]});
  assert.equal(result.courses.length,1);
  assert.deepEqual(result.courses[0].weeks,[1]);
});
for(const [name,response] of Object.entries({html:'<html>用户登陆超时</html>',badJson:'m(broken)',wrongShape:'m({})',httpError:{status:503,body:'unavailable'}}))
  test(`failed ${name} batch aborts instead of importing a partial table`,()=>assert.throws(()=>run({responses:[[sample()],response]})));
test('empty semester, malformed record and unmatched times are explicit failures',()=>{
  for(const response of [[],[sample({kssj:''})],[sample({kssj:'08:47'})]])
    assert.throws(()=>run({responses:[response]}));
});
test('VPN uses same-origin academic endpoint; unrelated origin is rejected',()=>{
  assert.ok(run({hostname:'webvpn.tsinghua.edu.cn'}).urls[0].startsWith('https://webvpn.tsinghua.edu.cn'+vpnAcademic+'jxmh_out.do'));
  assert.throws(()=>run({hostname:'example.com'}));
});

test('VPN queries preserve HTTPS or HTTP route before diagnostic URL sanitization',()=>{
  for(const protocol of ['http','https']) {
    const prefix=vpnAcademic.replace('/https/', '/'+protocol+'/');
    const {urls,history}=run({hostname:'webvpn.tsinghua.edu.cn',pathname:prefix+'jxmh.do'});
    assert.ok(urls.every(url=>url.startsWith('https://webvpn.tsinghua.edu.cn'+prefix+'jxmh_out.do?')));
    assert.equal(history.path,'/nju-schedule-import');
  }
});
test('VPN login, portal and unknown encrypted hosts cannot be parsed as academic pages',()=>{
  for(const pathname of ['/login',new URL(vpnPortal).pathname+'/f/info_mobile/studentIndex','/https/unknown/jxmh.do'])
    assert.throws(()=>run({hostname:'webvpn.tsinghua.edu.cn',pathname}));
});

test('unordered adjacent periods and duplicate records become one continuous course',()=>{
  const {result}=run({responses:[[sample({kssj:'09:50',jssj:'10:35'}),sample({kssj:'08:00',jssj:'08:45'}),sample(),sample()]]});
  assert.deepEqual(result.courses.map(c=>[c.start_time,c.time_count,c.weeks]),[[1,2,[1]]]);
});
test('different weekly lengths retain exact weeks instead of extending all weeks',()=>{
  const {result}=run({responses:[[sample({kssj:'08:00',jssj:'08:45'}),sample(),sample({nq:'2026-09-21',kssj:'08:00',jssj:'08:45'}),sample({nq:'2026-09-28'})]]});
  assert.deepEqual(result.courses.map(c=>[c.start_time,c.time_count,c.weeks]),[[1,1,[1]],[1,0,[2]],[2,0,[3]]]);
});
test('different rooms, different days and gaps stay separate',()=>{
  const {result}=run({responses:[[sample({kssj:'08:00',jssj:'08:45'}),sample({dd:'另一教室'}),sample({nq:'2026-09-15'}),sample({kssj:'10:40',jssj:'11:25'})]]});
  assert.equal(result.courses.length,4);
  assert.ok(result.courses.every(c=>c.time_count===0));
});
test('overlapping multi-period records and adjacent single periods merge once',()=>{
  const {result}=run({responses:[[sample({kssj:'08:00',jssj:'10:35'}),sample({kssj:'09:50',jssj:'11:25'}),sample({kssj:'11:30',jssj:'12:15'})]]});
  assert.deepEqual(result.courses.map(c=>[c.start_time,c.time_count,c.weeks]),[[1,4,[1]]]);
});
test('merging preserves the exact set of name, room, date and occupied periods',()=>{
  const periods=[['08:00','08:45'],['08:50','09:35'],['09:50','10:35'],['10:40','11:25']];
  const input=[];
  for(let week=0;week<5;week++) for(let day=0;day<3;day++) for(let slot=0;slot<4;slot++) {
    if((week+day+slot)%3===0)continue;
    input.push(sample({nr:'课'+(slot%2),dd:'教室'+(day%2),nq:new Date(Date.UTC(2026,8,14+week*7+day)).toISOString().slice(0,10),kssj:periods[slot][0],jssj:periods[slot][1]}));
  }
  const {result}=run({responses:[input]});
  const before=new Set(input.map(x=>[x.nr,x.dd,x.nq,periods.findIndex(p=>p[0]===x.kssj)+1].join('|')));
  const after=new Set();
  for(const c of result.courses) for(const week of c.weeks) for(let slot=c.start_time;slot<=c.start_time+c.time_count;slot++) {
    const date=new Date(Date.UTC(2026,8,14+(week-1)*7+c.week_time-1)).toISOString().slice(0,10);
    after.add([c.name,c.classroom,date,slot].join('|'));
  }
  assert.deepEqual([...after].sort(),[...before].sort());
});
