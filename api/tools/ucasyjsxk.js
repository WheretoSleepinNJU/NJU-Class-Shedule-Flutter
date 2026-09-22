// 中国科学院大学（UCAS / 国科大）研究生课表提取脚本
// 数据源：国科大在线（超星平台）个人课表
//   页面：https://kb.mooc.ucas.edu.cn/res/pc/curriculum/schedule.html
//   接口：同源 /pc/curriculum/getMyLessons?week=<周>
// 该接口为页面自身加载课表所用的同源 JSON 接口（登录后可访问），按周返回该周
// 实际上课的课程，每节课含 weeks(上课周次)/dayOfWeek(星期)/beginNumber(起始节)/
// length(持续节数)/location(教室)/teacherName(教师)/name(课程名)/courseNo(课程编号)。
// 其中 weeks 字段是该课程段准确的上课周次（能体现单双周、分段、调课等变化）。
//
// 脚本逐周（1..maxWeek）以同步 XHR 拉取并按 lessonConfigUuid 去重合并，得到
// 全学期所有课程段，再转换为南哪课表标准 JSON，返回 encodeURIComponent 结果。

function scheduleHtmlParser() {
  // 同步 GET JSON
  function getJSON(url) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url, false);
    try {
      xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    } catch (e) {}
    xhr.send(null);
    if (xhr.status !== 200 || !xhr.responseText) {
      throw new Error("HTTP " + xhr.status + " for " + url);
    }
    return JSON.parse(xhr.responseText);
  }

  // 取某周课表：优先用 preExtractJS 并行预取好的缓存（window.__ucasLessonsCache），
  // 缓存缺失（如单独运行本脚本）再退回同步请求。
  function fetchWeek(w) {
    const cache =
      (typeof window !== "undefined" && window.__ucasLessonsCache) || null;
    if (cache && cache[w] && cache[w].result === 1) {
      return cache[w];
    }
    const url =
      "/pc/curriculum/getMyLessons?curTime=" +
      new Date().getTime() +
      "&week=" +
      w;
    return getJSON(url);
  }

  // 周次文本 "2,3,4,5,7-11" / "2、3、4" / "1-16单" / "2-18双" → 周次数组（1 起始）
  function parseWeeks(text) {
    const weeks = [];
    if (!text) return weeks;
    const norm = String(text)
      .replace(/，/g, ",")
      .replace(/、/g, ",")
      .replace(/\s/g, "");
    const parts = norm.split(",");
    for (let p = 0; p < parts.length; p++) {
      const part = parts[p];
      if (!part) continue;
      const isSingle = /单/.test(part);
      const isDouble = /双/.test(part);
      const clean = part.replace(/[周单双()（）]/g, "");
      if (clean.indexOf("-") > -1 || clean.indexOf("~") > -1) {
        const range = clean.split(/[-~]/);
        const start = parseInt(range[0], 10);
        const end = parseInt(range[1], 10);
        if (isNaN(start) || isNaN(end)) continue;
        const step = isSingle || isDouble ? 2 : 1;
        let cur = start;
        if (isSingle && start % 2 === 0) cur = start + 1;
        if (isDouble && start % 2 === 1) cur = start + 1;
        for (let i = cur; i <= end; i += step) weeks.push(i);
      } else {
        const n = parseInt(clean, 10);
        if (!isNaN(n)) weeks.push(n);
      }
    }
    // 去重并升序（用普通对象，避免页面旧 polyfill 占用原生 Set/Map）
    const seen = {};
    const uniq = [];
    for (let i = 0; i < weeks.length; i++) {
      const w = weeks[i];
      if (!seen[w]) {
        seen[w] = 1;
        uniq.push(w);
      }
    }
    return uniq.sort((a, b) => a - b);
  }

  function termName(cur) {
    if (!cur) return "国科大课表";
    // semester: 1=第一学期(秋)，2=第二学期(春)
    const year = String(cur.schoolYear || "");
    const sem = Number(cur.semester);
    let suffix = "";
    if (sem === 1) suffix = "学年(秋)第一学期";
    else if (sem === 2) suffix = "学年(春)第二学期";
    if (year && suffix) {
      const next = (Number(year) + 1).toString();
      return "中国科学院大学 " + year + "—" + next + suffix;
    }
    return "中国科学院大学研究生课表";
  }

  function run() {
    // 先取一次拿到学期配置（maxWeek / 学期名）；优先走并行预取缓存
    const first = fetchWeek(1);
    if (!first || first.result !== 1 || !first.data) {
      // 未登录或会话失效：直接抛错，App 会上报错误页
      throw new Error("getMyLessons 未返回有效数据（可能未登录）：" +
        (first && first.msg ? first.msg : "unknown"));
    }
    const curriculum = first.data.curriculum || {};
    const maxWeek = Number(curriculum.maxWeek) || 20;

    // 逐周拉取并按 lessonConfigUuid 去重合并
    // 用普通对象而非 Map/Set：课表页是老平台页面，可能有 IE 时代 polyfill
    // 占用原生 Map/Set，导致 forEach 等方法不存在。
    const seen = {};
    const merged = [];
    for (let w = 1; w <= maxWeek; w++) {
      try {
        // fetchWeek 优先读 preExtractJS 的并行预取缓存，缺失再同步请求
        const rsp = fetchWeek(w);
        if (!rsp || rsp.result !== 1 || !rsp.data) continue;
        const arr = rsp.data.lessonArray || [];
        for (let i = 0; i < arr.length; i++) {
          const L = arr[i];
          // 同一课程段用 lessonConfigUuid 去重；缺失时用 名称+星期+节次+教室 兜底
          const key =
            L.lessonConfigUuid ||
            [L.name, L.dayOfWeek, L.beginNumber, L.length, L.location].join("|");
          if (!seen[key]) {
            seen[key] = 1;
            merged.push(L);
          }
        }
      } catch (e) {
        // 单周失败不影响其它周
      }
    }

    const result = { name: termName(curriculum), courses: [] };

    for (let idx = 0; idx < merged.length; idx++) {
      const L = merged[idx];
      const weeks = parseWeeks(L.weeks);
      if (weeks.length === 0) continue; // 无有效周次（如免修免考/全天占位）跳过
      const dayOfWeek = parseInt(L.dayOfWeek, 10);
      const beginNumber = parseInt(L.beginNumber, 10);
      const length = parseInt(L.length, 10) || 1;
      if (!dayOfWeek || !beginNumber) continue;

      const room = (L.location || "").trim();
      const online = (L.onlineLocation || "").trim();
      const classroom = room || online || "待定";

      result.courses.push({
        name: L.name || L.displayCourseName || "",
        classroom: classroom,
        class_number: L.courseNo || L.classNo || "",
        teacher: L.teacherName || "",
        test_time: null,
        test_location: null,
        link: "https://kb.mooc.ucas.edu.cn/res/pc/curriculum/schedule.html",
        weeks: weeks,
        week_time: dayOfWeek,                 // 周一=1 ... 周日=7
        start_time: beginNumber,             // 起始节（1 起始）
        time_count: length - 1,              // 持续节数 = 末节 - 首节
        import_type: 1,
        info: L.englishCourseName || null,
        data: null,
      });
    }

    return result;
  }

  const result = run();
  return encodeURIComponent(JSON.stringify(result));
}

scheduleHtmlParser();
