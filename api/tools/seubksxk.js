function scheduleHtmlParser() {
  // 1. 获取学期列表
  var getTerms = function () {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/jshkcb/xnxqcx.do', false);
    xhr.send();
    var data = JSON.parse(xhr.responseText);
    var terms = data.datas.xnxqcx.rows;
    terms.sort((a, b) => a.PX - b.PX);   // 早→新
    return terms;
  };

  // 2. 获取课表
  var getRawKb = function (termCode) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/xskcb/xskcb.do?XNXQDM=' + termCode, false);
    xhr.send();
    return JSON.parse(xhr.responseText).datas.xskcb.rows;
  };

  // 3. 解析周数
  function parseWeekRange(zcmc) {
    var m = zcmc.match(/(\d+)-(\d+)周(?:\((单|双)\))?/);
    if (!m) return [];
    var start = parseInt(m[1], 10);
    var end = parseInt(m[2], 10);
    var flag = { '单': 1, '双': 2 }[m[3]] || 0;
    var arr = [];
    for (var w = start; w <= end; w++) {
      if (flag === 0 || (flag === 1 && w % 2 === 1) || (flag === 2 && w % 2 === 0)) arr.push(w);
    }
    return arr;
  }

  // 4. 从DOM获取当前学期
  var currentTermCode = null;
  var currentTermName = null;
  
  // 尝试从DOM元素获取当前学期
  var termLabel = document.getElementById('dqxnxq2');
  if (termLabel) {
    currentTermCode = termLabel.getAttribute('value');
    currentTermName = termLabel.textContent || termLabel.innerText;
  }
  
  // 如果无法从DOM获取，则从学期列表中查找
  if (!currentTermCode) {
    var terms = getTerms();
    if (terms.length > 0) {
      // 使用最新的学期
      var currentTerm = terms[terms.length - 1];
      currentTermCode = currentTerm.DM;
      currentTermName = currentTerm.MC;
    }
  }
  
  if (!currentTermCode) {
    return encodeURIComponent(JSON.stringify({
      name: "无法获取学期信息",
      courses: []
    }));
  }

  // 5. 抓取并转换
  var rows = getRawKb(currentTermCode);
  var courses = [];
  rows.forEach(function (r) {
    var weeksArr = parseWeekRange(r.ZCMC);
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
      time_count: parseInt(r.JSJC, 10) - parseInt(r.KSJC, 10) + 1,
      import_type: 1,
      info: r.ZCMC,
      data: null
    });
  });

  console.log('已选择学期：' + currentTermCode + ' ' + currentTermName);
  
  // 返回符合南哪课表格式的数据
  var result = {
    name: currentTermName,
    courses: courses
  };
  
  return encodeURIComponent(JSON.stringify(result));
}

scheduleHtmlParser();