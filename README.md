<div align="center">

<img src="./android/app/src/main/res/ic_launcher.png" alt="logo" width="128" height="128" />

<h1>南哪课表 APP</h1>

**为 不止 NJUer 打造的 Android/iOS 平台课程表,使用 Flutter 编写**

</div>

## 下载/Download

[南哪课表官网](https://nju.app)

[安卓下载地址](https://mirror.nju.edu.cn/download/%E5%8D%97%E5%93%AA%E8%AF%BE%E8%A1%A8)

[iOS 下载地址](https://apps.apple.com/cn/app/%E5%8D%97%E5%93%AA%E8%AF%BE%E8%A1%A8/id1511705694)

[南哪课表 FAQ](https://idealclover.top/archives/606/)

<!--more-->

## 功能/Features

当前适配学校：南京大学、东南大学、上海交通大学、中国人民大学

更多学校适配欢迎联系作者或自行 PR~

1. Android & iOS 全平台支持
2. 支持南京大学统一认证登录，本科生&研究生均支持
3. 一键导入南大教务处，自动获取当前周
4. 支持免修不免考，同一时段允许多门课程
5. 支持不同学期多个课表管理与切换
6. 更多样式，自由添加背景图片

## 如何支持更多学校

南哪课表解析课程的主要原理是通过打开页面，并通过 JS 脚本获取页面中的课程信息，然后解析出课程的时间、地点、教师等信息。

涉及到的主要文件：

> [api/schoolList.json](api/schoolList.json): 学校列表，包含学校名称、登录 URL、课程表 URL 等信息，在其中添加需要适配学校的相关信息
> [api/tools/njubksjw2.js](api/tools/njubksjw2.js): 当前南京大学使用的示例课程表解析脚本，你可以参考该文件，根据学校的课程表页面，获取课程信息并解析出时间、地点、教师等信息
> [api/tools/seubksxk.js](api/tools/parseCourse.js): 当前东南大学使用的示例课程表解析脚本，你可以参考该文件，在 JS 脚本中进行 http 请求，根据学校的课程表页面，获取课程信息并解析出时间、地点、教师等信息

需要返回的数据格式（返回下面 json 格式数据的 encodeURIComponent 结果）：

```
{
    "name": "当前学期名称",
    "course": [
        {
            "name": "课程名称",
            "classroom": "课程地点",
            "class_number": "课程编号",
            "teacher": "教师名称",
            "test_time": "考试时间",
            "test_location": "考试地点",
            "link":"课程详情链接，没有传null",
            "week": [1,2,3], // 课程第几周上，是一个数组
            "week_time": 1, // 课程周几上
            "start_time": 1, // 课程开始节数，从1开始,
            "time_count": 2, // 课程持续节数，即结束节数-开始结束，注意如果是3-4节则为1，不需要额外进行加一操作
            "import_type": 1, // 固定填1，作为自动导入方式
            "info": "课程详情，没有传null",
            "data": null
        }
    ]
}

```
