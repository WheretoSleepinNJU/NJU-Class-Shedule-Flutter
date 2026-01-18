class Config {
  static const int MAX_CLASSES = 13;
  static const int MAX_WEEKS = 25;
  static const int DEFAULT_WEEK_NUM = 17;

  static const String default_class_table = "默认课表";

  static const String HIDE_CLASS_COLOR = '#cccccc';

  static const String ANDROID_GROUP = '569300290';
  static const String IOS_GROUP = '493247215';
  static const String OHOS_GROUP = '921608761';

  static const int DONATE_DIALOG_DELAY_SECONDS = 10;
  static const int REVIEW_DIALOG_DELAY_SECONDS = 10;
  static const int REVIEW_DIALOG_SHOW_TIME = 10;

  static const Map jw_config = {
    "page_title": "统一认证登录",
    "initialUrl":
        "https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp",
    "redirectUrl": "http://elite.nju.edu.cn/jiaowu/login.do",
    "targetUrl":
        "http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse",
    "extractJS": "document.body.innerHTML",
    "banner_content":
        "注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常",
    "banner_action": "下载南京大学VPN",
    "banner_url": "https://vpn.nju.edu.cn"
  };

  static const Map xk_config = {
    "page_title": "选课系统登录",
    "initialUrl": "https://xk.nju.edu.cn",
    "redirectUrl": "",
    "targetUrl":
        "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/grablessons.do",
    "preExtractJS":
        "document.getElementsByClassName('yxkc-window-btn')[0].click()",
    "delayTime": 3,
    "extractJS": "document.body.innerHTML",
    "banner_content":
        "注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常",
    "banner_action": "下载南京大学VPN",
    "banner_url": "https://vpn.nju.edu.cn"
  };
}
