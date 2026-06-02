# 项目对话与开发规则

1. 前后端联动开发
2. 采用模块化设计，每个模块负责特定的功能，模块之间通过接口进行通信。
3. 遵循开源鸿蒙的最佳开发实践（ArkTS 严格模式, Stage 模型, API 12+）。
4. 严禁使用 any 类型，严禁使用废弃的布局方式。
5. 必须正确使用状态管理修饰符（@State, @Prop, @Link, @Provide 等）。
6. bug修复采取生成级别的代码，确保修复效果持久。
7. UI 设计规范：
   - 栅格系统：以 8vp 为基准。
   - 间距：使用合适的 padding (12vp/16vp) 和 margin。
   - 圆角与阴影：容器使用 borderRadius(16) 和轻微 shadow。
   - 配色：主色调 $r('sys.color.ohos_id_color_emphasize')，背景使用浅灰色背景区分层次。
   - 交互反馈：点击项必须包含缩放效果或颜色反馈。
8. UI 设计不要有过多的容器。
9. 不要有 emoji 图标，全部采用极简的统一风格 svg 图标。
10. 页面不要有英文，全部采用中文。
11. 遇到 HarmonyOS NEXT、ArkTS、ArkUI、Stage 模型、UI 设计或代码审查中的不确定问题时，先查看并学习核心参考资料：
   - HarmonyOS AI Skill (DengShiyingA)：https://github.com/DengShiyingA/harmonyos-ai-skill
   - HarmonyOS Skills (CoreyLyn)：https://github.com/CoreyLyn/harmonyos-skills
   - Awesome HarmonyOS NEXT：https://github.com/harmonyos-dev/awesome-harmonyos-next

## 可用技能索引（.claude/skills/）

### 鸿蒙专属（项目自有）
- `harmonyos-expert`：鸿蒙高级开发与 UI 设计基线
- `harmonyos-25d-expert`：2.5D 宠物表现、ArkUI 动效与交互架构

### 通用工程能力（来自 [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)，已转为 Cursor Skill 格式）
- 核心开发：`ui-designer`（视觉规范）、`mobile-developer`（移动端通用模式）、`api-designer`（前后端接口架构）
- 质量与安全：`code-reviewer`（代码审查）、`debugger`（调试根因）、`architect-reviewer`（架构审查）、`performance-engineer`（性能优化）、`error-detective`（错误聚类）、`accessibility-tester`（无障碍）
- 开发者体验：`refactoring-specialist`（重构）、`documentation-engineer`（技术文档）
- 元/编排：`agent-organizer`（多技能协同编排）

### 协同建议
- 鸿蒙特定问题（ArkTS/ArkUI/Stage/2.5D）优先 `harmonyos-expert` / `harmonyos-25d-expert`
- 通用工程问题（审查/重构/性能/文档）优先对应通用技能，再由鸿蒙技能做平台落地
- 复杂任务（跨多技能）由 `agent-organizer` 拆解、串联与汇总
