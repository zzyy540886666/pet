import { PetModel } from '../models/PetModel';
import { PetLifecycleService } from './PetLifecycleService';

export interface EnvironmentSnapshot {
  temperature: number;
  humidity: number;
  light: number;
  comfortScore: number;
  statusText: string;
  infraredDetected: boolean;
  activityLevel: string;
  timestamp: number;
}

export class PetSensorService {
  private static readonly WARNING_COOLDOWN_MS: number = 15 * 60 * 1000;
  private static latest: EnvironmentSnapshot = {
    temperature: 26.2,
    humidity: 56,
    light: 280,
    comfortScore: 84,
    statusText: '环境舒适，宠物状态稳定',
    infraredDetected: false,
    activityLevel: '中等活动',
    timestamp: Date.now()
  };
  private static lastWarningAt: number = 0;

  static sample(): EnvironmentSnapshot {
    const nextTemperature: number = PetSensorService.latest.temperature + PetSensorService.rangeFloat(-1.2, 1.2);
    const nextHumidity: number = PetSensorService.latest.humidity + PetSensorService.rangeInt(-3, 3);
    const nextLight: number = PetSensorService.latest.light + PetSensorService.rangeInt(-120, 120);

    const temperature: number = Math.max(8, Math.min(42, Number(nextTemperature.toFixed(1))));
    const humidity: number = Math.max(20, Math.min(95, nextHumidity));
    const light: number = Math.max(20, Math.min(1500, nextLight));
    const comfortScore: number = Math.max(0, Math.min(100,
      Math.round(100 - Math.abs(temperature - 25) * 2 - Math.abs(humidity - 55) * 0.5)
    ));

    const infraredDetected: boolean = Math.random() > 0.45;
    const activityLevel: string = PetSensorService.resolveActivityText(light, infraredDetected);
    const statusText: string = PetSensorService.resolveStatusText(temperature, humidity, comfortScore);

    PetSensorService.latest = {
      temperature,
      humidity,
      light,
      comfortScore,
      statusText,
      infraredDetected,
      activityLevel,
      timestamp: Date.now()
    };

    return PetSensorService.latest;
  }

  static getLatest(): EnvironmentSnapshot {
    return PetSensorService.latest;
  }

  static applyEnvironmentImpact(pet: PetModel, snapshot: EnvironmentSnapshot): string {
    const now: number = Date.now();
    if (snapshot.comfortScore >= 80) {
      pet.attributes.mood = Math.min(100, pet.attributes.mood + 4);
      PetLifecycleService.updateEmotionAndStage(pet);
      return '环境很舒服，心情自然恢复';
    }

    if (snapshot.temperature > 35 || snapshot.temperature < 10) {
      pet.attributes.mood = Math.max(0, pet.attributes.mood - 5);
      pet.attributes.health = Math.max(0, pet.attributes.health - 3);
      PetSensorService.recordWarning(pet, '温度异常，触发健康预警', now, snapshot.comfortScore);
      PetLifecycleService.updateEmotionAndStage(pet);
      return '温度异常，触发健康预警';
    }

    if (snapshot.humidity > 80 || snapshot.humidity < 30) {
      pet.attributes.mood = Math.max(0, pet.attributes.mood - 3);
      pet.attributes.health = Math.max(0, pet.attributes.health - 2);
      PetSensorService.recordWarning(pet, '湿度异常，宠物出现轻微不适', now, snapshot.comfortScore);
      PetLifecycleService.updateEmotionAndStage(pet);
      return '湿度异常，宠物出现轻微不适';
    }

    if (snapshot.light < 100) {
      pet.attributes.energy = Math.min(100, pet.attributes.energy + 2);
      PetLifecycleService.updateEmotionAndStage(pet);
      return '环境光线偏暗，宠物更想休息';
    }

    PetLifecycleService.updateEmotionAndStage(pet);
    return '环境一般，状态维持稳定';
  }

  private static recordWarning(pet: PetModel, message: string, now: number, comfortScore: number): void {
    if (now - PetSensorService.lastWarningAt < PetSensorService.WARNING_COOLDOWN_MS) {
      return;
    }

    PetSensorService.lastWarningAt = now;
    PetLifecycleService.addMemory(pet, '长期记忆', `环境预警：${message}`, now);
    PetLifecycleService.unlockAchievement(pet, 'weather_guardian', '患难与共', '经历一次环境异常预警并照顾宠物');

    if (comfortScore <= 45) {
      PetLifecycleService.unlockAchievement(pet, 'extreme_weather_guardian', '守护到底', '在低舒适度环境下持续守护宠物');
    }
  }

  private static resolveStatusText(temperature: number, humidity: number, comfortScore: number): string {
    if (comfortScore >= 80) {
      return '环境舒适，宠物状态稳定';
    }
    if (temperature > 35) {
      return '环境偏热，建议降温';
    }
    if (temperature < 10) {
      return '环境偏冷，建议保暖';
    }
    if (humidity > 80) {
      return '环境偏潮，建议通风';
    }
    if (humidity < 30) {
      return '环境偏干，建议补湿';
    }
    return '环境一般，可继续观察';
  }

  private static resolveActivityText(light: number, infraredDetected: boolean): string {
    if (!infraredDetected) {
      return '低活动';
    }
    if (light > 900) {
      return '高活动';
    }
    if (light > 400) {
      return '中等活动';
    }
    return '轻活动';
  }

  private static rangeFloat(min: number, max: number): number {
    return Math.random() * (max - min) + min;
  }

  private static rangeInt(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }
}
