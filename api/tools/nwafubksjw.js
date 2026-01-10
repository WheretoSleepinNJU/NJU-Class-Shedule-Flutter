(() => {
  const WEEK_MAP = { 一: 1, 二: 2, 三: 3, 四: 4, 五: 5, 六: 6, 日: 7 };
  
  const name = document.querySelector("#dqxnxq2").textContent.trim();
  const courses = [];
  const courseMap = new Map();
  
  document.querySelectorAll('.mtt_arrange_item').forEach((item) => {
    if (item.querySelector('.mtt_item_tkbz')) return;
    
    const parentCell = item.closest('td[data-week]');
    if (!parentCell) return;
    
    const weekDay = parseInt(parentCell.getAttribute('data-week'));
    const divs = item.querySelectorAll('div');
    if (divs.length < 3) return;
    
    // 课程名提取
    const courseName = divs[1].textContent
      .replace(/^《【本】/, '')
      .replace(/》\[.*\]$/, '')  // 去掉》[XX]
      .replace(/》$/, '')
      .replace(/^《/, '')
      .replace(/^【本】/, '')
      .trim();
    
    const infoText = divs[2].innerHTML;
    const parts = infoText.split('&nbsp;').filter(p => p && p.trim() && !p.startsWith('<'));
    
    let teacher = parts[0] ? parts[0].replace(/,$/, '').trim() : '';
    // 去掉重复的教师姓名
    if (teacher.includes(',')) {
      const teachers = teacher.split(',');
      teacher = [...new Set(teachers)].join(',');
    }
    
    let weekStr = parts[1] ? parts[1].trim() : '';
    let timeStr = parts[2] ? parts[2].trim() : '';
    let classroom = parts[3] ? parts[3].split('<')[0].trim() : '';
    
    let startTime = 0, endTime = 0;
    const timeMatch = timeStr.match(/第(\d+)节-第(\d+)节/);
    if (timeMatch) {
      startTime = parseInt(timeMatch[1]);
      endTime = parseInt(timeMatch[2]);
    }
    
    // 优化周数解析
    const weeks = [];
    if (weekStr) {
      weekStr.split(',').forEach(part => {
        part = part.trim();
        const isSingle = part.includes('(单)');
        const isDouble = part.includes('(双)');
        const cleanPart = part.replace(/周/g, '').replace(/\(单\)/g, '').replace(/\(双\)/g, '');
        
        if (cleanPart.includes('-')) {
          const [s, e] = cleanPart.split('-').map(Number);
          if (isSingle) {
            // 单周：从s开始，每隔一周取一次
            for (let i = s; i <= e; i++) {
              if (i % 2 === 1) weeks.push(i);
            }
          } else if (isDouble) {
            // 双周：从s开始，每隔一周取一次
            for (let i = s; i <= e; i++) {
              if (i % 2 === 0) weeks.push(i);
            }
          } else {
            for (let i = s; i <= e; i++) weeks.push(i);
          }
        } else if (cleanPart) {
          weeks.push(Number(cleanPart));
        }
      });
    }
    
    const jxbLink = item.querySelector('a[data-action="查看教学班说明"]');
    const classNumber = jxbLink ? jxbLink.getAttribute('data-jxbid') : '';
    
    if (courseName && weeks.length > 0) {
      const courseKey = `${courseName}_${teacher}_${weekDay}_${startTime}_${endTime}`;
      if (courseMap.has(courseKey)) {
        const existing = courseMap.get(courseKey);
        // 合并周次并去重排序
        existing.weeks = [...new Set([...existing.weeks, ...weeks])].sort((a, b) => a - b);
      } else {
        const courseData = {
          name: courseName,
          classroom: classroom || '未安排教室',
          class_number: classNumber,
          teacher: teacher,
          test_time: null,
          test_location: null,
          link: null,
          weeks: weeks.sort((a, b) => a - b),
          week_time: weekDay,
          start_time: startTime,
          time_count: endTime - startTime,
          import_type: 1,
          info: null,
          data: null
        };
        courses.push(courseData);
        courseMap.set(courseKey, courseData);
      }
    }
  });
  
  return encodeURIComponent(JSON.stringify({ 
    name, 
    courses,
    note: '西北农林科技大学课表数据',
    totalCourses: courses.length
  }));
})();
