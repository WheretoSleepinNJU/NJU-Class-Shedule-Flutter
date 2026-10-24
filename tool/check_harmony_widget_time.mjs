// Node 24+: execute the actual pure ArkTS time helper after stripping types.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import assert from 'node:assert/strict';
const source = readFileSync(new URL('../ohos/entry/src/main/ets/widget/utils/TimeHelper.ets', import.meta.url), 'utf8');
const { isCourseActive } = await import('data:text/javascript,' + encodeURIComponent(stripTypeScriptTypes(source)));
const cases = [
  ['07:29', false, 'before approaching window'],
  ['07:30', true, 'approaching boundary'],
  ['08:00', true, 'start boundary'],
  ['08:49', true, 'last active minute'],
  ['08:50', false, 'end boundary is exclusive'],
  ['08:51', false, 'after course ended'],
];
for (const [time, expected, label] of cases) {
  assert.equal(isCourseActive('08:00', '08:50', time), expected, label);
  console.log(`PASS: ${label}`);
}
console.log(`${cases.length} Harmony time boundary checks passed`);
