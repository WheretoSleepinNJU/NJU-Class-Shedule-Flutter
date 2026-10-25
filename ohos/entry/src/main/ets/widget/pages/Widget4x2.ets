import { TodayWidgetData } from '../models/WidgetDataModel';
import { MOCK_DATA } from '../mock/MockData';
import { ScheduleCard } from './components/ScheduleCard';

const storage = new LocalStorage();
@Entry(storage)
@Component
struct Widget4x2 {
  // The gallery renders a realistic preview before a live form binding arrives.
  @LocalStorageProp('widgetData') data: TodayWidgetData = MOCK_DATA;
  @LocalStorageProp('currentTime') currentTime: string = '08:30';
  build() {
    Column() {
      ScheduleCard({ data: this.data, currentTime: this.currentTime, wide: true })
    }.width('100%').height('100%')
  }
}
