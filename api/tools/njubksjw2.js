(() => {
  const WEEK_MAP = { 一: 1, 二: 2, 三: 3, 四: 4, 五: 5, 六: 6, 日: 7 };

  /* 1.  name 只拿学年学期文字 */
  const name = document.querySelector("#dqxnxqkclb").textContent.trim(); // “2025-2026学年 第1学期”

  /* 2. 逐行解析 */
  const courses = [];
  document
    .querySelector("table tbody")
    .querySelectorAll("tr")
    .forEach((tr) => {
      const td = tr.querySelectorAll("td");
      const classNumber = td[1].textContent.trim(); // 课程号
      const courseName = td[2].textContent.trim(); // 课程名
      const teacher = td[4].textContent.trim();
      const testTime = td[10].textContent.trim() || null;
      const info = td[8].textContent.trim() || null;
      const timeLocFull = td[6].textContent.trim();

      /* 周数解析 */
      function parseWeeks(weekStr) {
        const weeks = [];

        weekStr.split(",").forEach((part) => {
          // 检查是否为单双周
          const isSingle = part.includes("(单)");
          const isDouble = part.includes("(双)");
          const cleanPart = part
            .replace(/周/g, "")
            .replace(/\(单\)/g, "")
            .replace(/\(双\)/g, ""); // 去掉"周"字
          if (cleanPart.includes("-")) {
            const [start, end] = cleanPart.split("-").map(Number);
            if (isSingle) {
              // 单周：从start开始，取奇数周
              let current = start % 2 === 1 ? start : start + 1;
              for (let i = current; i <= end; i += 2) weeks.push(i);
            } else if (isDouble) {
              // 双周：从start开始，取偶数周
              let current = start % 2 === 0 ? start : start + 1;
              for (let i = current; i <= end; i += 2) weeks.push(i);
            } else {
              // 普通周：连续周
              for (let i = start; i <= end; i++) weeks.push(i);
            }
          } else {
            weeks.push(Number(cleanPart));
          }
        });
        return weeks;
      }

      /* 按逗号拆多段 */
      timeLocFull.split(/,周|，/).forEach((seg) => {
        /* 自由时间 */
        if (/自由时间/.test(seg)) {
          const weeks = parseWeeks(
            seg.match(/([\d\-,]+)周/)?.[1] || "1-18",
            seg,
          );
          courses.push({
            name: courseName,
            classroom: "自由地点",
            class_number: classNumber,
            teacher,
            test_time: testTime,
            test_location: null,
            link: null,
            weeks,
            week_time: 0,
            start_time: 0,
            time_count: 0,
            import_type: 1,
            info,
            data: null,
          });
          return;
        }

        /* 正常匹配 */
        // 周三 2-4节 14-18周 基础实验楼丙405
        // 周三 2-4节 1-3周,10-13周 仙Ⅱ-304
        // 周二 5-8节 2-18周(双) 仙1-216
        const m = seg.match(
          /([一二三四五六日])?\s*(\d+)-(\d+)节\s*([\d\-,周]+(?:\([单双]\))?)\s*(.+)/,
        );

        if (!m) return;
        const weekDay = WEEK_MAP[m[1]];
        const startTime = Number(m[2]);
        const endTime = Number(m[3]);
        const classroom = m[5];
        const weeks = parseWeeks(m[4]);

        courses.push({
          name: courseName,
          classroom,
          class_number: classNumber,
          teacher,
          test_time: testTime,
          test_location: null,
          link: null,
          weeks,
          week_time: weekDay,
          start_time: startTime,
          time_count: endTime - startTime, // 不+1
          import_type: 1,
          info,
          data: null,
        });
      });
    });

  // return { name, courses };
  return encodeURIComponent(JSON.stringify({ name, courses }));
})();
