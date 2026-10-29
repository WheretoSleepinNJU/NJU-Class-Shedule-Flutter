package com.lilystudio.wheretosleepinnju.compose

import android.content.Context
import android.graphics.Typeface
import android.widget.FrameLayout
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.fillMaxWidth
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.resolveTopBarScrollProgress
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopBarMaterialRevealStartDistance
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.TopBarMaterialRevealEndDistance
import com.lilystudio.wheretosleepinnju.deadliner.ui.material.glass.ProgressiveTopBarMaterial
import com.lilystudio.wheretosleepinnju.deadliner.ui.material.glass.LocalTopBarScrollProgress
import com.lilystudio.wheretosleepinnju.deadliner.ui.material.glass.SoftGlassIconButton
import android.view.View
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import com.lilystudio.wheretosleepinnju.deadliner.model.AdvancedMaterialFineTuning
import com.lilystudio.wheretosleepinnju.deadliner.model.AdvancedMaterialTuning
import com.lilystudio.wheretosleepinnju.deadliner.ui.theme.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import top.yukonga.miuix.kmp.blur.LayerBackdrop
import top.yukonga.miuix.kmp.theme.MiuixTheme

/** Shared root-owned source; the platform view must never record itself. */
internal class GlassBackdropState {
    var source by mutableStateOf<LayerBackdrop?>(null)
    var ready by mutableStateOf(false)
    var consumers by mutableIntStateOf(0)
    var recordCount = 0L
    var topBarOffset = 0f
    var topBars by mutableIntStateOf(0)
    var iconButtons by mutableIntStateOf(0)
    val totalConsumers get() = consumers + topBars + iconButtons
}

internal class ComposeGlassSurfaceFactory(
    private val messenger: BinaryMessenger,
    private val backdrop: GlassBackdropState,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        ComposeGlassSurface(context, viewId, messenger, backdrop, args as? Map<*, *> ?: emptyMap<Any, Any>())
}

/** Native chrome only; ordinary controls and dialogs use flutter_miuix. */
private class ComposeGlassSurface(
    context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
    private val backdrop: GlassBackdropState,
    initialTheme: Map<*, *>,
) : PlatformView {
    private var theme by mutableStateOf(initialTheme)
    private val channel = MethodChannel(messenger, "nju/glass-surface/$viewId")
    private val kind = initialTheme["kind"] as? String ?: "icon"
    private var active = false
    private var disposed = false
    private val typeface by lazy { Typeface.createFromAsset(context.assets, "flutter_assets/fonts/MaterialIcons-Regular.otf") }
    private val iconFont by lazy { FontFamily(typeface) }
    private val view = SurfaceContainer(context) { updateActivity() }
    private val compose = ComposeView(context).apply {
        consumeWindowInsets = false
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
        setContent {
            val dark = theme["dark"] == true
            val onSurface = Color((theme["onSurface"] as? Number)?.toInt() ?: 0xff161619.toInt())
            val palette = AdaptiveNativePalette.from(theme)
            val colors = remember(palette, dark) { palette.miuix(dark) }
            val materialColors = remember(palette, dark) { palette.material(dark) }
            MaterialTheme(colorScheme = materialColors) { MiuixTheme(colors = colors) {
                val spec = createAdvancedMaterialSpec(true, AdvancedMaterialTuning.DefaultBlurRadius, AdvancedMaterialFineTuning.Default)
                CompositionLocalProvider(LocalAdvancedMaterialSpec provides spec,
                    LocalAdvancedMaterialBackdrop provides if (backdrop.ready) backdrop.source else null) {
                    when (kind) {
                        "topbar" -> {
                            val offset = (theme["scrollOffset"] as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: 0f
                            val progress = resolveTopBarScrollProgress(offset,
                                TopBarMaterialRevealStartDistance.value, TopBarMaterialRevealEndDistance.value)
                            val height = (theme["contentHeight"] as? Number)?.toFloat()?.takeIf { it.isFinite() && it > 0f } ?: 80f
                            CompositionLocalProvider(LocalTopBarScrollProgress provides progress) {
                                ProgressiveTopBarMaterial(Modifier.fillMaxWidth()) {
                                    Box(Modifier.fillMaxWidth().height(height.dp))
                                }
                            }
                        }
                        "icon" -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            val enabled = theme["enabled"] != false
                            val foreground = (theme["foreground"] as? Number)?.toInt()?.let { Color(it) } ?: onSurface
                            val code = (theme["codePoint"] as? Number)?.toInt() ?: 0xe57f
                            val rtl = theme["rtl"] == true && theme["mirror"] == true
                            SoftGlassIconButton(onClick = { channel.invokeMethod("press", null) }, enabled = enabled) {
                                BasicText(String(Character.toChars(code)),
                                    style = TextStyle(color = foreground.copy(alpha = if (enabled) 1f else .38f), fontSize = 24.sp, fontFamily = iconFont),
                                    modifier = Modifier.graphicsLayer { scaleX = if (rtl) -1f else 1f })
                            }
                        }

                    }
                }
            } }
        }
    }
    init {
        if (kind == "topbar") backdrop.topBarOffset = (theme["scrollOffset"] as? Number)?.toFloat() ?: 0f
        view.addView(compose, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        channel.setMethodCallHandler { call, result ->
            if (call.method == "update") {
                theme = call.arguments as? Map<*, *> ?: theme
                if (kind == "topbar") backdrop.topBarOffset = (theme["scrollOffset"] as? Number)?.toFloat() ?: 0f
                result.success(null)
            } else result.notImplemented()
        }
    }
    private fun updateActivity() {
        val next = !disposed && view.isAttachedToWindow && view.isShown
        if (next == active) return
        active = next
        val delta = if (next) 1 else -1
        when (kind) {
            "topbar" -> backdrop.topBars += delta
            "icon" -> backdrop.iconButtons += delta
            else -> backdrop.consumers += delta
        }
        if (backdrop.totalConsumers == 0) backdrop.ready = false
    }
    override fun getView(): View = view
    override fun dispose() {
        channel.setMethodCallHandler(null)
        disposed = true
        updateActivity()
        compose.disposeComposition()
    }
}

/** Visibility follows Flutter's mutator parent, including retained offstage routes. */
private class SurfaceContainer(context: Context, private val changed: () -> Unit) : FrameLayout(context) {
    override fun onAttachedToWindow() { super.onAttachedToWindow(); post { changed() } }
    override fun onDetachedFromWindow() { super.onDetachedFromWindow(); post { changed() } }
    override fun onVisibilityChanged(changedView: View, visibility: Int) {
        super.onVisibilityChanged(changedView, visibility)
        post { changed() }
    }
}

