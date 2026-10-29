// Transport/state contracts are independent of ArkUI and Flutter embedding.
export function chromeNumber(value: number, fallback: number, minimum: number, maximum: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? Math.min(maximum, Math.max(minimum, value)) : fallback;
}
export function chromeText(value: string, fallback: string = ''): string {
  return typeof value === 'string' ? value : fallback;
}
export function chromeColor(value: number, fallback: number): string {
  const color = chromeNumber(value, fallback, 0, 4294967295);
  return '#' + Math.round(color).toString(16).padStart(8, '0');
}

export class HdsAction {
  index: number = 0;
  label: string = '';
  title: string = '';
  symbol: string = 'circle';
  enabled: boolean = true;
  loading: boolean = false;
  prominent: boolean = false;

  static read(value: HdsAction): HdsAction {
    const action = new HdsAction();
    action.index = Math.floor(chromeNumber(value.index, -1, -1, 100));
    action.label = chromeText(value.label);
    action.title = chromeText(value.title);
    action.symbol = chromeText(value.symbol, 'circle');
    action.enabled = value.enabled !== false;
    action.loading = value.loading === true;
    action.prominent = value.prominent === true;
    return action;
  }
}

export class HdsHeaderState {
  owner: number = 0;
  visible: boolean = false;
  interactive: boolean = false;
  canBack: boolean = false;
  titleTappable: boolean = false;
  leadingTitle: boolean = false;
  title: string = '';
  subtitle: string = '';
  semanticLabel: string = '';
  backLabel: string = '返回';
  dark: boolean = false;
  rtl: boolean = false;
  foreground: number = 4279637526;
  surface: number = 4294967295;
  primary: number = 4278228473;
  fontScale: number = 1;
  tabLabels: string[] = [];
  tabRowHeight: number = 42;
  selectedTabIndex: number = 0;
  actions: HdsAction[] = [];
  scrollOffset: number = 0;

  static decode(json: string): HdsHeaderState {
    const value: HdsHeaderState = JSON.parse(json);
    if (!value || typeof value !== 'object') throw new Error('Invalid header state');
    const state = new HdsHeaderState();
    state.owner = chromeNumber(value.owner, 0, 0, Number.MAX_SAFE_INTEGER);
    state.visible = value.visible === true;
    state.interactive = value.interactive === true;
    state.canBack = value.canBack === true;
    state.titleTappable = value.titleTappable === true;
    state.leadingTitle = value.leadingTitle === true;
    state.title = chromeText(value.title);
    state.subtitle = chromeText(value.subtitle);
    state.semanticLabel = chromeText(value.semanticLabel, state.title);
    state.backLabel = chromeText(value.backLabel, '返回');
    state.dark = value.dark === true;
    state.rtl = value.rtl === true;
    state.foreground = chromeNumber(value.foreground, state.foreground, 0, 4294967295);
    state.surface = chromeNumber(value.surface, state.surface, 0, 4294967295);
    state.primary = chromeNumber(value.primary, state.primary, 0, 4294967295);
    state.fontScale = chromeNumber(value.fontScale, 1, 0.5, 4);
    state.tabRowHeight = chromeNumber(value.tabRowHeight, 42, 42, 120);
    if (Array.isArray(value.tabLabels)) {
      state.tabLabels = value.tabLabels.filter((label: string) => typeof label === 'string').slice(0, 10);
    }
    state.selectedTabIndex = Math.floor(chromeNumber(value.selectedTabIndex, 0, 0, Math.max(0, state.tabLabels.length - 1)));
    if (Array.isArray(value.actions)) {
      state.actions = value.actions.filter((action: HdsAction) => action !== null && typeof action === 'object')
        .slice(0, 10).map((action: HdsAction) => HdsAction.read(action));
    }
    state.scrollOffset = chromeNumber(value.scrollOffset, 0, 0, 100000);
    return state;
  }
  tabExtent(): number { return this.tabLabels.length > 0 ? this.tabRowHeight + 8 : 0; }
  occupiedHeight(): number { return 56 + this.tabExtent(); }
}

export class HdsNavigationItem {
  label: string = '';
  icon: string = 'Months';
}
export class HdsNavigationState {
  owner: number = 0;
  visible: boolean = false;
  left: number = 0;
  top: number = 0;
  width: number = 0;
  height: number = 56;
  selectedIndex: number = 0;
  dark: boolean = false;
  rtl: boolean = false;
  primary: number = 4278228473;
  surface: number = 4294967295;
  onSurface: number = 4279637526;
  items: HdsNavigationItem[] = [];

  static decode(json: string): HdsNavigationState {
    const value: HdsNavigationState = JSON.parse(json);
    if (!value || typeof value !== 'object') throw new Error('Invalid navigation state');
    const state = new HdsNavigationState();
    state.owner = chromeNumber(value.owner, 0, 0, Number.MAX_SAFE_INTEGER);
    state.visible = value.visible === true;
    state.left = chromeNumber(value.left, 0, -10000, 10000);
    state.top = chromeNumber(value.top, 0, -10000, 10000);
    state.width = chromeNumber(value.width, 0, 0, 10000);
    state.height = chromeNumber(value.height, 56, 1, 200);
    state.dark = value.dark === true;
    state.surface = chromeNumber(value.surface, state.dark ? 4278190080 : 4294967295, 0, 4294967295);
    state.rtl = value.rtl === true;
    state.primary = chromeNumber(value.primary, state.primary, 0, 4294967295);
    state.onSurface = chromeNumber(value.onSurface, state.onSurface, 0, 4294967295);
    if (Array.isArray(value.items)) {
      state.items = value.items.filter((item: HdsNavigationItem) => item !== null && typeof item === 'object').slice(0, 8)
        .map((item: HdsNavigationItem) => {
          const entry = new HdsNavigationItem();
          entry.label = chromeText(item.label);
          entry.icon = chromeText(item.icon, 'Months');
          return entry;
        });
    }
    state.selectedIndex = Math.floor(chromeNumber(value.selectedIndex, 0, 0, Math.max(0, state.items.length - 1)));
    state.visible = state.visible && state.width > 0 && state.items.length > 0;
    return state;
  }
}

export class HdsChromeState {
  header: HdsHeaderState = new HdsHeaderState();
  navigation: HdsNavigationState = new HdsNavigationState();
  resumed: boolean = true;
  ready: boolean = false;
  scrollOffset: number = 0;

  updateHeader(json: string): void {
    this.header = HdsHeaderState.decode(json);
    this.scrollOffset = this.header.scrollOffset;
  }
  updateScroll(owner: number, offset: number): boolean {
    if (owner !== this.header.owner || !Number.isFinite(offset)) return false;
    this.scrollOffset = chromeNumber(offset, 0, 0, 100000);
    return true;
  }
  hideHeader(owner: number): boolean {
    if (owner !== this.header.owner) return false;
    this.header.visible = false;
    return true;
  }
  hideNavigation(owner: number): boolean {
    if (owner !== this.navigation.owner) return false;
    this.navigation.visible = false;
    return true;
  }
  acceptsHeader(owner: number): boolean {
    return this.ready && this.resumed && this.header.visible && this.header.interactive && owner === this.header.owner;
  }
  acceptsAction(owner: number, index: number): boolean {
    return this.acceptsHeader(owner) && this.header.actions.some((action: HdsAction) =>
      action.index === index && action.enabled && !action.loading);
  }
  acceptsCategory(owner: number, index: number): boolean {
    return this.acceptsHeader(owner) && Number.isInteger(index) && index >= 0 && index < this.header.tabLabels.length;
  }
  acceptsNavigation(owner: number, index: number): boolean {
    return this.ready && this.resumed && this.navigation.visible && owner === this.navigation.owner &&
      Number.isInteger(index) && index >= 0 && index < this.navigation.items.length;
  }
}
