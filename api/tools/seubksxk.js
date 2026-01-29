function scheduleHtmlParser() {
  // 1. 获取学期列表
  var getTerms = function () {
    var xhr = new XMLHttpRequest();
    xhr.open(
      "GET",
      "https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/jshkcb/xnxqcx.do",
      false,
    );
    xhr.send();
    var data = JSON.parse(xhr.responseText);
    var terms = data.datas.xnxqcx.rows;
    terms.sort((a, b) => a.PX - b.PX); // 早→新
    return terms;
  };

  // 2. 获取课表
  var getRawKb = function (termCode) {
    var xhr = new XMLHttpRequest();
    xhr.open(
      "GET",
      "https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/xskcb/xskcb.do?XNXQDM=" +
        termCode,
      false,
    );
    xhr.send();
    return JSON.parse(xhr.responseText).datas.xskcb.rows;
  };

  // 3. 解析周数（优先使用bitmap，fallback到文本解析）
  function parseWeekRange(zcmc, skzc) {
    // 优先使用周次bitmap（更准确）
    if (skzc && typeof skzc === "string") {
      var weeks = [];
      for (var i = 0; i < skzc.length; i++) {
        if (skzc[i] === "1") {
          weeks.push(i + 1); // 索引从0开始，周数从1开始
        }
      }
      if (weeks.length > 0) return weeks;
    }

    // Fallback: 解析文本格式
    if (!zcmc) return [];

    var parts = zcmc.split(",");
    var allWeeks = [];

    parts.forEach(function (part) {
      // 支持复杂格式：'9-11周(单),13-15周,16周'
      var m = part.match(/(\d+)(?:-(\d+))?周?(?:\((单|双)\))?/);
      if (!m) return;

      var start = parseInt(m[1], 10);
      var end = m[2] ? parseInt(m[2], 10) : start;
      var flag = { 单: 1, 双: 2 }[m[3]] || 0;

      for (var w = start; w <= end; w++) {
        if (
          flag === 0 ||
          (flag === 1 && w % 2 === 1) ||
          (flag === 2 && w % 2 === 0)
        ) {
          if (allWeeks.indexOf(w) === -1) allWeeks.push(w);
        }
      }
    });

    return allWeeks.sort(function (a, b) {
      return a - b;
    });
  }

  // 4. 从DOM获取当前学期
  var currentTermCode = null;
  var currentTermName = null;

  var terms = getTerms();
  var currentTerm = terms[0];
  currentTermCode = currentTerm.DM;
  currentTermName = currentTerm.MC;

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
  rows.forEach(function (r) {
    var weeksArr = parseWeekRange(r.ZCMC, r.SKZC);
    if (!weeksArr.length) return;
    courses.push({
      name: r.KCM,
      classroom: r.JASMC,
      class_number: r.KCH,
      teacher: r.SKJS,
      test_time: null,
      test_location: null,
      link: null,
      weeks: weeksArr,
      week_time: parseInt(r.SKXQ, 10),
      start_time: parseInt(r.KSJC, 10),
      time_count: parseInt(r.JSJC, 10) - parseInt(r.KSJC, 10),
      import_type: 1,
      info: r.ZCMC,
      data: null,
    });
  });

  console.log("已选择学期：" + currentTermCode + " " + currentTermName);

  // 返回符合南哪课表格式的数据
  var result = {
    name: currentTermName,
    courses: courses,
  };
  return encodeURIComponent(JSON.stringify(result));
}

scheduleHtmlParser();
