import { FlutterEngine, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { HdsChromeState, HdsHeaderState, HdsNavigationState } from './HdsChromeState';

export const HDS_HEADER_KEY = 'nju.hds.header';
export const HDS_NAVIGATION_KEY = 'nju.hds.navigation';
export const HDS_SCROLL_KEY = 'nju.hds.scroll';
export const HDS_INPUT_KEY = 'nju.hds.input';

/** Owns channels for one engine. ArkUI surfaces remain children of the main page. */
export class HdsChromeBridge {
  static readonly shared: HdsChromeBridge = new HdsChromeBridge();
  readonly state: HdsChromeState = new HdsChromeState();
  private topInset: number = 0;
  private bottomInset: number = 0;
  private engine: FlutterEngine | null = null;
  private context: common.UIAbilityContext | null = null;
  private headerChannel: MethodChannel | null = null;
  private navigationChannel: MethodChannel | null = null;
  private supportChannel: MethodChannel | null = null;

  attach(engine: FlutterEngine, context: common.UIAbilityContext): void {
    this.detach();
    this.engine = engine;
    this.context = context;
    const messenger = engine.dartExecutor.getBinaryMessenger();
    this.headerChannel = new MethodChannel(messenger, 'nju/hds-titlebar');
    this.navigationChannel = new MethodChannel(messenger, 'nju/hds-navigation');
    this.supportChannel = new MethodChannel(messenger, 'nju/hds-chrome');
    this.headerChannel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.receiveHeader(call, result);
    } });
    this.navigationChannel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.receiveNavigation(call, result);
    } });
    this.supportChannel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      if (call.method !== 'capabilities') { result.notImplemented(); return; }
      const capabilities = new Map<string, number | boolean>();
      capabilities.set('protocolVersion', 1);
      capabilities.set('supported', deviceInfo.sdkApiVersion >= 20);
      capabilities.set('sdkApiVersion', deviceInfo.sdkApiVersion);
      capabilities.set('topInset', this.topInset);
      capabilities.set('bottomInset', this.bottomInset);
      capabilities.set('immersiveMaterial', deviceInfo.sdkApiVersion >= 23);
      result.success(capabilities);
    } });
  }
  detach(): void {
    this.headerChannel?.setMethodCallHandler(null);
    this.navigationChannel?.setMethodCallHandler(null);
    this.supportChannel?.setMethodCallHandler(null);
    this.headerChannel = null;
    this.navigationChannel = null;
    this.supportChannel = null;
    this.engine = null;
    this.context = null;
    this.state.header = new HdsHeaderState();
    this.state.navigation = new HdsNavigationState();
    this.state.scrollOffset = 0;
    AppStorage.setOrCreate(HDS_SCROLL_KEY, 0);
    this.syncInput();
    AppStorage.setOrCreate(HDS_HEADER_KEY, this.state.header);
    AppStorage.setOrCreate(HDS_NAVIGATION_KEY, this.state.navigation);
  }
  detachEngine(engine: FlutterEngine): void { if (engine === this.engine) this.detach(); }
  setReady(ready: boolean): void { this.state.ready = ready; this.syncInput(); }
  setResumed(resumed: boolean): void { this.state.resumed = resumed; this.syncInput(); }
  private syncInput(): void { AppStorage.setOrCreate(HDS_INPUT_KEY, this.state.ready && this.state.resumed); }
  setWindowInsets(top: number, bottom: number): void {
    if (!Number.isFinite(top) || !Number.isFinite(bottom) || top < 0 || bottom < 0 ||
      (this.topInset === top && this.bottomInset === bottom)) return;
    this.topInset = top;
    this.bottomInset = bottom;
    const data = new Map<string, number>();
    data.set('topInset', top);
    data.set('bottomInset', bottom);
    this.supportChannel?.invokeMethod('insets', data);
  }
  systemBack(): void { this.context?.eventHub.emit('EVENT_BACK_PRESS'); }

  private receiveHeader(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === 'update') {
        const json: string = call.argument('json');
        this.state.updateHeader(json);
        AppStorage.setOrCreate(HDS_HEADER_KEY, this.state.header);
        AppStorage.setOrCreate(HDS_SCROLL_KEY, this.state.scrollOffset);
        this.reportHeight(this.state.header.owner, this.state.header.occupiedHeight());
      } else if (call.method === 'scroll') {
        const json: string = call.argument('json');
        const value: HdsHeaderState = JSON.parse(json);
        if (this.state.updateScroll(value.owner, value.scrollOffset)) AppStorage.setOrCreate(HDS_SCROLL_KEY, this.state.scrollOffset);
      } else if (call.method === 'hide') {
        const owner: number = call.argument('owner');
        if (this.state.hideHeader(owner)) {
          const header = new HdsHeaderState();
          header.owner = owner;
          this.state.header = header;
          AppStorage.setOrCreate(HDS_HEADER_KEY, header);
        }
      } else { result.notImplemented(); return; }
      result.success(null);
    } catch (error) {
      this.state.header = new HdsHeaderState();
      AppStorage.setOrCreate(HDS_HEADER_KEY, this.state.header);
      result.error('HDS_HEADER_STATE', 'Invalid native header state', null);
    }
  }
  private receiveNavigation(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === 'update') {
        const json: string = call.argument('json');
        this.state.navigation = HdsNavigationState.decode(json);
        AppStorage.setOrCreate(HDS_NAVIGATION_KEY, this.state.navigation);
      } else if (call.method === 'hide') {
        const owner: number = call.argument('owner');
        if (this.state.hideNavigation(owner)) {
          const navigation = new HdsNavigationState();
          navigation.owner = owner;
          this.state.navigation = navigation;
          AppStorage.setOrCreate(HDS_NAVIGATION_KEY, navigation);
        }
      } else { result.notImplemented(); return; }
      result.success(null);
    } catch (error) { result.error('HDS_NAVIGATION_STATE', 'Invalid native navigation state', null); }
  }
  private emit(channel: MethodChannel | null, method: string, owner: number, index: number = -1): void {
    const data = new Map<string, number>();
    data.set('owner', owner);
    if (index >= 0) data.set('index', index);
    channel?.invokeMethod(method, data);
  }
  reportHeight(owner: number, height: number): void {
    if (owner !== this.state.header.owner || !this.state.header.visible || !Number.isFinite(height)) return;
    const data = new Map<string, number>();
    data.set('owner', owner);
    data.set('height', height);
    this.headerChannel?.invokeMethod('metrics', data);
  }
  back(owner: number): void {
    if (this.state.acceptsHeader(owner) && this.state.header.canBack) this.emit(this.headerChannel, 'back', owner);
  }
  title(owner: number): void {
    if (this.state.acceptsHeader(owner) && this.state.header.titleTappable) this.emit(this.headerChannel, 'title', owner);
  }
  action(owner: number, index: number): void {
    if (this.state.acceptsAction(owner, index)) this.emit(this.headerChannel, 'action', owner, index);
  }
  category(owner: number, index: number): void {
    if (this.state.acceptsCategory(owner, index)) this.emit(this.headerChannel, 'tab', owner, index);
  }
  navigate(owner: number, index: number): void {
    if (this.state.acceptsNavigation(owner, index)) this.emit(this.navigationChannel, 'select', owner, index);
  }
}
