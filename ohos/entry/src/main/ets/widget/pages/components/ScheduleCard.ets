import { CourseWidgetVO } from '../../models/CourseModel';
import { TodayWidgetData } from '../../models/WidgetDataModel';

@Component
export struct ScheduleCard {
  @Prop @Watch('updateData') data: TodayWidgetData;
  @Prop @Watch('updateData') currentTime: string = '00:00';
  @Prop wide: boolean = false;
  @State courses: CourseWidgetVO[] = [];
  @State status: string = '';

  aboutToAppear() { this.updateData(); }

  private minutes(value: string): number {
    const parts = value.split(':');
    return Number(parts[0]) * 60 + Number(parts[1]);
  }

  updateData() {
    const now = this.minutes(this.currentTime);
    this.courses = this.data.courses.filter(course => this.data.tomorrow || this.minutes(course.endTimeStr) > now)
      .sort((a, b) => this.minutes(a.startTimeStr) - this.minutes(b.startTimeStr));
    if (this.data.tomorrow) {
      this.status = `明天有 ${this.courses.length} 门课`;
    } else if (this.courses.length > 0) {
      const start = this.minutes(this.courses[0].startTimeStr);
      this.status = now >= start ? '上课中' : now >= start - 15 ? '即将上课' : '下一节课';
    } else {
      this.status = this.data.stale ? '等待同步' : this.data.courses.length > 0 ? '今日课程已结束' : '今天没有课程';
    }
  }

  private openApp() {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { target: 'main' } });
  }

  @Builder CourseRow(course: CourseWidgetVO, detailed: boolean) {
    Row({ space: 7 }) {
      Column().width(3).height(detailed ? 58 : 36).borderRadius(2).backgroundColor(course.color)
      Column({ space: 3 }) {
        Text(course.name).fontSize(detailed ? 14 : 12).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.widget_font_primary')).maxLines(detailed ? 2 : 1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text(`${course.startTimeStr}–${course.endTimeStr}`).fontSize(11)
          .fontColor($r('app.color.widget_font_secondary')).maxLines(1)
        if (detailed || course.classroom.length > 0) {
          Text(course.classroom || '教室待定').fontSize(11)
            .fontColor($r('app.color.widget_font_secondary')).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.padding(8).width('100%').backgroundColor($r('app.color.widget_fill_color'))
      .borderRadius(10).onClick(() => this.openApp())
  }

  @Builder CourseList(start: number) {
    List({ space: 5 }) {
      ForEach(this.courses.slice(start), (course: CourseWidgetVO, index: number) => {
        ListItem() { this.CourseRow(course, !this.wide && index === 0) }
      })
    }.width('100%').height('100%').scrollBar(BarState.Auto)
  }

  build() {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text(this.data.dateKey ? `${Number(this.data.dateKey.slice(5, 7))}/${Number(this.data.dateKey.slice(8, 10))}` : '南哪课表')
          .fontSize(12).fontColor($r('app.color.widget_font_primary')).maxLines(1)
        Text(this.data.date).fontSize(12).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.widget_accent')).maxLines(1).layoutWeight(1)
        if (this.data.week) {
          Text(`第${this.data.week}周`).fontSize(10).fontColor($r('app.color.widget_font_secondary'))
        }
      }.width('100%').onClick(() => this.openApp())
      Row() {
        Text(this.status).fontSize(11).fontColor($r('app.color.widget_accent')).maxLines(1).layoutWeight(1)
        if (this.courses.length > 0 && !this.data.tomorrow) {
          Text(`剩 ${this.courses.length} 门`).fontSize(10).fontColor($r('app.color.widget_font_secondary'))
        }
      }.width('100%')
      if (this.courses.length === 0) {
        Column({ space: 5 }) {
          Text(this.data.stale ? '打开课表同步' : this.data.tomorrow ? '明天没有课程' : this.status)
            .fontSize(14).fontColor($r('app.color.widget_font_primary'))
          Text(this.data.stale ? '点击打开南哪课表' : '好好享受课余时光')
            .fontSize(11).fontColor($r('app.color.widget_font_secondary'))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.widget_fill_color')).borderRadius(10).onClick(() => this.openApp())
      } else if (this.wide) {
        Row({ space: 8 }) {
          Column() { this.CourseRow(this.courses[0], true) }.layoutWeight(1).height('100%')
          Column({ space: 4 }) {
            if (this.courses.length > 1) {
              Text('后续课程').fontSize(10).fontColor($r('app.color.widget_font_secondary')).width('100%')
              Column() { this.CourseList(1) }.layoutWeight(1)
            } else {
              Text('后续无课程').fontSize(12).fontColor($r('app.color.widget_font_secondary'))
            }
          }.layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        }.width('100%').layoutWeight(1)
      } else {
        Column() { this.CourseList(0) }.width('100%').layoutWeight(1)
      }
    }.padding(10).width('100%').height('100%').borderRadius(20)
      .backgroundColor($r('app.color.widget_background')).clip(true)
  }
}
