# School Adapter Scripts

This folder contains provider/parser/timer script templates for school adapters.

## Design

- `provider.js`: run inside logged-in WebView, return raw string.
- `parser.js`: pure function, consume provider string, return normalized data.
- `timer.js`: optional, return timetable timing config.

## Parser output formats

Supported parser return values:

1. `Array<Course>` (recommended for new adapters)
2. `{ name: string, courses: Array<Course> }`

Where `Course` can be either:

- unified format: `{ name, day, sections, weeks, position, teacher }`
- legacy format: `{ name, week_time, start_time, time_count, weeks, classroom, ... }`

## Timer output formats

Supported timer return fields:

- `class_time_list`: `[{"start":"08:00","end":"08:45"}, ...]`
- `semester_start_monday`: `"2026-03-02"`

Also accepts:

- `sectionTimes`: `[{ section:1, startTime:"08:00", endTime:"08:45" }, ...]`
- `semesterStart`: `"2026-03-02"`

## Config example

```json
{
  "provider": {
    "type": "remote",
    "url": "https://cdn.example.com/adapters/foo/provider.js",
    "sha256Hash": "put_sha256_here"
  },
  "parser": {
    "type": "asset",
    "path": "assets/adapters/foo/parser.js"
  },
  "timer": {
    "type": "inline",
    "code": "function scheduleTimer(){return {\"semester_start_monday\":\"2026-03-02\"};}"
  }
}
```
