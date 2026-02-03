function scheduleHtmlParser() {
  // 1. 获取学期列表
  var getTerms = function () {
    var xhr = new XMLHttpRequest();
    xhr.open(
      "POST",
      "https://yjs2.ruc.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/kfdxnxqcx.do",
      false,
    );
    xhr.send();
    var data = JSON.parse(xhr.responseText);
    var terms = data.datas.kfdxnxqcx.rows;
    terms.sort((a, b) => a.PX - b.PX); // 早→新
    return terms;
  };

  // 2. 获取课表
  var getRawKb = function (termCode) {
    var formData = new FormData();
    formData.append("XNXQDM", termCode);
    var xhr = new XMLHttpRequest();
    xhr.open(
      "POST",
      "https://yjs2.ruc.edu.cn/gsapp/sys/wdkbapp/bykb/loadXskbData.do",
      false,
    );
    xhr.send(formData);
    return JSON.parse(xhr.responseText).rwList;
  };

  // 3. 解析信息
  function parseInfo(info) {
    const result = [];
    const segments = info.split(";");

    segments.forEach((seg) => {
      // 1-4,6-8周 星期二[3-4节]公学一楼102;3周 星期日[3-4节]公学一楼102
      const match = seg.match(/(.+?周)\s*星期(.+?)\[(.+?)节\](.*)/);
      if (!match) return;

      const [, weekPart, dayPart, timePart, classroom] = match;

      // 解析周次
      const weeks = [];
      weekPart.split(",").forEach((w) => {
        var m = w.match(/(\d+)-?(\d+)?(?:(单|双))?周?/);
        if (!m) return [];
        var start = parseInt(m[1], 10);
        var end = parseInt(m[2], 10);
        if (isNaN(end)) end = start;
        var flag = { 单: 1, 双: 2 }[m[3]] || 0;
        for (var w = start; w <= end; w++) {
          if (
            flag === 0 ||
            (flag === 1 && w % 2 === 1) ||
            (flag === 2 && w % 2 === 0)
          )
            weeks.push(w);
        }
      });

      // 解析星期几
      const dayMap = { 一: 1, 二: 2, 三: 3, 四: 4, 五: 5, 六: 6, 日: 7 };
      const week_time = dayMap[dayPart.trim()];

      // 解析节次
      const [startStr, endStr] = timePart.split("-");
      const start_time = parseInt(startStr, 10);
      const time_count = parseInt(endStr, 10) - start_time;

      result.push({
        classroom: classroom.trim(),
        weeks,
        week_time,
        start_time,
        time_count,
      });
    });

    return result;
  }

  var terms = getTerms();
  var currentTerm = terms[0];
  currentTermCode = currentTerm.XNXQDM;
  currentTermName = currentTerm.XNXQDM_DISPLAY;

  if (!currentTermCode) {
    return encodeURIComponent(
      JSON.stringify({
        name: "无法获取学期信息",
        courses: [],
      }),
    );
  }

  // 5. 抓取并转换
  var rows = getRawKb(currentTermCode);
  var courses = [];
  console.log(rows);
  rows.forEach(function (r) {
    // 无时间课程直接忽略
    if (r.PKSJDD == null) return;
    var info = parseInfo(r.PKSJDD);
    info.forEach(function (i) {
      courses.push({
        name: r.KCMC,
        classroom: i.classroom,
        class_number: r.KCDM,
        teacher: r.RKJS,
        test_time: null,
        test_location: null,
        link: null,
        weeks: i.weeks,
        week_time: i.week_time,
        start_time: i.start_time,
        time_count: i.time_count,
        import_type: 1,
        info: r.XKBZ,
        data: null,
      });
    });
  });

  // 返回符合南哪课表格式的数据
  var result = {
    name: currentTermName,
    courses: courses,
  };
  // return result;
  return encodeURIComponent(JSON.stringify(result));
}

scheduleHtmlParser();
