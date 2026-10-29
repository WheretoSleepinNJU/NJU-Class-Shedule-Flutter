import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_title_bar.dart';

void main() {
  testWidgets('page viewport extends under chrome with one scrollable inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => platform.AdaptiveToolbarHost(
          nativeBackend: createComposeTitleBarBackend(),
          child: child!,
        ),
        home: AdaptiveScaffold(
          appBar: const AdaptiveTopAppBar(title: Text('Scroll page')),
          body: SafeArea(
            child: AdaptiveListView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 20),
              children: [
                const SizedBox(
                  key: ValueKey('first-row'),
                  height: 60,
                  child: Text('First'),
                ),
                const AdaptiveScrollView(child: Text('nested')),
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 60, child: Text('Row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final viewport = find.byType(ListView);
    expect(tester.getTopLeft(viewport).dy, 0);
    expect(
      tester.getBottomLeft(viewport).dy,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
      reason: 'The viewport extends under the system navigation area.',
    );
    expect(
      tester.widget<ListView>(viewport).padding,
      const EdgeInsets.fromLTRB(16, 88, 16, 40),
      reason:
          'System navigation clearance belongs to scroll content exactly once.',
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('first-row'))).dy,
      24 + 52 + 12,
    );
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .padding,
      isNull,
    );
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    state.position.jumpTo(100);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('first-row'))).dy, -12);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fixed native view starts below chrome without a second inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => platform.AdaptiveToolbarHost(
          nativeBackend: createComposeTitleBarBackend(),
          child: child!,
        ),
        home: const AdaptiveScaffold(
          scrollUnderAppBar: false,
          appBar: AdaptiveTopAppBar(title: Text('Embedded view')),
          body: SafeArea(child: SizedBox.expand(key: ValueKey('embedded'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('embedded'))).dy, 76);
    expect(
      AdaptiveContentInsets.topOf(
        tester.element(find.byKey(const ValueKey('embedded'))),
      ),
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
