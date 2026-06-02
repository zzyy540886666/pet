/**
 * 公共常量类，定义 UI 规范和业务限制
 */
export class CommonConstants {
  /**
   * 栅格系统基准 (8vp)
   */
  static readonly GRID_BASE: number = 8;

  /**
   * 默认间距
   */
  static readonly SPACE_12: number = 12;
  static readonly SPACE_16: number = 16;
  static readonly SPACE_24: number = 24;

  /**
   * 默认圆角
   */
  static readonly BORDER_RADIUS_16: number = 16;

  /**
   * 动画配置
   */
  static readonly CLICK_SCALE: number = 0.95;

  /**
   * 颜色常量 (建议优先使用 $r('sys.color.*'))
   */
  static readonly THEME_COLOR: string = '#007DFF';
  static readonly BACKGROUND_LIGHT_GRAY: string = '#F1F3F5';
}
