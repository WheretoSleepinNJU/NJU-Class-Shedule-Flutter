package com.lilystudio.wheretosleepinnju.compose

import android.app.Activity
import android.content.Context
import android.view.MotionEvent
import android.graphics.Typeface
import android.graphics.RectF
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import top.yukonga.miuix.kmp.icon.MiuixIcons
import top.yukonga.miuix.kmp.icon.extended.Months
import top.yukonga.miuix.kmp.icon.extended.NotesFill
import top.yukonga.miuix.kmp.icon.extended.ContactsCircle
import com.lilystudio.wheretosleepinnju.deadliner.ui.navigation.ImmersiveTextTabRow
import com.lilystudio.wheretosleepinnju.deadliner.ui.navigation.MiuixFloatingTabBar
import com.lilystudio.wheretosleepinnju.deadliner.ui.navigation.MiuixFloatingTabItem
import com.lilystudio.wheretosleepinnju.deadliner.ui.navigation.MiuixFloatingTabLayout
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.res.painterResource
import com.lilystudio.wheretosleepinnju.R
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.*
import androidx.lifecycle.*
import androidx.savedstate.*
import io.flutter.embedding.android.FlutterImageView
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.lilystudio.wheretosleepinnju.deadliner.ui.material.glass.*
import com.lilystudio.wheretosleepinnju.deadliner.ui.theme.*
import com.lilystudio.wheretosleepinnju.deadliner.model.AdvancedMaterialTuning
import com.lilystudio.wheretosleepinnju.deadliner.model.AdvancedMaterialFineTuning
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopAppBar
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopAppBarStyle
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopBarIconButton
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.resolveTopBarScrollProgress
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopBarMaterialRevealStartDistance
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopBarMaterialRevealEndDistance
import top.yukonga.miuix.kmp.blur.*
import top.yukonga.miuix.kmp.theme.MiuixTheme

/** AdaptiveUI owns one Flutter GPU layer and its native chrome; no screenshot transport. */
class AdaptiveChromeHost(private val activity: Activity, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "nju/compose-titlebar")
    private var title by mutableStateOf(TitleState())
    private var navigation by mutableStateOf(NavigationState())
    private var tabs by mutableStateOf(NavigationState())
    private val tabsChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "nju/compose-tabs")
    private var tabsInputReady = false
    private var tabActions = 0L
    private val navigationChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "nju/compose-navigation")
    private var navigationActions = 0L
    private var lastNavigationIndex = -1
    private var navigationInputReady = false
    private var inputEpoch by mutableLongStateOf(0L)
    private var recordScheduled = false
    private var hostResumed by mutableStateOf(false)
    private var windowFocused by mutableStateOf(true)
    private var flutterView: FlutterView? = null
    private var view: ComposeView? = null
    private var treeOwner: ActivityChromeViewTreeOwner? = null
    private var contentRoot: ActivityChromeLayout? = null
    private var touchDowns = 0L
    private var touchUps = 0L
    private var actionCount = 0L
    private var dispatchedActions = 0L
    private var lastPointerEvent: MotionEvent? = null
    private var lastDeviceEvent: MotionEvent? = null
    private var lastMetrics: Pair<Long, Float>? = null
    private var sourceRecordCount = 0L
    private val sourceVersion = mutableLongStateOf(0L)
    private val dialogBackdrop = GlassBackdropState()
    private val iconFont by lazy {
        FontFamily(Typeface.createFromAsset(activity.assets, "flutter_assets/fonts/MaterialIcons-Regular.otf"))
    }
    init {
        engine.platformViewsController.registry.registerViewFactory(
            "nju/deadliner-glass-surface", ComposeGlassSurfaceFactory(engine.dartExecutor.binaryMessenger, dialogBackdrop))
        navigationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val next = NavigationState.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    if (next.owner != navigation.owner || next.visible != navigation.visible ||
                        next.left != navigation.left || next.top != navigation.top ||
                        next.width != navigation.width || next.height != navigation.height) navigationInputReady = false
                    navigation = next
                    result.success(null)
                }
                "hide" -> {
                    val owner = ((call.arguments as? Map<*, *>)?.get("owner") as? Number)?.toLong()
                    if (owner == navigation.owner) navigation = navigation.copy(visible = false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        tabsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val next = NavigationState.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    if (next.owner != tabs.owner || next.visible != tabs.visible ||
                        next.left != tabs.left || next.top != tabs.top ||
                        next.width != tabs.width || next.height != tabs.height) tabsInputReady = false
                    tabs = next
                    result.success(null)
                }
                "hide" -> {
                    val owner = ((call.arguments as? Map<*, *>)?.get("owner") as? Number)?.toLong()
                    if (owner == tabs.owner) tabs = tabs.copy(visible = false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> { title = TitleState.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()); result.success(null) }
                "scroll" -> {
                    val args = call.arguments as? Map<*, *>
                    val owner = (args?.get("owner") as? Number)?.toLong()
                    val offset = (args?.get("scrollOffset") as? Number)?.toFloat()
                    if (owner == title.owner && offset != null && offset.isFinite()) title = title.copy(scrollOffset = offset)
                    result.success(null)
                }
                "hide" -> { title = title.copy(visible = false); result.success(null) }
                "diagnostics" -> result.success(mapOf("colorSchemes" to title.theme.palette.diagnostics(title.theme.dark), "transport" to "gpu-layer", "pixelCopyCount" to 0,
                    "gpuDrawCount" to sourceRecordCount,
                    "dialogSurfaces" to dialogBackdrop.consumers,
                    "glassTopBars" to dialogBackdrop.topBars,
                    "glassTopBarOffset" to dialogBackdrop.topBarOffset,
                    "glassTopBarProgress" to resolveTopBarScrollProgress(dialogBackdrop.topBarOffset,
                        TopBarMaterialRevealStartDistance.value, TopBarMaterialRevealEndDistance.value), "glassIconButtons" to dialogBackdrop.iconButtons, "glassNavigationBars" to if (navigation.visible) 1 else 0,
                    "tabsVisible" to (tabs.visible || (title.visible && title.interactive && title.tabLabels.isNotEmpty())),
                    "tabsSelectedIndex" to if (title.visible && title.tabLabels.isNotEmpty()) title.selectedTabIndex else tabs.selectedIndex,
                    "tabsActions" to tabActions, "tabsInputReady" to (tabsInputReady || (title.visible && title.interactive && title.tabLabels.isNotEmpty() && hostResumed && windowFocused)),
                    "headerTabLabels" to title.tabLabels,
                    "tabsBounds" to listOf(tabs.left, tabs.top, tabs.width, tabs.height),
                    "chromeInputAllowed" to (hostResumed && windowFocused), "toolbarHitHeight" to contentRoot?.toolbarHeight,
                    "navigationDark" to navigation.theme.dark, "navigationOnSurface" to navigation.theme.onSurface,
                    "navigationRenderer" to "activity-compose", "navigationInputReady" to navigationInputReady, "navigationLayout" to "stacked",
                    "navigationItems" to navigation.items.map { it.icon }, "navigationSelectedIndex" to navigation.selectedIndex,
                    "navigationActions" to navigationActions, "navigationLastIndex" to lastNavigationIndex, "navigationOwner" to navigation.owner, "navigationInputEpoch" to inputEpoch,
                    "navigationBounds" to listOf(navigation.left, navigation.top, navigation.width, navigation.height), "dialogBackdropReady" to dialogBackdrop.ready,
                    "dialogBackgroundDraws" to dialogBackdrop.recordCount,
                    "dialogTransport" to "hardware-buffer-background", "toolbarVisible" to title.visible,
                    "touchDowns" to touchDowns, "touchUps" to touchUps, "nativeActions" to actionCount, "dispatchedActions" to dispatchedActions, "visible" to title.visible, "resumed" to hostResumed, "windowFocus" to activity.hasWindowFocus(), "owner" to title.owner,
                    "title" to title.title, "scrollOffset" to title.scrollOffset,
                    "titleTappable" to title.titleTappable,
                    "actions" to title.actions.map { mapOf("index" to it.index, "label" to it.label,
                        "text" to it.text, "enabled" to it.enabled, "loading" to it.loading) },
                    "progress" to title.progress, "canBack" to title.canBack, "interactive" to title.interactive))
                else -> result.notImplemented()
            }
        }
    }
    fun isSupported(): Boolean = flutterView != null
    fun enableSharedGpuRoot() {
        val flutter = findFlutterView(activity.window.decorView) ?: return
        if (!hasTextureView(flutter)) return
        flutterView = flutter
        val parent = flutter.parent as? ViewGroup ?: return
        val index = parent.indexOfChild(flutter)
        val originalParams = flutter.layoutParams
        val root = ActivityChromeLayout(activity, flutter,
            hasToolbar = { title.visible },
            navigationBounds = {
                if (navigation.visible && navigationInputReady) {
                    val d = activity.resources.displayMetrics.density
                    RectF(navigation.left * d + flutter.left, navigation.top * d + flutter.top,
                        (navigation.left + navigation.width) * d + flutter.left,
                        (navigation.top + navigation.height) * d + flutter.top)
                } else null
            },
            tabsBounds = {
                if (tabs.visible && tabsInputReady) {
                    val d = activity.resources.displayMetrics.density
                    RectF(tabs.left * d + flutter.left, tabs.top * d + flutter.top,
                        (tabs.left + tabs.width) * d + flutter.left, (tabs.top + tabs.height) * d + flutter.top)
                } else null
            },
            sourceChanged = {
                if (hostResumed && windowFocused && !recordScheduled) {
                    recordScheduled = true
                    flutter.postOnAnimation {
                        recordScheduled = false
                        if (hostResumed && windowFocused) sourceVersion.longValue++
                    }
                }
            })
        contentRoot = root
        val owner = ActivityChromeViewTreeOwner(activity as LifecycleOwner)
        treeOwner = owner
        root.setViewTreeLifecycleOwner(owner)
        root.setViewTreeViewModelStoreOwner(owner)
        root.setViewTreeSavedStateRegistryOwner(owner)
        val compose = ComposeView(activity).apply {
            consumeWindowInsets = false
            setViewTreeLifecycleOwner(owner)
            setViewTreeViewModelStoreOwner(owner)
            setViewTreeSavedStateRegistryOwner(owner)
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
            setContent {
                val frame = title
                ChromeContent(flutter, frame, navigation, tabs, inputEpoch, hostResumed && windowFocused, iconFont, dialogBackdrop, sourceVersion,
                    onRecord = { sourceRecordCount++ },
                    onHeaderTabSelected = { index ->
                        if (hostResumed && windowFocused && frame.visible && frame.interactive && index in frame.tabLabels.indices) {
                            tabActions++
                            channel.invokeMethod("tab", mapOf("owner" to frame.owner, "index" to index))
                        }
                    },
                    onNavigationReady = { owner, ready ->
                        if (owner == navigation.owner) navigationInputReady = ready
                    },
                    onNavigation = { index ->
                        if (hostResumed && windowFocused && navigation.visible) {
                            navigationActions++
                            lastNavigationIndex = index
                            navigationChannel.invokeMethod("select", mapOf("owner" to navigation.owner, "index" to index))
                        }
                    },
                    onTabsReady = { owner, ready -> if (owner == tabs.owner) tabsInputReady = ready },
                    onTabSelected = { index ->
                        if (hostResumed && windowFocused && tabs.visible) {
                            tabActions++
                            tabsChannel.invokeMethod("select", mapOf("owner" to tabs.owner, "index" to index))
                        }
                    },
                    onHeight = {
                        root.toolbarHeight = it * activity.resources.displayMetrics.density +
                            androidx.core.view.ViewCompat.getRootWindowInsets(root)?.getInsets(androidx.core.view.WindowInsetsCompat.Type.statusBars())?.top.let { inset -> inset ?: 0 }
                        val metrics = frame.owner to it
                        if (lastMetrics != metrics) {
                            lastMetrics = metrics
                            channel.invokeMethod("metrics", mapOf("height" to it, "owner" to frame.owner))
                        }
                    },
                    onBack = { if (hostResumed && windowFocused) channel.invokeMethod("back", mapOf("owner" to frame.owner)) },
                    onTitle = { if (hostResumed && windowFocused) channel.invokeMethod("title", mapOf("owner" to frame.owner)) },
                    onAction = { actionCount++; if (hostResumed && windowFocused) { dispatchedActions++; channel.invokeMethod("action", mapOf("index" to it, "owner" to frame.owner)) } })
            }
        }
        parent.removeView(flutter)
        root.addView(flutter, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        root.addView(compose, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.TOP))
        parent.addView(root, index, originalParams)
        view = compose
    }
    private fun findFlutterView(node: View): FlutterView? {
        if (node is FlutterView) return node
        if (node is ViewGroup) for (i in 0 until node.childCount) findFlutterView(node.getChildAt(i))?.let { return it }
        return null
    }
    private fun hasTextureView(node: View): Boolean = node is FlutterTextureView ||
        (node is ViewGroup && (0 until node.childCount).any { hasTextureView(node.getChildAt(it)) })
    fun onWindowTouch(event: MotionEvent) {
        if (event.actionMasked == MotionEvent.ACTION_DOWN) touchDowns++
        if (event.actionMasked == MotionEvent.ACTION_UP) touchUps++
        lastDeviceEvent?.recycle()
        lastDeviceEvent = MotionEvent.obtainNoHistory(event)
        lastPointerEvent?.recycle()
        lastPointerEvent = when (event.actionMasked) {
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> null
            else -> MotionEvent.obtainNoHistory(event)
        }
    }
    private fun cancelPointerInput() {
        val event = lastPointerEvent ?: return
        lastPointerEvent = null
        // Preserve device, source, tool type and pointer ids. A synthetic event
        // with SOURCE_UNKNOWN creates a device switch inside Compose's processor.
        event.action = MotionEvent.ACTION_CANCEL
        activity.window.decorView.dispatchTouchEvent(event)
        view?.cancelPendingInputEvents()
        event.recycle()
    }
    private fun resetNativePointerSession() {
        val source = lastDeviceEvent ?: return
        val cancel = MotionEvent.obtainNoHistory(source)
        cancel.action = MotionEvent.ACTION_CANCEL
        // ComposeView's ViewGroup may already have dropped its Android touch
        // target after focus loss. Deliver cancel to its content view as well,
        // so Compose's pointer adapter and hit-path tracker both end the stream.
        view?.getChildAt(0)?.dispatchTouchEvent(cancel)
        view?.cancelPendingInputEvents()
        cancel.recycle()
    }
    fun setResumed(value: Boolean) {
        if (!value) cancelPointerInput()
        resetNativePointerSession()
        if (value && !hostResumed) { navigationInputReady = false; inputEpoch++ }
        hostResumed = value
        if (value) refreshWindow()
    }
    fun onWindowFocusChanged(focused: Boolean) {
        resetNativePointerSession()
        if (focused && !windowFocused) { navigationInputReady = false; inputEpoch++ }
        windowFocused = focused
        if (!focused) cancelPointerInput() else refreshWindow()
    }
    private fun refreshWindow() {
        view?.requestApplyInsets()
        view?.invalidate()
        flutterView?.invalidate()
        dialogBackdrop.ready = false
    }
    fun dispose() {
        lastPointerEvent?.recycle(); lastPointerEvent = null
        lastDeviceEvent?.recycle(); lastDeviceEvent = null
        channel.setMethodCallHandler(null)
        navigationChannel.setMethodCallHandler(null)
        tabsChannel.setMethodCallHandler(null)
        view?.let { it.disposeComposition(); (it.parent as? ViewGroup)?.removeView(it) }
        view = null
        val root = contentRoot
        val flutter = flutterView
        val parent = root?.parent as? ViewGroup
        if (root != null && flutter != null && parent != null) {
            val index = parent.indexOfChild(root)
            val params = root.layoutParams
            root.removeView(flutter)
            parent.removeView(root)
            parent.addView(flutter, index, params)
        }
        contentRoot = null; flutterView = null; treeOwner?.dispose(); treeOwner = null
    }
}

/** One Activity-owned scaffold: direct Flutter input and native chrome siblings.
 * Flutter is never inside Compose AndroidView's pointer/IME interop pipeline. */
private class ActivityChromeLayout(
    context: Context,
    private val flutter: FlutterView,
    private val hasToolbar: () -> Boolean,
    private val navigationBounds: () -> RectF?,
    private val tabsBounds: () -> RectF?,
    private val sourceChanged: () -> Unit,
) : FrameLayout(context) {
    var toolbarHeight = 0f
    private var gestureTarget: View? = null
    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.actionMasked == MotionEvent.ACTION_DOWN) {
            gestureTarget = if ((hasToolbar() && event.y < toolbarHeight) ||
                navigationBounds()?.contains(event.x, event.y) == true || tabsBounds()?.contains(event.x, event.y) == true) getChildAt(1) else flutter
        }
        val target = gestureTarget ?: return false
        val handled = target.dispatchTouchEvent(event)
        if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) gestureTarget = null
        // The toolbar band belongs to native chrome even between its controls.
        return handled || target !== flutter
    }
    override fun onDescendantInvalidated(child: View, target: View) {
        super.onDescendantInvalidated(child, target)
        if (child === flutter && (target === flutter || target is FlutterTextureView || target.javaClass == FlutterImageView::class.java)) {
            sourceChanged()
        }
    }
}

private data class NavigationItem(val label: String, val icon: String)
private data class NavigationState(
    val owner: Long = 0, val visible: Boolean = false,
    val left: Float = 0f, val top: Float = 0f, val width: Float = 0f, val height: Float = 54f,
    val selectedIndex: Int = 0, val items: List<NavigationItem> = emptyList(),
    val theme: ChromeTheme = ChromeTheme(),
) {
    companion object {
        fun from(a: Map<*, *>): NavigationState {
            fun coordinate(key: String) = (a[key] as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: 0f
            val items = (a["items"] as? List<*>)?.mapNotNull {
                val item = it as? Map<*, *> ?: return@mapNotNull null
                NavigationItem(item["label"] as? String ?: "", item["icon"] as? String ?: "Months")
            }.orEmpty()
            val width = coordinate("width"); val height = coordinate("height")
            return NavigationState((a["owner"] as? Number)?.toLong() ?: 0,
                a["visible"] == true && width > 0 && height > 0 && items.isNotEmpty(),
                coordinate("left"), coordinate("top"), width, height,
                ((a["selectedIndex"] as? Number)?.toInt() ?: 0).coerceIn(0, (items.size - 1).coerceAtLeast(0)),
                items, ChromeTheme.from(a))
        }
    }
}

private data class ChromeTheme(val dark: Boolean = false, val primary: Int = 0xff0095f9.toInt(),
    val surface: Int = 0xfff8f8fa.toInt(), val onSurface: Int = 0xff161619.toInt(), val fontScale: Float = 1f, val rtl: Boolean = false, val palette: AdaptiveNativePalette = AdaptiveNativePalette()) {
    companion object {
        fun from(a: Map<*, *>) = ChromeTheme(a["dark"] == true,
            (a["primary"] as? Number)?.toInt() ?: 0xff0095f9.toInt(),
            (a["surface"] as? Number)?.toInt() ?: 0xfff8f8fa.toInt(),
            (a["onSurface"] as? Number)?.toInt() ?: 0xff161619.toInt(),
            (a["fontScale"] as? Number)?.toFloat()?.takeIf { it.isFinite() && it > 0 } ?: 1f, a["rtl"] == true, AdaptiveNativePalette.from(a))
    }
}
private data class TitleAction(val index: Int, val label: String, val codePoint: Int?, val mirror: Boolean,
    val text: String? = null, val enabled: Boolean = true, val loading: Boolean = false, val prominent: Boolean = false)
private data class TitleState(val visible: Boolean = false, val title: String = "", val subtitle: String = "",
    val owner: Long = 0, val canBack: Boolean = false, val interactive: Boolean = false,
    val scrollOffset: Float = 0f, val backLabel: String = "返回", val actions: List<TitleAction> = emptyList(),
    val theme: ChromeTheme = ChromeTheme(), val titleTappable: Boolean = false,
    val tabLabels: List<String> = emptyList(), val selectedTabIndex: Int = 0) {
    val progress: Float get() = resolveTopBarScrollProgress(scrollOffset,
        TopBarMaterialRevealStartDistance.value, TopBarMaterialRevealEndDistance.value)
    companion object {
        fun from(a: Map<*, *>) = TitleState(a["visible"] == true, a["title"] as? String ?: "",
            a["subtitle"] as? String ?: "", (a["owner"] as? Number)?.toLong() ?: 0,
            a["canBack"] == true, a["interactive"] == true,
            (a["scrollOffset"] as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: 0f,
            a["backLabel"] as? String ?: "返回",
            (a["actions"] as? List<*>)?.mapNotNull { item ->
                val m = item as? Map<*, *> ?: return@mapNotNull null
                TitleAction((m["index"] as? Number)?.toInt() ?: return@mapNotNull null,
                    m["label"] as? String ?: "", (m["codePoint"] as? Number)?.toInt(),
                    m["mirror"] == true, m["title"] as? String,
                    m["enabled"] != false, m["loading"] == true, m["prominent"] == true)
            }.orEmpty(), ChromeTheme.from(a), a["titleTappable"] == true,
            (a["tabLabels"] as? List<*>)?.filterIsInstance<String>().orEmpty(),
            (a["selectedTabIndex"] as? Number)?.toInt() ?: 0)
    }
}

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ChromeContent(flutter: FlutterView, title: TitleState, navigation: NavigationState, tabs: NavigationState, inputEpoch: Long, active: Boolean, iconFont: FontFamily, dialog: GlassBackdropState, sourceVersion: State<Long>,
    onRecord: () -> Unit, onHeaderTabSelected: (Int) -> Unit, onTabSelected: (Int) -> Unit, onTabsReady: (Long, Boolean) -> Unit, onNavigation: (Int) -> Unit, onNavigationReady: (Long, Boolean) -> Unit, onHeight: (Float) -> Unit, onBack: () -> Unit, onTitle: () -> Unit, onAction: (Int) -> Unit) {
    val t = if (title.visible) title.theme else navigation.theme
    val foreground = Color(t.onSurface)
    val material = remember(t.palette, t.dark) { t.palette.material(t.dark) }
    val miuix = remember(t.palette, t.dark) { t.palette.miuix(t.dark) }
    val dialogCount = dialog.totalConsumers
    val backdrop = rememberLayerBackdrop(onDraw = {
        onRecord()
        var background: View? = null
        for (i in 0 until flutter.childCount) {
            val child = flutter.getChildAt(i)
            if (child.javaClass == FlutterImageView::class.java && child.isShown && child.alpha > 0f) {
                background = child
                break
            }
        }
        val source = background ?: if (dialogCount == 0) flutter else null
        if (source != null) {
            val canvas = drawContext.canvas.nativeCanvas
            val save = canvas.save()
            canvas.translate((flutter.left + if (source === flutter) 0 else source.left).toFloat(),
                (flutter.top + if (source === flutter) 0 else source.top).toFloat())
            source.draw(canvas)
            canvas.restoreToCount(save)
            if (background != null) dialog.recordCount++
            if (!dialog.ready && (dialogCount > 0 || navigation.visible || tabs.visible)) flutter.post {
                if (dialog.totalConsumers > 0 || navigation.visible || tabs.visible) dialog.ready = true
            }
        } else if (dialog.ready) {
            flutter.post { dialog.ready = false }
        }
    })
    SideEffect { dialog.source = backdrop }
    DisposableEffect(dialog) { onDispose { dialog.source = null; dialog.ready = false } }
    val density = LocalDensity.current
    MaterialTheme(colorScheme = material) { MiuixTheme(colors = miuix) {
        CompositionLocalProvider(LocalDensity provides Density(density.density, t.fontScale),
            androidx.compose.ui.platform.LocalLayoutDirection provides if (t.rtl) LayoutDirection.Rtl else LayoutDirection.Ltr,
            LocalAdvancedMaterialBackdrop provides backdrop,
            LocalAdvancedMaterialSpec provides createAdvancedMaterialSpec(true, AdvancedMaterialTuning.DefaultBlurRadius, AdvancedMaterialFineTuning.Default)) {
            Box(Modifier.fillMaxSize()) {
                // Retain coordinates and the last GPU layer while unfocused. Only
                // source invalidation drives capture; no screenshot or frame timer.
                Box(Modifier.fillMaxSize().drawWithContent {
                    if (active && (title.visible || navigation.visible || tabs.visible || dialogCount > 0)) {
                        sourceVersion.value
                        drawContent()
                    }
                }.layerBackdrop(backdrop))
                if (navigation.visible) {
                    val navTheme = navigation.theme
                    val navMaterial = remember(navTheme.palette, navTheme.dark) { navTheme.palette.material(navTheme.dark) }
                    val navMiuix = remember(navTheme.palette, navTheme.dark) { navTheme.palette.miuix(navTheme.dark) }
                    MaterialTheme(colorScheme = navMaterial) { MiuixTheme(colors = navMiuix) {
                        CompositionLocalProvider(
                            LocalDensity provides Density(density.density, navTheme.fontScale),
                            LocalAdvancedMaterialSpec provides createAdvancedMaterialSpec(true, AdvancedMaterialTuning.DefaultBlurRadius, AdvancedMaterialFineTuning.Default)) {
                            // Resume starts a fresh transient pointer/press session. The
                            // selected route and shared GPU source remain root-owned.
                            key(navigation.owner, inputEpoch) {
                                DisposableEffect(navigation.owner) {
                                    onDispose { onNavigationReady(navigation.owner, false) }
                                }
                                Box(Modifier.offset {
                                    IntOffset((navigation.left * density.density + flutter.left).toInt(),
                                        (navigation.top * density.density + flutter.top).toInt())
                                }.requiredSize(navigation.width.dp, navigation.height.dp).onGloballyPositioned { onNavigationReady(navigation.owner, true) }.clearAndSetSemantics {}) {
                                    val items = navigation.items.mapIndexed { index, item ->
                                        val vector = when (item.icon) {
                                            "NotesFill" -> MiuixIcons.NotesFill
                                            "ContactsCircle" -> MiuixIcons.ContactsCircle
                                            else -> MiuixIcons.Months
                                        }
                                        val painter = rememberVectorPainter(vector)
                                        remember(index, item, painter) {
                                            MiuixFloatingTabItem(index.toString(), item.label, painter, painter)
                                        }
                                    }
                                    MiuixFloatingTabBar(items, navigation.selectedIndex.toString(),
                                        onItemSelected = { onNavigation(it.key.toInt()) },
                                        layout = MiuixFloatingTabLayout.Stacked)
                                }
                            }
                        }
                    } }
                }
                if (tabs.visible) {
                    key(tabs.owner, inputEpoch) {
                        DisposableEffect(tabs.owner) { onDispose { onTabsReady(tabs.owner, false) } }
                        Box(Modifier.offset {
                            IntOffset((tabs.left * density.density + flutter.left).toInt(),
                                (tabs.top * density.density + flutter.top).toInt())
                        }.requiredSize(tabs.width.dp, tabs.height.dp).onGloballyPositioned { onTabsReady(tabs.owner, true) }.clearAndSetSemantics {}) {
                            ImmersiveTextTabRow(tabs.items.map { it.label }, tabs.selectedIndex,
                                onTabSelected = onTabSelected, materialProgress = 1f, backdrop = backdrop)
                        }
                    }
                }
                if (title.visible) {
                    val statusHeight = WindowInsets.statusBars.getTop(LocalDensity.current)
                    CompositionLocalProvider(LocalTopBarScrollProgress provides title.progress) {
                        // One canonical material owns title, categories and the fading gap.
                        ProgressiveTopBarMaterial {
                            Column(Modifier.fillMaxWidth().onGloballyPositioned { onHeight((it.size.height - statusHeight) / density.density) }) {
                                Box(if (title.titleTappable) Modifier.clickable(enabled = title.interactive, onClick = onTitle) else Modifier) {
                                    TopAppBar(title.title, subtitle = title.subtitle.takeIf { it.isNotEmpty() }, mode = TopAppBarStyle.SMALL,
                                        navigationIcon = if (title.canBack) ({
                                            TopBarIconButton(onClick = onBack, enabled = title.interactive,
                                                modifier = Modifier.semantics { contentDescription = title.backLabel }) {
                                                Image(painterResource(R.drawable.deadliner_glass_back), null, colorFilter = ColorFilter.tint(foreground),
                                                    modifier = Modifier.size(24.dp).graphicsLayer { scaleX = if (t.rtl) -1f else 1f })
                                            }
                                        }) else null,
                                        actions = { title.actions.forEach { action ->
                                            val enabled = title.interactive && action.enabled && !action.loading
                                            if (action.text != null) {
                                                SoftGlassButton(onClick = { onAction(action.index) }, enabled = enabled,
                                                    prominent = action.prominent, capsule = true, minHeight = 44.dp,
                                                    insideMargin = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                                    modifier = Modifier.semantics { contentDescription = action.label }) {
                                                    if (action.loading) {
                                                        androidx.compose.material3.CircularProgressIndicator(Modifier.size(18.dp),
                                                            color = androidx.compose.material3.LocalContentColor.current, strokeWidth = 2.dp)
                                                    } else androidx.compose.material3.Text(action.text, maxLines = 1)
                                                }
                                            } else if (action.codePoint != null) {
                                                TopBarIconButton(onClick = { onAction(action.index) }, enabled = enabled,
                                                    modifier = Modifier.semantics { contentDescription = action.label }) {
                                                    BasicText(String(Character.toChars(action.codePoint)),
                                                        style = TextStyle(color = foreground.copy(alpha = if (enabled) 1f else .38f), fontSize = 24.sp, fontFamily = iconFont),
                                                        modifier = Modifier.graphicsLayer { scaleX = if (action.mirror && t.rtl) -1f else 1f })
                                                }
                                            }
                                        } })
                                }
                                if (title.tabLabels.isNotEmpty()) {
                                    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
                                        Box(Modifier.widthIn(max = 760.dp).fillMaxWidth().padding(start = 16.dp, end = 16.dp, bottom = 8.dp)) {
                                            key(title.owner, inputEpoch) {
                                                ImmersiveTextTabRow(title.tabLabels, title.selectedTabIndex, modifier = Modifier.widthIn(max = 420.dp).clearAndSetSemantics {},
                                                    onTabSelected = { if (active && title.interactive) onHeaderTabSelected(it) },
                                                    backdrop = backdrop)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    } }
}

// Owner implementation adapted from Hyper-PiliPlus (GPL-3.0); see third_party/hyperpiliplus-backdrop.
private class ActivityChromeViewTreeOwner(
    host: LifecycleOwner,
) : LifecycleOwner, ViewModelStoreOwner, SavedStateRegistryOwner, DefaultLifecycleObserver {
    private val hostLifecycle = host.lifecycle
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateController = SavedStateRegistryController.create(this)

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry
    override val viewModelStore = ViewModelStore()
    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateController.savedStateRegistry

    init {
        savedStateController.performAttach()
        savedStateController.performRestore(null)
        hostLifecycle.addObserver(this)
        lifecycleRegistry.currentState = hostLifecycle.currentState
    }

    override fun onCreate(owner: LifecycleOwner) = moveTo(Lifecycle.State.CREATED)

    override fun onStart(owner: LifecycleOwner) = moveTo(Lifecycle.State.STARTED)

    override fun onResume(owner: LifecycleOwner) = moveTo(Lifecycle.State.RESUMED)

    override fun onPause(owner: LifecycleOwner) = moveTo(Lifecycle.State.STARTED)

    override fun onStop(owner: LifecycleOwner) = moveTo(Lifecycle.State.CREATED)

    override fun onDestroy(owner: LifecycleOwner) = dispose()

    fun dispose() {
        hostLifecycle.removeObserver(this)
        if (lifecycleRegistry.currentState != Lifecycle.State.DESTROYED) {
            lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
            viewModelStore.clear()
        }
    }

    private fun moveTo(state: Lifecycle.State) {
        if (lifecycleRegistry.currentState != Lifecycle.State.DESTROYED)
            lifecycleRegistry.currentState = state
    }
}
