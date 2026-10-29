/// Application-facing UI contracts. Pages describe content; this layer owns
/// platform selection, native capabilities and the original-component fallback.
library;

export 'src/adaptive_app.dart';
export 'src/adaptive_scaffold.dart';
export 'src/adaptive_ui_controller.dart';
export 'src/adaptive_dialog.dart';
export 'src/adaptive_content.dart';
export 'src/native_top_bar_configuration.dart'
    show AdaptiveNativeTitle, NativeTitleContent;

export 'src/adaptive_button.dart';
export 'src/adaptive_controls.dart';

export 'src/adaptive_selection.dart';

export 'src/adaptive_text_form_field.dart';

export 'src/theme/deadliner_color_theme.dart';

export 'src/adaptive_layout.dart';
export 'src/adaptive_typography.dart';

export 'src/adaptive_navigation.dart';

export 'src/adaptive_tabs.dart' show AdaptiveTabRow;
