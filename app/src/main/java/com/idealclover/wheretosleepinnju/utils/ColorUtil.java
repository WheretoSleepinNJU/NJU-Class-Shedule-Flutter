package com.idealclover.wheretosleepinnju.utils;

import android.content.Context;
import android.content.res.TypedArray;
import android.util.TypedValue;

import com.idealclover.wheretosleepinnju.R;
import com.idealclover.wheretosleepinnju.app.Constant;

/**
 * Created by mnnyang on 17-11-8.
 */

public class ColorUtil {
    public static int getColor(Context context, int colorAttr) {
        TypedValue typedValue = new TypedValue();
        context.getTheme().resolveAttribute(R.attr.theme,
                typedValue, true);

        int[] attribute = new int[]{colorAttr};
        TypedArray array = context.obtainStyledAttributes(typedValue.resourceId, attribute);
        int color = array.getColor(0, context.getResources().getColor(R.color.primary_nanjing_blue));
        array.recycle();

        return color;
    }
}
