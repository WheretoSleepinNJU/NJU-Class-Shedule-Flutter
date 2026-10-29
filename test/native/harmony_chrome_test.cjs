const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { stripTypeScriptTypes } = require('node:module');
const vm = require('node:vm');
const source = readFileSync('ohos/entry/src/main/ets/adaptive/HdsChromeState.ets', 'utf8').replace(/\bexport /g, '');
const { HdsChromeState, HdsHeaderState, HdsNavigationState } = vm.runInNewContext(
  stripTypeScriptTypes(source) + '\n({ HdsChromeState, HdsHeaderState, HdsNavigationState });');
const header = (overrides = {}) => JSON.stringify({ owner: 7, visible: true, interactive: true, canBack: true,
  tabLabels: ['已添加', '全校', '讲座'], selectedTabIndex: 0,
  actions: [{ index: 0, label: '保存', enabled: true }], ...overrides });
const navigation = (overrides = {}) => JSON.stringify({ owner: 8, visible: true, left: 80, top: 700, width: 240, height: 56,
  items: [{ label: '课表', icon: 'Months' }, { label: '课程', icon: 'NotesFill' }], ...overrides });

function ready() {
  const state = new HdsChromeState();
  state.updateHeader(header()); state.navigation = HdsNavigationState.decode(navigation()); state.ready = true;
  return state;
}
test('native input waits for the page and remains disabled while backgrounded', () => {
  const state = ready();
  state.ready = false;
  assert.equal(state.acceptsAction(7, 0), false);
  state.ready = true;
  assert.equal(state.acceptsAction(7, 0), true);
  state.resumed = false;
  assert.equal(state.acceptsAction(7, 0), false);
  assert.equal(state.acceptsNavigation(8, 1), false);
  assert.equal(state.header.visible, true);
  assert.equal(state.navigation.visible, true);
  state.resumed = true;
  assert.equal(state.acceptsNavigation(8, 1), true);
});
test('page ownership isolates actions, categories, old hides and old scroll reports', () => {
  const state = ready();
  assert.equal(state.acceptsAction(6, 0), false);
  assert.equal(state.acceptsCategory(6, 1), false);
  assert.equal(state.hideHeader(6), false);
  assert.equal(state.hideNavigation(7), false);
  assert.equal(state.updateScroll(6, 50), false);
  assert.equal(state.header.visible, true);
  assert.equal(state.navigation.visible, true);
  assert.equal(state.scrollOffset, 0);
});
test('popup coverage and disabled/loading buttons cannot dispatch native actions', () => {
  const state = ready();
  state.updateHeader(header({ interactive: false }));
  assert.equal(state.acceptsCategory(7, 1), false);
  assert.equal(state.acceptsAction(7, 0), false);
  for (const disabled of [{ enabled: false }, { loading: true }]) {
    state.updateHeader(header({ actions: [{ index: 0, label: '保存', ...disabled }] }));
    assert.equal(state.acceptsAction(7, 0), false);
  }
});
test('indices outside the active controls are rejected', () => {
  const state = ready();
  for (const index of [-1, 0.5, 3, 100]) assert.equal(state.acceptsCategory(7, index), false);
  for (const index of [-1, 0.5, 2, 100]) assert.equal(state.acceptsNavigation(8, index), false);
  assert.equal(state.acceptsCategory(7, 2), true);
  assert.equal(state.acceptsNavigation(8, 1), true);
});
test('scroll-only transport retains the native header model and clamps invalid offsets', () => {
  const state = ready(), original = state.header;
  assert.equal(state.updateScroll(7, 45), true);
  assert.equal(state.scrollOffset, 45);
  assert.equal(state.header, original);
  assert.equal(state.updateScroll(7, NaN), false);
  assert.equal(state.updateScroll(7, Infinity), false);
  assert.equal(state.scrollOffset, 45);
  state.updateScroll(7, -40);
  assert.equal(state.scrollOffset, 0);
});
test('each full route/category state restores its own material offset and header extent', () => {
  const state = ready();
  state.updateHeader(header({ scrollOffset: 160 }));
  assert.equal(state.scrollOffset, 160);
  assert.equal(state.header.occupiedHeight(), 106);
  state.updateHeader(header({ owner: 9, scrollOffset: 0, tabLabels: [] }));
  assert.equal(state.scrollOffset, 0);
  assert.equal(state.header.occupiedHeight(), 56);
  assert.equal(state.acceptsAction(7, 0), false);
});
test('matching renderer teardown hides chrome without allowing later native input', () => {
  const state = ready();
  assert.equal(state.hideHeader(7), true);
  assert.equal(state.hideNavigation(8), true);
  assert.equal(state.acceptsAction(7, 0), false);
  assert.equal(state.acceptsNavigation(8, 1), false);
});
test('invalid payloads do not replace the previous valid state', () => {
  const state = ready(), original = state.header;
  assert.throws(() => state.updateHeader('{broken'));
  assert.throws(() => state.updateHeader('null'));
  assert.equal(state.header, original);
  assert.equal(HdsHeaderState.decode('{}').visible, false);
});
test('empty or zero-width navigation remains hidden and selected indices are bounded', () => {
  assert.equal(HdsNavigationState.decode(navigation({ width: 0 })).visible, false);
  assert.equal(HdsNavigationState.decode(navigation({ items: [] })).visible, false);
  assert.equal(HdsNavigationState.decode(navigation({ selectedIndex: 99 })).selectedIndex, 1);
  assert.equal(HdsHeaderState.decode(header({ selectedTabIndex: -2 })).selectedTabIndex, 0);
});


function engineBridge(api = 23) {
  const channels = new Map(), storage = new Map(), backEvents = [];
  class Channel {
    constructor(_messenger, name) { this.calls = []; channels.set(name, this); }
    setMethodCallHandler(handler) { this.handler = handler; }
    invokeMethod(method, data) { this.calls.push({ method, data }); }
  }
  const bridgeSource = readFileSync('ohos/entry/src/main/ets/adaptive/HdsChromeBridge.ets', 'utf8')
    .replace(/^import .*;\n/gm, '').replace(/\bexport /g, '');
  const { bridge } = vm.runInNewContext(stripTypeScriptTypes(source + '\n' + bridgeSource) +
    '\n({ bridge: HdsChromeBridge.shared });', {
      MethodChannel: Channel, deviceInfo: { sdkApiVersion: api },
      AppStorage: { setOrCreate: (key, value) => storage.set(key, value) },
    });
  const engine = { dartExecutor: { getBinaryMessenger: () => ({}) } };
  bridge.attach(engine, { eventHub: { emit: (event) => backEvents.push(event) } });
  function send(name, method, data = {}) {
    let response;
    channels.get('nju/hds-' + name).handler.onMethodCall({ method, argument: (key) => data[key] }, {
      success: (value) => { response = value; },
      error: (code) => { response = { error: code }; },
      notImplemented: () => { response = { unsupported: true }; },
    });
    return response;
  }
  return { bridge, channels, storage, backEvents, engine, send };
}
test('embedding capabilities negotiate API20 HDS and API23 immersive material', () => {
  for (const api of [12, 19, 20, 23, 26]) {
    const { send } = engineBridge(api);
    const capabilities = send('chrome', 'capabilities');
    assert.equal(capabilities.get('protocolVersion'), 1);
    assert.equal(capabilities.get('supported'), api >= 20);
    assert.equal(capabilities.get('immersiveMaterial'), api >= 23);
  }
});
test('real bridge publishes header extent, scroll-only updates and safe insets', () => {
  const { bridge, channels, storage, send } = engineBridge();
  assert.equal(send('titlebar', 'update', { json: header() }), null);
  const original = storage.get('nju.hds.header');
  const metrics = channels.get('nju/hds-titlebar').calls.at(-1);
  assert.equal(metrics.method, 'metrics');
  assert.equal(metrics.data.get('height'), 106);
  assert.equal(metrics.data.get('owner'), 7);
  send('titlebar', 'scroll', { json: JSON.stringify({ owner: 7, scrollOffset: 60 }) });
  assert.equal(storage.get('nju.hds.scroll'), 60);
  assert.equal(storage.get('nju.hds.header'), original);
  bridge.setWindowInsets(40, 24);
  bridge.setWindowInsets(40, 24);
  const calls = channels.get('nju/hds-chrome').calls;
  assert.equal(calls.length, 1);
  assert.equal(calls[0].method, 'insets');
  assert.equal(calls[0].data.get('topInset'), 40);
  assert.equal(send('chrome', 'capabilities').get('bottomInset'), 24);
});
test('real bridge emits callbacks once, gates inactive input, and hides original renderer chrome', () => {
  const { bridge, channels, storage, send } = engineBridge();
  send('titlebar', 'update', { json: header({ titleTappable: true }) });
  send('navigation', 'update', { json: navigation() });
  bridge.setReady(true);
  bridge.action(7, 0); bridge.category(7, 1); bridge.title(7); bridge.back(7); bridge.navigate(8, 1);
  assert.deepEqual(channels.get('nju/hds-titlebar').calls.map(x => x.method), ['metrics', 'action', 'tab', 'title', 'back']);
  assert.deepEqual(channels.get('nju/hds-navigation').calls.map(x => x.method), ['select']);
  bridge.setResumed(false);
  assert.equal(storage.get('nju.hds.input'), false);
  bridge.action(7, 0); bridge.navigate(8, 0);
  assert.equal(channels.get('nju/hds-titlebar').calls.length, 5);
  assert.equal(channels.get('nju/hds-navigation').calls.length, 1);
  bridge.setResumed(true);
  send('titlebar', 'hide', { owner: 6 });
  assert.equal(storage.get('nju.hds.header').visible, true);
  send('titlebar', 'hide', { owner: 7 });
  send('navigation', 'hide', { owner: 8 });
  assert.equal(storage.get('nju.hds.header').visible, false);
  assert.equal(storage.get('nju.hds.navigation').visible, false);
});
test('malformed native state fails closed and engine teardown removes handlers', () => {
  const { bridge, channels, storage, send, engine, backEvents } = engineBridge();
  send('titlebar', 'update', { json: header() });
  assert.equal(send('titlebar', 'update', { json: '{broken' }).error, 'HDS_HEADER_STATE');
  assert.equal(storage.get('nju.hds.header').visible, false);
  bridge.systemBack();
  assert.deepEqual(backEvents, ['EVENT_BACK_PRESS']);
  bridge.detachEngine({});
  assert.ok(channels.get('nju/hds-titlebar').handler);
  bridge.detachEngine(engine);
  assert.equal(channels.get('nju/hds-titlebar').handler, null);
  assert.equal(channels.get('nju/hds-navigation').handler, null);
  assert.equal(channels.get('nju/hds-chrome').handler, null);
  bridge.systemBack();
  assert.equal(backEvents.length, 1);
});

test('navigation backdrop follows the Flutter surface and has a dark legacy fallback', () => {
  assert.equal(HdsNavigationState.decode(navigation({ surface: 0xff152030 })).surface, 0xff152030);
  assert.equal(HdsNavigationState.decode(navigation({ dark: true })).surface, 0xff000000);
  assert.equal(HdsNavigationState.decode(navigation({ dark: false })).surface, 0xffffffff);
});
