import { PetDreamRecord, PetModel } from '../models/PetModel';
import { PetLifecycleService } from './PetLifecycleService';

export class PetAiService {
  private static readonly MEMORY_LIMIT: number = 12;

  static reply(pet: PetModel, userMessage: string): string {
    const sanitized: string = userMessage.trim();
    const finalMessage: string = sanitized.length > 0 ? sanitized : '你今天想和我聊点什么';
    PetLifecycleService.addMemory(pet, '对话记忆', `主人：${finalMessage}`);

    const toxicity: number = pet.attributes.toxicity;
    const intimacy: number = pet.attributes.intimacy;
    const emotion: string = pet.emotion;
    const userEmotion: string = PetAiService.resolveUserEmotion(finalMessage);
    const intent: string = PetAiService.resolveIntent(finalMessage);
    const focus: string = PetAiService.resolveMessageFocus(finalMessage);
    const contextLine: string = PetAiService.resolveContextLine(pet, finalMessage);
    const personalityLine: string = PetAiService.resolvePersonalityLine(pet);

    let stylePrefix: string = '主人';
    if (intimacy >= 70) {
      stylePrefix = '最喜欢的主人';
    } else if (intimacy <= 20) {
      stylePrefix = '你好呀';
    }

    let tone: string = '我认真听着呢';
    if (emotion === '困倦') {
      tone = '我有点困，但还是想陪你聊聊';
    } else if (emotion === '悲伤') {
      tone = '抱抱我，我们一起变得更开心';
    } else if (emotion === '兴奋') {
      tone = '太棒了，我现在超级有活力';
    }

    let suffix: string = '你愿意再多告诉我一点吗';
    if (toxicity >= 70) {
      suffix = '哼，不过我还是会好好听你说完';
    } else if (toxicity <= 20) {
      suffix = '我会一直温柔地陪着你';
    }

    const empathyLine: string = PetAiService.resolveEmpathyLine(intent, userEmotion, finalMessage, pet);
    const knowledgeLine: string = PetAiService.resolveKnowledgeLine(intent, finalMessage);
    const suggestionLine: string = PetAiService.resolveSuggestionLine(intent, pet);
    const proactiveLine: string = PetAiService.resolveProactiveLine(userEmotion, pet);
    let contextAndAdvice: string = contextLine;
    if (knowledgeLine.length > 0) {
      contextAndAdvice = `${contextAndAdvice}，${knowledgeLine}`;
    }
    contextAndAdvice = `${contextAndAdvice}，${suggestionLine}`;
    let reply: string = `${stylePrefix}，${personalityLine}${tone}。关于“${focus}”，${empathyLine}。${contextAndAdvice}。`;
    if (proactiveLine.length > 0) {
      reply = `${reply}${proactiveLine}。`;
    }
    reply = `${reply}${suffix}。`;

    PetLifecycleService.addMemory(pet, '情感记忆', `宠物：${reply}`);
    pet.currentSpeech = reply;
    return reply;
  }

  static generateDream(pet: PetModel, timestamp: number = Date.now()): PetDreamRecord {
    const category: string = PetAiService.resolveDreamCategory(pet);
    const now: number = timestamp;
    const dream: PetDreamRecord = new PetDreamRecord();
    dream.id = `${now}-${pet.dreams.length + 1}`;
    dream.timestamp = now;
    dream.category = category;

    const titlePrefix: string = PetAiService.pickOne(PetAiService.resolveTitlePrefixes(category));
    const place: string = PetAiService.pickOne(PetAiService.resolvePlaces(category));
    const sceneStart: string = PetAiService.pickOne(PetAiService.resolveSceneStarts(category));
    const sceneMiddle: string = PetAiService.pickOne(PetAiService.resolveSceneMiddles(category));
    const sceneConflict: string = PetAiService.pickOne(PetAiService.resolveSceneConflicts(category));
    const sceneEnding: string = PetAiService.pickOne(PetAiService.resolveSceneEndings(category));
    const timePhase: string = PetAiService.resolveTimePhase(now);
    const ownerTopic: string = PetAiService.resolveRecentOwnerTopic(pet);
    const preferredActivity: string = PetAiService.resolvePreferredActivity(pet);
    const closenessLabel: string = PetAiService.resolveClosenessLabel(pet);

    dream.title = `${titlePrefix}·${place}`;
    dream.content = `在${timePhase}的梦里，我和你来到${place}。${sceneStart}。你提到“${ownerTopic}”，于是我们${sceneMiddle}。后来${sceneConflict}，我因为${closenessLabel}慢慢安定下来。醒来前，我们还一起${sceneEnding}，像现实里你陪我${preferredActivity}时一样踏实。`;
    dream.moodTag = PetAiService.resolveMoodTag(category, pet.emotion);

    pet.dreams.unshift(dream);
    if (pet.dreams.length > PetAiService.MEMORY_LIMIT) {
      pet.dreams.pop();
    }

    PetLifecycleService.addMemory(pet, '长期记忆', `梦境：${dream.title}`);
    if (pet.dreams.length >= 3) {
      PetLifecycleService.unlockAchievement(pet, 'dream_starter', '初梦收藏家', '累计记录3篇梦境日记');
    }
    if (pet.dreams.length >= 8) {
      PetLifecycleService.unlockAchievement(pet, 'dream_master', '梦境大师', '累计记录8篇梦境日记');
    }
    return dream;
  }

  private static pickOne(items: string[]): string {
    if (items.length === 0) {
      return '';
    }
    const index: number = Math.floor(Math.random() * items.length);
    return items[index];
  }

  private static resolveTitlePrefixes(category: string): string[] {
    if (category === '快乐梦') {
      return ['晴天散步记录', '晚风回家路', '公园长椅小记'];
    }
    if (category === '回忆梦') {
      return ['第一次回家那天', '旧相册那一页', '你掌心的温度'];
    }
    if (category === '奇幻梦') {
      return ['云朵飞艇巡游', '星光邮局奇遇', '会说话的风之岛'];
    }
    if (category === '焦虑梦') {
      return ['雨夜等你回家', '人群里的脚步声', '夜班后的门口'];
    }
    return ['夜宵小铺排队记', '厨房香气探险', '小鱼干补给站'];
  }

  private static resolvePlaces(category: string): string[] {
    if (category === '快乐梦') {
      return ['楼下梧桐步道', '周末公园湖边', '家里阳台暖垫旁', '小区花园长椅'];
    }
    if (category === '回忆梦') {
      return ['第一次见面的客厅', '你接我回家的路口', '旧照片墙前', '熟悉的餐桌旁'];
    }
    if (category === '奇幻梦') {
      return ['漂浮云层上的小镇', '会发光的图书馆', '月光隧道尽头的广场', '会唱歌的森林'];
    }
    if (category === '焦虑梦') {
      return ['下班高峰的街口', '雨后的公交站台', '灯光忽明忽暗的走廊', '陌生又拥挤的商场'];
    }
    return ['夜市小吃摊前', '厨房灶台旁', '宠物零食货架前', '街角小面馆门口'];
  }

  private static resolveSceneStarts(category: string): string[] {
    if (category === '快乐梦') {
      return ['路边的风很轻，你弯下腰帮我理了理项圈'];
    }
    if (category === '回忆梦') {
      return ['我又看见你第一次叫我名字时的神情，声音和那天一样温柔'];
    }
    if (category === '奇幻梦') {
      return ['我追着一束会发光的尾巴跑，抬头发现天空挂着会慢慢转动的糖果星球'];
    }
    if (category === '焦虑梦') {
      return ['我听见很多急促的脚步声，一开始有点慌，尾巴都不敢抬起来'];
    }
    return ['我闻到小鱼干和热牛奶的味道，肚子咕噜咕噜地叫起来'];
  }

  private static resolveSceneMiddles(category: string): string[] {
    if (category === '快乐梦') {
      return ['沿着熟悉的小路慢慢散步，还在路边一起看了一会儿云'];
    }
    if (category === '回忆梦') {
      return ['重新走了一遍我们从陌生到熟悉的那段路，我一步也不想落下'];
    }
    if (category === '奇幻梦') {
      return ['我们坐上纸飞机改装的列车，在风里穿过会说话的云朵商店'];
    }
    if (category === '焦虑梦') {
      return ['贴着你的脚边往前走，你一边轻声安慰我，一边放慢了步子'];
    }
    return ['你帮我挑了好多零食，我抱着最喜欢的小鱼干开心地转圈圈'];
  }

  private static resolveSceneConflicts(category: string): string[] {
    if (category === '快乐梦') {
      return ['忽然有一阵大风把树叶吹得满天都是，你笑着把我抱到怀里'];
    }
    if (category === '回忆梦') {
      return ['我差点在巷口走丢，你远远喊了我一声，我立刻就认出了你'];
    }
    if (category === '奇幻梦') {
      return ['半路出现了一只巨大的闹钟怪，把我们追得满街飞奔'];
    }
    if (category === '焦虑梦') {
      return ['人群突然加快了节奏，雨点也密了起来，我的心跳一下子变快'];
    }
    return ['结果最后一份小鱼干被抢走了，我急得原地跺脚'];
  }

  private static resolveSceneEndings(category: string): string[] {
    if (category === '快乐梦') {
      return ['在便利店门口分着一块小点心，然后慢慢走回家'];
    }
    if (category === '回忆梦') {
      return ['坐在门口的台阶上听你说今天的烦恼，直到夜色完全安静下来'];
    }
    if (category === '奇幻梦') {
      return ['拿着闪闪发光的奖章回家，你说我是今天最勇敢的小伙伴'];
    }
    if (category === '焦虑梦') {
      return ['在屋檐下等雨停，你轻拍着我，我终于敢把头靠在你手臂上'];
    }
    return ['你把最后一块点心掰给我，我们心满意足地一起回到小窝'];
  }

  private static resolveTimePhase(now: number): string {
    const hour: number = new Date(now).getHours();
    if (hour >= 5 && hour < 10) {
      return '清晨';
    }
    if (hour < 14) {
      return '上午';
    }
    if (hour < 18) {
      return '午后';
    }
    if (hour < 22) {
      return '傍晚';
    }
    return '深夜';
  }

  private static resolveRecentOwnerTopic(pet: PetModel): string {
    const memoryLimit: number = Math.min(pet.memories.length, 20);
    for (let i: number = 0; i < memoryLimit; i += 1) {
      const item = pet.memories[i];
      if (item.type !== '对话记忆') {
        continue;
      }
      if (item.content.startsWith('主人：')) {
        const topic: string = item.content.slice(3).trim();
        if (topic.length > 0) {
          return topic.length > 14 ? `${topic.slice(0, 14)}…` : topic;
        }
      }
    }
    return '今天的日常';
  }

  private static resolvePreferredActivity(pet: PetModel): string {
    const stats = pet.interactionStats;
    let maxCount: number = stats.feedCount;
    let activity: string = '吃饭';

    if (stats.playCount > maxCount) {
      maxCount = stats.playCount;
      activity = '玩耍';
    }
    if (stats.petCount > maxCount) {
      maxCount = stats.petCount;
      activity = '贴贴';
    }
    if (stats.trainCount > maxCount) {
      maxCount = stats.trainCount;
      activity = '训练';
    }
    if (stats.chatCount > maxCount) {
      maxCount = stats.chatCount;
      activity = '聊天';
    }

    if (maxCount <= 0) {
      if (pet.attributes.energy <= 35) {
        return '安静休息';
      }
      return '散步聊天';
    }
    return activity;
  }

  private static resolveClosenessLabel(pet: PetModel): string {
    const intimacy: number = pet.attributes.intimacy;
    if (intimacy >= 75) {
      return '你熟悉的心跳和呼吸';
    }
    if (intimacy >= 40) {
      return '你手心里稳稳的温度';
    }
    return '你轻轻叫我名字的声音';
  }

  private static resolveMoodTag(category: string, emotion: string): string {
    if (category === '焦虑梦') {
      return emotion === '悲伤' ? '惦念' : '释然';
    }
    if (category === '回忆梦') {
      return '感动';
    }
    if (category === '快乐梦') {
      return '温暖';
    }
    return '平和';
  }

  private static resolveIntent(message: string): string {
    const text: string = message.trim();
    if (PetAiService.containsAny(text, ['什么是', '是什么意思', '为什么', '谁是', '科普', '介绍一下'])) {
      return '问答';
    }
    if (PetAiService.containsAny(text, ['怎么办', '如何', '怎么做', '建议', '要不要'])) {
      return '求助';
    }
    if (PetAiService.containsAny(text, ['难过', '压力', '烦', '焦虑', '累', '崩溃', '失眠'])) {
      return '情绪';
    }
    if (PetAiService.containsAny(text, ['开心', '高兴', '通过', '成功', '顺利'])) {
      return '喜悦';
    }
    if (PetAiService.containsAny(text, ['记得', '以前', '上次', '昨天', '小时候'])) {
      return '回忆';
    }
    if (PetAiService.containsAny(text, ['你好', '在吗', '早安', '晚安', '嗨'])) {
      return '问候';
    }
    return '日常';
  }

  private static resolveMessageFocus(message: string): string {
    const normalized: string = message.trim();
    if (normalized.length <= 18) {
      return normalized;
    }
    return `${normalized.slice(0, 18)}…`;
  }

  private static resolveContextLine(pet: PetModel, currentMessage: string): string {
    const recalled: string[] = [];
    const memories = PetLifecycleService.recallMemories(pet, currentMessage, 2);
    for (let i: number = 0; i < memories.length; i += 1) {
      const raw: string = memories[i].content.replace('主人：', '').replace('宠物：', '').trim();
      if (raw.length > 0) {
        recalled.push(raw.length > 12 ? `${raw.slice(0, 12)}…` : raw);
      }
    }
    if (recalled.length > 0) {
      return `我还记得我们聊过“${recalled.join('、')}”`;
    }
    return '我在认真听你的每一句话';
  }

  private static resolveEmpathyLine(intent: string, userEmotion: string, message: string, pet: PetModel): string {
    if (userEmotion === '开心') {
      return '我也跟着你一起高兴，尾巴都快摇成小风扇了';
    }
    if (userEmotion === '难过') {
      return '难受的时候就靠近我一点，我会乖乖陪着你';
    }
    if (userEmotion === '生气') {
      return '我会先安静听你说，等你情绪缓下来我们再一起想办法';
    }
    if (userEmotion === '焦虑') {
      return '先把节奏放慢一点，我会陪你一步一步把事情理清楚';
    }
    if (userEmotion === '疲惫') {
      return '你已经很辛苦了，我们先休息一下也没关系';
    }

    if (intent === '求助') {
      return '我们可以把问题拆成一小步一小步，我会陪你一起想办法';
    }
    if (intent === '情绪') {
      if (pet.attributes.intimacy >= 50) {
        return '你可以先靠着我休息一下，情绪慢慢放下来再继续面对';
      }
      return '你已经很努力了，先让呼吸慢一点，事情会一点点清晰';
    }
    if (intent === '喜悦') {
      return '我能感受到你的开心，这份进步真的很了不起';
    }
    if (intent === '回忆') {
      return '这些片段对你很重要，我愿意陪你把它们一条条整理好';
    }
    if (message.length <= 4) {
      return '你想聊什么我都在';
    }
    return '你说的我都听进去了';
  }

  private static resolveKnowledgeLine(intent: string, message: string): string {
    if (intent !== '问答') {
      return '';
    }
    if (PetAiService.containsAny(message, ['天气', '温度', '湿度'])) {
      return '我理解到你在问环境知识，温度和湿度舒适时我会更开心';
    }
    if (PetAiService.containsAny(message, ['猫', '狗', '狐狸', '金毛'])) {
      return '我理解到你在问宠物知识，不同宠物需要的陪伴节奏会有差异';
    }
    return '我理解到你在问知识问题，我会用宠物视角给你一个简单解释';
  }

  private static resolveSuggestionLine(intent: string, pet: PetModel): string {
    if (intent === '问答') {
      return '你想的话可以再追问一个细节，我会继续认真回答';
    }
    if (intent === '求助') {
      return '要不要先定一个十分钟可完成的小目标，我们做完第一步再看下一步';
    }
    if (intent === '情绪') {
      if (pet.attributes.energy <= 35) {
        return '现在先补一点能量，喝口温水，休息几分钟会更好';
      }
      return '我们先做三次慢呼吸，然后去阳台或窗边站一会儿';
    }
    if (intent === '喜悦') {
      return '我们把这件好事记下来，等低落的时候再拿出来鼓励自己';
    }
    if (intent === '回忆') {
      return '你可以告诉我当时最打动你的一个细节，我会记住它';
    }
    if (pet.attributes.intimacy >= 70) {
      return '如果你愿意，我们可以继续聊聊你现在最在意的那件事';
    }
    return '你愿意的话，再多告诉我一点点细节';
  }

  private static resolveProactiveLine(userEmotion: string, pet: PetModel): string {
    if (pet.attributes.intimacy < 40) {
      return '';
    }
    if (userEmotion === '难过' || userEmotion === '焦虑') {
      return '要不要我晚点再来问你一句“现在好一点了吗”';
    }
    if (userEmotion === '疲惫') {
      return '你休息的时候我会安静守着你';
    }
    return '';
  }

  private static resolvePersonalityLine(pet: PetModel): string {
    const personality = pet.personality;
    if (personality.warmth >= 75) {
      return '我会用最暖心的方式陪你，';
    }
    if (personality.naughty >= 70) {
      return '我今天有点调皮，但还是会认真陪你，';
    }
    if (personality.cheerful >= 70) {
      return '我现在超有活力，';
    }
    if (personality.independence >= 70) {
      return '我会先陪你梳理思路，也相信你能做到，';
    }
    return '';
  }

  private static resolveUserEmotion(message: string): string {
    if (PetAiService.containsAny(message, ['开心', '高兴', '兴奋', '太棒', '顺利'])) {
      return '开心';
    }
    if (PetAiService.containsAny(message, ['难过', '伤心', '委屈', '想哭'])) {
      return '难过';
    }
    if (PetAiService.containsAny(message, ['生气', '火大', '烦死', '愤怒'])) {
      return '生气';
    }
    if (PetAiService.containsAny(message, ['焦虑', '紧张', '担心', '不安', '压力'])) {
      return '焦虑';
    }
    if (PetAiService.containsAny(message, ['好累', '疲惫', '困', '没精神'])) {
      return '疲惫';
    }
    return '平静';
  }

  private static containsAny(text: string, keywords: string[]): boolean {
    for (let i: number = 0; i < keywords.length; i += 1) {
      if (text.includes(keywords[i])) {
        return true;
      }
    }
    return false;
  }

  private static resolveDreamCategory(pet: PetModel): string {
    if (pet.attributes.energy <= 30 || pet.attributes.health <= 35) {
      return '美食梦';
    }
    if (pet.attributes.mood >= 80) {
      return '快乐梦';
    }
    if (pet.attributes.mood <= 30) {
      return '焦虑梦';
    }
    if (pet.memories.length > 0 && pet.memories[0].type === '长期记忆') {
      return '回忆梦';
    }
    if (Math.random() > 0.82) {
      return '奇幻梦';
    }
    return '回忆梦';
  }
}
