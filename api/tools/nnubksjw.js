(() => {
  "use strict";

  // 从课表页面中读取当前展示的学年学期
  const pageText = (document.body?.innerText || "").replace(/\s+/g, "");
  const semesterMatch = pageText.match(
    /(\d{4})[-－–—](\d{4})学年第([12一二])学期/,
  );

  if (!semesterMatch) {
    throw new Error("无法识别当前学期，请先打开课表查看页面并等待加载完成");
  }

  const term = { "一": "1", "二": "2" }[semesterMatch[3]] || semesterMatch[3];
  const semesterCode = `${semesterMatch[1]}-${semesterMatch[2]}-${term}`;

  // 定位课表 API
  const endpoint = performance
    .getEntriesByType("resource")
    .map((entry) => entry.name)
    .filter((url) => url.includes("/cxxszhxqkb.do"))
    .pop();

  if (!endpoint) {
    throw new Error("未找到南师大课表接口，请打开课表查看页面后重试");
  }

  // POST 请求，携带学年学期代码
  const request = new XMLHttpRequest();
  request.open("POST", endpoint, false);
  request.withCredentials = true;

  request.setRequestHeader(
    "Content-Type",
    "application/x-www-form-urlencoded;charset=UTF-8",
  );

  request.setRequestHeader("X-Requested-With", "XMLHttpRequest");

  request.send(`XNXQDM=${encodeURIComponent(semesterCode)}`);

  if (request.status < 200 || request.status >= 300) {
    throw new Error(`南师大课表接口请求失败：HTTP ${request.status}`);
  }

  let payload;

  try {
    payload = JSON.parse(request.responseText);
  } catch {
    throw new Error("南师大课表接口未返回有效 JSON，请确认登录状态");
  }

  const table = payload?.datas?.cxxszhxqkb;
  const rows = table?.rows;

  if (String(table?.extParams?.code) !== "1" || !Array.isArray(rows)) {
    throw new Error(
      table?.extParams?.msg || payload?.msg || "南师大课表数据格式异常",
    );
  }

  // 解析上课周次
  const parseWeeks = (weekBits) =>
    Array.from(String(weekBits || "")).flatMap((enabled, index) =>
      enabled === "1" ? [index + 1] : [],
    );

  // 转换课程数据
  const courses = rows
    .filter(
      (row) =>
        row.KCM &&
        Number.isInteger(row.SKXQ) &&
        Number.isInteger(row.KSJC) &&
        Number.isInteger(row.JSJC) &&
        row.JSJC >= row.KSJC &&
        parseWeeks(row.SKZC).length > 0,
    )
    .map((row) => ({
      name: row.KCM,
      classroom: row.JASMC || "",
      class_number: [row.KCH, row.KXH].filter(Boolean).join("-"),
      teacher: row.SKJS || "",
      test_time: "",
      test_location: "",
      link: null,

      // 同时兼容 week 和 weeks
      week: parseWeeks(row.SKZC),
      weeks: parseWeeks(row.SKZC),

      week_time: row.SKXQ,
      start_time: row.KSJC,
      time_count: row.JSJC - row.KSJC,

      import_type: 1,

      info: [
        row.KCXZDM_DISPLAY,
        row.KCLBDM_DISPLAY,
        row.XF == null ? "" : `${row.XF}学分`,
      ]
        .filter(Boolean)
        .join("；"),

      data: null,
    }));

  if (courses.length === 0) {
    throw new Error("没有找到包含上课时间的课程，请检查当前学期及数据字段");
  }

  // 设置学期名称
  const semester =
    rows.find((row) => row.XNXQDM_DISPLAY)?.XNXQDM_DISPLAY ||
    rows.find((row) => row.XNXQDM)?.XNXQDM ||
    `${semesterMatch[1]}-${semesterMatch[2]}学年第${term}学期`;

  return encodeURIComponent(
    JSON.stringify({
      name: semester,
      courses,
    }),
  );
})();
