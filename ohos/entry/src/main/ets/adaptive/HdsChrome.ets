import { FrameCallback, LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { Available, deviceInfo } from '@kit.BasicServicesKit';
import { BottomBuilderParams, DividerMode, DividerShowType, hdsMaterial, HdsNavigation,
  HdsNavigationAttribute, HdsNavigationMenuItemOptions, HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode, HdsNavDestination, HdsNavDestinationAttribute, HdsNavDestinationTitleMode,
  HdsTabs, HdsTabsAttribute, HdsTabsController, IconStyleMode, ScrollEffectType,
  TextStyleMode, TitleBarStyleOptions } from '@kit.UIDesignKit';
import { HdsAction, HdsHeaderState, HdsNavigationItem, HdsNavigationState, chromeColor } from './HdsChromeState';
import { HdsChromeBridge } from './HdsChromeBridge';

// Rendering APIs are verified against UIDesignKit; Flutter remains the route owner.
const MASK_EXTRA_HEIGHT = 32;
function actionSymbol(name: string): Resource {
  switch (name) {
    case 'plus': return $r('sys.symbol.plus');
    case 'gearshape': return $r('sys.symbol.gearshape');
    case 'arrow.clockwise': return $r('sys.symbol.arrow_clockwise');
    case 'play.fill': return $r('sys.symbol.play_fill');
    case 'trash': return $r('sys.symbol.trash');
    case 'info.circle': return $r('sys.symbol.info_circle');
    case 'xmark': return $r('sys.symbol.xmark');
    case 'square.and.arrow.up': return $r('sys.symbol.rectangle_and_arrowshape_turn_up_right');
    case 'ellipsis': return $r('sys.symbol.more');
    case 'pencil': return $r('sys.symbol.square_and_pencil');
    case 'checkmark': return $r('sys.symbol.checkmark');
    case 'magnifyingglass': return $r('sys.symbol.magnifyingglass');
    default: return $r('sys.symbol.circle');
  }
}
function navigationSymbol(name: string): Resource {
  switch (name) {
    case 'NotesFill': return $r('sys.symbol.book');
    case 'ContactsCircle': return $r('sys.symbol.person_crop_circle_fill_1');
    default: return $r('sys.symbol.calendar_1');
  }
}
function titleStyle(state: HdsHeaderState): TitleBarStyleOptions {
  const color = chromeColor(state.foreground, 4279637526);
  const textColor = state.actions.some((action: HdsAction) => action.prominent) ? chromeColor(state.primary, 4278228473) : color;
  const style: TitleBarStyleOptions = {
    scrollEffectOpts: { enableScrollEffect: true,
      scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
      blurEffectiveStartOffset: LengthMetrics.vp(0), blurEffectiveEndOffset: LengthMetrics.vp(20) },
    originalStyle: { backgroundStyle: { backgroundColor: '#00000000', maskExtraHeight: MASK_EXTRA_HEIGHT },
      contentStyle: { titleStyle: { mainTitleColor: color, subTitleColor: color },
        menuStyle: { iconColor: color, textColor: textColor }, backIconStyle: { iconColor: color } } },
    scrollEffectStyle: { backgroundStyle: { backgroundColor: chromeColor(state.surface, 4294967295), maskExtraHeight: MASK_EXTRA_HEIGHT },
      contentStyle: { titleStyle: { mainTitleColor: color, subTitleColor: color },
        menuStyle: { iconColor: color, textColor: textColor }, backIconStyle: { iconColor: color } } }
  };
  if (deviceInfo.sdkApiVersion >= 23) {
    style.scrollEffectOpts = { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
      blurEffectiveStartOffset: LengthMetrics.vp(0), blurEffectiveEndOffset: LengthMetrics.vp(20) };
    style.systemMaterialEffect = { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE };
  }
  return style;
}

class NavigationTheme implements AttributeModifier<HdsNavigationAttribute> {
  applyNormalAttribute(instance: HdsNavigationAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) instance.withTheme({ enableThemeColorMode: true });
  }
}
class DestinationTheme implements AttributeModifier<HdsNavDestinationAttribute> {
  applyNormalAttribute(instance: HdsNavDestinationAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) instance.withTheme({ enableThemeColorMode: true });
  }
}
class ScrollFrame extends FrameCallback {
  private callback: () => void;
  constructor(callback: () => void) { super(); this.callback = callback; }
  onFrame(_frameTimeInNano: number): void { this.callback(); }
  onIdle(_timeLeftInNano: number): void {}
}

@Available({ minApiVersion: '20' })
@Component
export struct HdsChromeHeader {
  @StorageLink('nju.hds.header') @Watch('onHeaderChanged') header: HdsHeaderState = new HdsHeaderState();
  @StorageLink('nju.hds.scroll') @Watch('scheduleScroll') scrollOffset: number = 0;
  @StorageLink('nju.hds.input') inputReady: boolean = false;
  @Prop statusBarHeight: number = 0;
  private paths: NavPathStack = new NavPathStack();
  private rootScroller: Scroller = new Scroller();
  private destinationScroller: Scroller = new Scroller();
  private categories: TabsController = new TabsController();
  private alive: boolean = false;
  private scrollScheduled: boolean = false;
  private appliedScrollOffset: number = -1;

  aboutToAppear(): void { this.alive = true; this.onHeaderChanged(); }
  aboutToDisappear(): void { this.alive = false; }
  private onHeaderChanged(): void {
    this.appliedScrollOffset = -1;
    if (this.header.canBack && this.paths.size() === 0) this.paths.pushPathByName('flutter', null, false);
    if (!this.header.canBack && this.paths.size() > 0) this.paths.clear(false);
    if (this.header.tabLabels.length > 0) this.categories.changeIndex(this.header.selectedTabIndex);
    this.scheduleScroll();
  }
  private scheduleScroll(): void {
    if (!this.alive || this.scrollScheduled) return;
    this.scrollScheduled = true;
    this.getUIContext().postFrameCallback(new ScrollFrame((): void => {
      this.scrollScheduled = false;
      if (!this.alive) return;
      const scroller = this.header.canBack ? this.destinationScroller : this.rootScroller;
      // Only the first 20vp controls material. A bounded empty proxy avoids
      // relaying the Flutter list or allocating/capturing any pixels.
      const offset = Math.min(20, Math.max(0, this.scrollOffset));
      if (offset === this.appliedScrollOffset) return;
      scroller.scrollTo({ xOffset: 0, yOffset: offset, animation: false });
      this.appliedScrollOffset = offset;
    }));
  }
  private menuItem(state: HdsHeaderState, action: HdsAction): HdsNavigationMenuItemOptions {
    const item: HdsNavigationMenuItemOptions = { content: {
      icon: action.title.length > 0 ? undefined : new SymbolGlyphModifier(actionSymbol(action.symbol)),
      label: action.loading ? action.label + '…' : action.label,
      type: action.title.length > 0 ? TextStyleMode.NORMAL : IconStyleMode.NORMAL,
      isEnabled: this.inputReady && state.interactive && action.enabled && !action.loading,
      action: (): void => { HdsChromeBridge.shared.action(state.owner, action.index); }
    } };
    return item;
  }
  private options(): HdsNavigationTitleBarOptions {
    const state = this.header;
    const options: HdsNavigationTitleBarOptions = {
      avoidLayoutSafeArea: true,
      style: titleStyle(state),
      content: {
        title: { mainTitle: state.titleTappable ? '' : state.title, subTitle: state.titleTappable ? undefined : state.subtitle },
        menu: { value: state.actions.map((action: HdsAction) => this.menuItem(state, action)), maxCount: 3 },
        backIcon: { icon: new SymbolGlyphModifier($r('sys.symbol.chevron_left')), label: state.backLabel,
          isEnabled: this.inputReady && state.interactive,
          action: (): void => { HdsChromeBridge.shared.back(state.owner); } },
        divider: { showType: DividerShowType.OFF }
      }
    };
    if (state.titleTappable) options.content!.stackBuilder = (): void => { this.tappableTitle(); };
    if (state.tabLabels.length > 0) {
      const bottom: BottomBuilderParams = { height: state.tabExtent(), builder: (): void => { this.categoryTabs(); } };
      options.content!.bottomBuilder = bottom;
    }
    return options;
  }
  @Builder private tappableTitle() {
    Column({ space: 2 }) {
      Row({ space: 3 }) {
        Text(this.header.title).fontSize((18 * this.header.fontScale).toString() + 'vp').fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor(chromeColor(this.header.foreground, 4279637526))
        SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(12).fontColor([chromeColor(this.header.foreground, 4279637526)])
      }
      Text(this.header.subtitle).fontSize((12 * this.header.fontScale).toString() + 'vp').maxLines(1).opacity(0.65).fontColor(chromeColor(this.header.foreground, 4279637526))
    }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center).height(56).width('100%')
      .padding({ left: 16, right: 16 }).accessibilityText(this.header.semanticLabel)
      .enabled(this.inputReady && this.header.interactive)
      .onClick((): void => { HdsChromeBridge.shared.title(this.header.owner); })
  }
  @Builder private categoryTabs() {
    Tabs({ index: this.header.selectedTabIndex, controller: this.categories }) {
      ForEach(this.header.tabLabels, (label: string) => {
        TabContent() {}.tabBar(SubTabBarStyle.of(label).labelStyle({
          selectedColor: chromeColor(this.header.primary, 4278228473),
          unselectedColor: chromeColor(this.header.foreground, 4279637526), font: { size: 14 }
        }))
      }, (label: string) => label)
    }.barMode(BarMode.Fixed).barHeight(this.header.tabRowHeight).height(this.header.tabExtent()).width('100%')
      .padding({ left: 16, right: 16, bottom: 8 }).scrollable(false).animationDuration(200)
      .enabled(this.inputReady && this.header.interactive)
      .onTabBarClick((index: number): void => { HdsChromeBridge.shared.category(this.header.owner, index); })
  }
  @Builder private scrollProxy(scroller: Scroller) {
    Scroll(scroller) { Column().height(2048).width('100%') }
      .width('100%').height('100%').opacity(0).scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
      .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
      .onAreaChange((): void => { this.appliedScrollOffset = -1; this.scheduleScroll(); })
  }
  @Builder private destination(_name: string) {
    HdsNavDestination() { this.scrollProxy(this.destinationScroller) }
      .titleBar(this.options()).titleMode(HdsNavDestinationTitleMode.MINI)
      .bindToScrollable([this.destinationScroller]).backgroundColor(Color.Transparent)
      .attributeModifier(new DestinationTheme())
      .onBackPressed((): boolean => { HdsChromeBridge.shared.back(this.header.owner); return true; })
      .onShown((): void => { this.appliedScrollOffset = -1; this.scheduleScroll(); })
      .hitTestBehavior(HitTestMode.Transparent)
  }
  build() {
    WithTheme({ colorMode: this.header.dark ? ThemeColorMode.DARK : ThemeColorMode.LIGHT }) {
      Column() {
        HdsNavigation(this.paths) { this.scrollProxy(this.rootScroller) }
          .titleBar(this.options()).titleMode(HdsNavigationTitleMode.MINI).hideBackButton(true)
          .hideTitleBar(this.header.canBack).mode(NavigationMode.Stack).navBarWidth('100%')
          .navDestination(this.destination).bindToScrollable([this.rootScroller])
          .attributeModifier(new NavigationTheme()).backgroundColor(Color.Transparent)
          .width('100%').height('100%').hitTestBehavior(HitTestMode.Transparent)
      }.width('100%').height(this.statusBarHeight + this.header.occupiedHeight() + MASK_EXTRA_HEIGHT)
        .clip(true).direction(this.header.rtl ? Direction.Rtl : Direction.Ltr).hitTestBehavior(HitTestMode.Transparent)
    }
  }
}

class NavigationMaterial implements AttributeModifier<HdsTabsAttribute> {
  private width: number;
  constructor(width: number) { this.width = width; }
  applyNormalAttribute(instance: HdsTabsAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) {
      instance.barFloatingStyle({ barWidth: { smallWidth: this.width, mediumWidth: this.width, largeWidth: this.width },
        barSideMargin: 24, barBottomMargin: 0,
        systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
        gradientMask: { maskColor: '#00000000', maskHeight: MASK_EXTRA_HEIGHT } });
    } else {
      instance.barBackgroundBlurStyle(BlurStyle.COMPONENT_REGULAR);
    }
  }
}

@Available({ minApiVersion: '20' })
@Component
export struct HdsChromeNavigation {
  @StorageLink('nju.hds.navigation') @Watch('onNavigationChanged') navigation: HdsNavigationState = new HdsNavigationState();
  @StorageLink('nju.hds.input') inputReady: boolean = false;
  private tabs: HdsTabsController = new HdsTabsController();
  aboutToAppear(): void { this.onNavigationChanged(); }
  private onNavigationChanged(): void {
    if (this.navigation.items.length > 0) this.tabs.changeIndex(this.navigation.selectedIndex);
  }
  private sideMargin(): number { return deviceInfo.sdkApiVersion >= 23 ? 24 : 0; }
  @Builder private tabLabel(item: HdsNavigationItem, index: number) {
    Column({ space: 3 }) {
      SymbolGlyph(navigationSymbol(item.icon)).fontSize('23vp').fontColor([
        chromeColor(index === this.navigation.selectedIndex ? this.navigation.primary : this.navigation.onSurface, 4279637526)])
      Text(item.label).fontSize(12).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).fontWeight(index === this.navigation.selectedIndex ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(chromeColor(index === this.navigation.selectedIndex ? this.navigation.primary : this.navigation.onSurface, 4279637526))
    }.width('100%').height(this.navigation.height).justifyContent(FlexAlign.Center).accessibilityText(item.label)
  }
  build() {
    WithTheme({ colorMode: this.navigation.dark ? ThemeColorMode.DARK : ThemeColorMode.LIGHT }) {
      HdsTabs({ index: this.navigation.selectedIndex, controller: this.tabs }) {
        ForEach(this.navigation.items, (item: HdsNavigationItem, index: number) => {
          TabContent() {}.tabBar(this.tabLabel(item, index))
        }, (item: HdsNavigationItem) => item.icon + ':' + item.label)
      }.width(this.navigation.width + this.sideMargin() * 2).height(this.navigation.height + MASK_EXTRA_HEIGHT)
        .position({ x: this.navigation.left - this.sideMargin(), y: this.navigation.top - MASK_EXTRA_HEIGHT })
        .barPosition(BarPosition.End).barMode(BarMode.Fixed).barOverlap(true).barHeight(this.navigation.height)
        .barWidth(this.navigation.width).barBackgroundColor('#00000000').divider({ mode: DividerMode.NONE })
        .attributeModifier(new NavigationMaterial(this.navigation.width)).backgroundColor(Color.Transparent)
        .scrollable(false).animationDuration(200).enabled(this.inputReady)
        .direction(this.navigation.rtl ? Direction.Rtl : Direction.Ltr)
        .onTabBarClick((index: number): void => { HdsChromeBridge.shared.navigate(this.navigation.owner, index); })
        .hitTestBehavior(HitTestMode.Transparent)
    }
  }
}
