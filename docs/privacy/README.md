# Lucky Island 隐私政策交付说明

核对日期：2026-09-17。适用于当前 Lucky Island 1.0 工程，Bundle ID 为 `com.ccvl.Veltranomixa`。

- [中文政策](privacy-policy.zh-CN.md)
- [英文政策](privacy-policy.en.md)
- [英文 HTML 网页](html/index.html)：独立文件，适配手机，无外部字体、脚本或统计服务。托管时上传 `html` 文件夹即可，默认首页为 `index.html`。正文与英文 Markdown 已核对一致，邮箱以纯文本显示。

两份文本已按用户确认填写：开发者／运营主体为 Trademark Roofing Co，生效日期为 2026 年 9 月 17 日，联系邮箱为 `cressidal@trademarkroofing.homes`。名称、日期和邮箱占位项均已替换。政策中的支持通信保留与处理方式应与运营者实际执行方式一致。

## 本次核对依据

- `Veltranomixa/Info.plist`：显示名为 Lucky Island，当前本地化为英语，未发现敏感权限用途声明。
- `Veltranomixa/Domain/GameEngine.swift`：保存局内状态、结果标识、收藏、成就、累计游戏统计和偏好。
- `Veltranomixa/Data/SaveRepository.swift`：设备本地 JSON 存档及备份；损坏文件保留在本地；重置时清理有效的损坏副本并覆盖主存档及备份。
- `Veltranomixa/ViewController.swift`：存储于 Application Support；当前设置中包含本地隐私及备份说明；未发现账号、广告、内购或网络服务调用。
- `Veltranomixa/Resources/PrivacyInfo.xcprivacy` 及 SnapKit 隐私清单：未声明数据收集或跟踪。依赖为 SnapKit 5.7.1，供界面布局使用。

核对对象是当前源码、依赖及清单；本次没有执行网络流量监测，也没有核验运营者的邮箱服务、App Store Connect 诊断访问或网站托管行为。不将隐私清单单独视为没有数据处理的证明。

## 发布说明

1. 主体、日期和邮箱已填写；发布时确认邮件处理约定与实际一致。
2. 将选定语言的政策发布为无需登录即可访问的稳定网页，并把政策链接填入 App Store Connect，且在应用内提供易于访问的入口。正式政策已托管至 [Flycricket](https://doc-hosting.flycricket.io/lucky-island-privacy-policy/0844502f-3dcc-4b6b-b833-8b7e5930bd9c/privacy)，已核对 HTTP 200 与正文。设置页新增 Privacy Policy，使用系统浏览器打开；Privacy and saves 弹窗保留离线说明、运营主体、联系邮箱及生效日期。App Store Connect 的政策字段仍需填写，当前没有修改线上后台。
3. 当前代码中的本地存档不等于开发者远程收集。App Store 隐私问卷应结合正式构建、所有 SDK 以及实际从平台获取的数据填写，不能仅凭“离线”直接确认所有答案。
4. 如果政策网页的托管服务记录访问 IP、使用 Cookie 或统计工具，应按所选服务补充对应网页的数据处理说明；本次政策仅覆盖应用及用户主动联系。
5. 新增广告、账号、内购、联网功能或诊断服务后，先重新核对政策和隐私申报。

## 官方参考

- [Apple 审核指南 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)：隐私政策入口以及收集、用途、保留和删除说明要求。
- [App Store 隐私详情](https://developer.apple.com/app-store/app-privacy-details/)：仅在设备上处理的数据，以及开发者通过 Apple 服务获取数据时的申报说明。
- [iCloud 备份包含的内容](https://support.apple.com/en-us/108770)：设备备份可能包含第三方应用数据。

隐私文档及应用内隐私弹窗的运营主体、邮箱和生效日期已同步。
