# Maintained dependency patches

Dependencies are restored outside the tracked source tree by `tool/ci/bootstrap.sh`, following the project's existing `external` checkout workflow. Android, iOS, HarmonyOS and host tests all use OHOS Flutter `3.47.7+ohos-0.0.1-pre`.

| Dependency | Pinned upstream | Local patch |
| --- | --- | --- |
| adaptive_platform_ui 1.0.2 | [04f81286f7a1b8fbb67c489aa8d0cd663b5cd3ed](https://github.com/berkaycatak/adaptive_platform_ui/commit/04f81286f7a1b8fbb67c489aa8d0cd663b5cd3ed) | Optional native toolbar backend, structured UIKit titles/actions and integrated category headers, native navigation sizing/tints, input contracts and bounded integration diagnostics |
| umeng_common_sdk 1.3.0 | [Pub release archive](https://pub.dev/packages/umeng_common_sdk/versions/1.3.0), SHA-256 `8374ced1ab1d89f596ff71c0eff044d5395337145c9a69a6be02f5d8a678e42c` | Replace Gradle 9's removed `jcenter()` shorthand with `mavenCentral()` |

The initializer checks upstream revisions/archive hashes, applies patches idempotently, and refuses incompatible local modifications. It never patches the global Pub cache. Licenses remain in the upstream checkouts and release archives. Mobile scanner, Fluttertoast and package info use their existing pinned Git/external sources without local source copies.

Application pages depend on `lib/AdaptiveUI` only. It owns component selection, typography, colors, content insets and the original-component preference. The upstream extension exposes `NativeToolbarBackend`, `NativeToolbarScope` and `NativeToolbarBodyScope`; it has no dependency on this app or Compose. The registered backend owns native transport and rendering, while the shared toolbar registry owns routes, actions and visibility. UIKit continues through the upstream host; Android registers the Compose backend.

The same platform-neutral backend boundary is the extension point for a future ArkUI toolbar. Bottom navigation similarly stays behind `AdaptiveNavigationShell` and its shared destinations/selection contract. ArkUI rendering belongs in the facade's OHOS adapter, with page trees unchanged.

When updating a patch, preserve local checkout changes and regenerate the diff against the pinned upstream revision. The cache key includes these patches. Device acceptance covers native pointer routing, popup visibility, retained form state, renderer changes and lifecycle recovery.
