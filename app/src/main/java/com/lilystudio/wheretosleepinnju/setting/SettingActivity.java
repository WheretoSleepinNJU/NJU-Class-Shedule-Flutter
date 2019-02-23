package com.lilystudio.wheretosleepinnju.setting;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.support.v7.widget.AppCompatRadioButton;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.RadioGroup;
import android.widget.ScrollView;

import com.lilystudio.wheretosleepinnju.BaseActivity;
import com.lilystudio.wheretosleepinnju.R;
import com.lilystudio.wheretosleepinnju.about.AboutActivity;
import com.lilystudio.wheretosleepinnju.add.AddActivity;
import com.lilystudio.wheretosleepinnju.app.Constant;
import com.lilystudio.wheretosleepinnju.app.app;
import com.lilystudio.wheretosleepinnju.course.CourseActivity;
import com.lilystudio.wheretosleepinnju.custom.settting.SettingItemNormal;
import com.lilystudio.wheretosleepinnju.impt.ImptActivity;
import com.lilystudio.wheretosleepinnju.mg.MgActivity;
import com.lilystudio.wheretosleepinnju.utils.ActivityUtil;
import com.lilystudio.wheretosleepinnju.utils.DialogHelper;
import com.lilystudio.wheretosleepinnju.utils.DialogListener;
import com.lilystudio.wheretosleepinnju.utils.Preferences;
import com.lilystudio.wheretosleepinnju.utils.ScreenUtils;
import com.lilystudio.wheretosleepinnju.utils.ToastUtils;
import com.lilystudio.wheretosleepinnju.utils.AlipayDonate;

import static com.lilystudio.wheretosleepinnju.app.Constant.themeColorArray;
import static com.lilystudio.wheretosleepinnju.app.Constant.themeNameArray;

public class SettingActivity extends BaseActivity implements SettingContract.View,
        SettingItemNormal.SettingOnClickListener {
    private SettingItemNormal sinUserAdd;
    private SettingItemNormal sinImportNju;
    private SettingItemNormal sinKbManage;

    private SettingItemNormal sinHideFab;
    private SettingItemNormal sinMorePref;
    private SettingItemNormal sinFeedback;
    private SettingItemNormal sinDonate;
    private SettingItemNormal sinAbout;
    private SettingPresenter mPresenter;
    private HorizontalScrollView hsvTheme;
    private LinearLayout layoutTheme;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_setting);
        initBackToolbar(getString(R.string.setting));

        initView();
        initDefaultValues();

        mPresenter = new SettingPresenter(this);
    }

    private void initView() {
        hsvTheme = findViewById(R.id.hsv_theme);
        layoutTheme = findViewById(R.id.layout_theme);

        sinUserAdd = findViewById(R.id.sin_user_add);
        sinImportNju = findViewById(R.id.sin_import_nju);
        sinKbManage = findViewById(R.id.sin_kb_manage);

        sinHideFab = findViewById(R.id.sin_hide_fab);
        sinMorePref = findViewById(R.id.sin_more_pref);
        sinFeedback = findViewById(R.id.sin_feedback);
        sinDonate = findViewById(R.id.sin_donate);
        sinAbout = findViewById(R.id.sin_about);

        sinUserAdd.setSettingOnClickListener(this);
        sinImportNju.setSettingOnClickListener(this);
        sinKbManage.setSettingOnClickListener(this);

        sinHideFab.setSettingOnClickListener(this);
        sinMorePref.setSettingOnClickListener(this);
        sinFeedback.setSettingOnClickListener(this);
        sinDonate.setSettingOnClickListener(this);
        sinAbout.setSettingOnClickListener(this);

        layoutTheme.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showThemeDialog();
            }
        });
    }

    private void initDefaultValues() {

        sinHideFab.setChecked(PreferenceManager
                .getDefaultSharedPreferences(getBaseContext())
                .getBoolean(getString(R.string.app_preference_hide_fab),
                        false));
//                        true));
    }

    @Override
    public void onClick(View view, boolean checked) {
        System.out.println(view);
        switch (view.getId()) {
            case R.id.sin_user_add:
                gotoAddActivity();
                break;
            case R.id.sin_import_nju:
                gotoImpActivity();
//                importCourseTable();
                break;

            case R.id.sin_kb_manage:
                gotoMgActivity();
                break;

            case R.id.sin_hide_fab:
                hideFabPref(checked);
                break;

            case R.id.sin_more_pref:
                gotoConfActivity();
                break;
            case R.id.sin_feedback:
                mPresenter.feedback();
                break;
            case R.id.sin_about:
                gotoAboutActivity();
                break;
            case R.id.sin_donate:
                gotoDonateActivity();
                break;
            case R.id.hsv_theme:
                showThemeDialog();
            default:
                break;
        }
    }

    @Override
    public void onCheckedChanged(View view, boolean checked) {
        switch (view.getId()) {
            case R.id.sin_hide_fab:
                hideFabPref(checked);
                break;
            default:
                break;
        }
    }

    int theme;

    private void showThemeDialog() {
        ScrollView scrollView = new ScrollView(this);
        RadioGroup radioGroup = new RadioGroup(this);
        scrollView.addView(radioGroup);
        int margin = ScreenUtils.dp2px(16);
        radioGroup.setPadding(margin / 2, margin, margin, margin);

        for (int i = 0; i < themeColorArray.length; i++) {
            AppCompatRadioButton arb = new AppCompatRadioButton(this);

            RadioGroup.LayoutParams params =
                    new RadioGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT);

            arb.setLayoutParams(params);
            arb.setId(i);
            arb.setTextColor(getResources().getColor(themeColorArray[i]));
            arb.setText(themeNameArray[i]);
            arb.setTextSize(16);
            arb.setPadding(0, margin / 2, 0, margin / 2);
            radioGroup.addView(arb);
        }

        radioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                theme = checkedId;
            }
        });

        DialogHelper dialogHelper = new DialogHelper();
        dialogHelper.showCustomDialog(this, scrollView,
                getString(R.string.theme_preference), new DialogListener() {
                    @Override
                    public void onPositive(DialogInterface dialog, int which) {
                        super.onPositive(dialog, which);
                        dialog.dismiss();
                        String key = getString(R.string.app_preference_theme);
                        int oldTheme = Preferences.getInt(key, 0);

                        if (theme != oldTheme) {
                            Preferences.putInt(key, theme);
                            ActivityUtil.finishAll();
                            startActivity(new Intent(app.mContext, CourseActivity.class));
                        }
                    }
                });
    }

    private void hideFabPref(boolean checked) {
        PreferenceManager
                .getDefaultSharedPreferences(getBaseContext())
                .edit()
                .putBoolean(getString(R.string.app_preference_hide_fab), checked)
                .apply();

        notifiUpdateMainPage(Constant.INTENT_UPDATE_TYPE_OTHER);
    }


    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                finish();
                break;
        }
        return super.onOptionsItemSelected(item);
    }

//    private void importCourseTable() {
//        gotoActivity(SchoolActivity.class);
//    }

    private void gotoImpActivity() {
        gotoActivity(ImptActivity.class);
    }

    private void gotoConfActivity() {
        ToastUtils.show("还在开发中...");
    }

    private void gotoAboutActivity() {
        gotoActivity(AboutActivity.class);
    }

    private void gotoDonateActivity() {
        boolean hasInstalledAlipayClient = AlipayDonate.hasInstalledAlipayClient(this);
        if (!hasInstalledAlipayClient) {
            ToastUtils.show(getString(R.string.alipay_not_installed));
        } else{
            AlipayDonate.startAlipayClient(this, getString(R.string.pay_code));
        }
    }

    private void gotoMgActivity() {
        gotoActivity(MgActivity.class);
    }

    public void gotoAddActivity() {
        gotoActivity(AddActivity.class);
    }

    @Override
    public void showNotice(String notice) {
        ToastUtils.show(notice);
    }
}
