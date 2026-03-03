function scheduleHtmlParser(providerResult) {
  const WEEK_WITH_BIAS = ['', '一', '二', '三', '四', '五', '六', '日'];
  const data = JSON.parse((providerResult || '').replace(/\n/g, ''));
  const rows = Array.isArray(data.results) ? data.results : [];
  const termName = rows.length > 0 ? (rows[rows.length - 1].XNXQMC || '') : '';
  const courses = [];

  for (const row of rows) {
    if ((row.XNXQMC || '') !== termName) continue;
    const infoText = row.PKSJDD || '';
    const infoList = infoText ? infoText.split(';') : [''];
    for (const item of infoList) {
      const parsed = parseScheduleItem(item);
      courses.push({
        name: row.KCMC || '',
        day: parsed.day,
        sections: parsed.sections,
        weeks: parsed.weeks,
        position: parsed.position,
        teacher: row.RKJS || '',
        class_number: row.KCDM || '',
        test_time: '',
        test_location: '',
        info: row.XKBZ || '',
        import_type: 1,
      });
    }
  }

  return {
    name: termName,
    courses,
  };

  function parseScheduleItem(item) {
    const pattern = /(\d{1,2})(-(\d{1,2}))?(单|双)?周 星期(.)\[(\d{1,2})(-(\d{1,2}))?节](.*)/i;
    const matched = pattern.exec(item || '');
    if (!matched) {
      return {
        day: 0,
        sections: [],
        weeks: [],
        position: '',
      };
    }
    const dayChar = matched[5] || '';
    let day = 0;
    for (let i = 0; i < WEEK_WITH_BIAS.length; i++) {
      if (WEEK_WITH_BIAS[i] === dayChar) {
        day = i;
        break;
      }
    }
    const weekStart = toInt(matched[1], 1);
    const weekEnd = matched[3] ? toInt(matched[3], weekStart) : weekStart;
    const weekMode = matched[4] || '';
    const startSec = toInt(matched[6], 1);
    const endSec = matched[8] ? toInt(matched[8], startSec) : startSec;
    const weeks = [];
    for (let w = weekStart; w <= weekEnd; w++) {
      if (weekMode === '单' && w % 2 === 0) continue;
      if (weekMode === '双' && w % 2 === 1) continue;
      weeks.push(w);
    }
    const sections = [];
    for (let s = startSec; s <= endSec; s++) {
      sections.push(s);
    }
    return {
      day,
      sections,
      weeks,
      position: (matched[9] || '').trim(),
    };
  }

  function toInt(raw, fallback) {
    const n = parseInt(raw, 10);
    return Number.isNaN(n) ? fallback : n;
  }
}
