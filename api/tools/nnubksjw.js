
(() => {
  "use strict";

  const clean = (value) =>
    String(value ?? "").replace(/\s+/g, " ").trim();

  // 1. 识别当前学期
  const pageText = clean(document.body?.innerText);

  const semesterMatch = pageText.match(
    /(\d{4})\s*[-－–—]\s*(\d{4})\s*学年\s*第\s*([12一二])\s*学期/
  );

  if (!semesterMatch) {
    throw new Error("无法识别学期，请等待课表加载完成");
  }

  const term =
    { 一: "1", 二: "2" }[semesterMatch[3]] ||
    semesterMatch[3];

  const semester =
    `${semesterMatch[1]}-${semesterMatch[2]}学年第${term}学期`;

  // 2. 解析上课周次
  function parseWeeks(detail) {
    const text = clean(detail)
      .replace(/，/g, ",")
      .replace(/[－–—～~]/g, "-");

    const match = text.match(
      /(\d+(?:\s*-\s*\d+)?(?:\s*[,、]\s*\d+(?:\s*-\s*\d+)?)*)\s*周(?:\s*[（(]([单双])[）)])?/
    );

    if (!match) return [];

    const weeks = new Set();
    const oddEven = match[2] || "";

    for (const part of match[1].split(/[,、]/)) {
      const range = part.trim().match(
        /^(\d+)(?:\s*-\s*(\d+))?$/
      );

      if (!range) continue;

      const start = Number(range[1]);
      const end = range[2]
        ? Number(range[2])
        : start;

      if (
        start < 1 ||
        end > 40 ||
        end < start
      ) {
        continue;
      }

      for (let week = start; week <= end; week++) {
        if (
          !oddEven ||
          (oddEven === "单" && week % 2 === 1) ||
          (oddEven === "双" && week % 2 === 0)
        ) {
          weeks.add(week);
        }
      }
    }

    return [...weeks].sort((a, b) => a - b);
  }

  // 3. 解析星期和节次
  function parseTime(detail, td) {
    const match = clean(detail).match(
      /星期\s*([1-7一二三四五六日天])\s*[,，]\s*(\d+)\s*[-－–—]\s*(\d+)\s*节/
    );

    const dayMap = {
      一: 1,
      二: 2,
      三: 3,
      四: 4,
      五: 5,
      六: 6,
      日: 7,
      天: 7
    };

    if (match) {
      return {
        day: dayMap[match[1]] || Number(match[1]),
        start: Number(match[2]),
        end: Number(match[3])
      };
    }

    return {
      day: Number(td.dataset.week),
      start: Number(td.dataset.beginUnit),
      end: Number(td.dataset.endUnit)
    };
  }

  // 4. 提取教室
  function parseClassroom(detail) {
    return clean(detail)
      .replace(
        /\d+(?:\s*[-－–—]\s*\d+)?(?:\s*[,，、]\s*\d+(?:\s*[-－–—]\s*\d+)?)*\s*周(?:\s*[（(][单双][）)])?/g,
        ""
      )
      .replace(
        /星期\s*[1-7一二三四五六日天]/g,
        ""
      )
      .replace(
        /\d+\s*[-－–—]\s*\d+\s*节/g,
        ""
      )
      .replace(
        /^[,，、\s]+|[,，、\s]+$/g,
        ""
      );
  }

  // 5. 读取课程单元格
  const cells = [
    ...document.querySelectorAll(
      'td[data-role="item"][data-week]'
    )
  ];

  if (!cells.length) {
    throw new Error(
      "未找到课程，请等待课表加载完成"
    );
  }

  const courses = [];
  const seen = new Set();
  const errors = [];

  // 6. 不同课程分配不同 course_id
  // 同名课程共享 ID，以保持颜色一致
  const courseIds = new Map();

  function getCourseId(name) {
    if (!courseIds.has(name)) {
      courseIds.set(name, courseIds.size);
    }
    return courseIds.get(name);
  }

  // 7. 遍历课程
  for (const td of cells) {
    const items =
      td.querySelectorAll(".mtt_arrange_item");

    for (const item of items) {
      const nameElement =
        item.querySelector(".mtt_item_kcmc");

      const teacherElement =
        item.querySelector(".mtt_item_jxbmc");

      const roomElement =
        item.querySelector(".mtt_item_room");

      // 只读取课程名称，避免混入教师信息
      const name = clean(
        [...(nameElement?.childNodes || [])]
          .filter(
            (node) =>
              node.nodeType === Node.TEXT_NODE
          )
          .map((node) => node.textContent)
          .join(" ")
      ) || clean(nameElement?.textContent);

      const teacher =
        clean(teacherElement?.textContent);

      const detail =
        clean(roomElement?.textContent);

      if (!name) continue;

      const weeks = parseWeeks(detail);
      const time = parseTime(detail, td);
      const classroom = parseClassroom(detail);

      // 校验课程数据
      if (
        !weeks.length ||
        !Number.isInteger(time.day) ||
        time.day < 1 ||
        time.day > 7 ||
        !Number.isInteger(time.start) ||
        !Number.isInteger(time.end) ||
        time.start < 1 ||
        time.end < time.start
      ) {
        errors.push(`${name}：${detail}`);
        continue;
      }

      // 8. 完全相同的上课安排去重
      const key = [
        name,
        teacher,
        classroom,
        time.day,
        time.start,
        time.end,
        weeks.join(",")
      ].join("|");

      if (seen.has(key)) continue;
      seen.add(key);

      // 9. 构造南哪课表课程数据
      courses.push({
        name,
        classroom,
        // 页面没有教学班编号，不用上课时段伪造编号。
        // App 优先按教学班编号分组；留空后才会使用共享 course_id。
        class_number: "",
        teacher,

        test_time: "",
        test_location: "",
        link: null,

        // 注意：必须是 weeks（复数）
        weeks: weeks,

        week_time: time.day,
        start_time: time.start,

        // 保持南哪课表原有的节次差值约定
        time_count: time.end - time.start,

        // 新增：让 App 自动分配课程颜色
        course_id: getCourseId(name),

        import_type: 1,
        info: "",
        data: null
      });
    }
  }

  // 10. 校验最终结果
  if (!courses.length) {
    throw new Error(
      "没有解析出有效课程。\n" +
      errors.slice(0, 5).join("\n")
    );
  }

  if (errors.length) {
    throw new Error(
      `成功解析 ${courses.length} 条，` +
      `但有 ${errors.length} 条无法识别：\n` +
      errors.slice(0, 5).join("\n")
    );
  }

  // 11. 返回导入数据
  return encodeURIComponent(
    JSON.stringify({
      name: semester,
      courses
    })
  );
})();
