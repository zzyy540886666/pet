---
name: "harmonyos-2.5d-pet"
description: "提供 HarmonyOS 2.5D（伪3D）虚拟宠物的最佳实践和代码规范。Invoke when user asks to implement 2.5D rendering, Lottie animations, or pseudo-3D effects."
---

# HarmonyOS 2.5D 虚拟宠物开发指南

本技能包基于华为官方开发指南、`DengShiyingA/harmonyos-ai-skill`、`CoreyLyn/harmonyos-skills` 的性能与体验标准，提供将 3D 渲染降级为 2.5D 互动方案的技术规范。

## 适用场景 (When to Use)
- 模拟器/低端机不支持 `Component3D` / `SceneView` (WebGL/OpenGL 错误、黑屏)。
- 需要使用 `@ohos/lottie` 进行高质量骨骼矢量动画渲染。
- 需要通过 ArkUI `Stack` 结合手势 (`PanGesture`, `PinchGesture`) 实现视差景深（Parallax）与 2.5D 伪 3D 旋转。

## 1. 架构与选型
- **禁用 `SceneView`**: 废弃复杂的 `.glb` PBR 渲染引擎。
- **推荐方案**: 
  - 方案 A: Lottie 矢量动画 (`@ohos/lottie`) - 性能最佳。
  - 方案 B: 预渲染序列帧 (`ImageAnimator`) - 保真度最高。
  - 方案 C: 分层 Image 配合属性动画（`rotate`, `translate`） - 兼容性最好。

## 2. 2.5D 交互实现规范 (ArkUI)
### 视差分层 (Parallax Layers)
必须使用 `Stack` 容器将背景、阴影、宠物、前景分离。
```arkts
Stack() {
  // Layer 1: 阴影层
  Ellipse().opacity(0.2).translate({ y: this.shadowOffsetY })
  
  // Layer 2: 宠物层 (绑定缩放和旋转)
  Image(this.pet.image)
    .scale({ x: this.petScale, y: this.petScale })
    .rotate({ x: 0, y: 1, z: 0, angle: this.petRotationY })
    
  // Layer 3: 前景交互UI
  Bubble().translate({ x: this.bubbleOffsetX, y: this.bubbleOffsetY })
}
```

### 手势绑定 (Gesture Group)
绑定 `GestureGroup(GestureMode.Parallel)`。滑动屏幕时，修改 `petRotationY`（需限制在 -30 到 30 度防穿帮），捏合修改 `petScale`。

## 3. 性能优化 (Performance Best Practices)
- **避免内存泄漏**: Lottie 组件在销毁时 (`aboutToDisappear`) 必须调用 `lottie.destroy()`。
- **回弹动画**: 松手后的回弹应当使用 `.animation({ curve: Curve.SpringMotion })`。
- **节流控制**: 手势的 `event.offsetX` 应除以适当系数（如 10）避免过度跳帧。
- **RenderGroup**: 对高频重绘的复杂动画层使用 `.renderGroup(true)` 开启离屏绘制缓存。

## 4. UI 规范检查 (Review Checklist)
- [ ] 不使用 `any`，严格类型声明。
- [ ] 使用了 `$r('sys.color.*')` 系统级颜色，或 UI 规范深色 `#081e2a`。
- [ ] 点击交互必须包含缩小反馈 (`.scale({x:0.95, y:0.95})`)。
- [ ] 组件的圆角遵循 8vp 栅格（如 `borderRadius(16)`）。
