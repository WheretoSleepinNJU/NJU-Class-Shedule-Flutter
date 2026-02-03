import { CourseWidgetVO } from '../../models/CourseModel';

@Component
export struct WidgetSecondaryCard {
  @Prop course: CourseWidgetVO;

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.course.color)
        .opacity(0.15)
        .borderRadius(10)

      Row() {
        Text(this.course.name)
          .fontSize(13)
          .fontColor($r('app.color.widget_font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.course.startTimeStr)
          .fontSize(12)
          .fontColor(this.course.color)
          .fontWeight(FontWeight.Medium)
          .opacity(0.8)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 7, right: 7 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }
}