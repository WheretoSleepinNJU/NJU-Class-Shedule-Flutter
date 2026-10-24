function scheduleHtmlParser() {
  // The existing app runs preExtractJS on the logged-in portal. Its navigation
  // to the academic SSO entry carries semester metadata in a URL fragment;
  // HTTP redirects preserve it without sending it to either server.
  const fragment = /^#nju-schedule=(\d{4}-\d{2}-\d{2}),(\d+)$/.exec(window.location.hash || "");
  const config = window.__NJU_SCHEDULE_IMPORT_CONFIG__ || (fragment ? {
    semester_start_monday: fragment[1], week_count: Number(fragment[2]),
  } : {});
  // Capture the actual VPN route before replaceState sanitizes the URL. VPN
  // academic pages may use either /http/ or /https/; do not switch protocols.
  const pageLocation = {
    hostname: window.location.hostname, origin: window.location.origin,
    pathname: window.location.pathname || "",
  };
  // Keep authenticated HTML and URLs out of the unchanged app's error report.
  document.documentElement.innerHTML = '<head><meta name="viewport" content="width=device-width,initial-scale=1"><title>清华课表导入</title></head><body style="font:18px sans-serif;padding:24px">正在读取清华研究生课表，请稍候…</body>';
  history.replaceState(null, "", "/nju-schedule-import");
  const DAY_MS = 86400000;
  const parseDate = (value) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value));
    if (!match) throw new Error("清华课表日期格式异常");
    const date = new Date(Date.UTC(+match[1], +match[2] - 1, +match[3]));
    if (date.toISOString().slice(0, 10) !== value) {
      throw new Error("清华课表日期无效");
    }
    return date;
  };
  const firstDay = parseDate(config.semester_start_monday);
  const weekCount = Number(config.week_count || 16);
  if (firstDay.getUTCDay() !== 1 || !Number.isInteger(weekCount) ||
      weekCount < 1 || weekCount > 30) {
    throw new Error("清华课表学期配置异常");
  }

  // Both the official site and the WebVPN page must query their own origin so
  // that the academic-system session is carried, without cross-origin cookies.
  const location = pageLocation;
  const vpnAcademicPage = /^\/https?\/77726476706e69737468656265737421eaff4b8b69336153301c9aa596522b20bc86e6e559a9b290\/jxmh\.do$/.test(location.pathname);
  const vpnPath = vpnAcademicPage
    ? location.pathname.slice(0, location.pathname.lastIndexOf("/") + 1)
    : null;
  const base = location.hostname === "zhjw.cic.tsinghua.edu.cn"
    ? location.origin + "/"
    : location.hostname === "webvpn.tsinghua.edu.cn" && vpnPath
      ? location.origin + vpnPath
      : null;
  if (!base) throw new Error("请先登录清华研究生教学日历");

  const slots = [
    ["08:00", "08:45"], ["08:50", "09:35"],
    ["09:50", "10:35"], ["10:40", "11:25"],
    ["11:30", "12:15"], ["13:30", "14:15"],
    ["14:20", "15:05"], ["15:20", "16:05"],
    ["16:10", "16:55"], ["17:05", "17:50"],
    ["17:55", "18:40"], ["19:20", "20:05"],
    ["20:10", "20:55"], ["21:00", "21:45"],
  ];
  const normalizeTime = (value) => {
    const match = /^(\d{1,2})[:：](\d{2})(?::\d{2})?$/.exec(String(value).trim());
    return match ? match[1].padStart(2, "0") + ":" + match[2] : "";
  };
  const period = (value, boundary) => {
    const time = normalizeTime(value);
    // Start/end use separate exact maps: 08:50 belongs to period 2, not 1.
    return slots.findIndex((slot) => slot[boundary] === time) + 1;
  };
  const formatDate = (offset) => new Date(firstDay.getTime() + offset * DAY_MS)
    .toISOString().slice(0, 10).replace(/-/g, "");
  const parseResponse = (text) => {
    const body = text.trim();
    if (body.startsWith("<")) {
      throw new Error("清华教务登录已失效，请重新登录信息门户");
    }
    const match = /^m\s*\(([\s\S]*)\)\s*;?\s*$/.exec(body);
    let data;
    try { data = JSON.parse(match ? match[1] : body); }
    catch (_) { throw new Error("清华课表接口返回格式异常"); }
    if (!Array.isArray(data)) throw new Error("清华课表接口未返回课程列表");
    return data;
  };

  const records = [];
  for (let startWeek = 0; startWeek < weekCount; startWeek += 3) {
    const url = base + "jxmh_out.do?m=yjs_jxrl_all&p_start_date=" +
      formatDate(startWeek * 7) + "&p_end_date=" +
      formatDate(Math.min(startWeek + 3, weekCount) * 7 - 1) + "&jsoncallback=m";
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url, false);
    xhr.setRequestHeader("Accept", "application/json, text/javascript, */*");
    xhr.send();
    if (xhr.status !== 200) throw new Error("清华课表请求失败，请稍后重试");
    // Any failed batch aborts the import instead of producing a partial table.
    records.push(...parseResponse(xhr.responseText));
  }

  const dailyCourses = new Map();
  for (const item of records) {
    // The calendar also includes personal events and announcements.
    if (item.fl && item.fl !== "上课") continue;
    if (!item.nr || !item.nq || !item.kssj || !item.jssj) {
      throw new Error("清华课程缺少日期或上课时间");
    }
    const date = parseDate(item.nq);
    const week = Math.floor((date.getTime() - firstDay.getTime()) / DAY_MS / 7) + 1;
    if (week < 1 || week > weekCount) continue;
    const weekday = date.getUTCDay() || 7;
    const start = period(item.kssj, 0);
    const end = period(item.jssj, 1);
    if (!start || !end || end < start) {
      throw new Error("清华课程时间与节次不匹配，未导入不完整课表");
    }
    // Combine only occurrences on the same day and week. Merging week lists
    // first would incorrectly extend shorter courses in weeks with fewer periods.
    const dayKey = JSON.stringify([item.nr, item.dd || "", weekday, week]);
    if (!dailyCourses.has(dayKey)) {
      dailyCourses.set(dayKey, {
        name: item.nr, classroom: item.dd || "", weekday, week, info: item.fl || "", spans: [],
      });
    }
    dailyCourses.get(dayKey).spans.push([start, end]);
  }
  const courseMap = new Map();
  for (const day of dailyCourses.values()) {
    const spans = day.spans.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
    const merged = [];
    for (const span of spans) {
      const previous = merged[merged.length - 1];
      if (previous && span[0] <= previous[1] + 1) {
        previous[1] = Math.max(previous[1], span[1]);
      } else {
        merged.push(span.slice());
      }
    }
    for (const [start, end] of merged) {
      const key = JSON.stringify([day.name, day.classroom, day.weekday, start, end]);
      if (!courseMap.has(key)) {
        courseMap.set(key, {
          name: day.name, classroom: day.classroom, class_number: "", teacher: "",
          test_time: null, test_location: null, link: null, weeks: [],
          week_time: day.weekday, start_time: start, time_count: end - start,
          import_type: 1, info: day.info, data: null,
        });
      }
      courseMap.get(key).weeks.push(day.week);
    }
  }
  const courses = [...courseMap.values()];
  if (courses.length === 0) {
    throw new Error("本学期未读取到已安排时间的课程，请核对学期后重试");
  }
  courses.forEach((course) => course.weeks.sort((a, b) => a - b));
  const year = firstDay.getUTCFullYear();
  const month = firstDay.getUTCMonth() + 1;
  const spring = month >= 2 && month <= 7;
  const academicYear = spring || month === 1 ? year - 1 : year;
  return encodeURIComponent(JSON.stringify({
    name: `清华大学研究生课表 ${academicYear}-${academicYear + 1}学年 ${spring ? "春" : "秋"}季学期`,
    courses,
  }));
}

scheduleHtmlParser();
