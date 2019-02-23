package com.lilystudio.wheretosleepinnju.custom;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AutoCompleteTextView;
import android.widget.Filterable;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListAdapter;

import com.lilystudio.wheretosleepinnju.R;


/**
 * Created by mnnyang on 17-11-5.
 */

public class AutoCompleteTextViewLayout extends LinearLayout {

    private AutoCompleteTextView mAtCompTtView;
    private ImageView mIvIcon;
    private ImageView mIvClear;
    private String mHint;

    public AutoCompleteTextViewLayout(Context context) {
        super(context);
        init();
    }

    public AutoCompleteTextViewLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }


    public AutoCompleteTextViewLayout(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        TypedArray typedArray = context.obtainStyledAttributes(attrs, R.styleable.EditTextLayout);
        mHint = typedArray.getString(R.styleable.EditTextLayout_hint);
        String text = typedArray.getString(R.styleable.EditTextLayout_text);
        Drawable icon = typedArray.getDrawable(R.styleable.EditTextLayout_icon);
        Boolean inputEnabled = typedArray.getBoolean(R.styleable.EditTextLayout_input_enabled, true);
        int textColor = typedArray.getColor(R.styleable.EditTextLayout_textColor, Color.BLACK);
        int hintColor = typedArray.getColor(R.styleable.EditTextLayout_hintColor, Color.GRAY);

        typedArray.recycle();

        init();
        setHint(mHint);
        setText(text);
        setIcon(icon);
        setTextColor(textColor);
        setHintColor(hintColor);
        setInputEnabled(inputEnabled);
    }

    private void setHintColor(int color) {
        mAtCompTtView.setHintTextColor(color);
    }

    private void setTextColor(int color) {
        mAtCompTtView.setTextColor(color);
    }

    private void init() {
        LayoutInflater.from(getContext()).inflate(R.layout.layout_custom_auto_complete_text_view, this);
        mAtCompTtView = findViewById(R.id.auto_text_view);
        mIvIcon = findViewById(R.id.iv_icon);
        mIvClear = findViewById(R.id.iv_clear);

        mIvClear.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                mAtCompTtView.setText("");
            }
        });

        mAtCompTtView.setOnFocusChangeListener(new OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                mIvClear.setVisibility(hasFocus ? VISIBLE : INVISIBLE);
                mAtCompTtView.setHint(hasFocus?"":mHint);
            }
        });
    }

    /**
     *
     * @param inputType definition of EditorInfo class
     */
    public AutoCompleteTextViewLayout setInputType(int inputType){
        mAtCompTtView.setInputType(inputType);
        return this;
    }

    public AutoCompleteTextViewLayout setInputEnabled(boolean enabled) {
        mAtCompTtView.setFocusable(enabled);
        return this;
    }

    public AutoCompleteTextViewLayout setHint(String hint) {
        mHint = hint;
        mAtCompTtView.setHint(hint);
        return this;
    }

    public AutoCompleteTextViewLayout setText(String text) {
        mAtCompTtView.setText(text);
        return this;
    }

    public String getText() {
        return mAtCompTtView.getText().toString();
    }

    public AutoCompleteTextViewLayout setIcon(Drawable icon) {
        if (icon != null) {
            mIvIcon.setImageDrawable(icon);
        }
        return this;
    }

    public <T extends ListAdapter & Filterable> void setAdapter(T adapter){
        mAtCompTtView.setAdapter(adapter);
    }

    @Override
    public void setOnClickListener(@Nullable final OnClickListener l) {
        super.setOnClickListener(l);
        mAtCompTtView.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (l != null) {
                    l.onClick(AutoCompleteTextViewLayout.this);
                }
            }
        });
    }

    public void setDropDownVerticalOffset(int offset){
        mAtCompTtView.setDropDownVerticalOffset(offset);
    }
}
