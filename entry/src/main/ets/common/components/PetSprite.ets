import { CommonConstants } from '../constants/CommonConstants';
import { PetActionType, PetModel } from '../models/PetModel';
import { PetActionService, PetMotionProfile } from '../services/PetActionService';
import { InteractionService } from '../services/InteractionService';
import { PetStageAssetResolver, PetStageVisual } from '../services/PetStageAssetResolver';
import { PetCuteVoiceService, PetTouchBodyPart, PetTouchReactionPlan } from '../services/PetCuteVoiceService';
import { PetTtsService } from '../services/PetTtsService';

interface ActionSequenceFrame {
  duration: number;
  motionOffsetYExtra: number;
  bodyScaleXExtra: number;
  bodyScaleYExtra: number;
  actionRotateYExtra: number;
  tiltZExtra: number;
  auraScaleExtra: number;
  auraOpacityExtra: number;
  shadowScaleXExtra: number;
  shadowScaleYExtra: number;
  accentOffsetX: number;
  accentOffsetY: number;
  accentScale: number;
  accentOpacity: number;
}

@Component
export struct PetSprite {
  @ObjectLink pet: PetModel;

  @State petRotationY: number = 0;
  @State interactionScale: number = 1;
  @State floatOffsetY: number = -10;
  @State bodyScaleX: number = 1.02;
  @State bodyScaleY: number = 1.03;
  @State actionRotateY: number = 0;
  @State tiltZ: number = -1;
  @State auraScale: number = 1.04;
  @State auraOpacity: number = 0.18;
  @State shadowScaleX: number = 0.98;
  @State shadowScaleY: number = 0.92;
  @State bodyOpacity: number = 1;
  @State effectOpacity: number = 0.12;
  @State effectOffsetY: number = -8;
  @State motionDuration: number = 1800;
  @State motionOffsetYExtra: number = 0;
  @State bodyScaleXExtra: number = 0;
  @State bodyScaleYExtra: number = 0;
  @State actionRotateYExtra: number = 0;
  @State tiltZExtra: number = 0;
  @State auraScaleExtra: number = 0;
  @State auraOpacityExtra: number = 0;
  @State shadowScaleXExtra: number = 0;
  @State shadowScaleYExtra: number = 0;
  @State accentOffsetX: number = 0;
  @State accentOffsetY: number = 0;
  @State accentScale: number = 1;
  @State accentOpacity: number = 0;

  private lastResolvedAction: PetActionType = 'idle';
  private actionLoopId: number = -1;
  private actionStepIndex: number = 0;
  private isTouchReacting: boolean = false;
  private readonly cuteVoiceService: PetCuteVoiceService = PetCuteVoiceService.getInstance();
  private readonly ttsService: PetTtsService = PetTtsService.getInstance();
  private lastSpokenActionVersion: number = 0;
  private lastSpokenSpeech: string = '';

  aboutToAppear(): void {
    this.lastResolvedAction = this.pet.currentAction;
    this.lastSpokenActionVersion = this.pet.actionVersion;
    this.lastSpokenSpeech = this.pet.currentSpeech.trim();
    this.ttsService.ensureEngine();
    this.applyMotionProfile(this.pet.currentAction);
    this.startActionLoop(this.pet.currentAction);
  }

  aboutToDisappear(): void {
    this.stopActionLoop();
    this.ttsService.stop();
  }

  private resolveVisual(): PetStageVisual {
    return PetStageAssetResolver.resolve(this.pet);
  }

  private syncActionProfile(): void {
    if (this.lastResolvedAction === this.pet.currentAction) {
      return;
    }

    this.lastResolvedAction = this.pet.currentAction;
    this.applyMotionProfile(this.pet.currentAction);
    this.startActionLoop(this.pet.currentAction);
  }

  private applyMotionProfile(action: PetActionType): void {
    const profile: PetMotionProfile = PetActionService.resolveMotion(action);
    this.floatOffsetY = profile.floatOffsetY;
    this.bodyScaleX = profile.scaleX;
    this.bodyScaleY = profile.scaleY;
    this.actionRotateY = profile.rotateY;
    this.tiltZ = profile.tiltZ;
    this.auraScale = profile.auraScale;
    this.auraOpacity = profile.auraOpacity;
    this.shadowScaleX = profile.shadowScaleX;
    this.shadowScaleY = profile.shadowScaleY;
    this.bodyOpacity = profile.bodyOpacity;
    this.effectOpacity = profile.effectOpacity;
    this.effectOffsetY = profile.effectOffset;
    this.motionDuration = profile.animationDuration;
    this.resetActionAccents();
  }

  private async handleTouchByBodyPart(bodyPart: PetTouchBodyPart | undefined): Promise<void> {
    if (this.isTouchReacting) {
      return;
    }
    this.isTouchReacting = true;
    this.interactionScale = 0.95;
    try {
      this.pet.currentSpeech = '哈哈，好痒啊';
      const plan: PetTouchReactionPlan = bodyPart
        ? this.cuteVoiceService.buildTouchReactionByBodyPart(this.pet, bodyPart)
        : this.cuteVoiceService.buildRandomTouchReaction(this.pet);
      void this.applyTouchReaction(plan);
    } finally {
      setTimeout(() => {
        this.interactionScale = 1;
      }, 180);
      this.isTouchReacting = false;
    }
  }

  private handlePetImageTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Down) {
      return;
    }
    void this.handleTouchByBodyPart(undefined);
  }

  private async applyTouchReaction(plan: PetTouchReactionPlan): Promise<void> {
    const service: InteractionService = InteractionService.getInstance();
    if (plan.actionType === 'speak') {
      return;
    }
    if (plan.actionType === 'play') {
      await service.play(this.pet, { toyId: plan.toyId, duration: 22_000 });
      return;
    }
    if (plan.actionType === 'train') {
      await service.train(this.pet, plan.commandId);
      return;
    }
    if (plan.actionType === 'chat') {
      await service.chat(this.pet, plan.promptText);
      return;
    }
    await service.pet(this.pet);
  }

  private resetActionAccents(): void {
    this.motionOffsetYExtra = 0;
    this.bodyScaleXExtra = 0;
    this.bodyScaleYExtra = 0;
    this.actionRotateYExtra = 0;
    this.tiltZExtra = 0;
    this.auraScaleExtra = 0;
    this.auraOpacityExtra = 0;
    this.shadowScaleXExtra = 0;
    this.shadowScaleYExtra = 0;
    this.accentOffsetX = 0;
    this.accentOffsetY = 0;
    this.accentScale = 1;
    this.accentOpacity = 0;
  }

  private stopActionLoop(): void {
    if (this.actionLoopId >= 0) {
      clearTimeout(this.actionLoopId);
      this.actionLoopId = -1;
    }
  }

  private startActionLoop(action: PetActionType): void {
    this.stopActionLoop();
    this.actionStepIndex = 0;
    this.resetActionAccents();
    const sequence: ActionSequenceFrame[] = this.resolveActionSequence(action);
    this.scheduleNextActionFrame(action, sequence);
  }

  private scheduleNextActionFrame(action: PetActionType, sequence: ActionSequenceFrame[]): void {
    if (sequence.length === 0) {
      return;
    }

    const frame: ActionSequenceFrame = sequence[this.actionStepIndex % sequence.length];
    this.applySequenceFrame(frame);
    this.actionLoopId = setTimeout(() => {
      if (this.pet.currentAction !== action) {
        return;
      }

      this.actionStepIndex = (this.actionStepIndex + 1) % sequence.length;
      this.scheduleNextActionFrame(action, sequence);
    }, frame.duration);
  }

  private applySequenceFrame(frame: ActionSequenceFrame): void {
    this.motionDuration = frame.duration;
    this.motionOffsetYExtra = frame.motionOffsetYExtra;
    this.bodyScaleXExtra = frame.bodyScaleXExtra;
    this.bodyScaleYExtra = frame.bodyScaleYExtra;
    this.actionRotateYExtra = frame.actionRotateYExtra;
    this.tiltZExtra = frame.tiltZExtra;
    this.auraScaleExtra = frame.auraScaleExtra;
    this.auraOpacityExtra = frame.auraOpacityExtra;
    this.shadowScaleXExtra = frame.shadowScaleXExtra;
    this.shadowScaleYExtra = frame.shadowScaleYExtra;
    this.accentOffsetX = frame.accentOffsetX;
    this.accentOffsetY = frame.accentOffsetY;
    this.accentScale = frame.accentScale;
    this.accentOpacity = frame.accentOpacity;
  }

  private resolveActionSequence(action: PetActionType): ActionSequenceFrame[] {
    switch (action) {
      case 'interact':
        return [
          this.createFrame(220, -12, 0.03, 0.03, 6, 2, 0.06, 0.05, 0.02, -0.02, 16, -24, 1.12, 0.3),
          this.createFrame(260, -2, 0.01, 0.01, 0, -1, 0.03, 0.03, 0.00, 0.00, 12, -12, 0.98, 0.24),
          this.createFrame(240, -8, 0.02, 0.02, -4, -2, 0.04, 0.04, -0.01, 0.01, 20, -20, 1.04, 0.28)
        ];
      case 'eat':
        return [
          this.createFrame(180, 8, 0.02, 0.00, -3, -5, 0.02, 0.02, 0.03, -0.03, 18, 30, 0.92, 0.34),
          this.createFrame(260, 1, 0.01, 0.01, 2, 2, 0.03, 0.03, 0.01, -0.01, 6, 18, 1.06, 0.28),
          this.createFrame(320, -7, 0.00, 0.02, 0, -1, 0.05, 0.04, -0.02, 0.02, 2, -8, 1.04, 0.22)
        ];
      case 'chat':
        return [
          this.createFrame(240, -4, 0.01, 0.01, 7, -5, 0.03, 0.04, 0, 0, 18, -18, 0.96, 0.30),
          this.createFrame(220, 10, 0.02, 0.02, 0, 1, 0.04, 0.04, 0.02, -0.02, 28, -6, 1.08, 0.34),
          this.createFrame(240, -5, 0.01, 0.01, -7, 5, 0.03, 0.03, -0.01, 0.01, 20, -20, 0.98, 0.28)
        ];
      case 'sleep':
        return [
          this.createFrame(840, 3, 0.00, 0.02, -1, -3, -0.02, -0.02, -0.03, 0.02, 18, -28, 0.92, 0.20),
          this.createFrame(620, 1, 0.00, 0.01, 0, -2, 0.00, -0.01, -0.02, 0.01, 26, -44, 1.00, 0.24),
          this.createFrame(920, -5, 0.01, 0.00, 1, -1, 0.02, 0.02, 0.02, -0.01, 34, -62, 1.10, 0.18)
        ];
      case 'play':
        return [
          this.createFrame(220, -10, 0.03, 0.03, 4, 4, 0.06, 0.06, 0.04, -0.03, -12, -20, 1.15, 0.28),
          this.createFrame(240, 4, 0.01, 0.01, -3, -3, 0.02, 0.04, -0.02, 0.02, 14, -10, 0.96, 0.22),
          this.createFrame(260, -2, 0.01, 0.01, 2, 2, 0.04, 0.04, 0.01, -0.01, 0, -16, 1.05, 0.24)
        ];
      case 'train':
        return [
          this.createFrame(260, -8, 0.02, 0.03, 2, 1, 0.04, 0.03, 0.01, -0.01, -16, -22, 1.06, 0.24),
          this.createFrame(220, 2, 0.01, 0.01, 6, -2, 0.03, 0.03, 0.00, 0.00, 18, -10, 1.0, 0.26),
          this.createFrame(240, -4, 0.01, 0.02, -3, 2, 0.02, 0.02, -0.01, 0.01, 6, -16, 0.98, 0.22)
        ];
      case 'bath':
        return [
          this.createFrame(240, -4, 0.01, 0.01, -4, -1, 0.03, 0.04, 0.02, -0.02, -20, -12, 1.02, 0.2),
          this.createFrame(280, 6, 0.02, 0.02, 3, 2, 0.05, 0.04, -0.01, 0.02, 20, -24, 1.08, 0.24),
          this.createFrame(260, -3, 0.01, 0.01, 0, -1, 0.03, 0.03, 0.00, 0.00, 8, -14, 1.00, 0.2)
        ];
      case 'idle':
      default:
        return [
          this.createFrame(1200, -2, 0.00, 0.01, 0, -0.6, 0.00, 0.00, -0.015, 0.01, 0, -4, 1.00, 0.08),
          this.createFrame(1200, 2, 0.01, 0.01, 0, 0.6, 0.00, 0.00, 0.015, -0.01, 0, 0, 1.00, 0.08)
        ];
    }
  }

  private createFrame(duration: number, motionOffsetYExtra: number, bodyScaleXExtra: number,
    bodyScaleYExtra: number, actionRotateYExtra: number, tiltZExtra: number, auraScaleExtra: number,
    auraOpacityExtra: number, shadowScaleXExtra: number, shadowScaleYExtra: number, accentOffsetX: number,
    accentOffsetY: number, accentScale: number, accentOpacity: number): ActionSequenceFrame {
    return {
      duration,
      motionOffsetYExtra,
      bodyScaleXExtra,
      bodyScaleYExtra,
      actionRotateYExtra,
      tiltZExtra,
      auraScaleExtra,
      auraOpacityExtra,
      shadowScaleXExtra,
      shadowScaleYExtra,
      accentOffsetX,
      accentOffsetY,
      accentScale,
      accentOpacity
    };
  }

  private resolveBodyScale(): number {
    const baseScale: number = (this.bodyScaleX + this.bodyScaleY) / 2;
    const extraScale: number = (this.bodyScaleXExtra + this.bodyScaleYExtra) / 2;
    const scale: number = (baseScale + extraScale) * this.interactionScale;
    return Math.max(0.96, Math.min(1.08, scale));
  }

  private resolvePetRotateY(): number {
    const rotateY: number = this.petRotationY + this.actionRotateY + this.actionRotateYExtra;
    return Math.max(-12, Math.min(12, rotateY));
  }

  private resolvePetTiltZ(): number {
    const tiltZ: number = this.tiltZ + this.tiltZExtra;
    return Math.max(-5, Math.min(5, tiltZ));
  }

  private shouldUseFrameAnimator(): boolean {
    const modelPath: string = this.pet.modelPath.toLowerCase();
    return modelPath.includes('duck') || modelPath.includes('fox') || modelPath.includes('golden') || modelPath.includes('cat');
  }

  private resolveFramePrefix(): string {
    const modelPath: string = this.pet.modelPath.toLowerCase();
    if (modelPath.includes('fox')) {
      return 'fox';
    }
    if (modelPath.includes('golden')) {
      return 'golden';
    }
    if (modelPath.includes('cat')) {
      return 'cat';
    }
    return 'duck';
  }

  private resolveFrameAction(): PetActionType {
    switch (this.pet.currentAction) {
      case 'eat':
        return 'eat';
      case 'chat':
      case 'play':
      case 'train':
      case 'interact':
        return 'chat';
      case 'sleep':
        return 'sleep';
      case 'bath':
      case 'idle':
      default:
        return 'idle';
    }
  }

  private createAnimatorFrame(src: Resource, duration: number): ImageFrameInfo {
    return {
      src: src,
      duration: duration
    };
  }

  private resolveFrameResource(prefix: string, action: PetActionType, frameIndex: number): Resource {
    if (prefix === 'fox') {
      if (action === 'eat') {
        return frameIndex === 1 ? $r('app.media.fox_eat_01') : (frameIndex === 2 ? $r('app.media.fox_eat_02') : $r('app.media.fox_eat_03'));
      }
      if (action === 'chat') {
        return frameIndex === 1 ? $r('app.media.fox_chat_01') : (frameIndex === 2 ? $r('app.media.fox_chat_02') : $r('app.media.fox_chat_03'));
      }
      if (action === 'sleep') {
        return frameIndex === 1 ? $r('app.media.fox_sleep_01') : (frameIndex === 2 ? $r('app.media.fox_sleep_02') : $r('app.media.fox_sleep_03'));
      }
      return frameIndex === 1 ? $r('app.media.fox_idle_01') : (frameIndex === 2 ? $r('app.media.fox_idle_02') : $r('app.media.fox_idle_03'));
    }

    if (prefix === 'golden') {
      if (action === 'eat') {
        return frameIndex === 1 ? $r('app.media.golden_eat_01') : (frameIndex === 2 ? $r('app.media.golden_eat_02') : $r('app.media.golden_eat_03'));
      }
      if (action === 'chat') {
        return frameIndex === 1 ? $r('app.media.golden_chat_01') : (frameIndex === 2 ? $r('app.media.golden_chat_02') : $r('app.media.golden_chat_03'));
      }
      if (action === 'sleep') {
        return frameIndex === 1 ? $r('app.media.golden_sleep_01') : (frameIndex === 2 ? $r('app.media.golden_sleep_02') : $r('app.media.golden_sleep_03'));
      }
      return frameIndex === 1 ? $r('app.media.golden_idle_01') : (frameIndex === 2 ? $r('app.media.golden_idle_02') : $r('app.media.golden_idle_03'));
    }

    if (prefix === 'cat') {
      if (action === 'eat') {
        return frameIndex === 1 ? $r('app.media.cat_eat_01') : (frameIndex === 2 ? $r('app.media.cat_eat_02') : $r('app.media.cat_eat_03'));
      }
      if (action === 'chat') {
        return frameIndex === 1 ? $r('app.media.cat_chat_01') : (frameIndex === 2 ? $r('app.media.cat_chat_02') : $r('app.media.cat_chat_03'));
      }
      if (action === 'sleep') {
        return frameIndex === 1 ? $r('app.media.cat_sleep_01') : (frameIndex === 2 ? $r('app.media.cat_sleep_02') : $r('app.media.cat_sleep_03'));
      }
      return frameIndex === 1 ? $r('app.media.cat_idle_01') : (frameIndex === 2 ? $r('app.media.cat_idle_02') : $r('app.media.cat_idle_03'));
    }

    return $r('app.media.pet_duck_full');
  }

  private resolvePetFrames(action: PetActionType): ImageFrameInfo[] {
    const prefix: string = this.resolveFramePrefix();
    switch (action) {
      case 'eat':
        return [
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'eat', 1), 180),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'eat', 2), 260),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'eat', 3), 320)
        ];
      case 'chat':
        return [
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'chat', 1), 240),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'chat', 2), 220),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'chat', 3), 240)
        ];
      case 'sleep':
        return [
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'sleep', 1), 840),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'sleep', 2), 620),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'sleep', 3), 920)
        ];
      case 'idle':
      default:
        return [
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'idle', 1), 1300),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'idle', 2), 1300),
          this.createAnimatorFrame(this.resolveFrameResource(prefix, 'idle', 3), 1300)
        ];
    }
  }

  @Builder
  private AnimatedPetBody() {
    if (this.shouldUseFrameAnimator()) {
      ImageAnimator()
        .images(this.resolvePetFrames(this.resolveFrameAction()))
        .state(AnimationStatus.Running)
        .iterations(-1)
        .width(this.resolveVisual().width)
        .height(this.resolveVisual().height)
        .fixedSize(true);
    } else {
      Image(this.resolveVisual().image)
        .width(this.resolveVisual().width)
        .height(this.resolveVisual().height)
        .objectFit(ImageFit.Contain);
    }
  }

  @Builder
  private ActionAccent() {
    if (this.pet.currentAction === 'eat') {
      Row({ space: 4 }) {
        Circle({ width: 8, height: 8 })
          .fill('rgba(255, 255, 255, 0.90)');
        Circle({ width: 12, height: 12 })
          .fill('rgba(8, 148, 189, 0.90)');
      }
      .opacity(this.accentOpacity)
      .scale({ x: this.accentScale, y: this.accentScale })
      .translate({ x: this.accentOffsetX + 42, y: this.accentOffsetY + 36 });
    } else if (this.pet.currentAction === 'chat') {
      Row({ space: 4 }) {
        Circle({ width: 7, height: 7 }).fill('#FFFFFF');
        Circle({ width: 7, height: 7 }).fill('rgba(255, 255, 255, 0.88)');
        Circle({ width: 7, height: 7 }).fill('rgba(8, 148, 189, 0.92)');
      }
      .opacity(this.accentOpacity)
      .scale({ x: this.accentScale, y: this.accentScale })
      .translate({ x: this.accentOffsetX + 20, y: this.accentOffsetY - 52 });
    } else if (this.pet.currentAction === 'sleep') {
      Column({ space: 4 }) {
        Circle({ width: 8, height: 8 }).fill('rgba(255, 255, 255, 0.80)');
        Circle({ width: 10, height: 10 }).fill('rgba(255, 255, 255, 0.64)');
        Circle({ width: 12, height: 12 }).fill('rgba(8, 148, 189, 0.38)');
      }
      .opacity(this.accentOpacity)
      .scale({ x: this.accentScale, y: this.accentScale })
      .translate({ x: this.accentOffsetX + 24, y: this.accentOffsetY - 52 });
    } else if (this.pet.currentAction === 'play') {
      Row({ space: 6 }) {
        Circle({ width: 10, height: 10 }).fill('#FFFFFF');
        Circle({ width: 14, height: 14 }).fill('rgba(8, 148, 189, 0.94)');
      }
      .opacity(this.accentOpacity)
      .scale({ x: this.accentScale, y: this.accentScale })
      .translate({ x: this.accentOffsetX, y: this.accentOffsetY - 72 });
    }
  }

  private syncActionProfileIfNeeded(): string {
    if (this.lastResolvedAction !== this.pet.currentAction) {
      this.lastResolvedAction = this.pet.currentAction;
      this.applyMotionProfile(this.pet.currentAction);
      this.startActionLoop(this.pet.currentAction);
    }

    return '';
  }

  private syncSpeechPlaybackIfNeeded(): string {
    const speechText: string = this.pet.currentSpeech.trim();
    if (speechText.length === 0) {
      this.lastSpokenActionVersion = this.pet.actionVersion;
      this.lastSpokenSpeech = '';
      return '';
    }

    const actionChanged: boolean = this.lastSpokenActionVersion !== this.pet.actionVersion;
    const speechChanged: boolean = this.lastSpokenSpeech !== speechText;
    if (!actionChanged && !speechChanged) {
      return '';
    }

    this.lastSpokenActionVersion = this.pet.actionVersion;
    this.lastSpokenSpeech = speechText;

    this.ttsService.speak(this.pet, speechText);
    return '';
  }

  build() {
    Column() {
      Text(this.syncActionProfileIfNeeded())
        .fontSize(0)
        .opacity(0)
        .width(0)
        .height(0)

      Text(this.syncSpeechPlaybackIfNeeded())
        .fontSize(0)
        .opacity(0)
        .width(0)
        .height(0)

      if (this.pet.currentSpeech.length > 0) {
        Column() {
          Text(this.pet.currentSpeech)
            .fontSize(14)
            .fontColor('#081E2A')
            .padding({
              top: CommonConstants.SPACE_12,
              bottom: CommonConstants.SPACE_12,
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            });
        }
        .backgroundColor('rgba(255, 255, 255, 0.94)')
        .borderRadius(CommonConstants.BORDER_RADIUS_16)
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 4 })
        .margin({ bottom: 18 })
        .translate({ y: (this.floatOffsetY + this.motionOffsetYExtra) * 0.35 })
        .animation({
          duration: this.motionDuration,
          curve: Curve.EaseInOut,
          iterations: 1,
          playMode: PlayMode.Normal
        });
      }

      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 232, height: 232 })
          .fill('rgba(8, 148, 189, 0.16)')
          .opacity(this.auraOpacity + this.auraOpacityExtra)
          .scale({ x: this.auraScale + this.auraScaleExtra, y: this.auraScale + this.auraScaleExtra })
          .translate({ y: -20 })
          .animation({
            duration: this.motionDuration,
            curve: Curve.EaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          });

        Circle({ width: 18, height: 18 })
          .fill('rgba(255, 255, 255, 0.78)')
          .opacity(this.effectOpacity)
          .translate({ x: -84 + this.accentOffsetX * 0.14, y: this.effectOffsetY - 94 + this.accentOffsetY * 0.12 })
          .animation({
            duration: Math.max(180, this.motionDuration - 40),
            curve: Curve.EaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          });

        Circle({ width: 10, height: 10 })
          .fill('rgba(8, 148, 189, 0.92)')
          .opacity(this.effectOpacity)
          .translate({ x: 92 + this.accentOffsetX * 0.1, y: this.effectOffsetY - 56 + this.accentOffsetY * 0.1 })
          .animation({
            duration: Math.max(180, this.motionDuration),
            curve: Curve.EaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          });

        Circle({ width: 12, height: 12 })
          .fill('rgba(255, 255, 255, 0.56)')
          .opacity(this.effectOpacity * 0.9)
          .translate({ x: 18 + this.accentOffsetX * 0.12, y: this.effectOffsetY - 120 + this.accentOffsetY * 0.12 })
          .animation({
            duration: Math.max(180, this.motionDuration + 40),
            curve: Curve.EaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          });

        this.ActionAccent();

        Ellipse()
          .width(this.resolveVisual().shadowWidth)
          .height(30)
          .fill('#000000')
          .opacity(this.resolveVisual().shadowOpacity)
          .margin({ top: this.resolveVisual().stageHeight - 44 })
          .scale({
            x: (this.shadowScaleX + this.shadowScaleXExtra) * this.interactionScale,
            y: (this.shadowScaleY + this.shadowScaleYExtra) * this.interactionScale
          })
          .animation({
            duration: this.motionDuration,
            curve: Curve.EaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          });

        Column() {
          this.AnimatedPetBody();
        }
        .width(this.resolveVisual().width)
        .height(this.resolveVisual().height)
        .opacity(this.bodyOpacity)
        .scale({ x: this.resolveBodyScale(), y: this.resolveBodyScale() })
        .rotate({
          x: 0,
          y: 1,
          z: 0,
          angle: this.resolvePetRotateY()
        })
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.resolvePetTiltZ()
        })
        .translate({ y: this.floatOffsetY + this.motionOffsetYExtra })
        .animation({
          duration: this.motionDuration,
          curve: Curve.EaseInOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        .onTouch((event: TouchEvent) => {
          this.handlePetImageTouch(event);
        });
      }
      .width('100%')
      .height(this.resolveVisual().stageHeight)
      .align(Alignment.Center)
      .renderGroup(true)
      .clip(false)
      .gesture(
        GestureGroup(
          GestureMode.Parallel,
          PanGesture({ direction: PanDirection.Horizontal })
            .onActionUpdate((event: GestureEvent) => {
              let nextRotation: number = this.petRotationY + event.offsetX / 18;
              nextRotation = Math.max(-16, Math.min(16, nextRotation));
              this.petRotationY = nextRotation;
            })
            .onActionEnd(() => {
              this.petRotationY = 0;
            }),
          PinchGesture()
            .onActionUpdate((event: GestureEvent) => {
              let nextScale: number = event.scale;
              nextScale = Math.max(0.94, Math.min(1.12, nextScale));
              this.interactionScale = nextScale;
            })
            .onActionEnd(() => {
              this.interactionScale = 1;
            })
        )
      )
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 16 });
  }
}
