# IoT感知南向模块 — 模块设计文档

> **模块名称**: IoT感知南向模块 (IoT Sensing Module - South)  
> **所属项目**: 鸿蒙虚拟数字宠物 (HarmoPet)  
> **模块版本**: v1.0  
> **更新日期**: 2026-04-15  
> **硬件平台**: Hi3863 星闪开发板 + E53传感器扩展模块（OpenHarmony轻量系统）

---

## 1. 模块概述

### 1.1 模块定位

IoT感知南向模块是 HarmoPet 的**环境感知与交互反馈终端**，运行于 Hi3863 星闪开发板上。通过 E53 传感器模块采集环境数据、检测用户活动，并通过星闪(SparkLink)无线通信与北向应用协同，为虚拟宠物赋予对真实世界的感知能力。

### 1.2 模块职责

| 职责 | 说明 |
|------|------|
| 环境数据采集 | 温湿度/光照/加速度等多传感器实时采集 |
| 活动检测 | 用户靠近/离开/设备晃动/静止等事件检测 |
| 星闪通信 | 与北向端建立稳定无线连接，上报数据/接收指令 |
| 设备联动控制 | 蜂鸣器/LED/OLED/振动马达的本地反馈 |
| 健康预警 | 环境异常检测与分级预警通知 |
| 低功耗管理 | 根据活动状态动态调整功耗策略 |

### 1.3 硬件平台配置

```
Hi3863星闪开发板（OpenHarmony轻量系统 / LiteOS-M）
├── 主控芯片: Hi3863V100 (ARM Cortex-M4, 160MHz)
├── 通信模块: 星闪 (SparkLink) 无线通信
├── 传感器接口: E53接口标准
├── 电源管理: USB供电 / 电池供电
└── 存储资源: 352KB SRAM + 288KB ROM
```

#### E53传感器模块清单

| 模块 | 型号 | 功能 | 对宠物系统的作用 |
|------|------|------|------------------|
| 温湿度传感器 | AHT20 | 环境温湿度检测 | 环境舒适度计算 → 影响宠物心情/健康 |
| 人体红外传感器 | AS312 | 用户靠近/离开检测 | 触发欢迎/等待行为 |
| 三轴加速度计 | LIS3DH | 设备振动/晃动检测 | 互动反馈、活动量统计 |
| 光照传感器 | AP3216C | 环境光照强度检测 | 昼夜判断、睡眠触发 |
| OLED显示屏 | SSD1306 | 0.96寸屏幕显示 | 南向端显示宠物状态 |
| LED灯 | WS2812 | RGB彩灯 | 表情/状态可视化 |
| 蜂鸣器 | 无源蜂鸣器 | 发声反馈 | 宠物声音模拟 |
| 振动马达 | 1027震动马达 | 振动反馈 | 互动触感 |

### 1.4 依赖关系

```
IoT感知南向模块 (Hi3863 / OpenHarmony LiteOS-M)
├── 依赖: E53传感器硬件 (AHT20/AS312/LIS3DH/AP3216C等)
├── 依赖: 星闪通信协议栈
├── 数据上报 → 北向全息端 (SC-3568HA) 或 手机端
├── 接收指令 ← 北向下发控制指令
└── 被依赖: 核心宠物模块 (环境数据影响属性/情绪)
```

> ⚠️ **赛题合规**：南向主控运行 OpenHarmony 操作系统（LiteOS-M），符合"南向部分主控必须采用OpenHarmony操作系统"要求。

---

## 2. 环境感知子系统

### 2.1 功能描述

通过多种传感器持续采集环境数据，计算环境舒适度指数，并将数据上报北向用于影响宠物状态。

#### 采集项定义

| 采集项 | 传感器型号 | 采样频率 | 数据格式 | 单位 |
|--------|-----------|----------|----------|------|
| 温度 | AHT20 | 1Hz | `{temp: 26.5}` | °C |
| 湿度 | AHT20 | 1Hz | `{humidity: 58}` | %RH |
| 光照强度 | AP3216C | 0.5Hz | `{light: 250}` | lux |
| 三轴加速度 | LIS3DH | 10Hz | `{x:0.02, y:0.01, z:0.98}` | g |

#### 环境状态映射规则

```typescript
// 文件路径: 南向端 env_classifier.c / 或北向端 EnvClassifier.ets

interface EnvState {
  temperature: number;    // °C
  humidity: number;       // %
  lightLevel: number;     // lux
  comfortScore: number;   // 舒适度 0-100
  comfortLevel: 'excellent' | 'good' | 'poor' | 'severe';
}

/** 舒适度计算模型 */
function calculateComfortScore(temp: number, humidity: number): number {
  // 公式: 舒适度 = 100 - |温度-25|×2 - |湿度-55|×0.5
  return Math.max(0, 100 - Math.abs(temp - 25) * 2 - Math.abs(humidity - 55) * 0.5);
}

/** 环境状态判定规则 */
const ENV_RULES = [
  { condition: (s) => s.temp > 40 || s.temp < 5,
    level: 'severe',    moodDelta: -10, healthDelta: -5 },
  { condition: (s) => s.temp > 35 || s.temp < 10 || s.humidity > 85 || s.humidity < 25,
    level: 'poor',      moodDelta: -5,  healthDelta: -3 },
  { condition: (s) => s.comfortScore >= 60 && s.comfortScore < 80,
    level: 'good',      moodDelta: 0,   healthDelta: 0 },
  { condition: (s) => s.comfortScore >= 80,
    level: 'excellent', moodDelta: +5,  healthDelta: 0 },
];
```

#### 舒适度分级标准

| 分级 | 舒适度范围 | 宠物感受 | 属性影响 | MVP |
|------|-----------|---------|----------|-----|
| 优秀 | 80-100 | 非常舒适 | 心情自然恢复+5/h | P0 |
| 良好 | 60-79 | 一般 | 无影响 | P0 |
| 较差 | 40-59 | 不适 | 心情-3/h 健康-2/h | P1 |
| 恶劣 | 0-39 | 很难受 | 心情-8/h 健康-5/h | P1 |

### 2.2 接口定义

#### 传感器数据上报消息

```json
{
  "msg_type": "sensor_data",
  "timestamp": 1681234567890,
  "device_id": "hi3863_001",
  "data": {
    "temp": 26.5,
    "humidity": 58,
    "light": 250,
    "accel_x": 0.02,
    "accel_y": 0.01,
    "accel_z": 0.98,
    "comfort_score": 82,
    "comfort_level": "excellent"
  }
}
```

#### 北向环境数据处理接口

```typescript
// 文件路径: services/EnvSensorService.ets

export interface SensorDataPayload {
  msg_type: 'sensor_data';
  timestamp: number;
  device_id: string;
  data: {
    temp: number;
    humidity: number;
    light: number;
    accel_x: number;
    accel_y: number;
    accel_z: number;
    comfort_score: number;
    comfort_level: string;
  };
}

export class EnvSensorService {
  private static instance: EnvSensorService;
  
  public static getInstance(): EnvSensorService
  
  /** 处理南向上报的传感器数据 */
  processSensorData(payload: SensorDataPayload): void
  
  /** 获取最新环境状态 */
  getCurrentEnvState(): EnvState
  
  /** 监听环境变化事件 */
  onEnvStateChange(): Observable<EnvState>
  
  /** 获取历史传感器数据（用于图表展示） */
  getSensorHistory(hours?: number): Promise<SensorDataPayload[]>
}
```

### 2.3 参数说明

| 参数名 | 类型 | 单位 | 范围 | 说明 |
|--------|------|------|------|------|
| `temp` | float | °C | -40~80 | 环境温度 |
| `humidity` | float | %RH | 0~100 | 相对湿度 |
| `light` | integer | lux | 0~65535 | 光照强度 |
| `accel_x/y/z` | float | g | ±16g | 三轴加速度值 |
| `comfort_score` | integer | - | 0~100 | 舒适度计算结果 |

---

## 3. 活动检测子系统

### 3.1 功能描述

利用红外和加速度传感器检测用户与设备的交互行为，生成结构化事件并上报北向驱动宠物行为响应。

#### 检测项目定义

| 检测项 | 传感器 | 检测算法 | 上报条件 | MVP优先级 |
|--------|--------|----------|----------|-----------|
| 用户靠近 | AS312人体红外 | 电平触发(高电平=有人) | 检测到人体→立即上报 | **P0** |
| 用户离开 | AS312人体红外 | 超时判断(低电平持续N秒) | 无信号>30秒→上报 | **P0** |
| 设备晃动 | LIS3DH加速度计 | 加速度突变(滑动窗口方差) | 方差>阈值→上报 | P1 |
| 设备静止 | LIS3DH加速度计 | 长时无振动判断 | 无振动>10分钟→上报 | P2 |
| 环境振动 | LIS3DH加速度计 | 持续振动检测 | 振动强度>设定值→上报 | P2 |

#### 活动量统计模型

```c
// 文件路径: Hi3863南向端 activity_tracker.c

/**
 * 活动量 = Σ(|加速度变化量|) × 时间权重
 * 
 * 用途：
 * - 统计用户与设备互动频率和强度
 * - 映射到宠物"运动量"属性
 * - 影响精力消耗和心情变化
 * - 生成每日活动报告
 */

typedef struct {
    float total_activity;      // 累计活动量
    float peak_intensity;      // 峰值强度
    uint32_t active_seconds;   // 活跃时长(秒)
    uint32_t still_seconds;    // 静止时长(秒)
} ActivityReport;

ActivityReport calculate_daily_activity(
    const accel_sample_t* samples, 
    uint32_t sample_count,
    uint32_t window_ms
);
```

### 3.2 接口定义

#### 事件上报消息格式

```json
{
  "msg_type": "event",
  "timestamp": 1681234567890,
  "device_id": "hi3863_001",
  "event": {
    "type": "user_approach",
    "data": {
      "duration": 0
    }
  }
}
```

#### 支持的事件类型

| 事件类型(event.type) | data结构 | 说明 |
|---------------------|----------|------|
| `user_approach` | `{duration: 0}` | 用户靠近 |
| `user_leave` | `{duration: 30}` | 用户离开(持续时间秒) |
| `device_shake` | `{intensity: 0.8}` | 设备被晃动(强度0~1) |
| `device_stillness` | `{duration: 600}` | 设备静止(持续秒数) |
| `vibration_detected` | `{intensity: 0.5}` | 环境振动 |

#### 北向活动事件处理接口

```typescript
// 文件路径: services/ActivityEventService.ets

export type EventType = 
  | 'user_approach'
  | 'user_leave'
  | 'device_shake'
  | 'device_stillness'
  | 'vibration_detected';

export interface EventPayload {
  msg_type: 'event';
  timestamp: number;
  device_id: string;
  event: {
    type: EventType;
    data: Record<string, number>;
  };
}

export class ActivityEventService {
  private static instance: ActivityEventService;
  
  public static getInstance(): ActivityEventService
  
  /** 处理南向上报的活动事件 */
  processEvent(payload: EventPayload): void
  
  /** 获取今日活动统计 */
  getTodayActivityReport(): Promise<ActivityReport>
  
  /** 监听活动事件 */
  onActivityEvent(): Observable<EventPayload>
}
```

### 3.3 参数说明

| 参数名 | 类型 | 范围 | 说明 |
|--------|------|------|------|
| `type` | string | 见上表 | 事件类型标识 |
| `duration` | integer | ≥0 | 持续时间(秒) |
| `intensity` | float | 0.0~1.0 | 强度归一化值 |

---

## 4. 星闪通信子系统

### 4.1 功能描述

星闪通信子系统负责Hi3863南向端与北向应用之间的可靠数据传输，包括传感器数据上报、事件通知、控制指令下发和心跳保活。

#### 通信架构

```
┌─────────────┐         星闪无线 (2.4GHz, 低功耗)         ┌─────────────┐
│  Hi3863     │◄───────────────────────────────────────→│  北向应用    │
│  南向端      │                                         │ (手机/开发板)│
└─────────────┘                                         └─────────────┘
     │                                                        │
     ├─ sensor_data 传感器数据上报                              ├─ 数据处理与存储
     ├─ event        事件通知                                  ├─ 宠物状态更新
     └─ heartbeat    心跳保活                                  └─ command 控制指令下发
```

#### 通信协议消息类型总览

| msg_type | 方向 | 说明 | 频率 |
|----------|------|------|------|
| `sensor_data` | 南→北 | 传感器数据批量上报 | 1Hz |
| `event` | 南→北 | 活动/异常事件通知 | 事件驱动 |
| `heartbeat` | 南→北 | 心跳保活包 | 10s |
| `command` | 北→南 | 控制指令下发 | 事件驱动 |
| `config` | 北→南 | 配置参数下发 | 手动触发 |

#### 心跳机制参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 心跳间隔 | 10秒 | 南向定期发送心跳 |
| 超时阈值 | 30秒 | 连续3次未响应判定离线 |
| 重连间隔 | 5秒 | 离线后尝试重连 |
| 最大重连次数 | 无限 | 持续尝试直到成功 |

### 4.2 控制指令接口定义

#### 控制指令消息格式

```json
{
  "msg_type": "command",
  "timestamp": 1681234567890,
  "cmd": "buzzer",
  "params": {
    "freq": 2000,
    "duration": 500
  }
}
```

#### 指令集定义

| cmd标识 | params | 功能说明 | MVP |
|--------|--------|----------|-----|
| `buzzer` | `{freq: Hz, duration: ms}` | 控制蜂鸣器发声(模拟叫声) | **P0** |
| `led` | `{pattern: string, color: string, speed: ms}` | 控制LED灯显示表情/状态 | **P0** |
| `oled` | `{text?: string, icon?: string, x?, y?}` | 在OLED显示文本或图标 | P1 |
| `motor` | `{intensity: 0-1, duration: ms}` | 控制振动马达 | P2 |
| `sensor_config` | `{sample_rate?: Hz, threshold?: float}` | 配置传感器采样参数 | P1 |

#### LED pattern模式列表

| pattern | color | 含义 | MVP |
|---------|-------|------|-----|
| `normal` | green | 正常状态常亮 | P0 |
| `happy` | rainbow | 开心渐变 | P1 |
| `alert` | yellow | 预警慢闪 | P0 |
| `alarm` | red | 报警快闪 | P1 |
| `sleep` | blue | 睡眠呼吸灯 | P1 |
| `interactive` | purple | 互动脉冲 | P1 |

#### 北向南向通信服务接口

```typescript
// 文件路径: services/SouthDeviceService.ets

export interface CommandParams {
  [key: string]: string | number | boolean;
}

export interface SouthCommand {
  cmd: string;
  params: CommandParams;
  expectAck?: boolean;           // 是否需要确认回复
  timeoutMs?: number;            // 超时时间(ms)，默认3000
}

export class SouthDeviceService {
  private static instance: SouthDeviceService;
  
  public static getInstance(): SouthDeviceService
  
  // ---------- 连接管理 ----------
  /** 尝试连接南向设备 */
  async connect(deviceId?: string): Promise<boolean>
  /** 断开连接 */
  disconnect(): void
  /** 获取连接状态 */
  isConnected(): boolean
  
  // ---------- 指令发送 ----------
  /** 发送控制指令 */
  async sendCommand(command: SouthCommand): Promise<boolean>
  
  /** 便捷方法：蜂鸣器发声 */
  async buzzer(freq: number, duration: number): Promise<boolean>
  
  /** 便捷方法：设置LED */
  async led(pattern: string, color?: string, speed?: number): Promise<boolean>
  
  // ---------- 数据监听 ----------
  /** 监听南向上报的数据流 */
  onSensorData(): Observable<SensorDataPayload>
  /** 监听南向上报的事件流 */
  onEvent(): Observable<EventPayload>
  /** 监听连接状态变化 */
  onConnectionChange(): Observable<'connected' | 'disconnected' | 'timeout'>
}
```

### 4.3 参数说明

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `cmd` | string | **是** | - | 指令标识符 |
| `freq` | integer | 条件需 | - | 频率(Hz)，用于buzzer |
| `duration` | integer | 条件需 | `500` | 持续时间(ms) |
| `pattern` | string | 条件需 | `"normal"` | LED显示模式 |
| `color` | string | 否 | `"green"` | LED颜色 |
| `speed` | integer | 否 | `1000` | 闪烁速度(ms) |
| `expectAck` | boolean | 否 | `false` | 是否等待确认回复 |

---

## 5. 设备联动子系统

### 5.1 功能描述

设备联动子系统将南向感知事件与北向宠物行为进行映射绑定，实现"传感器→宠物反应→反馈执行"的完整闭环链路。

#### 南向→北向事件映射表

| 南向事件 | 数据结构 | 宠物属性影响 | 北向UI响应 | MVP |
|----------|----------|-------------|-----------|-----|
| 环境异常 | `{type:"env_alert", level, temp, humidity}` | 心情-5~-10, 健康-3~-5 | 弹出预警通知 | P1 |
| 用户靠近 | `{type:"user_approach", duration:0}` | 心情+5 | 宠物欢迎动画 | **P0** |
| 用户离开 | `{type:"user_leave", duration:30}` | 心情-3 | 宠物失落动画 | **P0** |
| 设备晃动 | `{type:"device_shake", intensity:0.8}` | 无 | 宠物晕了/玩闹动画 | P1 |
| 环境舒适 | `{type:"env_comfort", score:85}` | 心情+5/h | 状态面板更新 | P1 |
| 活动量统计 | `{type:"activity_report", value:1250}` | 更新运动属性 | 档案记录 | P2 |

#### 北向→南向控制映射表

| 北向操作 | 下发指令 | 南向执行效果 | MVP |
|----------|----------|-------------|-----|
| 宠物欢迎 | `buzzer(freq:2000, dur:200)` + `led("happy")` | 喵叫+彩虹灯 | **P0** |
| 环境预警 | `led("alarm")` + `buzzer(freq:1500, dur:1000)` | 红灯快闪+警报声 | P1 |
| 宠物睡觉 | `led("sleep")` | 蓝色呼吸灯 | P1 |
| 互动中 | `led("interactive")` | 紫色脉冲灯 | P1 |

#### 联动场景示例：用户靠近 → 宠物欢迎完整链路

```
1. Hi3863: AS312红外检测到高电平(有人靠近)
2. Hi3863: 构造事件 {type:"user_approach"} → 星闪上报
3. SC-3568HA/手机: 收到事件 → ActivityEventService处理
4. 北向: 更新宠物情绪 → 心情+5 → 切换"欢迎"动作
5. 北向: 下发控制指令 → buzzer(2000,200) + led("happy")
6. Hi3863: 蜂鸣器发出喵叫音效
7. Hi3863: LED切换彩虹渐变模式
8. Hi3863: OLED显示 "主人回来啦！"
```

### 5.2 接口定义

```typescript
// 文件路径: services/DeviceLinkageService.ets

export interface LinkageRule {
  id: string;
  name: string;
  triggerEvent: EventType;          // 触发事件
  conditions?: Record<string, any>; // 附加条件
  petActions: string[];             // 宠物行为列表
  southCommands: SouthCommand[];    // 南向控制指令列表
  enabled: boolean;                 // 是否启用
  priority: number;                 // 规则优先级
}

export class DeviceLinkageService {
  private static instance: DeviceLinkageService;
  
  public static getInstance(): DeviceLinkageService
  
  /**
   * 执行联动规则匹配与执行
   * @param event 南向上报的事件
   */
  executeLinkage(event: EventPayload): Promise<void>
  
  /** 注册自定义联动规则 */
  registerRule(rule: LinkageRule): void
  
  /** 移除联动规则 */
  removeRule(ruleId: string): void
  
  /** 获取所有已注册规则 */
  getRules(): LinkageRule[]
}
```

---

## 6. 健康预警子系统

### 6.1 功能描述

当环境参数超出安全范围时，自动触发分级预警，同时在南向端（LED/蜂鸣器）和北向端（弹窗/通知）同步发出告警。

#### 预警分级体系

| 级别 | 名称 | 触发条件 | 南向响应 | 北向响应 | MVP |
|------|------|----------|----------|---------|-----|
| Level 1 | 提醒 | 环境轻微偏离舒适区 | LED黄灯慢闪 | 弹出Toast提示 | **P0** |
| Level 2 | 警告 | 环境持续异常>10分钟 | LED红灯快闪+蜂鸣短鸣 | 弹窗警告+宠物不适动画 | P1 |
| Level 3 | 紧急 | 温度>40°C或<5°C | LED红灯急闪+蜂鸣长鸣+OLED全屏警告 | 强提醒弹窗+建议措施 | P1 |

#### 预警解除条件

| 级别 | 解除条件 |
|------|----------|
| 提醒(L1) | 环境恢复正常范围 → 自动解除 |
| 警告(L2) | 环境恢复正常且持续5分钟 → 自动解除 |
| 紧急(L3) | 需要用户手动确认 + 环境恢复正常 |

### 6.2 接口定义

```typescript
// 文件路径: services/AlertService.ets

export type AlertLevel = 1 | 2 | 3;

export interface AlertRecord {
  alertId: string;
  level: AlertLevel;
  type: 'temperature' | 'humidity' | 'light' | 'multi';
  message: string;
  value: number;              // 触发时的实际值
  threshold: number;          // 阈值
  timestamp: number;          // 触发时间
  resolvedAt?: number;        // 解除时间
  resolvedBy?: 'auto' | 'manual'; // 解除方式
}

export class AlertService {
  private static instance: AlertService;
  
  public static getInstance(): AlertService
  
  /** 检查环境数据是否触发预警 */
  checkAndTrigger(envData: SensorDataPayload): Promise<AlertRecord | null>
  
  /** 手动解除预警（L3级别必须手动） */
  manualResolve(alertId: string): Promise<void>
  
  /** 获取当前活跃预警 */
  getActiveAlerts(): AlertRecord[]
  
  /** 获取预警历史记录 */
  getAlertHistory(limit?: number): Promise<AlertRecord[]>
  
  /** 监听新预警事件 */
  onNewAlert(): Observable<AlertRecord>
  
  /** 监听预警解除事件 */
  onAlertResolved(): Observable<AlertRecord>
}
```

### 6.3 参数说明

| 参数名 | type | 说明 |
|--------|------|------|
| `level` | 1\|2\|3 | 预警等级 |
| `type` | string | 预警来源: temperature/humidity/light/multi |
| `value` | number | 触发时的实际测量值 |
| `threshold` | number | 触发阈值 |

---

## 7. 南向软件开发架构

### 7.1 软件分层

```
┌─────────────────────────────────────┐
│      应用层 (Application)            │
│  ├── 传感器管理模块                   │
│  ├── 星闪通信模块                     │
│  ├── 本地显示模块 (OLED/LED)          │
│  └── 预警处理模块                     │
├─────────────────────────────────────┤
│      中间件层 (Middleware)           │
│  ├── 数据滤波与融合                   │
│  ├── 事件检测算法                     │
│  └── 心跳与重连机制                   │
├─────────────────────────────────────┤
│      驱动层 (Driver)                 │
│  ├── AHT20温湿度驱动                 │
│  ├── AS312红外驱动                   │
│  ├── LIS3DH加速度驱动                │
│  ├── AP3216C光照驱动                 │
│  ├── SSD1306 OLED驱动                │
│  ├── WS2812 LED驱动                  │
│  └── 星闪通信驱动                     │
├─────────────────────────────────────┤
│      系统层 (OpenHarmony LiteOS-M)   │
│  ├── 任务调度                         │
│  ├── 内存管理                         │
│  └── 设备管理                         │
└─────────────────────────────────────┘
```

### 7.2 任务划分

| 任务名 | 优先级 | 周期 | 功能说明 | MVP |
|--------|--------|------|----------|-----|
| sensor_task | 高 | 100ms | 读取所有传感器原始数据 | **P0** |
| process_task | 中 | 500ms | 数据滤波、舒适度计算、事件检测 | **P0** |
| comm_task | 高 | 事件驱动 | 星闪收发消息 | **P0** |
| display_task | 低 | 1s | 更新OLED屏幕和LED显示 | P1 |
| heartbeat_task | 低 | 10s | 维持心跳保活 | **P0** |

### 7.3 低功耗策略

```
正常运行模式:
├── CPU频率: 160MHz
├── 采样频率: 标准频率 (见上文任务划分)
└── 通信频率: 实时上报

低功耗模式 (无互动 > 5分钟):
├── CPU频率: 80MHz (降频)
├── 采样频率: 降低50%
└── 通信频率: 仅保留心跳

休眠模式 (夜间 或 无互动 > 30分钟):
├── CPU: 休眠, 中断唤醒
├── 采样: 仅AS312红外传感器工作
└── 通信: 被动唤醒

唤醒条件:
├── AS312检测到用户靠近
├── 收到北向下发控制指令
├── 环境异常 (高温/低温)
└── 定时唤醒 (每小时一次, 同步状态)
```

---

## 8. 南向端本地显示

### 8.1 OLED显示布局

```
┌──────────────────┐
│ 🐱 HarmoPet      │  ← 标题栏
│ ❤️85 😊90 ⚡70    │  ← 宠物属性(北向下发)
├──────────────────┤
│ 温度: 26.5°C     │  ← 环境数据
│ 湿度: 58%        │
│ 舒适度: 82       │
├──────────────────┤
│ 状态: 舒适 ✓      │  ← 状态提示
│ 💬 主人在吗？     │  ← 宠物气泡(可选)
└──────────────────┘
```

### 8.2 LED表情模式

详见第4.2节的LED pattern模式列表。

---

## 9. MVP最小可用版本清单

### 9.1 Phase 4 IoT-MVP 核心功能

> 注意：IoT模块属于Phase 4开发内容。MVP版本在无硬件时使用**模拟数据降级**运行。

| 功能点 | 子项 | 优先级 | 有硬件实现 | 无硬件降级方案 |
|--------|------|--------|-----------|---------------|
| **星闪通信基础** | 连接/心跳/断线重连 | **P0** | 实际星闪通信 | N/A（此模块整体不可用） |
| **温湿度采集** | AHT20读取+上报 | **P0** | 实际读取传感器 | 模拟随机数据 |
| **人体红外检测** | AS312靠近/离开事件 | **P0** | 实际红外检测 | 模拟定时事件 |
| **环境舒适度计算** | score计算+等级判定 | **P0** | 使用真实数据 | 使用模拟数据 |
| **蜂鸣器控制** | 下发buzzer指令 | **P0** | 蜂鸣器发声 | 日志输出 |
| **LED控制** | 下发led指令 | **P0** | LED亮灭 | 日志输出 |
| **基础预警** | L1提醒级预警 | **P0** | LED黄灯闪烁 | UI Toast提示 |
| **OLED显示** | 显示宠物状态 | P1 | OLED文字显示 | 跳过 |

### 9.2 无硬件时的完整降级方案

```typescript
// 文件路径: services/MockSouthDeviceService.ets
// 当未检测到南向设备时，自动启用Mock服务

export class MockSouthDeviceService extends SouthDeviceService {
  // 模拟传感器数据（正弦波+随机噪声）
  protected generateMockSensorData(): SensorDataPayload {
    return {
      msg_type: 'sensor_data',
      timestamp: Date.now(),
      device_id: 'mock_device',
      data: {
        temp: 25 + Math.sin(Date.now() / 60000) * 3 + (Math.random() - 0.5),
        humidity: 55 + Math.random() * 10,
        light: 200 + Math.random() * 100,
        accel_x: 0, accel_y: 0, accel_z: 1,
        comfort_score: 80,
        comfort_level: 'good',
      },
    };
  }

  // 模拟定时用户靠近/离开事件
  protected startMockEvents(): void {
    setInterval(() => {
      this.emit('event', { /* mock user_approach */ });
      setTimeout(() => {
        this.emit('event', { /* mock user_leave after 60s */ });
      }, 60000);
    }, 120000);  // 每2分钟循环一次
  }
}
```

---

## 10. 文件结构

```
south_device/                             # Hi3863 南向工程 (OpenHarmony LiteOS-M)
├── applications/
│   └── HarmoPet_South/
│       ├── main.c                       # 应用入口
│       ├── src/
│       │   ├── app_task.c               # 主任务调度
│       │   ├── sensor_manager.c         # 传感器管理
│       │   ├── env_processor.c          # 环境数据处理
│       │   ├── activity_detector.c      # 活动检测算法
│       │   ├── sparklink_comm.c         # 星闪通信
│       │   ├── local_display.c          # 本地显示(OLED/LED)
│       │   ├── buzzer_ctrl.c            # 蜂鸣器控制
│       │   ├── motor_ctrl.c             # 马达控制
│       │   ├── alert_handler.c          # 预警处理器
│       │   └── power_manager.c          # 低功耗管理
│       └── inc/
│           └── harmopet_south.h
├── drivers/                             # HDF驱动适配
│   ├── aht20/
│   ├── as312/
│   ├── lis3dh/
│   ├── ap3216c/
│   ├── ssd1306/
│   ├── ws2812/
│   └── sparklink/
└── build.gradle

entry/src/main/ets/                        # ArkTS 北向客户端对应服务
├── services/
│   ├── SouthDeviceService.ets            # 南向设备通信总服务
│   ├── MockSouthDeviceService.ets        # Mock降级服务
│   ├── EnvSensorService.ets              # 环境数据处理
│   ├── ActivityEventService.ets          # 活动事件处理
│   ├── DeviceLinkageService.ets          # 设备联动规则引擎
│   └── AlertService.ets                  # 健康预警服务
└── pages/
    └── SensorPage.ets                    # 传感器数据面板页
```
