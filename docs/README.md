# 幸运小岛 · 开发资料

整理日期：2026-09-16。当前采用单人转盘游戏方案，娱乐类互动小岛留作备用。布局确定采用 UIKit + SnapKit，通过 CocoaPods 引入。

| 资料 | 文件 |
|---|---|
| 产品方案 | [01-product-plan.md](01-product-plan.md) |
| 原型说明 | [02-prototype-guide.md](02-prototype-guide.md) |
| 视觉原型 | [lucky-island-visual-v1.png](prototypes/lucky-island-visual-v1.png) |
| 可交互原型 | [lucky-island-interactive-v1.html](prototypes/lucky-island-interactive-v1.html) |
| 技术方案 | [03-technical-plan.md](03-technical-plan.md) |

先看产品方案，再体验原型，最后按技术方案进入实现。源片段保存在 prototypes/lucky-island-source-v1.html，独立 HTML 可直接在浏览器打开。

范围说明：本轮仅整理文件并导出原型；没有改动现有 Xcode 工程、安装 Pods 或执行 iOS 应用构建。SnapKit 计划固定 5.7.1（6.0 已移除 CocoaPods 支持）。中国大陆发行资质路径仍待解决，不与技术实现完成混为一谈。

## 原生实现

原生应用已接入当前工程，使用 `Veltranomixa.xcworkspace` 开发。实现范围、运行方法和实测限制见 [实现与验证](04-implementation-and-validation.md)。上方“本轮仅整理文件”描述的是最初资料整理阶段。
