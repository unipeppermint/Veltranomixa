# 幸运小岛 · 实现与验证

更新时间：2026-09-16。开发在原有 Veltranomixa Target 内完成，未另建替代应用。

## 打开与运行

打开 `Veltranomixa.xcworkspace`，选择 `Veltranomixa` scheme。依赖为 CocoaPods 1.17.0 + SnapKit 5.7.1，版本见 Gemfile.lock / Podfile.lock。

```sh
bundle install
bundle exec pod install
xcodebuild -workspace Veltranomixa.xcworkspace -scheme Veltranomixa \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/LuckyIslandBuild CODE_SIGNING_ALLOWED=NO build
swift test --scratch-path /tmp/lucky-rule-tests
```

本机 Homebrew CocoaPods 使用独立 GEM_HOME；直接 `pod install` 已实测成功。Gemfile.lock 使用其已安装依赖解析生成。其他机器可通过 Bundler 标准安装还原。

Podfile 的 post_integrate 仅为 CocoaPods 资源复制脚本声明临时输出文件，使其在 Xcode 的脚本沙箱下正常工作；没有关闭脚本沙箱。Bundle ID `com.ccvl.Veltranomixa`、签名方式、版本号和原有发布设置保留。改为程序化 SceneDelegate 入口，保留原 storyboard 文件与启动屏。

## 已实现

- Swift / UIKit / SnapKit 原生首页、地图、关卡详情、转盘、升级、工坊、结算、收藏与设置，无 WebView。
- 3 区域、15 关；6 种格子、15 种升级；12 景观、10 成就、3 转盘配色。
- 灯塔为文档规定的 12 次、20 木材、八格等概率及三种基础升级。目标优先于升级；最后一转可用备用机会救场。
- 第 2 关起开放 6 金币替换单格为基础产出 2 的木材/金币格，第 6 关起可替换贝壳格。强化木材仍为 4 金币。单格始终 12.5%。
- 第 6 关引入贝壳，第 11 关引入补给。贝壳不消耗顺风，补给返还一次机会并提供 1 木材。
- 额外挑战为胜利时至少保留 3 次机会。主目标在木材、金币、贝壳与组合目标间变化。
- 首套海风皮肤默认可用，珊瑚/星夜在第 13/14 关完成后解锁，第 15 关解锁全岛成就。
- Core Animation 转盘减速、指针摆动、资源飞行动画；真实生成插画拆层场景和收藏、资源图标、App Icon；原创合成音效与原生触感。
- 声音、触感、快速动画、教学重看、玩法与概率、隐私说明、许可、清空进度二次确认。系统减弱动态效果自动适配。
- 本地 JSON v1 存档与上一份备份。新快照原子落盘后才发布 UI 状态。转动结果包含 UUID、索引及奖励消息；奖励预先提交，动画结束只清除 pending，恢复不重抽不重奖。
- 主存档损坏尝试备份；全部损坏保留副本并说明；未知未来版本拒绝写入。当前版本为首个格式，尚无旧正式版本需要迁移。

## 代码结构

- `Domain/GameEngine.swift`：配置、模型、随机源协议、纯规则、状态校验。
- `Data/SaveRepository.swift`：串行存档、原子提交、备份恢复。
- `ViewController.swift`：原生页面、交互与持久化提交后更新。
- `Views/`：转盘、岛屿分层、设计组件、声音与触感。
- `Assets.xcassets/`：岛屿底图、建筑图集、资源图集、图标。
- `Tests/`：可独立在 macOS 运行的规则/持久化 XCTest。
- `UITests/`：模拟器实际 UI 流程与大文字/偏好持久化。

## 美术与资源

图片由本任务通过内置 ImageGen 生成，最终素材全部保存在工程 Asset Catalog。建筑 4×3 图集由原生视图裁切，按真实解锁进度叠加到无建筑岛屿底图；资源图标为 3×2 图集。未使用原型三屏合成图作为游戏页面，也未采用 HTML emoji 场景。

`spin.wav` / `success.wav` 为正弦波叠加和包络生成的原创短音效。SnapKit MIT 原文包含在应用中。应用与 SnapKit 隐私清单均已编译进模拟器包，未接入账号、广告、内购、分析或网络服务。

## 验证记录

- Xcode 26.6 / iOS 26.5 SDK / CocoaPods 1.17.0。
- workspace Debug 模拟器构建通过。
- workspace Release 模拟器构建通过；未签名归档。
- 16 项规则及持久化 XCTest：0 失败。覆盖全部基础格子、先加后乘、顺风非叠加与消耗、最后一转、胜利优先、双触发去重、金币与替换、UUID 防重复、pending 恢复、损坏备份、未来版本保护、写入失败和非法状态。
- 第一轮真实随机 UI 测试通过：转动后退出应用、重启继续、升级、结束一局、收藏、设置。
- 最终 2 项 UI 测试均通过：固定结果完整通关并解锁下一关；最大辅助字号收藏/设置与重启后偏好保持。截图检查发现并修复底部导航裁切后，针对性大文字 UI 测试再次通过。证据见 `validation/screenshots/` 与测试日志。
- 15,000 局固定种子策略模拟：各关胜率 89.3%–99.7%，平均转动 12.959–35.871 次。策略优先工具、低剩余选备用机会并适度改造，属于诊断而非玩家胜率承诺。数值见 `validation/balance.csv`。
- 构建仅出现无 AppIntents 依赖的元数据提取提示，不影响应用功能。

UI 测试固定随机入口由 `#if DEBUG` 包裹，仅显式环境变量 `ISLAND_UI_FIXED_WOOD=1` 生效，画面带测试标识。Release 不编译此入口。界面测试截图不可直接作为 App Store 商品截图。

## 仍需外部验收与发行材料

- 真机音效、静音开关、触感、VoiceOver 实际朗读、不同 iOS 版本、长时间帧率/内存/热量与 TestFlight 尚未验证。
- 当前支持页提供本地故障指引；正式支持邮箱/网址、线上隐私政策网址、最终名称及商业化确认仍需用户提供。当前实现为无广告无内购。
- 中国大陆发行资质前置问题延续原文档状态，尚未解决。完成开发和模拟器测试不等同于能够提交或通过审核；未执行发布操作。
- 关卡节奏与 15 种升级还需真实玩家试玩；当前差异主要来自目标组合、格子解锁和升级选择。
