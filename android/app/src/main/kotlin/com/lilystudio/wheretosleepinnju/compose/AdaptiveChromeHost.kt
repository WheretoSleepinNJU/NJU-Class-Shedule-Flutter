package com.lilystudio.wheretosleepinnju.compose

import android.app.Activity
import android.graphics.Typeface
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.foundation.Image
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
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.*
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.*
import androidx.savedstate.*
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
import top.yukonga.miuix.kmp.icon.MiuixIcons
import top.yukonga.miuix.kmp.icon.extended.Back

/** AdaptiveUI owns one Flutter GPU layer and its native chrome; no screenshot transport. */
class AdaptiveChromeHost(private val activity: Activity, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "nju/compose-titlebar")
    private var title by mutableStateOf(TitleState())
    private var hostResumed by mutableStateOf(false)
    private var flutterView: FlutterView? = null
    private var view: ComposeView? = null
    private var treeOwner: OverlayViewTreeOwner? = null
    private var sourceRecordCount = 0L
    private val iconFont by lazy {
        FontFamily(Typeface.createFromAsset(activity.assets, "flutter_assets/fonts/MaterialIcons-Regular.otf"))
    }
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> { title = TitleState.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()); result.success(null) }
                "hide" -> { title = title.copy(visible = false); result.success(null) }
                "diagnostics" -> result.success(mapOf("transport" to "gpu-layer", "pixelCopyCount" to 0,
                    "gpuDrawCount" to sourceRecordCount, "toolbarVisible" to (title.visible && hostResumed),
                    "visible" to (title.visible && hostResumed), "owner" to title.owner,
                    "title" to title.title, "scrollOffset" to title.scrollOffset,
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
        (flutter.parent as? ViewGroup)?.removeView(flutter)
        val owner = OverlayViewTreeOwner(activity as LifecycleOwner)
        treeOwner = owner
        val compose = ComposeView(activity).apply {
            consumeWindowInsets = false
            setViewTreeLifecycleOwner(owner)
            setViewTreeViewModelStoreOwner(owner)
            setViewTreeSavedStateRegistryOwner(owner)
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
            setContent {
                val frame = title
                ChromeContent(flutter, frame.copy(visible = frame.visible && hostResumed), iconFont,
                    onRecord = { sourceRecordCount++ },
                    onHeight = { channel.invokeMethod("metrics", mapOf("height" to it, "owner" to frame.owner)) },
                    onBack = { channel.invokeMethod("back", mapOf("owner" to frame.owner)) },
                    onAction = { channel.invokeMethod("action", mapOf("index" to it, "owner" to frame.owner)) })
            }
        }
        activity.findViewById<ViewGroup>(android.R.id.content).addView(compose,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.TOP))
        view = compose
    }
    private fun findFlutterView(node: View): FlutterView? {
        if (node is FlutterView) return node
        if (node is ViewGroup) for (i in 0 until node.childCount) findFlutterView(node.getChildAt(i))?.let { return it }
        return null
    }
    private fun hasTextureView(node: View): Boolean = node is FlutterTextureView ||
        (node is ViewGroup && (0 until node.childCount).any { hasTextureView(node.getChildAt(it)) })
    fun setResumed(value: Boolean) { hostResumed = value }
    fun dispose() {
        channel.setMethodCallHandler(null)
        view?.let { it.disposeComposition(); (it.parent as? ViewGroup)?.removeView(it) }
        view = null; flutterView = null; treeOwner?.dispose(); treeOwner = null
    }
}

private data class ChromeTheme(val dark: Boolean = false, val primary: Int = 0xff0095f9.toInt(),
    val surface: Int = 0xfff8f8fa.toInt(), val onSurface: Int = 0xff161619.toInt(), val fontScale: Float = 1f, val rtl: Boolean = false) {
    companion object {
        fun from(a: Map<*, *>) = ChromeTheme(a["dark"] == true,
            (a["primary"] as? Number)?.toInt() ?: 0xff0095f9.toInt(),
            (a["surface"] as? Number)?.toInt() ?: 0xfff8f8fa.toInt(),
            (a["onSurface"] as? Number)?.toInt() ?: 0xff161619.toInt(),
            (a["fontScale"] as? Number)?.toFloat()?.takeIf { it.isFinite() && it > 0 } ?: 1f, a["rtl"] == true)
    }
}
private data class TitleAction(val index: Int, val label: String, val codePoint: Int, val mirror: Boolean)
private data class TitleState(val visible: Boolean = false, val title: String = "", val subtitle: String = "",
    val owner: Long = 0, val canBack: Boolean = false, val interactive: Boolean = false,
    val scrollOffset: Float = 0f, val backLabel: String = "返回", val actions: List<TitleAction> = emptyList(),
    val theme: ChromeTheme = ChromeTheme()) {
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
                    m["label"] as? String ?: "", (m["codePoint"] as? Number)?.toInt() ?: return@mapNotNull null,
                    m["mirror"] == true)
            }.orEmpty(), ChromeTheme.from(a))
    }
}

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ChromeContent(flutter: FlutterView, title: TitleState, iconFont: FontFamily,
    onRecord: () -> Unit, onHeight: (Float) -> Unit, onBack: () -> Unit, onAction: (Int) -> Unit) {
    val t = title.theme
    val primary = Color(t.primary); val surface = Color(t.surface); val foreground = Color(t.onSurface)
    val material = if (t.dark) androidx.compose.material3.darkColorScheme(primary = primary, surface = surface, onSurface = foreground)
        else androidx.compose.material3.lightColorScheme(primary = primary, surface = surface, onSurface = foreground)
    val miuix = if (t.dark) top.yukonga.miuix.kmp.theme.darkColorScheme(primary = primary, surface = surface, onSurface = foreground)
        else top.yukonga.miuix.kmp.theme.lightColorScheme(primary = primary, surface = surface, onSurface = foreground)
    val backdrop = rememberLayerBackdrop()
    val density = LocalDensity.current
    MaterialTheme(colorScheme = material) { MiuixTheme(colors = miuix) {
        CompositionLocalProvider(LocalDensity provides Density(density.density, t.fontScale),
            androidx.compose.ui.platform.LocalLayoutDirection provides if (t.rtl) LayoutDirection.Rtl else LayoutDirection.Ltr,
            LocalAdvancedMaterialBackdrop provides backdrop,
            LocalAdvancedMaterialSpec provides createAdvancedMaterialSpec(true, AdvancedMaterialTuning.DefaultBlurRadius, AdvancedMaterialFineTuning.Default)) {
            Box(Modifier.fillMaxSize()) {
                AndroidView(factory = { flutter }, modifier = Modifier.fillMaxSize().then(
                    if (title.visible) Modifier.drawWithContent { onRecord(); drawContent() }.layerBackdrop(backdrop) else Modifier))
                if (title.visible) {
                    val statusHeight = WindowInsets.statusBars.getTop(LocalDensity.current)
                    CompositionLocalProvider(LocalTopBarScrollProgress provides title.progress) {
                        Box(Modifier.fillMaxWidth().onGloballyPositioned { onHeight((it.size.height - statusHeight) / density.density) }) {
                            TopAppBar(title.title, subtitle = title.subtitle.takeIf { it.isNotEmpty() }, mode = TopAppBarStyle.SMALL,
                                navigationIcon = if (title.canBack) ({
                                    TopBarIconButton(onClick = onBack, enabled = title.interactive,
                                        modifier = Modifier.semantics { contentDescription = title.backLabel }) {
                                        Image(MiuixIcons.Back, null, colorFilter = ColorFilter.tint(foreground),
                                            modifier = Modifier.size(24.dp).graphicsLayer { scaleX = if (t.rtl) -1f else 1f })
                                    }
                                }) else null,
                                actions = { title.actions.forEach { action ->
                                    TopBarIconButton(onClick = { onAction(action.index) }, enabled = title.interactive,
                                        modifier = Modifier.semantics { contentDescription = action.label }) {
                                        BasicText(String(Character.toChars(action.codePoint)),
                                            style = TextStyle(color = foreground, fontSize = 24.sp, fontFamily = iconFont),
                                            modifier = Modifier.graphicsLayer { scaleX = if (action.mirror && t.rtl) -1f else 1f })
                                    }
                                } })
                        }
                    }
                }
            }
        }
    } }
}

// Owner implementation adapted from Hyper-PiliPlus (GPL-3.0); see third_party/hyperpiliplus-backdrop.
private class OverlayViewTreeOwner(
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
