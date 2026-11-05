(() => {
  "use strict";

  function importSchedule() {
    const { hostname, pathname } = window.location;
    const base = "/yjsxkapp/sys/xsxkappfudan/";
    if (hostname !== "yjsxk.fudan.edu.cn" || !pathname.startsWith(base)) {
      throw new Error("请登录复旦研究生选课系统并打开已选课程");
    }

    const xhr = new XMLHttpRequest();
    xhr.open("GET", base + "xsxkCourse/loadStdCourseInfo.do?_=" + Date.now(), false);
    xhr.setRequestHeader("Accept", "application/json, text/javascript, */*");
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    xhr.send();
    if (xhr.status !== 200) throw new Error("读取已选课程失败，请检查登录状态");

    const { results } = JSON.parse(xhr.responseText);
    const semester = results?.[0]?.XNXQMC?.trim();
    if (!Array.isArray(results) || !semester) {
      throw new Error("未读取到已选课程，请核对选课轮次");
    }

    const weekdays = "一二三四五六日";
    const range = "(\\d+)(?:\\s*[~～－–—-]\\s*(\\d+))?";
    const meeting = new RegExp(
      `^([0-9~～－–—,，、\\s-]+)周\\s*(?:[（(]([单双])周?[）)])?\\s*星期([一二三四五六日天])\\s*${range}\\s*节\\s*(.*)$`
    );
    const weekRange = new RegExp(`^${range}$`);
    const courses = results.flatMap((row, courseId) => {
      const name = row.KCMC?.trim();
      if (!name || row.XNXQMC?.trim() !== semester) {
        throw new Error("已选课程缺少名称或包含多个学期");
      }
      const detail = row.PKSJDD?.trim() || row.PKSJDDMS?.trim() || "";
      const parts = detail.split(/<br\s*\/?\s*>|[;；\r\n]+/i).map(s => s.trim()).filter(Boolean);
      const course = {
        name,
        class_number: row.BJDM || "",
        teacher: row.RKJS || "",
        test_time: row.XKSJ_VIEW || "",
        import_type: 1,
        course_id: courseId,
      };
      if (!parts.length) {
        return [{ ...course, classroom: "", weeks: [], week_time: 0, start_time: 0, time_count: 0 }];
      }
      return parts.map(part => {
        const match = meeting.exec(part);
        if (!match) throw new Error("已选课程含有无法识别的上课安排");
        const [, weekText, parity, day, first, last = first, classroom] = match;
        const start = Number(first);
        const end = Number(last);
        if (start < 1 || end < start || end > 13) throw new Error("上课节次超出复旦作息范围");

        const weeks = new Set();
        for (const span of weekText.split(/[,，、]/)) {
          const parsed = weekRange.exec(span.trim());
          if (!parsed) throw new Error("上课周次格式异常");
          const from = Number(parsed[1]);
          const to = Number(parsed[2] || parsed[1]);
          if (from < 1 || to < from || to > 40) throw new Error("上课周次超出范围");
          for (let week = from; week <= to; week++) {
            if (!parity || week % 2 === (parity === "单" ? 1 : 0)) weeks.add(week);
          }
        }
        if (!weeks.size) throw new Error("上课周次为空");
        return {
          ...course, classroom,
          weeks: [...weeks].sort((a, b) => a - b),
          week_time: day === "天" ? 7 : weekdays.indexOf(day) + 1,
          start_time: start,
          time_count: end - start,
        };
      });
    });
    return encodeURIComponent(JSON.stringify({ name: `复旦大学研究生课表 ${semester}`, courses }));
  }

  try {
    return importSchedule();
  } catch (_) {
    // The app includes the current page in its legacy failure diagnostics.
    document.documentElement.textContent = "导入失败，请重新打开导入入口并登录后重试。";
    window.history.replaceState(null, "", "/nju-schedule-import");
    throw new Error("无法导入复旦研究生已选课程");
  }
})();
