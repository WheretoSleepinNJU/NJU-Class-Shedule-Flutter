// Run with Node 24+: node test/native/harmony_widget_day_test.cjs
const { readFileSync } = require('node:fs');
const { stripTypeScriptTypes } = require('node:module');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const source = readFileSync('ohos/entry/src/main/ets/widget/utils/WidgetDaySelector.ets','utf8')
  .replace(/^import .*;\n/m, '').replace('export function selectWidgetDay', 'function selectWidgetDay');
const select = vm.runInNewContext(stripTypeScriptTypes(source) + '\nselectWidgetDay;');
const lesson = {name:'course', classroom:'A',color:'#0095F9',startTimeStr:'08:00',endTimeStr:'09:00',startNode:1,step:1};
const data = { date:'周日',courses:[lesson],scheduleName:'学期',tomorrowPreviewHour:21,days:[
  {date:'周日',dateKey:'2026-10-25',week:1,courses:[lesson]},
  {date:'周一',dateKey:'2026-10-26',week:2,courses:[lesson]},
]};
let checks = 0;
function check(f) {f(); checks++;}
check(() => assert.equal(select(data,new Date(2026,9,25,8,30)).dateKey,'2026-10-25'));
check(() => assert.equal(select(data,new Date(2026,9,25,20,59)).tomorrow,undefined));
check(() => assert.equal(select(data,new Date(2026,9,25,21,0)).tomorrow,true));
check(() => assert.equal(select(data,new Date(2026,9,25,21,0)).week,2));
check(() => assert.equal(select(data,new Date(2026,9,26,0,0)).dateKey,'2026-10-26'));
check(() => assert.equal(select(data,new Date(2026,9,26,0,0)).tomorrow,undefined));
check(() => assert.equal(select(data,new Date(2026,9,27)).stale,true));
check(() => assert.equal(select(data,new Date(2026,9,27)).courses.length,0));
const active = {...data,days:[{...data.days[0],courses:[{...lesson,endTimeStr:'22:00'}]},data.days[1]]};
check(() => assert.equal(select(active,new Date(2026,9,25,21,0)).tomorrow,undefined));
check(() => assert.equal(select(active,new Date(2026,9,25,22,0)).tomorrow,true));
check(() => assert.equal(select({...data,days:undefined}).courses.length,1));
console.log(`${checks}/${checks} Harmony native day selection checks passed`);
