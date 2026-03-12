function scheduleHtmlParser() {
  // 清华研究生课表解析器
  // 参考 thu-info-lib 实现

  const CONFIG = {
    // 研究生课表 API 前缀
    YJS_API_PREFIX:
      "https://webvpn.tsinghua.edu.cn/http/77726476706e69737468656265737421eaff4b8b69336153301c9aa596522b20bc86e6e559a9b290/jxmh_out.do?m=yjs_jxrl_all&p_start_date=",
    // 学期开始日期
    DEFAULT_FIRST_DAY: "2026-02-23",
    // 学期周数
    WEEK_COUNT: 16,
    // 分组大小（每次3周）
    GROUP_SIZE: 3,
  };

  // 时间段映射（清华的节次时间）
  const TIME_SLOTS = [
    { begin: "08:00", end: "08:45" }, // 1
    { begin: "08:50", end: "09:35" }, // 2
    { begin: "09:50", end: "10:35" }, // 3
    { begin: "10:40", end: "11:25" }, // 4
    { begin: "11:30", end: "12:15" }, // 5
    { begin: "13:30", end: "14:15" }, // 6
    { begin: "14:20", end: "15:05" }, // 7
    { begin: "15:20", end: "16:05" }, // 8
    { begin: "16:10", end: "16:55" }, // 9
    { begin: "17:05", end: "17:50" }, // 10
    { begin: "17:55", end: "18:40" }, // 11
    { begin: "19:20", end: "20:05" }, // 12
    { begin: "20:10", end: "20:55" }, // 13
    { begin: "21:00", end: "21:45" }, // 14
  ];

  // 同步 HTTP GET 请求（自动携带当前页面 cookies）
  const httpGet = (url) => {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url, false);
    xhr.setRequestHeader("Accept", "application/json, text/javascript, */*");
    xhr.send();
    if (xhr.status !== 200) {
      throw new Error(`HTTP ${xhr.status}`);
    }
    return xhr.responseText;
  };

  // 格式化日期为 YYYYMMDD
  const formatDate = (date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}${month}${day}`;
  };

  // 从时间字符串获取节次（1-14）
  const getPeriodFromTime = (timeStr) => {
    if (!timeStr) return 0;
    const [hours, minutes] = timeStr.replace("：", ":").split(":").map(Number);
    const timeValue = hours * 60 + minutes;

    for (let i = 0; i < TIME_SLOTS.length; i++) {
      const [beginH, beginM] = TIME_SLOTS[i].begin.split(":").map(Number);
      const [endH, endM] = TIME_SLOTS[i].end.split(":").map(Number);
      const beginValue = beginH * 60 + beginM;
      const endValue = endH * 60 + endM + 5; // 5分钟缓冲

      if (timeValue >= beginValue && timeValue <= endValue) {
        return i + 1; // 节次从1开始
      }
    }
    return 0;
  };

  // 计算周次
  const getWeekFromDate = (dateStr, firstDayStr) => {
    const date = new Date(dateStr);
    const firstDay = new Date(firstDayStr);
    const diffTime = date.getTime() - firstDay.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    return Math.floor(diffDays / 7) + 1;
  };

  // 获取星期几（1-7，周一=1）
  const getDayOfWeek = (dateStr) => {
    const date = new Date(dateStr);
    const day = date.getDay();
    return day === 0 ? 7 : day;
  };

  // 解析 JSONP 响应
  const parseJSONP = (response) => {
    // 清华格式: m([...])
    const match = response.match(/m\s*\(\s*(\[.*?\])\s*\)/s);
    if (match && match[1]) {
      return JSON.parse(match[1]);
    }
    // 尝试直接解析 JSON
    if (response.trim().startsWith("[")) {
      return JSON.parse(response);
    }
    throw new Error("无法解析响应格式");
  };

  // 解析课程数据
  const parseSchedule = (jsonData, firstDay) => {
    const courseMap = new Map();

    jsonData.forEach((item) => {
      try {
        const name = item.nr; // 课程名称
        const location = item.dd || ""; // 地点
        const dateStr = item.nq; // 日期 YYYY-MM-DD
        const beginTime = item.kssj?.replace("：", ":"); // 开始时间
        const endTime = item.jssj?.replace("：", ":"); // 结束时间
        const category = item.fl || ""; // 分类

        if (!name || !dateStr || !beginTime || !endTime) {
          return;
        }

        const week = getWeekFromDate(dateStr, firstDay);
        const dayOfWeek = getDayOfWeek(dateStr);
        const startPeriod = getPeriodFromTime(beginTime);
        const endPeriod = getPeriodFromTime(endTime);

        if (startPeriod === 0 || endPeriod === 0) {
          return;
        }

        // 键包含课程名称、地点、星期和节次信息，确保同名同地点但不同时间的课程被分别录入
        const key = `${name}@${location}@周${dayOfWeek}@第${startPeriod}-${endPeriod}节`;

        if (!courseMap.has(key)) {
          courseMap.set(key, {
            name: name,
            classroom: location,
            class_number: "",
            teacher: "",
            test_time: null,
            test_location: null,
            link: null,
            weeks: [],
            week_time: dayOfWeek,
            start_time: startPeriod,
            time_count: endPeriod - startPeriod,
            import_type: 1,
            info: category,
            data: null,
          });
        }

        const course = courseMap.get(key);
        if (!course.weeks.includes(week)) {
          course.weeks.push(week);
        }
      } catch (e) {
        // 跳过解析失败的条目
      }
    });

    // 转换为数组并排序周次
    const courses = [];
    courseMap.forEach((course) => {
      course.weeks.sort((a, b) => a - b);
      courses.push(course);
    });

    return courses;
  };

  // 获取课表数据
  const fetchSchedule = () => {
    const firstDay = new Date(CONFIG.DEFAULT_FIRST_DAY);
    const allData = [];

    // 分批次获取（每次3周）
    const groupCount = Math.ceil(CONFIG.WEEK_COUNT / CONFIG.GROUP_SIZE);

    for (let i = 0; i < groupCount; i++) {
      try {
        const startWeek = i * CONFIG.GROUP_SIZE + 1;
        const endWeek = Math.min(
          (i + 1) * CONFIG.GROUP_SIZE,
          CONFIG.WEEK_COUNT,
        );

        const startDate = new Date(firstDay);
        startDate.setDate(startDate.getDate() + (startWeek - 1) * 7);

        const endDate = new Date(firstDay);
        endDate.setDate(endDate.getDate() + (endWeek - 1) * 7 + 6);

        const url = `${CONFIG.YJS_API_PREFIX}${formatDate(startDate)}&p_end_date=${formatDate(endDate)}&jsoncallback=m`;

        const response = httpGet(url);

        // 检查是否是HTML（未登录）
        if (response.trim().startsWith("<")) {
          throw new Error("返回HTML页面，可能未登录");
        }

        const data = parseJSONP(response);
        if (Array.isArray(data) && data.length > 0) {
          allData.push(...data);
        }
      } catch (e) {
        // 继续下一批
      }
    }

    return parseSchedule(allData, CONFIG.DEFAULT_FIRST_DAY);
  };

  // 获取当前学期名称（基于开学日期）
  const getSemesterName = (firstDayStr) => {
    const date = new Date(firstDayStr);
    const year = date.getFullYear();
    const month = date.getMonth() + 1; // 1-12
    // 2-7月为春季学期（属上一学年的第二学期），8-1月为秋季学期（属上一学年的第一学期）
    if (month >= 2 && month <= 7) {
      return `${year - 1}-${year}学年 春季学期`;
    } else {
      return `${year}-${year + 1}学年 秋季学期`;
    }
  };

  // 主流程
  try {
    const courses = fetchSchedule();
    const semesterName = getSemesterName(CONFIG.DEFAULT_FIRST_DAY);

    const result = {
      name: `清华大学研究生课表 ${semesterName}`,
      courses: courses,
    };

    // return result;
    return encodeURIComponent(JSON.stringify(result));
  } catch (error) {
    return encodeURIComponent(
      JSON.stringify({
        name: "清华大学研究生课表",
        courses: [],
        error: error.message,
      }),
    );
  }
}

scheduleHtmlParser();
