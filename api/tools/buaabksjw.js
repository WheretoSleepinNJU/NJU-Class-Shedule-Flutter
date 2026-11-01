(() => {
  "use strict";

  const origin = window.location.origin;
  const hostname = window.location.hostname;
  const expectedMonday = window.__NJU_SCHEDULE_IMPORT_CONFIG__?.semester_start_monday;
  // The released app includes the current HTML/URL in an import error report.
  // Remove the authenticated portal and CAS ticket before making any requests.
  document.documentElement.innerHTML = '<head><meta name="viewport" content="width=device-width,initial-scale=1"><title>北航课表导入</title></head><body style="font:18px sans-serif;padding:24px">正在读取北航学期课表，请稍候…</body>';
  history.replaceState(null, "", "/nju-schedule-import");
  if (!["byxt.buaa.edu.cn", "byxt-443.e1.buaa.edu.cn"].includes(hostname)) {
    throw new Error("请先登录北航本研教育管理系统");
  }

  const clean = value => String(value ?? "").replace(/\s+/g, " ").trim();
  const api = origin + "/jwapp/sys/homeapp/api/home/";
  function request(path, params) {
    const xhr = new XMLHttpRequest();
    xhr.open(params ? "POST" : "GET", api + path, false);
    xhr.setRequestHeader("Accept", "application/json, text/javascript, */*");
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    if (params) xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    try {
      xhr.send(params ? Object.entries(params).map(([k, v]) =>
        encodeURIComponent(k) + "=" + encodeURIComponent(v)).join("&") : null);
    } catch (_) {
      throw new Error("北航课表请求失败，请检查校园网或学校 WebVPN 连接");
    }
    if (xhr.status !== 200) throw new Error("北航教务登录失效或请求失败，请重新登录");
    let result;
    try { result = JSON.parse(xhr.responseText); }
    catch (_) { throw new Error("北航教务未返回课表数据，请重新登录"); }
    if (!result || String(result.code) !== "0" || result.datas == null) {
      throw new Error("北航课表接口返回异常，未导入不完整课表");
    }
    return result.datas;
  }

  const terms = request("student/schoolCalendars.do");
  if (!Array.isArray(terms)) throw new Error("北航学期列表格式异常");
  const selected = terms.filter(t => [true, 1, "true", "1"].includes(t.selected));
  if (selected.length !== 1) throw new Error("无法确定北航当前学期，请刷新教务首页");
  const termCode = clean(selected[0].itemCode);
  const term = /^(\d{4})-(\d{4})-([1-3])$/.exec(termCode);
  if (!term || +term[2] !== +term[1] + 1) throw new Error("北航学期代码格式异常");

  const calendar = request("getTermWeeks.do?termCode=" + encodeURIComponent(termCode));
  if (!Array.isArray(calendar) || !calendar.length || calendar.some(w =>
    !Number.isInteger(Number(w.serialNumber)) || +w.serialNumber < 1 || +w.serialNumber > 40)) {
    throw new Error("北航教学周数据异常");
  }
  const weekOne = calendar.find(w => Number(w.serialNumber) === 1);
  const monday = clean(weekOne?.startDate).slice(0, 10);
  const date = new Date(monday + "T00:00:00Z");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(monday) || Number.isNaN(date.getTime()) ||
      date.toISOString().slice(0, 10) !== monday || date.getUTCDay() !== 1) {
    throw new Error("无法确定北航第一教学周的周一日期");
  }
  if (expectedMonday && expectedMonday !== monday) {
    throw new Error("当前学期与导入配置不一致，请刷新学校列表后重试");
  }
  const lastWeek = Math.max(...calendar.map(w => Number(w.serialNumber)));
  const data = request("student/getMyScheduleDetail.do", {
    termCode, campusCode: "", type: "term",
  });
  if (!Array.isArray(data.arrangedList) || !data.arrangedList.length) {
    throw new Error("当前学期没有已排课课程，请在教务系统确认课表");
  }
  if (data.notArrangeList != null && !Array.isArray(data.notArrangeList)) {
    throw new Error("北航未排课课程数据异常");
  }

  function parseWeeks(text) {
    const normalized = clean(text).replace(/\[[^\]]*\]/g, "")
      .replace(/[－–—~～]/g, "-").replace(/[（]/g, "(").replace(/[）]/g, ")")
      .replace(/周|\s/g, "");
    const weeks = new Set();
    for (const part of normalized.split(/[,，、]/)) {
      const match = /^(\d+)(?:-(\d+))?(?:([单双])|\(([单双])\))?$/.exec(part);
      if (!match) throw new Error("北航上课周次无法识别，未导入不完整课表");
      const start = Number(match[1]), end = Number(match[2] || match[1]);
      const parity = match[3] || match[4];
      if (start < 1 || end < start || end > lastWeek) {
        throw new Error("北航课程周次超出当前学期范围");
      }
      for (let w = start; w <= end; w++) {
        if (!parity || w % 2 === (parity === "单" ? 1 : 0)) weeks.add(w);
      }
    }
    if (!weeks.size) throw new Error("北航课程缺少有效上课周次");
    return [...weeks].sort((a, b) => a - b);
  }

  function teaching(row) {
    const title = (row.titleDetail || []).find(t => /^上课教师\s*[:：]/.test(clean(t)));
    const titleText = title ? clean(title).replace(/^上课教师\s*[:：]/, "") : "";
    // The term summary's weeksAndTeachers only describes its first teaching
    // assignment. The tooltip lists ALL teachers, weeks and period spans.
    if (titleText.includes("/[")) {
      const pattern = /([^/]+)\/\[([^\]]+)\]\/(\d+)(?:\s*[-－–—]\s*(\d+))?\s*节/g;
      const matches = [...titleText.matchAll(pattern)];
      if (!matches.length || titleText.replace(pattern, "").replace(/[\s,，;；、]/g, "")) {
        throw new Error("北航完整授课安排格式异常，未导入不完整课表");
      }
      return matches.map(match => ({
        teacher: clean(match[1].replace(/^[,，;；、\s]+/, "").replace(/\[[^\]]*\]/g, "")),
        weeks: parseWeeks(match[2]), start: Number(match[3]),
        end: Number(match[4] || match[3]),
      }));
    }
    const detail = clean(row.weeksAndTeachers);
    if (detail) {
      const parts = detail.split("/");
      if (parts.length !== 2 || !clean(parts[1])) throw new Error("北航授课信息格式异常");
      return [{weeks: parseWeeks(parts[0]), teacher: clean(parts[1].replace(/\[[^\]]*\]/g, ""))}];
    }
    // Separately scheduled experiments have no weeksAndTeachers. Their
    // tooltip/cell contains e.g. 教师甲,教师乙[14-16周(双)].
    const lines = title ? [titleText] :
      (row.cellDetail || []).map(c => clean(c.text)).filter(t => /\[[^\]]*周/.test(t));
    if (lines.length !== 1) throw new Error("北航实验课缺少明确的授课周次");
    const matches = [...lines[0].matchAll(/\[([^\[\]]*周[^\[\]]*)\]/g)];
    if (matches.length !== 1) throw new Error("北航实验课周次格式异常");
    const match = matches[0];
    const teacher = clean(lines[0].slice(0, match.index).replace(/\/$/, ""));
    if (!teacher) throw new Error("北航实验课缺少教师信息");
    return [{weeks: parseWeeks(match[1]), teacher}];
  }

  // A lab's teachClassId identifies an experiment/project, not its parent
  // course. Resolve the enrolled course/section so its meetings share a color.
  const sections = new Map();
  for (const row of [...data.arrangedList, ...(data.notArrangeList || [])]) {
    const code = clean(row.courseCode), serial = clean(row.courseSerialNo);
    if (code && serial) {
      if (!sections.has(code)) sections.set(code, new Set());
      sections.get(code).add(serial);
    }
  }
  function identity(row) {
    const code = clean(row.courseCode);
    if (!code) throw new Error("北航课程缺少课程号");
    let serial = clean(row.courseSerialNo);
    if (!serial) {
      const candidates = [...(sections.get(code) || [])];
      if (candidates.length === 1) serial = candidates[0];
      else if (candidates.length > 1) {
        const marker = "-" + code + "-", id = clean(row.teachClassId);
        const index = id.indexOf(marker);
        const group = index < 0 ? "" : id.slice(index + marker.length).split("-")[0];
        const matched = candidates.filter(s => group.length % s.length === 0 &&
          Array.from({length: group.length / s.length}, (_, i) =>
            group.slice(i * s.length, (i + 1) * s.length)).includes(s));
        if (matched.length !== 1) throw new Error("无法匹配北航实验课的教学班");
        serial = matched[0];
      }
    }
    return JSON.stringify([code, serial]);
  }

  const ids = new Map(), merged = new Map();
  for (const row of data.arrangedList) {
    const titleName = (row.titleDetail || []).find(t => /^课程名\s*[:：]/.test(clean(t)));
    const name = titleName ? clean(titleName).replace(/^课程名\s*[:：]/, "") : clean(row.courseName);
    const day = Number(row.dayOfWeek);
    if (!name || !Number.isInteger(day) || day < 1 || day > 7) {
      throw new Error("北航课程时间或节次异常，未导入不完整课表");
    }
    const group = identity(row), assignments = teaching(row);
    if (!ids.has(group)) ids.set(group, ids.size + 1);
    const classroom = clean(row.placeName);
    const project = (row.titleDetail || []).find(t => /^实验项目名称\s*[:：]/.test(clean(t)));
    const info = project ? clean(project) : "";
    for (const assignment of assignments) {
      const {teacher, weeks} = assignment;
      const start = assignment.start ?? Number(row.beginSection);
      const end = assignment.end ?? Number(row.endSection);
      if (!teacher || ![start, end].every(Number.isInteger) || start < 1 || end < start || end > 14) {
        throw new Error("北航课程时间或节次异常，未导入不完整课表");
      }
      const key = JSON.stringify([group, name, day, start, end, classroom, teacher, info]);
      if (!merged.has(key)) merged.set(key, {
        name, classroom, class_number: group, teacher,
        test_time: "", test_location: "", link: null, weeks: [],
        week_time: day, start_time: start, time_count: end - start,
        course_id: ids.get(group), import_type: 1, info, data: null,
      });
      const course = merged.get(key);
      course.weeks = [...new Set([...course.weeks, ...weeks])].sort((a, b) => a - b);
    }
  }

  return encodeURIComponent(JSON.stringify({
    name: `${term[1]}-${term[2]}学年第${term[3]}学期`,
    courses: [...merged.values()],
    semester_start_monday: monday,
  }));
})();
