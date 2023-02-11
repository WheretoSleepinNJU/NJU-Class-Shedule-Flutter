function getWeekSeriesString(info) {
  let weekList = [];
  let strs = [];
  try {
    info = info.split(" ")[2];
    strs = info.split(",");
  } catch (e) {
    return "[]";
  }

  for (let i = 0; i < strs.length; i++) {
    var rst4 = strs[i].match(/^(\d{1,2})周$/);
    if (rst4 != null) {
      weekList.push(rst4[1]);
    }

    var rst2 = strs[i].match(/(\d{1,2})-(\d{1,2})周/);
    if (rst2 != null) {
      let startWeek = parseInt(rst2[1]);
      let endWeek = parseInt(rst2[2]);
      if (strs[i].includes("单") || strs[i].includes("双")) {
        for (let j = startWeek; j <= endWeek; j = j + 2) {
          weekList.push(j);
        }
      } else {
        for (let j = startWeek; j <= endWeek; j++) {
          weekList.push(j);
        }
      }
    }
  }
  return weekList;
}

function scheduleHtmlParser() {
  let WEEK_WITH_BIAS = [
    "",
    "周一",
    "周二",
    "周三",
    "周四",
    "周五",
    "周六",
    "周日",
  ];
  let WEEK_NUM = 17;

  // let name = "";
  let name = document.getElementsByClassName("currentTerm")[0].innerHTML;
  let rst = { name: name, courses: [] };
  let tableHeads = document.getElementsByClassName("course-head");
  let tableHead = tableHeads[tableHeads.length - 1];
  let headElements = tableHead.children[0].children;
  let infoIndex = 3;
  let courseNameIndex = 1;
  let courseTeacherIndex = 2;
  let courseInfoIndex = 6;
  for (let i = 0; i < headElements.length; i++) {
    //  console.log(headElements[i].innerHTML);
    if (headElements[i].innerHTML.includes("时间地点")) {
      infoIndex = i;
    } else if (headElements[i].innerHTML.includes("课程名")) {
      courseNameIndex = i;
    } else if (headElements[i].innerHTML.includes("教师")) {
      courseTeacherIndex = i;
    } else if (headElements[i].innerHTML.includes("备注")) {
      courseInfoIndex = i;
    }
  }
  let tables = document.getElementsByClassName("course-body");
  let table = tables[tables.length - 1]
  let elements = table.children;

  for (let i = 0; i < elements.length; i++) {
    // console.log(elements[i]);
    //退选课程
    // String state = e.children[6].innerHtml.trim();
    // if(state.contains('已退选')) continue;

    if (elements[i].className.includes("wdbm-course-tr")) continue;
    // print(e.className);

    // Time and Place
    let infos = elements[i].children[infoIndex].children;
    let courseName = elements[i].children[courseNameIndex].innerHTML;
    let courseTeacher = elements[i].children[courseTeacherIndex].innerHTML;
    // console.log(courseInfoIndex)
    // console.log(elements[i].children[courseInfoIndex]);
    let courseInfo =
      elements[i].children[courseInfoIndex].attributes["title"].value;

    // console.log(infos);
    for (let j = 0; j < infos.length; j++) {
      let info = infos[j].innerHTML;
      if (info == "") continue;
      info = info.trim();
      // console.log(info);

      let strs = info.split(" ");

      //自由时间缺省值
      let weekTime = 0;
      let startTime = 0;
      let timeCount = 0;
      if (!info.includes("自由时间")) {
        // Get WeekTime
        let weekStr = info.substring(0, 2);
        for (let k = 0; k < WEEK_WITH_BIAS.length; k++) {
          if (WEEK_WITH_BIAS[k] == weekStr) {
            weekTime = k;
          }
        }
      }

      let weekSeries;
      // console.log(info)

      let time = info.match(/(\d{1,2})-(\d{1,2})节/);
      // console.log(time);
      // var time = patten1.firstMatch(info);
      if (time) {
        startTime = parseInt(time[1]);
        timeCount = parseInt(time[2]) - startTime;
        weekSeries = getWeekSeriesString(info);
      }
      if (weekSeries == null) {
        weekSeries = [];
        for (let j = 1; j <= WEEK_NUM; j++) {
          weekSeries.push(j);
        }
      }

      // Get ClassRoom
      let classRoom = strs[strs.length - 1];

      // console.log(weekTime);
      rst["courses"].push({
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
        info: courseInfo,
        data: null,
      });
    }
  }
  // return rst;
  return encodeURIComponent(JSON.stringify(rst));
}
scheduleHtmlParser();
