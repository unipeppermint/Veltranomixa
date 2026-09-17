# 幸运小岛 · 技术方案

版本：V1.0｜整理日期：2026-09-16｜状态：实施方案，尚未实现游戏

## 1. 技术决策

Swift + UIKit，使用 CocoaPods 导入 SnapKit 编写 Auto Layout。SnapKit 为用户明确指定的依赖，其余能力优先使用系统框架。

| 模块 | 技术 |
|---|---|
| 界面与导航 | UIKit，程序化创建业务界面 |
| 约束 | SnapKit 5.7.1，通过 CocoaPods 集成 |
| 转盘 | Core Graphics / CAShapeLayer + Core Animation |
| 岛屿 | 分层位图、UIView/CALayer 与轻量动画 |
| 音效 | AVFoundation |
| 触感 | UIKit feedback generators |
| 数据 | Codable、JSON、Application Support |
| 测试 | XCTest / XCUITest，真机及 TestFlight |

不使用 WebView 承载正式游戏，不引入 Unity 或真实 3D 引擎。HTML 只作为交互参考。

## 2. 当前工程事实

整理时已存在 Veltranomixa.xcodeproj 和 UIKit 模板，包括 AppDelegate、SceneDelegate、ViewController、Main.storyboard 和 LaunchScreen.storyboard。与前次讨论时的空目录状态不同，应在此工程上继续开发。

- Target：Veltranomixa。
- Target 部署版本：iOS 16.0；项目级默认值为 26.5，后续核验最终生效的构建设置。
- Swift 语言模式：5.0。
- iPhone 方向为竖屏，工程另有 iPad 横竖屏配置；支持设备范围开发时核对，不在整理文档时修改。
- 本机前次环境查询：Xcode 26.6、iPhoneOS SDK 26.5。
- 本轮仅整理资料，不改工程、Bundle ID、签名团队及发布配置，不声称已构建通过。

## 3. CocoaPods 与 SnapKit

SnapKit 6.0 官方发布说明移除了 CocoaPods 支持。遵循用户要求，固定使用提供 Podspec 的 5.7.1，不自动升级到 6.x，也不擅自切换 Swift Package Manager。

计划 Podfile（实际接入时创建）：

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '16.0'

use_frameworks! :linkage => :static

target 'Veltranomixa' do
  pod 'SnapKit', '5.7.1'
end
```

接入步骤：核对 CocoaPods/Ruby 环境 → 建立 Podfile → 执行 pod install → 使用生成的 Veltranomixa.xcworkspace 开发与构建。提交 Podfile 和 Podfile.lock；CocoaPods 工具版本在首次成功安装后通过 Gemfile/Gemfile.lock 固定。常规还原使用 pod install，不用 pod update 自动升级。保留 SnapKit MIT 许可信息，核对归档内隐私清单资源。

本次不执行依赖安装；5.7.1 与本机工具链的实际兼容性以首次构建为准。

### 约束规范

- 页面、按钮、弹层等 UIView 几何关系统一通过 SnapKit 描述。
- 使用 safeAreaLayoutGuide；makeConstraints 建立初始约束，updateConstraints 更新常量，布局关系变化才 remakeConstraints。
- 保留必要的 Constraint 引用，不在每次状态渲染中叠加约束。
- 转盘维持正方形、按可用宽度缩放；小屏与较大文字时允许页面内容合理滚动。
- CALayer 的 frame/path 在 layoutSubviews 根据最终 bounds 计算；SnapKit 不直接约束 CALayer。
- 程序化界面接入时同步处理 SceneDelegate 与 Main storyboard 的入口；保留启动屏，避免重复创建根控制器。

## 4. 架构与模块

采用轻量 MVVM + 独立规则引擎，不为首版引入额外响应式框架。

| 模块 | 职责 |
|---|---|
| Features/Island | 首页与建设场景 |
| Features/Game | 对局页、WheelView、资源条、升级面板 |
| Features/Collection、Settings | 收藏与偏好设置 |
| Domain | GameEngine、GameState、奖励及升级规则 |
| Data | 配置加载、SaveRepository、存档迁移 |
| Services | AudioService、HapticService、生命周期处理 |
| Resources | Assets、配置、文案、音频、隐私清单 |

页面处理展示和输入；ViewModel 映射状态与操作；GameEngine 执行确定性的状态转换。随机源通过协议注入，生产用系统随机数，测试用固定序列。规则层不依赖 UIKit、SnapKit 或动画。

主要模型：LevelConfig、WheelSegment、UpgradeDefinition、RunState、PlayerProgress、SpinRecord、SaveEnvelope。配置与存档均带版本，实体使用稳定 ID，避免以展示名称作为关联键。

## 5. 对局状态机与转盘

状态：ready → spinning → revealing → choosingUpgrade / ready / completed / failed。后台恢复以持久化状态为依据。等待动画或存档提交期间禁止新的转动和改造。

一次转动作为一次原子状态变更：

1. 验证操作是否合法，读取当前局状态。
2. 从 8 个格子均匀抽取结果，计算资源、次数和下一逻辑阶段。
3. 生成唯一 spinID，把新状态与待展示结果放在同一个存档快照中写入。
4. 写入成功后发布状态并播放动画；失败时不进入动画，保留原状态并允许重试。
5. 动画只展示已确定结果，不再次增加奖励。
6. 展示完成后清除待展示标记。若中途退出，恢复快照并展示或跳过动画，不重抽、不重复发奖。

使用串行存档通道，避免旧快照覆盖新状态；升级、改造和关卡完成也沿用原子变更方式。进入后台不是唯一保存时机。

按目标格中心角计算最终停点，增加若干完整圈并使用减速曲线。先更新 model layer 的最终状态，再添加动画，避免结束时回弹。指针与中奖高亮使用统一角度定义。首次教学如使用脚本结果，应与正式随机模式明确分开。

## 6. 素材与性能

岛屿分为海面、地形、建筑、植物、前景和灯光层。建筑具有施工与完成素材。正式资源放入 Asset Catalog，按实际显示大小控制分辨率与透明区域；原型合成图仅作参考，不能直接充当可交互页面。

资源飞行和灯光使用 Core Animation；避免每帧重新生成转盘路径。声音按需预加载；切后台暂停环境音和非必要动画。关闭触感、静音及系统减弱动态效果均需处理。普通交互以稳定 60 fps 为性能目标，最终以目标真机测量为准。

## 7. 配置与存档

关卡、格子、升级和建筑配置随安装包提供，不使用远程配置。启动校验 ID、引用关系、资源路径、概率和数值范围；配置错误应有可诊断信息及安全回退。

Application Support 保存 Codable JSON：长期进度、当前局、设置和待展示结果在版本化快照内保持一致。采用原子文件替换和上一份有效备份；加载时做字段及范围校验，再迁移版本，不能解析时尝试备份并向用户说明恢复结果。

首版无账号及云同步。正常升级保留存档；删除 App 可能丢失数据。清空进度需应用内二次确认。

## 8. 质量验证

- 规则：基础奖励、先加后乘、双倍消耗与非叠加、工具叠加、金币不足、最后一转升级与胜负优先级。
- 随机：固定源覆盖所有格子；抽样分布作为诊断，不用易波动的概率断言阻塞常规构建。
- 恢复：抽取后、写入后、动画中、升级前后、结算前后的中断；同一 spinID 不重复发奖。
- 存档：损坏、旧版本、备份回退、磁盘写入失败和并发写入顺序。
- UI：完整一局、连续点击、返回继续、VoiceOver 标签、安全区域、大文字、小屏。
- 工程：Pod 安装、模拟器 Debug 构建与测试；Release 编译、签名归档和真机验证按相应阶段进行。
- 性能：动画流畅、内存、热量和较长时间连续游玩。

## 9. 发布与隐私

首版不接入广告、分析 SDK、账号或后台服务。根据实际使用 API 填写 PrivacyInfo.xcprivacy，核对 SnapKit 资源、隐私标签、许可及支持网址。签名、Bundle ID、发布地区与发行资质独立确认。技术方案不代表已满足中国大陆发行资质。

## 10. 实施阶段

1. 在现有工程接入 CocoaPods/SnapKit，搭建原生页面和一个灯塔关卡。
2. 完成素材、音效触感、存档与生命周期恢复。
3. 扩展关卡和收藏，运行数值模拟并结合试玩调整。
4. 真机、TestFlight、归档与上架资料核验。

## 参考

- [SnapKit 官方发布记录：6.0 移除 CocoaPods、5.7.1 隐私资源支持](https://github.com/SnapKit/SnapKit/releases)
- [SnapKit 5.7.1 Podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/1/f/6/SnapKit/5.7.1/SnapKit.podspec.json)
- [UIKit](https://developer.apple.com/documentation/uikit)
- [Core Animation](https://developer.apple.com/documentation/quartzcore)
- [Codable](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)
- [隐私清单](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
