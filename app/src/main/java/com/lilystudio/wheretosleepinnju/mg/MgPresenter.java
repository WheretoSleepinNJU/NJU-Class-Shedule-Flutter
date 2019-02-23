package com.lilystudio.wheretosleepinnju.mg;

import android.text.TextUtils;

import com.lilystudio.wheretosleepinnju.R;
import com.lilystudio.wheretosleepinnju.app.app;
import com.lilystudio.wheretosleepinnju.data.bean.CsItem;
import com.lilystudio.wheretosleepinnju.data.db.CourseDbDao;
import com.lilystudio.wheretosleepinnju.utils.DialogHelper;
import com.lilystudio.wheretosleepinnju.utils.Preferences;

import java.util.ArrayList;

import rx.Observable;
import rx.Observer;
import rx.Subscriber;
import rx.android.schedulers.AndroidSchedulers;
import rx.schedulers.Schedulers;

/**
 * Created by mnnyang on 17-11-4.
 */

public class MgPresenter implements MgContract.Presenter {
    MgContract.View mView;
    MgContract.Model mModel;
    ArrayList<CsItem> mCsItems;

    public MgPresenter(MgContract.View view, ArrayList<CsItem> csItems) {
        mView = view;
        mCsItems = csItems;
        mModel = new MgModel();
    }

    @Override
    public void start() {
        reloadCsNameList();
    }

    @Override
    public void reloadCsNameList() {
        Observable.create(new Observable.OnSubscribe<ArrayList<CsItem>>() {
            @Override
            public void call(Subscriber<? super ArrayList<CsItem>> subscriber) {
                ArrayList<CsItem> data = mModel.getCsItemData();
                subscriber.onNext(data);
                subscriber.onCompleted();
            }
        }).subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new Observer<ArrayList<CsItem>>() {

                    @Override
                    public void onCompleted() {

                    }

                    @Override
                    public void onError(Throwable e) {
                        e.printStackTrace();
                    }

                    @Override
                    public void onNext(ArrayList<CsItem> items) {
                        mCsItems.clear();
                        mCsItems.addAll(items);
                        mView.showList(mCsItems);
                    }
                });
    }

    @Override
    public void addCsName(String csName) {
        if (TextUtils.isEmpty(csName)) {
            mView.showNotice(app.mContext.getString(R.string.course_name_can_not_be_empty));
        } else {
            //TODO 检查
            boolean isConflict = CourseDbDao.newInstance().hasConflictCourseTableName(csName);
            if (isConflict) {
                //notice conflict
                mView.showNotice(app.mContext.getString(R.string.course_name_is_conflicting));
            } else {
                //add cs_name
                CourseDbDao.newInstance().getCsNameId(csName);
                mView.addCsNameSucceed();
            }
        }
    }

    @Override
    public void editCsName(int id, String newCsName) {

        int update = CourseDbDao.newInstance().updateCsName(id, newCsName);
        if (update == 0) {
            mView.showNotice(app.mContext.getString(R.string.course_name_already_exists));
        } else {
            mView.editCsNameSucceed();
        }
    }

    @Override
    public void deleteCsName(final int csNameId, final DialogHelper dh) {
        Observable.create(new Observable.OnSubscribe<String>() {

            @Override
            public void call(Subscriber<? super String> subscriber) {
                CourseDbDao dao = CourseDbDao.newInstance();
                dao.removeByCsNameId(csNameId);
                subscriber.onNext("ok");
            }
        }).subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new Observer<String>() {

                    @Override
                    public void onCompleted() {
                    }

                    @Override
                    public void onError(Throwable e) {
                        e.printStackTrace();
                        dh.hideProgressDialog();
                    }

                    @Override
                    public void onNext(String s) {
                        dh.hideProgressDialog();
                        mView.deleteFinish();
                    }
                });
    }

    @Override
    public void switchCsName(int csNameId) {
        Preferences.putInt(app.mContext.getString(
                R.string.app_preference_current_cs_name_id), csNameId);

        mView.showNotice("切换成功");
        mView.gotoCourseActivity();
    }
}
