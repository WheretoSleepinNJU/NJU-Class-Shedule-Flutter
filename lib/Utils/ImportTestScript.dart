import 'dart:convert';

/// A script's completion value is preserved by try/catch. No eval or Function
/// is used, so portal CSP does not need to permit dynamic compilation.
String guardImportTestExtraction(String script) => '''
try {
$script
} catch (__njuScheduleExtractError) {
  JSON.stringify({
    "__nju_schedule_extract_error__": true,
    "name": String(__njuScheduleExtractError && __njuScheduleExtractError.name || "Error"),
    "message": String(__njuScheduleExtractError && __njuScheduleExtractError.message || __njuScheduleExtractError)
  });
}
''';

/// Android and Harmony return the string "null" for failed/void evaluation.
/// Inspect diagnostics before the timetable decoder can mistake it for data.
void validateImportTestExtraction(
  Object result, {
  required String emptyResultMessage,
}) {
  dynamic value = result;
  for (var i = 0; i < 4 && value is String; i++) {
    try {
      value = jsonDecode(value.trim());
    } on FormatException {
      break;
    }
  }
  if (value is Map && value['__nju_schedule_extract_error__'] == true) {
    throw FormatException('extractJS: ${value["name"]}: ${value["message"]}');
  }
  if (value == null ||
      value is String &&
          (value.trim().isEmpty || value.trim() == 'undefined')) {
    throw FormatException(emptyResultMessage);
  }
}
