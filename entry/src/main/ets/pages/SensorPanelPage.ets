import { router } from '@kit.ArkUI';
import { EnvironmentSnapshot, PetSensorService } from '../common/services/PetSensorService';
import { PetModel } from '../common/models/PetModel';

@Entry
@Component
struct SensorPanelPage {
  @StorageLink('currentPet') pet: PetModel = new PetModel('小橘', '宠物', $r('app.media.pet_duck_full'), 'duck_default');
  @State backBtnScale: number = 1;
  @State refreshBtnScale: number = 1;
  @State snapshot: EnvironmentSnapshot = PetSensorService.getLatest();
  @State impactText: string = '';

  aboutToAppear(): void {
    this.refreshSnapshot();
  }

  private formatTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '暂无';
    }
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  private refreshSnapshot(): void {
    this.snapshot = PetSensorService.sample();
    this.impactText = PetSensorService.applyEnvironmentImpact(this.pet, this.snapshot);
  }

  @Builder
  private DataCard(title: string, value: string, status: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.72)');
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF');
      Text(status)
        .fontSize(12)
        .fontColor('#8FD9EF');
    }
    .width('48%')
    .padding(16)
    .backgroundColor('#2A3641')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#12000000', offsetX: 0, offsetY: 4 });
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
          .scale({ x: this.backBtnScale, y: this.backBtnScale })
          .animation({ duration: 150 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.backBtnScale = 0.9;
            }
            if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.backBtnScale = 1;
            }
          })
          .onClick(() => {
            router.back();
          });

        Text('环境与感知')
          .layoutWeight(1)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .margin({ right: 24 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 });

      Row() {
        Text('南向设备：模拟在线')
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.82)');
        Blank();
        Text(`最近采样：${this.formatTime(this.snapshot.timestamp)}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.68)');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 2 });

      Row({ space: 10 }) {
        this.DataCard('温度', `${this.snapshot.temperature}°C`, this.snapshot.temperature > 35 ? '偏热' : '正常')
        this.DataCard('湿度', `${this.snapshot.humidity}%`, this.snapshot.humidity > 80 ? '偏潮' : '适宜')
      }
      .width('100%')
      .padding({ left: 16, right: 16 });

      Row({ space: 10 }) {
        this.DataCard('光照', `${this.snapshot.light} lux`, this.snapshot.light < 100 ? '偏暗' : '可用')
        this.DataCard('舒适度', `${this.snapshot.comfortScore}%`, this.snapshot.comfortScore >= 80 ? '舒适' : '需关注')
      }
      .width('100%')
      .padding({ left: 16, right: 16 });

      Column({ space: 6 }) {
        Text(`活动状态：${this.snapshot.activityLevel}`)
          .fontSize(14)
          .fontColor('#FFFFFF');
        Text(`红外感知：${this.snapshot.infraredDetected ? '检测到靠近' : '未检测到靠近'}`)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.78)');
        Text(this.snapshot.statusText)
          .fontSize(13)
          .fontColor('#8FD9EF');
        Text(`宠物状态：${this.pet.emotion}｜成长阶段：${this.pet.growthStage}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.72)');
        if (this.impactText.length > 0) {
          Text(`属性影响：${this.impactText}`)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.72)');
        }
      }
      .width('100%')
      .padding(16)
      .margin({ left: 16, right: 16, top: 4 })
      .backgroundColor('#31404D')
      .borderRadius(16);

      Button('刷新环境数据')
        .width('88%')
        .height(48)
        .backgroundColor('#0894BD')
        .fontColor('#FFFFFF')
        .fontSize(15)
        .borderRadius(14)
        .scale({ x: this.refreshBtnScale, y: this.refreshBtnScale })
        .animation({ duration: 150 })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.refreshBtnScale = 0.95;
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.refreshBtnScale = 1;
          }
        })
        .onClick(() => {
          this.refreshSnapshot();
        })
        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 });

      Blank();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#081E2A');
  }
}
