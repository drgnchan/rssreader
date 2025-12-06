# ReadYou (Flutter + FreshRSS)

Flutter RSS 阅读器起步工程，已接入 FreshRSS 的 Google Reader 兼容 API（`api/greader.php`），包含登录、订阅列表、文章列表基础流转。

## 当前进度
- Riverpod + GoRouter 应用骨架，Material 3 主题。
- 登录页：输入实例地址/用户名/密码，拿 SID，安全存储。
- 订阅列表：调用 `subscription/list` + `unread-count`，展示未读数，点击进入文章列表。
- 文章列表：调用 `stream/contents/{streamId}`，显示标题+摘要，星标/已读切换（乐观更新），下拉刷新。
- 文章详情：展示 HTML 内容、作者/时间，支持星标/已读切换。
- 会话状态持久化（`flutter_secure_storage`），支持退出登录。

## 目录速览
- `lib/data/`：FreshRSS API 封装、模型、仓库、Token 存储。
- `lib/state/`：Riverpod providers 与会话控制。
- `lib/ui/`：登录/订阅列表/文章列表/文章详情界面。
- `lib/app.dart`：GoRouter 配置与主题。
- `test/widget_test.dart`：登录流烟测。

## 运行
```bash
flutter pub get
flutter run   # 选择目标设备

flutter test  # 运行简单烟测
```

## FreshRSS API 速记
- Base: `https://<host>/api/greader.php`.
- 登录：`POST accounts/ClientLogin`，表单 `Email`/`Passwd`；响应中的 `SID=` 行即 Token。请求头形如 `Authorization: GoogleLogin auth=<SID>`.
- 订阅：`reader/api/0/subscription/list?output=json`
- 未读数：`reader/api/0/unread-count?output=json`
- 文章：`reader/api/0/stream/contents/<streamId>?output=json&n=40&r=o`
- 标记：`reader/api/0/edit-tag`，表单 `i=<itemId>&a=user/-/state/com.google/read&ac=edit-tags`

## 下一步可做
1) 增加简阅模式/内嵌浏览（可用 `webview_flutter` 或 HTML 清洗），完善外链打开（url_launcher）。  
2) 引入本地缓存（Isar/Drift）存储订阅与文章，离线可读。  
3) 后台/定时同步（workmanager），以及图片加载策略、主题设置等偏好项。  
