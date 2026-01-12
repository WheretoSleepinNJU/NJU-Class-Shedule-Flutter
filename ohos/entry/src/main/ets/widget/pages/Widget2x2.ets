import { CourseWidgetVO } from '../models/CourseModel';
import { TodayWidgetData } from '../models/WidgetDataModel'
import { WidgetPrimaryCard } from './components/WidgetPrimaryCard';
import { WidgetSecondaryCard } from './components/WidgetSecondaryCard';
import { isCourseActive } from '../utils/TimeHelper';

let storage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('currentTime') @Watch('updateData') currentTime: string = '08:00';
  @LocalStorageProp('widgetData') @Watch('updateData') rawWidgetData: TodayWidgetData = { date: '加载中', courses: [] };

  @State validCourses: CourseWidgetVO[] = []; // 过滤后的课程
  @State isNowActive: boolean = false;        // 第一节课是否高亮
  @State hasCoursesToday: boolean = false;    // 今天原本有没有课（用于区分"无课"和"已结束"）

  aboutToAppear() {
    this.updateData();
  }

  updateData() {
    const allCourses = this.rawWidgetData.courses || [];
    this.hasCoursesToday = allCourses.length > 0;

    const currentMin = this.parseTime(this.currentTime);

    this.validCourses = allCourses.filter(course => {
      const endMin = this.parseTime(course.endTimeStr);
      // 结束时间 >= 当前时间，保留
      return endMin >= currentMin;
    });

    if (this.validCourses.length > 0) {
      const first = this.validCourses[0];
      this.isNowActive = isCourseActive(first.startTimeStr, first.endTimeStr, this.currentTime);
    } else {
      this.isNowActive = false;
    }

    console.info(`[WidgetUI] Update: ${this.currentTime} | Original: ${allCourses.length} | Valid: ${this.validCourses.length}`);
  }

  private parseTime(timeStr: string): number {
    if (!timeStr) return 0;
    try {
      const parts = timeStr.split(':');
      return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  build() {
    Column() {
      // --- Header ---
      Row() {
        Text(this.rawWidgetData.date)
          .fontSize(13)
          .fontColor($r('app.color.widget_font_secondary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Text(`剩 ${this.validCourses.length} 节`)
          .fontSize(12)
          .fontColor($r('app.color.widget_font_tertiary'))
      }
      .width('100%').padding({ bottom: 6 })

      // --- 核心渲染逻辑 (直接使用已计算好的 validCourses) ---
      if (this.validCourses.length > 0) {

        // Active 模式
        if (this.isNowActive) {
          WidgetPrimaryCard({ course: this.validCourses[0] })
            .layoutWeight(2)

          Blank().height(6)

          if (this.validCourses.length > 1) {
            WidgetSecondaryCard({ course: this.validCourses[1] })
              .layoutWeight(1)
          } else {
            this.FinishedView()
          }
        }
        // 列表模式
        else {
          WidgetSecondaryCard({ course: this.validCourses[0] })
            .layoutWeight(1)

          Blank().height(4)

          if (this.validCourses.length > 1) {
            WidgetSecondaryCard({ course: this.validCourses[1] })
              .layoutWeight(1)

            Blank().height(4)

            if (this.validCourses.length > 2) {
              WidgetSecondaryCard({ course: this.validCourses[2] })
                .layoutWeight(1)
            } else {
              this.NoMoreView()
            }
          } else {
            this.FinishedView()
          }
        }
      } else {
        if (this.hasCoursesToday) {
          this.AllDoneView()
        } else {
          this.EmptyView()
        }
      }
    }
    .width('100%').height('100%').padding(10)
    .backgroundColor($r('app.color.widget_background'))
    .alignItems(HorizontalAlign.Start)
  }

  // --- 辅助视图 ---
  @Builder EmptyView() {
    Column() {
      Text("当前无课")
        .fontSize(14)
        .fontColor($r('app.color.widget_font_tertiary'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.widget_fill_color'))
    .borderRadius(12)
  }

  @Builder AllDoneView() {
    Column() {
      Text("今日课程已结束")
        .fontSize(14)
        .fontColor($r('app.color.widget_font_tertiary'))
      Text("好好休息一下吧")
        .fontSize(12)
        .fontColor($r('app.color.widget_font_tertiary'))
        .opacity(0.8)
        .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.widget_fill_color'))
    .borderRadius(12)
  }

  @Builder FinishedView() {
    Row() {
      Text("后续无课程")
        .fontSize(11)
        .fontColor($r('app.color.widget_font_tertiary'))
    }
    .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.widget_fill_color'))
    .borderRadius(10)
  }

  @Builder NoMoreView() {
    Row().width('100%').layoutWeight(1)
  }
}