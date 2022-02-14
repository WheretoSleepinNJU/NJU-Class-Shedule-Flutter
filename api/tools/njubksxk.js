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
  let name = document.querySelector(
    "body > div:nth-child(10) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1)"
  ).textContent;
  let rst = { name: name, courses: []};
  let table_1 = document.getElementsByClassName("TABLE_TR_01");
  let table_2 = document.getElementsByClassName("TABLE_TR_02");
  let table = table_1.concat(table_2);
  table.forEach((e) => {
    let state = e.children[6].innerText;
    if (state.includes("已退选")) return;
    let course_name = e.children[1].innerText;
    let class_number = e.children[0].innerText;
    let teacher = e.children[3].innerText;
    let test_time = e.children[8].innerText;
    let test_location = e.children[9].innerText;
    let course_info = e.children[10].innerText;
    let info_str = e.children[4].innerText;
    let info_list = info_str.split("\n");
    info_list.forEach((i) => {
      let week_time = 0;
      let strs = i.split(" ");
      let start_time = 0;
      let time_count = 0;
      let weeks = [];
      for (let z = 0; z < WEEK_WITH_BIAS.length; z++) {
        if (WEEK_WITH_BIAS[z] == strs[0]) week_time = z;
      }
      let pattern1 = new RegExp("第(\\d{1,2})-(\\d{1,2})节", "i");
      strs.forEach((w) => {
        let r = pattern1.exec(w);
        if (r) {
          start_time = parseInt(r[1]);
          time_count = parseInt(r[2]) - parseInt(r[1]);
        }
      });
      let pattern2 = new RegExp("(\\d{1,2})-(\\d{1,2})周", "i");
      strs.forEach((x) => {
        let s = pattern2.exec(x);
        if (s) {
          if (strs.includes("单周")) {
            for (let z = parseInt(s[1]); z <= parseInt(s[2]); z += 2)
              weeks.push(z);
          } else if (strs.includes("双周")) {
            for (let z = parseInt(s[1]); z <= parseInt(s[2]); z += 2)
              weeks.push(z);
          } else {
            for (let z = parseInt(s[1]); z <= parseInt(s[2]); z++)
              weeks.push(z);
          }
        }
      });
      let pattern3 = new RegExp("第(\\d{1,2})周", "i");
      strs.forEach((y) => {
        let t = pattern3.exec(y);
        if (t) {
          weeks.push(parseInt(t[1]));
        }
      });
      let classroom = strs[strs.length - 1];
      rst["courses"].push({
        name: course_name,
        classroom: classroom,
        class_number: class_number,
        teacher: teacher,
        test_time: test_time,
        test_location: test_location,
        link: null,
        weeks: weeks,
        week_time: week_time,
        start_time: start_time,
        time_count: time_count,
        import_type: 1,
        info: course_info,
        data: null,
      });
    });
  });
  return JSON.stringify(rst);
}
scheduleHtmlParser();
