import { CourseWidgetVO } from "../../models/CourseModel";

@Component
export struct WidgetPrimaryCard {
  @Prop course: CourseWidgetVO;

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.course.color)
        .opacity(0.3)
        .borderRadius(12)

      Row() {
        Column()
          .width(4)
          .height('60%')
          .backgroundColor(this.course.color)
          .borderRadius(2)
          .margin({ right: 6 })

        Column() {
          Text(this.course.name)
            .fontSize(14)
            .fontColor($r('app.color.widget_font_primary'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ bottom: 4 })

          Blank()

          Column({ space: 1 }) {
            Text(`${this.course.startTimeStr}-${this.course.endTimeStr}`)
              .fontSize(11)
              .fontColor(this.course.color)
              .opacity(0.95)

            // 教室信息
            Text(this.course.classroom)
              .fontSize(11)
              .fontColor($r('app.color.widget_font_secondary'))
              .opacity(0.8)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 4, right: 7, top: 8, bottom: 8 })
    }
    .width('100%')
  }
}