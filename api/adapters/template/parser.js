function scheduleHtmlParser(providerResult) {
  // Parse providerResult into one of:
  // 1) [{ name, day, sections, weeks, position, teacher }]
  // 2) { name: '2025-2026-1', courses: [...] }
  const data = JSON.parse(providerResult);
  const courses = [];

  for (const row of data) {
    courses.push({
      name: row.name || 'Unknown',
      day: Number(row.day || 1),
      sections: Array.isArray(row.sections) ? row.sections : [1],
      weeks: Array.isArray(row.weeks) ? row.weeks : [1],
      position: row.position || '',
      teacher: row.teacher || '',
    });
  }

  return {
    name: data.termName || '',
    courses,
  };
}
