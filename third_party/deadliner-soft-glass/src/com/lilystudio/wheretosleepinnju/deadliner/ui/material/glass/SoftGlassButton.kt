package com.lilystudio.wheretosleepinnju.deadliner.ui.material.glass

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ProvideTextStyle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.DeadlinerMiuixDefaults
import com.lilystudio.wheretosleepinnju.deadliner.ui.base.feedback.miuixControlFeedback
import com.lilystudio.wheretosleepinnju.deadliner.ui.theme.LocalAdvancedMaterialBackdrop
import com.lilystudio.wheretosleepinnju.deadliner.ui.theme.LocalAdvancedMaterialSpec
import top.yukonga.miuix.kmp.basic.Button as MiuixButton
import top.yukonga.miuix.kmp.basic.ButtonDefaults
import top.yukonga.miuix.kmp.basic.ButtonColors
import top.yukonga.miuix.kmp.blur.LayerBackdrop
import top.yukonga.miuix.kmp.theme.MiuixTheme

/**
 * MIUIX 0.9.4-rc01 Button owns layout, accessibility and activation. The existing
 * Deadliner glass stack owns the surface, shadow and capability fallbacks.
 * Shares the page backdrop; never records itself or allocates another recorder.
 */
@Composable
fun SoftGlassButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    prominent: Boolean = false,
    capsule: Boolean = false,
    cornerRadius: Dp = DeadlinerMiuixDefaults.ButtonCornerRadius,
    minHeight: Dp = 48.dp,
    insideMargin: PaddingValues = PaddingValues(horizontal = 14.dp, vertical = 10.dp),
    colors: ButtonColors? = null,
    textStyle: TextStyle = MiuixTheme.textStyles.button,
    backdrop: LayerBackdrop? = LocalAdvancedMaterialBackdrop.current,
    content: @Composable RowScope.() -> Unit,
) {
    val shape = if (capsule) RoundedCornerShape(50) else RoundedCornerShape(cornerRadius)
    val material = LocalAdvancedMaterialSpec.current
    val resolvedColors = colors ?: if (prominent) ButtonDefaults.buttonColorsPrimary()
        else ButtonDefaults.buttonColors(contentColor = MiuixTheme.colorScheme.onSurface)
    val contentColor = if (enabled) resolvedColors.contentColor else resolvedColors.disabledContentColor
    // An opaque semantic surface keeps controls readable without a sampled backdrop.
    val tint = when {
        !enabled -> resolvedColors.disabledColor
        prominent -> resolvedColors.color
        !material.textureBlurEnabled || backdrop == null -> MaterialTheme.colorScheme.surfaceContainerHigh
        else -> null
    }
    Box(
        modifier = modifier
            .softGlassShadow(shape, isDark = MaterialTheme.colorScheme.onSurface.luminance() > 0.5f)
            .miuixControlFeedback(enabled = enabled, shape = shape),
        propagateMinConstraints = true,
    ) {
        SoftGlassSurface(
            modifier = Modifier.matchParentSize(),
            shape = shape,
            recipe = DeadlinerGlassRecipes.floatingNavigation(material.fineTuning)
                .copy(surfaceRole = GlassSurfaceRole.Control),
            tint = tint,
            tintStyle = if (prominent && enabled) GlassTintStyle.SeedChromatic else GlassTintStyle.Neutral,
            backdrop = backdrop,
        ) {}
        MiuixButton(
            onClick = onClick,
            enabled = enabled,
            cornerRadius = if (capsule) minHeight / 2 else cornerRadius,
            minWidth = 0.dp,
            minHeight = minHeight,
            insideMargin = insideMargin,
            colors = ButtonDefaults.buttonColors(
                color = Color.Transparent,
                disabledColor = Color.Transparent,
                contentColor = contentColor,
                disabledContentColor = contentColor,
            ),
            indication = null,
        ) {
            CompositionLocalProvider(androidx.compose.material3.LocalContentColor provides contentColor) {
                ProvideTextStyle(textStyle) { content() }
            }
        }
    }
}
