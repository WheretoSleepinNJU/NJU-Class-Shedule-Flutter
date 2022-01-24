package com.umeng.umeng_common_sdk;

import android.content.Context;

import androidx.annotation.NonNull;

import com.umeng.analytics.MobclickAgent;
import com.umeng.commonsdk.UMConfigure;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** UmengCommonSdkPlugin */
public class UmengCommonSdkPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "umeng_common_sdk");
    UmengCommonSdkPlugin plugin = new UmengCommonSdkPlugin();
    plugin.mContext = registrar.context();
    channel.setMethodCallHandler(plugin);
    onAttachedEngineAdd();
  }

  private static void onAttachedEngineAdd() {
// add by umeng
    try {
      Class<?> agent = Class.forName("com.umeng.analytics.MobclickAgent");
      Method[] methods = agent.getDeclaredMethods();
      for (Method m : methods) {
        android.util.Log.e("UMLog", "Reflect:"+m);
        if(m.getName().equals("onEventObject")) {
          versionMatch = true;
          break;
        }
      }
      if(!versionMatch) {
        android.util.Log.e("UMLog", "安卓SDK版本过低，建议升级至8以上");
        //return;
      }
      else {
        android.util.Log.e("UMLog", "安卓依赖版本检查成功");
      }
    }
    catch (Exception e) {
      e.printStackTrace();
      android.util.Log.e("UMLog", "SDK版本过低，请升级至8以上"+e.toString());
      return;
    }

    Method method = null;
    try {
      Class<?> config = Class.forName("com.umeng.commonsdk.UMConfigure");
      method = config.getDeclaredMethod("setWraperType", String.class, String.class);
      method.setAccessible(true);
      method.invoke(null, "flutter","1.0");
      android.util.Log.i("UMLog", "setWraperType:flutter1.0 success");
    }
    catch (NoSuchMethodException | InvocationTargetException | IllegalAccessException | ClassNotFoundException e) {
      e.printStackTrace();
      android.util.Log.e("UMLog", "setWraperType:flutter1.0"+e.toString());
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mContext = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "umeng_common_sdk");
    channel.setMethodCallHandler(this);
    onAttachedEngineAdd();
  }

  private static Context mContext = null;

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if(!versionMatch) {
      android.util.Log.e("UMLog", "onMethodCall:"+call.method+":安卓SDK版本过低，请升级至8以上");
      //return;
    }
    try {
      List args = (List) call.arguments;
      switch (call.method) {
        case "getPlatformVersion":
          result.success("Android " + android.os.Build.VERSION.RELEASE);
          break;
        case "initCommon":
          initCommon(args);
          break;
        case "onEvent":
          onEvent(args);
          break;
        case "onProfileSignIn":
          onProfileSignIn(args);
          break;
        case "onProfileSignOff":
          onProfileSignOff();
          break;
        case "setPageCollectionModeAuto":
          setPageCollectionModeAuto();
          break;
        case "setPageCollectionModeManual":
          setPageCollectionModeManual();
          break;
        case "onPageStart":
          onPageStart(args);
          break;
        case "onPageEnd":
          onPageEnd(args);
          break;
        case "reportError":
          reportError(args);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (Exception e) {
      e.printStackTrace();
      android.util.Log.e("Umeng", "Exception:"+e.getMessage());
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  private static Boolean versionMatch = false;

  public static void setContext (Context ctx) {
    mContext = ctx;
  }

  public static Context getContext () {
    return mContext;
  }

  private void initCommon(List args) {
    String appkey = (String)args.get(0);
    String channel = (String)args.get(2);
    UMConfigure.init(getContext(), appkey, channel, UMConfigure.DEVICE_TYPE_PHONE, null);
    android.util.Log.i("UMLog", "initCommon:"+appkey+"@"+channel);
  }

  private void onEvent(List args) {
    String event = (String)args.get(0);
    Map map = null ;
    if(args.size()>1) {
      map = (Map) args.get(1);
    }
    //JSONObject properties = new JSONObject(map);
    MobclickAgent.onEventObject(getContext(), event, map);

    if(map!=null) {
      android.util.Log.i("UMLog", "onEventObject:"+event+"("+map.toString()+")");
    }
    else {
      android.util.Log.i("UMLog", "onEventObject:"+event);
    }
  }

  private void onProfileSignIn (List args) {
    String userID = (String)args.get(0);
    MobclickAgent.onProfileSignIn(userID);
    android.util.Log.i("UMLog", "onProfileSignIn:"+userID);
  }

  private void onProfileSignOff () {
    MobclickAgent.onProfileSignOff();
    android.util.Log.i("UMLog", "onProfileSignOff");
  }

  private void setPageCollectionModeAuto () {
    MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO);
    android.util.Log.i("UMLog", "setPageCollectionModeAuto");
  }

  private void setPageCollectionModeManual () {
    MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.MANUAL);
    android.util.Log.i("UMLog", "setPageCollectionModeManual");
  }

  private void onPageStart(List args) {
    String event = (String)args.get(0);
    MobclickAgent.onPageStart(event);
    android.util.Log.i("UMLog", "onPageStart:"+event);
  }

  private void onPageEnd(List args) {
    String event = (String)args.get(0);
    MobclickAgent.onPageEnd(event);
    android.util.Log.i("UMLog", "onPageEnd:"+event);
  }

  private void reportError(List args){
    String error = (String)args.get(0);
    MobclickAgent.reportError(getContext(), error);
    android.util.Log.i("UMLog", "reportError:"+error);
  }
}
