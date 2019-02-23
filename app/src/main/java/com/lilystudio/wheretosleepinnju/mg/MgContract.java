package com.lilystudio.wheretosleepinnju.mg;

import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;
import com.lilystudio.wheretosleepinnju.data.bean.CsItem;
import com.lilystudio.wheretosleepinnju.utils.DialogHelper;

import java.util.ArrayList;

/**
 * Created by mnnyang on 17-11-4.
 */

public interface MgContract {
    interface Presenter extends BasePresenter {
        void deleteCsName(int csNameId, DialogHelper dh);
        void switchCsName(int csNameId);
        void reloadCsNameList();
        void addCsName(String csName);
        void editCsName(int id, String newCsName);
    }

    interface View extends BaseView<Presenter> {
        void showList(ArrayList<CsItem> csNames);
        void showNotice(String notice);
        void gotoCourseActivity();
        void deleteFinish();
        void addCsNameSucceed();
        void editCsNameSucceed();
    }

    interface Model{
        ArrayList<CsItem> getCsItemData();
    }
}
