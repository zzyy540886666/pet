import { router } from '@kit.ArkUI';
import { PetActionMenu } from '../common/components/PetActionMenu';
import { PetSprite } from '../common/components/PetSprite';
import { PetStatusBar } from '../common/components/PetStatusBar';
import { PetModel } from '../common/models/PetModel';
import { InteractionService } from '../common/services/InteractionService';
import { PetLifecycleService } from '../common/services/PetLifecycleService';
import { EnvironmentSnapshot, PetSensorService } from '../common/services/PetSensorService';

interface SideActionItem {
  label: string;
  icon: Resource;
  kind: 'action' | 'route' | 'sheet';
  action?: 'interact' | 'train' | 'bath' | 'sleep';
  route?: string;
  sheet?: 'feed' | 'play';
}

interface FeedSheetOption {
  id: string;
  label: string;
  quantity: number;
}

interface PlaySheetOption {
  id: string;
  label: string;
  duration: number;
}

@Entry
@Component
struct Index {
  @StorageLink('currentPet') pet: PetModel = new PetModel('\u5c0f\u9ec4\u9e2d', '\u5ba0\u7269', $r('app.media.pet_duck_full'), 'duck_default');
  @State backBtnScale: number = 1;
  @State envTip: string = '';
  @State envVisible: boolean = false;
  @State snapshot: EnvironmentSnapshot = PetSensorService.getLatest();
  @State sideRailExpanded: boolean = true;
  @State feedSheetVisible: boolean = false;
  @State playSheetVisible: boolean = false;
  @State actionSheetOffsetY: number = 96;
  @State selectedFeedId: string = 'fish_meal';
  @State selectedPlayId: string = 'ball';
  private readonly sideActionItems: SideActionItem[] = [
    { label: '摸摸', icon: $r('app.media.ic_side_pet'), kind: 'action', action: 'interact' },
    { label: '喂食', icon: $r('app.media.ic_side_feed'), kind: 'sheet', sheet: 'feed' },
    { label: '玩耍', icon: $r('app.media.ic_side_play'), kind: 'sheet', sheet: 'play' },
    { label: '训练', icon: $r('app.media.ic_side_train'), kind: 'action', action: 'train' },
    { label: '洗澡', icon: $r('app.media.ic_side_bath'), kind: 'action', action: 'bath' },
    { label: '休息', icon: $r('app.media.ic_side_sleep'), kind: 'action', action: 'sleep' }
  ];
  private readonly feedOptions: FeedSheetOption[] = [
    { id: 'fish_meal', label: '鲜鱼餐', quantity: 1 },
    { id: 'grain_snack', label: '谷物点心', quantity: 1 },
    { id: 'vitamin_mix', label: '营养拼盘', quantity: 2 }
  ];
  private readonly playOptions: PlaySheetOption[] = [
    { id: 'ball', label: '弹力球', duration: 20_000 },
    { id: 'rope', label: '拉力绳', duration: 28_000 },
    { id: 'bubble', label: '泡泡追逐', duration: 35_000 }
  ];

  private decayTimerId: number = -1;
  private envTimerId: number = -1;

  aboutToAppear(): void {
    if (this.pet.modelPath === 'burmese_bull.glb') {
      this.pet.name = '\u5c0f\u9ec4\u9e2d';
      this.pet.type = '\u5ba0\u7269';
      this.pet.image = $r('app.media.pet_duck_full');
      this.pet.modelPath = 'duck_default';
      this.pet.currentSpeech = '\u6211\u662f\u4e00\u53ea\u5b8c\u6574\u7684\u5c0f\u9ec4\u9e2d';
    }

    this.applyDecayAndEmotion();
    this.refreshEnvironment();

    this.decayTimerId = setInterval(() => {
      this.applyDecayAndEmotion();
    }, 30_000);

    this.envTimerId = setInterval(() => {
      this.refreshEnvironment();
    }, 18_000);
  }

  aboutToDisappear(): void {
    if (this.decayTimerId >= 0) {
      clearInterval(this.decayTimerId);
      this.decayTimerId = -1;
    }
    if (this.envTimerId >= 0) {
      clearInterval(this.envTimerId);
      this.envTimerId = -1;
    }
  }

  private applyDecayAndEmotion(): void {
    PetLifecycleService.applyNaturalDecay(this.pet);
    if (this.pet.emotion === '困倦' && this.pet.currentAction !== 'sleep') {
      this.pet.currentSpeech = '我有点困了，想靠着你休息一下';
    }
    if (this.pet.emotion === '兴奋') {
      this.pet.currentSpeech = '今天状态超好，我们来玩点新的吧';
    }
  }

  private refreshEnvironment(): void {
    this.snapshot = PetSensorService.sample();
    this.envTip = PetSensorService.applyEnvironmentImpact(this.pet, this.snapshot);
    this.envVisible = true;
    setTimeout(() => {
      this.envVisible = false;
    }, 2600);
  }

  @Builder
  private SideActionRail() {
    Column({ space: 10 }) {
      this.SideRailToggleButton();

      if (this.sideRailExpanded) {
        ForEach(this.sideActionItems, (item: SideActionItem) => {
          this.SideActionButton(item);
        }, (item: SideActionItem) => item.label);
      }
    }
    .padding({ top: 12, bottom: 12, left: 10, right: 10 })
    .backgroundColor('rgba(6, 33, 55, 0.9)')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(143, 217, 239, 0.36)' })
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
    .animation({ duration: 180, curve: Curve.EaseInOut });
  }

  @Builder
  private SideRailToggleButton() {
    Text(this.sideRailExpanded ? '收起' : '展开')
      .fontSize(11)
      .fontColor('#FFFFFF')
      .width(52)
      .height(28)
      .textAlign(TextAlign.Center)
      .backgroundColor('rgba(8, 148, 189, 0.30)')
      .borderRadius(10)
      .onClick(() => {
        this.sideRailExpanded = !this.sideRailExpanded;
      })
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.94 });
  }

  @Builder
  private SideActionButton(item: SideActionItem) {
    Column({ space: 4 }) {
      Image(item.icon)
        .width(22)
        .height(22);

      Text(item.label)
        .fontSize(11)
        .fontColor('#FFFFFF');
    }
    .width(52)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor('rgba(8, 148, 189, 0.18)')
    .borderRadius(12)
    .onClick(() => {
      this.handleSideAction(item);
    })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.94 });
  }

  private handleSideAction(item: SideActionItem): void {
    if (item.kind === 'sheet' && item.sheet) {
      this.openActionSheet(item.sheet);
      return;
    }

    if (item.kind === 'route' && item.route) {
      router.pushUrl({ url: item.route });
      return;
    }

    if (item.kind === 'action' && item.action) {
      void this.runSideAction(item.action);
    }
  }

  private openActionSheet(sheet: 'feed' | 'play'): void {
    this.actionSheetOffsetY = 96;
    if (sheet === 'feed') {
      this.playSheetVisible = false;
      this.feedSheetVisible = true;
    } else {
      this.feedSheetVisible = false;
      this.playSheetVisible = true;
    }
    setTimeout(() => {
      this.actionSheetOffsetY = 0;
    }, 16);
  }

  private closeActionSheet(): void {
    if (!this.feedSheetVisible && !this.playSheetVisible) {
      return;
    }
    this.actionSheetOffsetY = 96;
    setTimeout(() => {
      this.feedSheetVisible = false;
      this.playSheetVisible = false;
    }, 180);
  }

  private async runSideAction(action: 'interact' | 'train' | 'bath' | 'sleep'): Promise<void> {
    const service: InteractionService = InteractionService.getInstance();
    if (action === 'interact') {
      await service.pet(this.pet);
      return;
    }
    if (action === 'sleep') {
      await service.sleep(this.pet);
      return;
    }
    if (action === 'bath') {
      await service.bath(this.pet);
      return;
    }
    await service.train(this.pet, 'sit');
  }

  private isFeedSelected(id: string): boolean {
    return this.selectedFeedId === id;
  }

  private isPlaySelected(id: string): boolean {
    return this.selectedPlayId === id;
  }

  private async confirmFeedAction(): Promise<void> {
    const selected: FeedSheetOption | undefined = this.feedOptions.find((item: FeedSheetOption) => item.id === this.selectedFeedId);
    if (!selected) {
      return;
    }
    await InteractionService.getInstance().feed(this.pet, { foodId: selected.id, quantity: selected.quantity });
    this.closeActionSheet();
  }

  private async confirmPlayAction(): Promise<void> {
    const selected: PlaySheetOption | undefined = this.playOptions.find((item: PlaySheetOption) => item.id === this.selectedPlayId);
    if (!selected) {
      return;
    }
    await InteractionService.getInstance().play(this.pet, { toyId: selected.id, duration: selected.duration });
    this.closeActionSheet();
  }

  @Builder
  private FeedActionSheet() {
    Column({ space: 10 }) {
      Row() {
        Text('喂食选择')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF');
        Blank();
        Text('收起')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.72)')
          .onClick(() => {
            this.closeActionSheet();
          })
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 });
      }
      .width('100%');

      ForEach(this.feedOptions, (item: FeedSheetOption) => {
        Row() {
          Row({ space: 8 }) {
            Image($r('app.media.ic_side_feed'))
              .width(16)
              .height(16);
            Text(item.label)
              .fontSize(13)
              .fontColor('#FFFFFF');
          }
          Blank();
          Text(this.isFeedSelected(item.id) ? '已选中' : '选择')
            .fontSize(12)
            .fontColor(this.isFeedSelected(item.id) ? '#8FD9EF' : 'rgba(255,255,255,0.62)');
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(this.isFeedSelected(item.id) ? 'rgba(8,148,189,0.22)' : 'rgba(255,255,255,0.08)')
        .borderRadius(12)
        .onClick(() => {
          this.selectedFeedId = item.id;
        })
        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 });
      }, (item: FeedSheetOption) => item.id);

      Button('确认喂食')
        .type(ButtonType.Normal)
        .width('100%')
        .height(42)
        .backgroundColor('#0894BD')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .borderRadius(12)
        .onClick(() => {
          void this.confirmFeedAction();
        });
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(6, 33, 55, 0.95)')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(143,217,239,0.30)' })
    .translate({ y: this.actionSheetOffsetY })
    .animation({ duration: 180, curve: Curve.EaseOut });
  }

  @Builder
  private PlayActionSheet() {
    Column({ space: 10 }) {
      Row() {
        Text('玩耍选择')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF');
        Blank();
        Text('收起')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.72)')
          .onClick(() => {
            this.closeActionSheet();
          })
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 });
      }
      .width('100%');

      ForEach(this.playOptions, (item: PlaySheetOption) => {
        Row() {
          Row({ space: 8 }) {
            Image($r('app.media.ic_side_play'))
              .width(16)
              .height(16);
            Text(item.label)
              .fontSize(13)
              .fontColor('#FFFFFF');
          }
          Blank();
          Text(this.isPlaySelected(item.id) ? '已选中' : '选择')
            .fontSize(12)
            .fontColor(this.isPlaySelected(item.id) ? '#8FD9EF' : 'rgba(255,255,255,0.62)');
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(this.isPlaySelected(item.id) ? 'rgba(8,148,189,0.22)' : 'rgba(255,255,255,0.08)')
        .borderRadius(12)
        .onClick(() => {
          this.selectedPlayId = item.id;
        })
        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 });
      }, (item: PlaySheetOption) => item.id);

      Button('确认玩耍')
        .type(ButtonType.Normal)
        .width('100%')
        .height(42)
        .backgroundColor('#0894BD')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .borderRadius(12)
        .onClick(() => {
          void this.confirmPlayAction();
        });
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(6, 33, 55, 0.95)')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(143,217,239,0.30)' })
    .translate({ y: this.actionSheetOffsetY })
    .animation({ duration: 180, curve: Curve.EaseOut });
  }

  @Builder
  private BackgroundLayer() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['#08283C', 0],
            ['#0B3246', 0.45],
            ['#102C3B', 1]
          ]
        });

      Circle({ width: 320, height: 320 })
        .fill('rgba(8, 148, 189, 0.22)')
        .position({ x: -80, y: -120 });

      Circle({ width: 260, height: 260 })
        .fill('rgba(255, 255, 255, 0.08)')
        .position({ x: 230, y: 120 });

      Circle({ width: 420, height: 420 })
        .fill('rgba(8, 148, 189, 0.12)')
        .position({ x: 120, y: 520 });

      Ellipse()
        .width(280)
        .height(80)
        .fill('rgba(255, 255, 255, 0.08)')
        .position({ x: 40, y: 520 });

      Row({ space: 10 }) {
        Circle({ width: 8, height: 8 }).fill('rgba(255,255,255,0.28)')
        Circle({ width: 6, height: 6 }).fill('rgba(255,255,255,0.18)')
        Circle({ width: 4, height: 4 }).fill('rgba(255,255,255,0.12)')
      }
      .position({ x: 36, y: 220 });

      Row({ space: 12 }) {
        Circle({ width: 6, height: 6 }).fill('rgba(255,255,255,0.2)')
        Circle({ width: 9, height: 9 }).fill('rgba(8,148,189,0.35)')
        Circle({ width: 6, height: 6 }).fill('rgba(255,255,255,0.16)')
      }
      .position({ x: 280, y: 260 });
    }
    .width('100%')
    .height('100%');
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      this.BackgroundLayer();

      Column() {
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

          Blank();

          Text(`舒适度 ${this.snapshot.comfortScore}%`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(8, 148, 189, 0.45)')
            .borderRadius(14);
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .zIndex(20);

        PetStatusBar({ attributes: this.pet.attributes });

        if (this.envVisible) {
          Text(this.envTip)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('rgba(12, 31, 44, 0.84)')
            .borderRadius(12)
            .margin({ left: 16, right: 16, bottom: 6 })
            .animation({ duration: 220, curve: Curve.EaseInOut });
        }

        PetSprite({ pet: this.pet });

        PetActionMenu({ pet: this.pet })
          .zIndex(20);
      }
      .width('100%')
      .height('100%');

      Row() {
        this.SideActionRail();
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ right: 12 })
      .margin({ top: 172 })
      .zIndex(30);

      if (this.feedSheetVisible || this.playSheetVisible) {
        Column() {
          Column()
            .layoutWeight(1)
            .width('100%')
            .onClick(() => {
              this.closeActionSheet();
            });

          if (this.feedSheetVisible) {
            this.FeedActionSheet();
          }

          if (this.playSheetVisible) {
            this.PlayActionSheet();
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ left: 12, right: 12, bottom: 108 })
        .zIndex(40);
      }
    }
    .width('100%')
    .height('100%');
  }
}
