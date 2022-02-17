function scheduleHtmlParser() {
  let WEEK_WITH_BIAS = [
    '',
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  data = JSON.parse(document.body.innerText.replace(/\n/g, ''));
  let name = data['results'][data['results'].length - 1]['XNXQMC'];
  let rst = { name: name, courses: []};
  data['results'].forEach((e) => {
    // console.log(e['XNXQMC']);
    let sem = e['XNXQMC'];
    if (sem != name) return;

    let course_name = e['KCMC'];
    let class_number = e['KCDM'];
    let teacher = e['RKJS'];
    let test_time = '';
    let test_location = '';
    let course_info = e['XKBZ'];
    let info_str = e['PKSJDD'];
    let info_list = info_str.split(';');
    info_list.forEach((i) => {
      let week_time = 0;
      let start_time = 0;
      let time_count = 0;
      let weeks = [];
      //pattern: xx(-xx)(单/双)周 星期x[x-x节]x
      let pattern = new RegExp(
        '(\\d{1,2})(-(\\d{1,2}))?(单|双)?周 星期(.)\\[(\\d{1,2})(-(\\d{1,2}))?节](.*)',
        'i'
      );
      let strs = pattern.exec(i);
      for (let z = 0; z < WEEK_WITH_BIAS.length; z++) {
        if (WEEK_WITH_BIAS[z] == strs[5]) week_time = z;
      }
      if (strs[4] == '单') {
        for (let z = parseInt(strs[1]); z <= parseInt(strs[3]); z += 2)
          weeks.push(z);
      } else if (strs[4] == '双') {
        for (let z = parseInt(strs[1]); z <= parseInt(strs[3]); z += 2)
          weeks.push(z);
      } else {
        for (let z = parseInt(strs[1]); z <= parseInt(strs[3]); z++)
          weeks.push(z);
      }
      start_time = parseInt(strs[6]);
      if (typeof(strs[8]) != 'undefined') {
        time_count = parseInt(strs[8]) - parseInt(strs[6]);
      } else {
        time_count = 1;
      }
      let classroom = strs[9];
      rst['courses'].push({
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
  rst['courses'] = JSON.stringify(rst['courses']);
  return encodeURIComponent(JSON.stringify(rst));
}
scheduleHtmlParser();
