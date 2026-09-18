(() => {
  "use strict";

  const endpoint = performance
    .getEntriesByType("resource")
    .map((entry) => entry.name)
    .filter((url) => url.includes("/cxxszhxqkb.do"))
    .pop();

  if (!endpoint) {
    throw new Error("未找到南师大课表接口，请打开课表查看页面后重试");
  }

  const request = new XMLHttpRequest();
  request.open("GET", endpoint, false);
  request.withCredentials = true;
  request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
  request.send(null);

  if (request.status < 200 || request.status >= 300) {
    throw new Error(`南师大课表接口请求失败：${request.status}`);
  }

  const payload = JSON.parse(request.responseText);
  const table = payload?.datas?.cxxszhxqkb;
  const rows = table?.rows;

  if (table?.extParams?.code !== 1 || !Array.isArray(rows)) {
    throw new Error(table?.extParams?.msg || "南师大课表数据格式异常");
  }

  const parseWeeks = (weekBits) =>
    Array.from(String(weekBits || "")).flatMap((enabled, index) =>
      enabled === "1" ? [index + 1] : [],
    );

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
    }));

  if (courses.length === 0) {
    throw new Error("没有找到包含上课时间的课程");
  }

  const semester =
    rows.find((row) => row.XNXQDM_DISPLAY)?.XNXQDM_DISPLAY ||
    rows.find((row) => row.XNXQDM)?.XNXQDM ||
    "南京师范大学课表";

  return encodeURIComponent(
    JSON.stringify({
      name: semester,
      courses,
    }),
  );
})()
