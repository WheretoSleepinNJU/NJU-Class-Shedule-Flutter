let WEEK_NUM = 16;
let NAME = "2022-2023学年第一学期";
let NUM_REF = {
  "一": 1,
  "二": 2,
  "三": 3,
  "四": 4,
  "五": 5,
  "六": 6,
  "七": 7,
  "八": 8,
  "九": 9
}

function getWeekSeriesString(info) {
  let weekSeries = [];
  if(info == "全周") {
    for (let j = 1; j <= WEEK_NUM; j++) {
      weekSeries.push(j);
    }
  }

  let rst = info.match(/(\d{1,2})-(\d{1,2})周/);
  if(rst != null) {
    let startWeek = parseInt(rst[1]);
    let endWeek = parseInt(rst[2]);
    for (let j = startWeek; j <= endWeek; j++) {
      weekSeries.push(j);
    }
  }

  let rst2 = info.match(/前(.)周/);
  if(rst2 != null) {
    let endWeek = NUM_REF[rst2[1]];
    for (let j = 1; j <= endWeek; j++) {
      weekSeries.push(j);
    }
  }
  return weekSeries.toString();
}

function scheduleHtmlParser() {
  let rst = { name: NAME, courses: [] };
  let rows = document.getElementsByTagName("table")[0].rows;
  for (let i = 1; i < rows.length; i++) {
    // console.log(rows[i]);
    for (let j = 1; j < rows.length; j++) {
      let course_info = String(rows[i].children[j].innerText);
      if (course_info == "") continue;
      infos = course_info.match(/(.*)\((.*)；(.*)；(.*)；(.*)\)/);
      if (infos != null) {
        let courseName = infos[1];
        let classRoom = infos[5];
        let courseTeacher = infos[2];
        let weekTime = j;
        let startTime = i;
        let timeCount = 1;
        let weekSeries = getWeekSeriesString(infos[4]);

        course = {
          name: courseName,
          classroom: classRoom,
          // class_number: class_number,
          teacher: courseTeacher,
          // test_time: test_time,
          // test_location: test_location,
          link: null,
          weeks: weekSeries,
          week_time: weekTime,
          start_time: startTime,
          time_count: timeCount,
          import_type: 1,
          // info: courseInfo,
          data: null,
        };

        console.log(course);
        rst["courses"].push(course);
      }
    }
  }

  return encodeURIComponent(JSON.stringify(rst));
}
scheduleHtmlParser();
