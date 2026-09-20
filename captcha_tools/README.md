# 南大统一认证登录 / 验证码识别 —— 调研记录

## 现状结论（最新，已通过抓包确认）

- **登录密码**：南大统一认证登录页对密码字段做了客户端 AES-128-CBC 加密（key 是
  页面隐藏字段 `pwdEncryptSalt`）。算法已经复现验证过，但目前**生产代码走的是
  WebView + 用户手动完成登录**这条路，没有用纯 HTTP 重放这个算法（那部分探索性
  代码已删除，思路记录在这里备查）。
- **验证码类型**：南大最近（约一个月内）把登录验证码从"文字验证码"整体换成了
  **滑动拼图**（组件库文件名 `longbow.slidercaptcha.js` + `ids-sliderCaptcha.js`，
  已下载在本目录）。抓包确认：
  - 拼图验证走独立接口 `openSliderCaptcha.htl`（取图）/ `verifySliderCaptcha.htl`
    （提交验证），跟登录表单本身是分开的两步；验证通过后页面才会提交账号密码。
  - 提交给 `verifySliderCaptcha.htl` 的 `sign` 字段，是用**跟密码加密同一个算法**
    （`encryptPassword`）加密的，只是 key 换成了"拼图小块图片二进制数据的最后
    16 字节"。
  - 实测快速拖动、来回拖动都能通过验证，说明服务端**只判断最终停的位置对不对，
    不分析拖动轨迹**——不涉及"伪造人类行为轨迹去骗过行为检测"这类问题。
  - 要自动过这一关，还差"自动算出拼图应该放在背景图哪个位置"这一步图像识别逻辑，
    目前**没有实现**。
- **`nju_captcha.onnx`**：这是针对**文字验证码**训练的识别模型，跟现在的滑动拼图
  不是一回事，暂时用不上，留着以防学校哪天又切回文字验证码。

## 当前优先级（已调整）

在得知统一认证的登录凭证（`CASTGC`）有效期很长（据社团指导老师反馈约一年，
且大概率是"闲置多久未使用才提前失效"这种滑动窗口机制，正常使用即可持续续期）
之后，**自动解拼图这件事的优先级明显降低**：

- 只要登录成功一次（哪怕是用户手动划一次拼图完成的），之后的"检查更新"可以
  一直复用这个登录状态，不需要每次都重新登录、更不需要每次都过一次拼图。
- 拼图自动识别现在定位为**加分项/远期任务**，不是当前阶段的阻塞项。

## 如果以后要重新捡起来做拼图自动识别

需要补的技术活：
1. 请求 `openSliderCaptcha.htl`，拿到背景图 `bigImage` 和拼图小块 `smallImage`
   （都是 base64 编码的 PNG）。
2. 解码两张图，做图像比对，找出背景图里缺口的正确横向偏移量（这部分逻辑还没写，
   需要引入图片处理库，比如 Dart 的 `image` 包）。
3. 用 `key = smallImage 解码后二进制数据的最后 16 字节`，把
   `{canvasLength, moveLength, tracks}` 这个 JSON 结构加密（复用密码加密的
   AES-128-CBC + 64 位 'a' 前缀混淆算法，之前删掉的 `NjuAuthCrypto.dart` 里的实现
   可以从 git 历史里找回来参考，也可以照着这份 README 重新写，逻辑不复杂）。
4. 提交给 `verifySliderCaptcha.htl`，通过后再走正常的账号密码登录提交。

## 参考文件来源

- `nju_captcha.onnx` / `nju_captcha.user.js`：下载自
  [yama-lei/nju-captcha-extension](https://github.com/yama-lei/nju-captcha-extension)
  （MIT License），分发/使用需保留原项目版权声明。文字验证码识别模型，当前用不上。
- `nju_cli_unified_auth.rs`：下载自
  [nju-cli/nju-cli](https://github.com/nju-cli/nju-cli)（MIT License）的统一认证
  登录参考实现，密码加密算法的原始参考。
- `longbow.slidercaptcha.js` / `ids-sliderCaptcha.js`：直接从南大统一认证登录页
  引用的静态资源下载（`authserver.nju.edu.cn/authserver/njuTheme/static/js/...`），
  公开可访问的前端组件代码，用于分析滑动拼图验证的真实机制。

## 采集/训练脚本（针对文字验证码，当前用不上，留作备用）

`collect_captcha.py`、`train_captcha_model.py` 是针对"文字验证码"设计的采集/训练
工具，现在的滑动拼图不需要这套流程。保留是因为学校以后可能改回文字验证码，或者
拼图机制以后也需要类似的"采集样本→训练模型"思路（如果图像比对的传统方法效果不好，
可能需要训练一个专门定位缺口位置的模型）。
