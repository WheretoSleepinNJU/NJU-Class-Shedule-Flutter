import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/adaptive_miuix_theme.dart';

void main() {
  testWidgets(
    'card renderer changes retain unsaved form and validation state',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveUIScope(
            controller: preference,
            debugMiuix: true,
            child: AdaptiveMiuixTheme(
              child: Scaffold(
                body: Form(
                  key: form,
                  child: AdaptiveCard(
                    child: AdaptiveTextFormField(
                      initialValue: 'initial',
                      validator: (_) => 'not saved',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'unsaved draft');
      form.currentState!.validate();
      await tester.pumpAndSettle();
      final state = tester.state<FormFieldState<String>>(
        find.byType(AdaptiveTextFormField),
      );
      for (final original in [true, false]) {
        await preference.setUseOriginalComponents(original);
        await tester.pumpAndSettle();
        expect(
          identical(tester.state(find.byType(AdaptiveTextFormField)), state),
          true,
        );
        expect(state.value, 'unsaved draft');
        expect(state.errorText, 'not saved');
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'unsaved draft',
        );
      }
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );
}
