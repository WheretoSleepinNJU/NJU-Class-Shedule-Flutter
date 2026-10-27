# Local Android toolbar extension

Source: adaptive_platform_ui 1.0.2, https://pub.dev/packages/adaptive_platform_ui. License retained. UPSTREAM_SHA256.json records original upstream inputs.

Opt-in API: AdaptiveApp.androidToolbarBackend (also router constructor) supplies AndroidToolbarBackend(builder, height, supports). AdaptiveToolbarHost installs this backend alongside the existing registry. The framework has no dependency on Deadliner, Compose or the app MethodChannel protocol.

AdaptiveScaffold publishes androidNativeToolbar and the actual per-page scrollOffset in ToolbarEntry, suppresses a supported Material AppBar, and provides measured status/content insets through AndroidToolbarBodyScope. Default bodies are padded safely; extendBodyBehindAppBar clients put the supplied inset inside scroll content. Native pages publish transparent system bars and theme-aware icon brightness when there is no Flutter AppBar.

No backend, unsupported app bars, drawers, non-page scaffolds or useNativeToolbar=false retain the Material path. The app defines support policy and owns the native bridge. The iOS host/rendering path and native iOS files are preserved. Existing hosted iOS toolbar and registry tests pass with the optional extension absent. debugAndroidToolbar is a test-only host switch because PlatformInfo uses dart:io rather than Flutter platform overrides.

AdaptiveScaffold.fallbackBuilder keeps custom/original Material page rendering in the same toolbar registry. Body wrappers remain stable across backend changes so form and scroll state survive the preference toggle. The application-facing AdaptiveUI facade owns all backend selection and exposes AdaptiveTopAppBar to pages. Upstream tests, screenshots and exploration documentation are omitted from this vendored runtime package.

Vendored Swift sources only receive trailing-whitespace cleanup; native iOS behavior is otherwise unchanged.
