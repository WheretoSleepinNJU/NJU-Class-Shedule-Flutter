package com.lilystudio.wheretosleepinnju.about;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;

import com.lilystudio.wheretosleepinnju.BaseActivity;
import com.lilystudio.wheretosleepinnju.R;
import com.lilystudio.wheretosleepinnju.utils.ToastUtils;


/**
 * Created by xxyangyoulin on 2018/3/13.
 * Changed by idealclover on 18-09-06
 */

public class AboutActivity extends BaseActivity implements AboutContract.View {

    private AboutPresenter mPresenter;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_about);

        initBackToolbar(getString(R.string.about));
        initGithubTextView();
        initDonateListTextView();
        initBlogTextView();
        initVersionName();
        initCheckUpdate();

        mPresenter = new AboutPresenter(this);
    }

    private void initVersionName() {
        TextView tvVersionName = findViewById(R.id.tv_version);
        tvVersionName.setText(R.string.app_LTS);
    }

    private void initCheckUpdate() {
        TextView tv = findViewById(R.id.tv_check_update);
        tv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mPresenter.checkUpdate();
            }
        });
    }

    private void initGithubTextView() {
        TextView tv = findViewById(R.id.tv_github);
        tv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Uri uri = Uri.parse(getString(R.string.github_njuclassschedule));
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                startActivity(intent);
            }
        });
    }

    private void initDonateListTextView() {
        TextView tv = findViewById(R.id.tv_donate);
        tv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Uri uri = Uri.parse(getString(R.string.donate_njuclassschedule));
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                startActivity(intent);
            }
        });
    }

    private void initBlogTextView() {
        TextView tv = findViewById(R.id.tv_blog);
        tv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Uri uri = Uri.parse(getString(R.string.blog_url));
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                startActivity(intent);
            }
        });
    }

    @Override
    public void showNotice(String notice) {
        ToastUtils.show(notice);
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
}
