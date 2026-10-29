import { FlutterPage } from '@ohos/flutter_ohos';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { HdsChromeHeader, HdsChromeNavigation } from '../adaptive/HdsChrome';
import { HdsChromeBridge } from '../adaptive/HdsChromeBridge';
import { HdsHeaderState, HdsNavigationState } from '../adaptive/HdsChromeState';

const storage: LocalStorage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink('nju.hds.header') header: HdsHeaderState = new HdsHeaderState();
  @StorageLink('nju.hds.navigation') navigation: HdsNavigationState = new HdsNavigationState();
  @State statusBarHeight: number = 0;
  @State navigationBarHeight: number = 0;
  private mainWindow: window.Window | null = null;
  private appeared: boolean = false;
  private avoidAreaChanged: (area: window.AvoidAreaOptions) => void = (_area: window.AvoidAreaOptions): void => { this.readStatusInset(); };

  aboutToAppear(): void {
    this.appeared = true;
    HdsChromeBridge.shared.setReady(true);
    const context = this.getUIContext().getHostContext();
    if (!context) return;
    window.getLastWindow(context).then((mainWindow: window.Window): void => {
      if (!this.appeared) return;
      this.mainWindow = mainWindow;
      this.readStatusInset();
      mainWindow.on('avoidAreaChange', this.avoidAreaChanged);
    }).catch((): void => {});
  }
  aboutToDisappear(): void {
    this.appeared = false;
    HdsChromeBridge.shared.setReady(false);
    try { this.mainWindow?.off('avoidAreaChange', this.avoidAreaChanged); } catch (error) {}
    this.mainWindow = null;
  }
  private readStatusInset(): void {
    if (!this.mainWindow) return;
    try {
    const area = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const cutout = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
    const navigation = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    this.statusBarHeight = this.getUIContext().px2vp(Math.max(area.topRect.height, cutout.topRect.height));
    this.navigationBarHeight = this.getUIContext().px2vp(navigation.bottomRect.height);
    HdsChromeBridge.shared.setWindowInsets(this.statusBarHeight, this.navigationBarHeight);
    } catch (error) {}
  }
  build() {
    Stack({ alignContent: Alignment.Top }) {
      FlutterPage({ viewId: this.viewId, xComponentRenderFit: RenderFit.TOP }).width('100%').height('100%')
      if (deviceInfo.sdkApiVersion >= 20 && this.navigation.visible) {
        HdsChromeNavigation({ bottomInset: this.navigationBarHeight })
      }
      if (deviceInfo.sdkApiVersion >= 20 && this.header.visible) {
        HdsChromeHeader({ statusBarHeight: this.statusBarHeight })
      }
    }.width('100%').height('100%').onAreaChange((): void => { this.readStatusInset(); })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
  onBackPress(): boolean { HdsChromeBridge.shared.systemBack(); return true; }
}
