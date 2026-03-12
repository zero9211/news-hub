/**
 * AI播客伴侣 — 核心逻辑
 * AI Podcast Companion — Core Logic
 *
 * 功能：播客播放器 + 语音提问 + Claude AI 流式回答 + 自动暂停/继续
 */

// ─────────────────────────────────────────────
// 全局状态
// ─────────────────────────────────────────────
const App = {
  apiKey:  localStorage.getItem('pc_api_key') || '',
  model:   localStorage.getItem('pc_model')   || 'glm-4-plus',
  lang:    localStorage.getItem('pc_lang')    || 'zh-CN',

  isPlaying:    false,
  wasPlaying:   false,   // 提问前是否在播放
  isListening:  false,
  isThinking:   false,

  audioCtx:       null,
  analyser:       null,
  waveRaf:        null,
  recognition:    null,

  // 音频捕获（用于实时转录）
  mediaStreamDest: null,
  mediaRecorder:   null,
  audioChunks:     [],   // { blob, ts } 滚动缓冲，保留最近 60 秒
};

// ─────────────────────────────────────────────
// 初始化
// ─────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', () => {
  // 若已有 key 则关闭弹窗
  if (App.apiKey) {
    hide('apiModal');
  }

  updateModelBadge();
  initPlayer();

  // 检查语音识别支持
  if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
    const btn = id('micBtn');
    btn.title = '当前浏览器不支持语音，请用 Chrome/Edge';
    btn.style.opacity = '0.4';
    btn.style.cursor = 'not-allowed';
  }
});

// ─────────────────────────────────────────────
// API Key / 设置
// ─────────────────────────────────────────────
function saveApiKey() {
  const key = id('apiKeyInput').value.trim();
  if (!key) {
    toast('请输入 API Key', 'error');
    return;
  }
  App.apiKey = key;
  localStorage.setItem('pc_api_key', key);
  hide('apiModal');
  toast('API Key 已保存 ✓', 'success');
}

function openSettings() {
  id('settingsKey').value = App.apiKey;
  id('modelSel').value    = App.model;
  id('langSel').value     = App.lang;
  show('settingsModal');
}

function closeSettings() {
  hide('settingsModal');
}

function saveSettings() {
  const key   = id('settingsKey').value.trim();
  const model = id('modelSel').value;
  const lang  = id('langSel').value;

  if (key) {
    App.apiKey = key;
    localStorage.setItem('pc_api_key', key);
  }
  App.model = model;
  App.lang  = lang;
  localStorage.setItem('pc_model', model);
  localStorage.setItem('pc_lang',  lang);

  updateModelBadge();
  closeSettings();
  toast('设置已保存 ✓', 'success');
}

function updateModelBadge() {
  const labels = {
    'glm-4-plus': 'GLM-4-Plus',
    'glm-4-flash': 'GLM-4-Flash',
    'glm-4-air':  'GLM-4-Air',
    'glm-4-long': 'GLM-4-Long',
  };
  id('modelBadge').textContent = labels[App.model] || App.model;
}

// ─────────────────────────────────────────────
// 音频播放器
// ─────────────────────────────────────────────
function initPlayer() {
  const audio = id('audio');

  audio.addEventListener('loadedmetadata', () => {
    id('totTime').textContent = fmt(audio.duration);
    show('playerCard');
    show('ctxCard');
    initWaveform();
    setStatus('AI 就绪，点击播放', true);
  });

  audio.addEventListener('timeupdate', () => {
    const pct = audio.duration ? (audio.currentTime / audio.duration) * 100 : 0;
    id('progressFill').style.width = pct + '%';
    id('curTime').textContent = fmt(audio.currentTime);
  });

  audio.addEventListener('play', () => {
    App.isPlaying = true;
    id('playIcon').className = 'ri-pause-fill';
    id('syncBadge').textContent = '● 同步中';
    setStatus('AI 全程同步收听中', true);
  });

  audio.addEventListener('pause', () => {
    App.isPlaying = false;
    id('playIcon').className = 'ri-play-fill';
    if (!App.isThinking) setStatus('已暂停', false);
  });

  audio.addEventListener('ended', () => {
    App.isPlaying = false;
    id('playIcon').className = 'ri-play-fill';
    id('syncBadge').textContent = '● 完毕';
    setStatus('播放完毕', false);
  });

  audio.addEventListener('error', () => {
    const err = audio.error;
    if (err && err.code === MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED) {
      toast('音频加载失败：该地址不支持跨域访问 (CORS)，请尝试本地文件', 'error');
    } else {
      toast('音频加载失败，请检查 URL 或文件格式', 'error');
    }
  });
}

function loadFromUrl() {
  const url = id('audioUrl').value.trim();
  if (!url) { toast('请输入音频 URL', 'error'); return; }
  loadAudio(url, decodeURIComponent(url.split('/').pop().split('?')[0]) || '在线播客');
}

function loadLocal(input) {
  const file = input.files[0];
  if (!file) return;
  loadAudio(URL.createObjectURL(file), file.name);
}

function loadSample(url, name) {
  id('audioUrl').value = url;
  loadAudio(url, name);
}

function loadAudio(src, name) {
  const audio = id('audio');

  // Blob URLs are same-origin; remote URLs need CORS so Web Audio API can route audio
  if (src.startsWith('blob:')) {
    audio.removeAttribute('crossOrigin');
  } else {
    audio.crossOrigin = 'anonymous';
  }

  audio.src = src;
  audio.load();

  const title = name.replace(/\.[^/.]+$/, '').replace(/[-_]/g, ' ');
  id('trackTitle').textContent = title;
  id('trackSub').textContent   = 'AI 将全程同步收听';
  setStatus('正在加载...', true);

  addMsg('ai', `🎙️ 已加载：**${title}**\n\n点击播放开始，随时可以提问！`);
}

async function togglePlay() {
  const audio = id('audio');
  if (!audio.src) { toast('请先加载播客', 'warning'); return; }
  if (App.audioCtx && App.audioCtx.state === 'suspended') {
    await App.audioCtx.resume();
  }
  audio.paused ? audio.play() : audio.pause();
}

function skip(sec) {
  const a = id('audio');
  if (App.audioCtx && App.audioCtx.state === 'suspended') App.audioCtx.resume();
  a.currentTime = Math.max(0, Math.min(a.duration || 0, a.currentTime + sec));
}

function seekByClick(e) {
  const audio = id('audio');
  if (!audio.duration) return;
  const rect = id('progressTrack').getBoundingClientRect();
  audio.currentTime = ((e.clientX - rect.left) / rect.width) * audio.duration;
}

function setSpeed(v) {
  id('audio').playbackRate = parseFloat(v);
}

// "听懂这句" 按钮：转录当前播放内容后直接问 AI
async function transcribeAndAsk() {
  if (!App.mediaRecorder) { toast('请先加载并播放音频', 'warning'); return; }
  if (!App.apiKey) { showApiModal(); return; }
  setStatus('正在识别音频内容...', true);
  const transcript = await transcribeRecentAudio(10);
  if (!transcript) {
    toast('识别失败，请播放一段后再试', 'error');
    setStatus('就绪', false);
    return;
  }
  // 将转录文本填入输入框，用户可直接发送或追加问题
  const inp = id('textQ');
  inp.value = transcript;
  inp.focus();
  toast('识别完成，可直接发送或补充问题', 'success');
  setStatus('就绪', false);
}

function fmt(s) {
  if (!s || isNaN(s)) return '0:00';
  const m = Math.floor(s / 60), sec = Math.floor(s % 60);
  return `${m}:${String(sec).padStart(2, '0')}`;
}

// ─────────────────────────────────────────────
// 波形可视化（Web Audio API）
// ─────────────────────────────────────────────
function initWaveform() {
  const canvas = id('waveform');
  const audio  = id('audio');

  try {
    if (!App.audioCtx) {
      App.audioCtx  = new (window.AudioContext || window.webkitAudioContext)();
      App.analyser  = App.audioCtx.createAnalyser();
      App.analyser.fftSize = 256;
      const src = App.audioCtx.createMediaElementSource(audio);
      src.connect(App.analyser);
      App.analyser.connect(App.audioCtx.destination);
      setupAudioCapture();
    }
    drawWaveform(canvas);
  } catch (e) {
    drawStaticBars(canvas);
  }
}

// ─────────────────────────────────────────────
// 音频捕获 & 转录
// ─────────────────────────────────────────────
function setupAudioCapture() {
  if (!App.audioCtx || !App.analyser || App.mediaRecorder) return;
  try {
    App.mediaStreamDest = App.audioCtx.createMediaStreamDestination();
    App.analyser.connect(App.mediaStreamDest);

    const mime = ['audio/webm;codecs=opus', 'audio/webm', 'audio/ogg']
      .find(t => MediaRecorder.isTypeSupported(t)) || '';
    App.mediaRecorder = new MediaRecorder(
      App.mediaStreamDest.stream,
      mime ? { mimeType: mime } : {}
    );
    App.audioChunks = [];
    App.mediaRecorder.ondataavailable = ({ data }) => {
      if (data.size > 0) {
        App.audioChunks.push({ blob: data, ts: Date.now() });
        const cutoff = Date.now() - 60000;
        App.audioChunks = App.audioChunks.filter(c => c.ts > cutoff);
      }
    };
    App.mediaRecorder.start(1000); // 每秒一个 chunk
  } catch (e) {
    console.warn('Audio capture unavailable:', e);
  }
}

function getRecentAudioBlob(seconds = 10) {
  const cutoff = Date.now() - seconds * 1000;
  const chunks = App.audioChunks.filter(c => c.ts > cutoff).map(c => c.blob);
  if (!chunks.length) return null;
  return new Blob(chunks, { type: chunks[0].type || 'audio/webm' });
}

async function blobToWav(blob) {
  const ab = await blob.arrayBuffer();
  const decoded = await App.audioCtx.decodeAudioData(ab);
  const sr = 16000;
  const offCtx = new OfflineAudioContext(1, Math.ceil(sr * decoded.duration), sr);
  const src = offCtx.createBufferSource();
  src.buffer = decoded;
  src.connect(offCtx.destination);
  src.start();
  const rendered = await offCtx.startRendering();
  return encodeWAV(rendered.getChannelData(0), sr);
}

function encodeWAV(samples, sr) {
  const buf = new ArrayBuffer(44 + samples.length * 2);
  const v = new DataView(buf);
  const ws = (o, s) => [...s].forEach((c, i) => v.setUint8(o + i, c.charCodeAt(0)));
  ws(0, 'RIFF'); v.setUint32(4, 36 + samples.length * 2, true);
  ws(8, 'WAVE'); ws(12, 'fmt '); v.setUint32(16, 16, true);
  v.setUint16(20, 1, true); v.setUint16(22, 1, true);
  v.setUint32(24, sr, true); v.setUint32(28, sr * 2, true);
  v.setUint16(32, 2, true); v.setUint16(34, 16, true);
  ws(36, 'data'); v.setUint32(40, samples.length * 2, true);
  for (let i = 0; i < samples.length; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    v.setInt16(44 + i * 2, s < 0 ? s * 0x8000 : s * 0x7FFF, true);
  }
  return new Blob([buf], { type: 'audio/wav' });
}

async function transcribeRecentAudio(seconds = 10) {
  const blob = getRecentAudioBlob(seconds);
  if (!blob) return null;
  try {
    const wav = await blobToWav(blob);
    const fd = new FormData();
    fd.append('file', wav, 'audio.wav');
    fd.append('model', 'glm-asr-2512');
    fd.append('stream', 'false');
    const resp = await fetch('https://open.bigmodel.cn/api/paas/v4/audio/transcriptions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${App.apiKey}` },
      body: fd,
    });
    if (!resp.ok) return null;
    const data = await resp.json();
    return data.text || null;
  } catch {
    return null;
  }
}

function drawWaveform(canvas) {
  const ctx    = canvas.getContext('2d');
  const data   = new Uint8Array(App.analyser.frequencyBinCount);

  function frame() {
    App.waveRaf = requestAnimationFrame(frame);

    const W = canvas.offsetWidth, H = 56;
    canvas.width  = W * devicePixelRatio;
    canvas.height = H * devicePixelRatio;
    ctx.scale(devicePixelRatio, devicePixelRatio);

    ctx.fillStyle = '#0f0f18';
    ctx.fillRect(0, 0, W, H);

    if (App.isPlaying) {
      App.analyser.getByteFrequencyData(data);
    }

    const bw  = W / data.length * 2.2;
    let   x   = 0;
    for (let i = 0; i < data.length; i++) {
      const h = App.isPlaying ? (data[i] / 255) * H * 0.85 : (Math.sin(i * 0.4 + Date.now() * 0.002) * 4 + 6);
      const grad = ctx.createLinearGradient(0, H, 0, 0);
      grad.addColorStop(0, 'rgba(124,111,247,0.9)');
      grad.addColorStop(1, 'rgba(167,139,250,0.3)');
      ctx.fillStyle = grad;
      ctx.fillRect(x, (H - h) / 2, bw - 1, h);
      x += bw;
    }
  }
  frame();
}

function drawStaticBars(canvas) {
  const ctx = canvas.getContext('2d');
  const W = canvas.offsetWidth, H = 56;
  canvas.width = W; canvas.height = H;
  ctx.fillStyle = '#0f0f18';
  ctx.fillRect(0, 0, W, H);
  for (let i = 0; i < 60; i++) {
    const h = Math.random() * 20 + 5;
    ctx.fillStyle = 'rgba(124,111,247,0.4)';
    ctx.fillRect(i * (W / 60), (H - h) / 2, W / 60 - 2, h);
  }
}

// ─────────────────────────────────────────────
// 语音识别
// ─────────────────────────────────────────────
function toggleMic() {
  if (App.isListening) stopListening();
  else startListening();
}

function startListening() {
  if (!App.apiKey) { showApiModal(); return; }
  if (App.isThinking) { toast('AI 回答中，请稍候...', 'warning'); return; }

  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) { toast('请使用 Chrome / Edge 浏览器', 'error'); return; }

  // 暂停播客
  const audio = id('audio');
  App.wasPlaying = App.isPlaying;
  if (App.isPlaying) audio.pause();

  const rec = new SR();
  rec.lang            = App.lang;
  rec.interimResults  = true;
  rec.continuous      = false;
  rec.maxAlternatives = 1;
  App.recognition = rec;

  rec.onstart = () => {
    App.isListening = true;
    id('micBtn').classList.add('recording');
    id('micIcon').className = 'ri-mic-fill';
    show('listenBar');
    id('listenLabel').textContent = '正在聆听...';
    setStatus('正在聆听你的问题...', true);
  };

  rec.onresult = (e) => {
    const transcript = Array.from(e.results).map(r => r[0].transcript).join('');
    id('interimText').textContent = transcript;
    if (e.results[0].isFinal) {
      stopListening();
      if (transcript.trim()) sendQuestion(transcript.trim());
      else resumeIfNeeded();
    }
  };

  rec.onerror = (e) => {
    stopListening();
    if (e.error === 'not-allowed') toast('请允许麦克风权限', 'error');
    else if (e.error === 'no-speech') { toast('未检测到语音，请重试', 'warning'); resumeIfNeeded(); }
    else toast(`语音识别出错: ${e.error}`, 'error');
  };

  rec.onend = () => { stopListening(); };
  rec.start();
}

function stopListening() {
  if (App.recognition) {
    try { App.recognition.stop(); } catch (_) {}
    App.recognition = null;
  }
  App.isListening = false;
  id('micBtn').classList.remove('recording');
  id('micIcon').className = 'ri-mic-line';
  hide('listenBar');
  id('interimText').textContent = '';
}

async function resumeIfNeeded() {
  if (!App.wasPlaying) return;
  if (App.audioCtx && App.audioCtx.state === 'suspended') {
    await App.audioCtx.resume();
  }
  id('audio').play();
}

// ─────────────────────────────────────────────
// 发问（文字）
// ─────────────────────────────────────────────
function sendText() {
  const inp = id('textQ');
  const q   = inp.value.trim();
  if (!q) return;

  // 暂停播客
  App.wasPlaying = App.isPlaying;
  if (App.isPlaying) id('audio').pause();

  inp.value = '';
  sendQuestion(q);
}

// ─────────────────────────────────────────────
// 核心：发问 → Claude 流式回答 → 自动继续
// ─────────────────────────────────────────────
async function sendQuestion(question) {
  if (!App.apiKey) { showApiModal(); return; }
  if (App.isThinking) { toast('AI 正在回答，请稍候...', 'warning'); return; }

  // 构建上下文
  const audio    = id('audio');
  const title    = id('trackTitle').textContent;
  const ts       = fmt(audio.currentTime);
  const duration = fmt(audio.duration);
  const ctx      = id('ctxText').value.trim();

  let context = `播客：${title}\n播放位置：${ts} / ${duration}`;
  if (ctx) context += `\n\n播客内容/字幕：\n${ctx}`;

  // 若问题涉及"当前/这句/刚才"，自动转录最近 10 秒
  const needsTranscript = /这句|那句|刚才|当前|现在说|重复|repeat|just said|what.*said/i.test(question);
  if (needsTranscript && App.mediaRecorder) {
    setStatus('正在识别音频内容...', true);
    const transcript = await transcribeRecentAudio(10);
    if (transcript) context += `\n\n当前正在播放的内容（AI自动识别）：\n"${transcript}"`;
  }

  const systemPrompt = `你是专业的AI播客伴侣，正与用户一起实时收听播客。
你拥有以下能力：
1. **单词讲解**：词义、音标（IPA）、例句、连读/弱读规则
2. **句子分析**：完整翻译、语法结构拆解、语气/情态分析
3. **口音识别与讲解**：
   - 美式英语（General American）：元音扁平，r音明显，t浊化
   - 英式英语（Received Pronunciation）：不卷舌，短促a音，清晰t音
   - 印度英语：t/d卷舌，节奏音节均等，独特元音
   - 爱尔兰英语：特殊r音，元音偏前，独特语调
   - 澳大利亚英语：元音升高，diphthong特征
4. **背景知识**：人物、地名、文化典故、历史事件
5. **内容理解**：帮助理解播客讨论的话题

当前播客信息：
${context}

回答要求：
- 简洁有力，重点突出
- 涉及英语发音时提供 IPA 音标和中文对照
- 用 Markdown 格式（**加粗**、列表、###标题）
- 语言：中文为主，英语术语保留原文

重要规则：
- 若上下文中有"当前正在播放的内容（AI自动识别）"，则直接基于该内容回答，无需用户再重复。
- 若用户说"这句话""这个词""刚才那句"等，但上下文中没有识别内容，则回复："请把你想问的那句话或单词粘贴进来 🎧"。
- 若用户提供了具体句子或单词，直接分析，无需再追问。`;

  // 显示用户消息
  addMsg('user', question);

  // 显示思考动画
  App.isThinking = true;
  setStatus('AI 正在思考...', true);
  const thinkEl = addThinking();

  try {
    await streamClaude(systemPrompt, question, thinkEl);
  } catch (err) {
    removeEl(thinkEl);
    const msg = err.message || '';
    let hint = '请检查 API Key 是否正确，或网络连接是否正常。';
    if (msg.includes('balance') || msg.includes('quota') || msg.includes('insufficient')) {
      hint = '账户余额不足，请前往 [open.bigmodel.cn](https://open.bigmodel.cn) 充值。';
    } else if (msg.includes('401') || msg.includes('invalid') || msg.includes('Authentication') || msg.includes('Unauthorized')) {
      hint = 'API Key 无效，请在设置中重新填写。';
    } else if (msg.includes('429') || msg.includes('rate limit')) {
      hint = '请求过于频繁，请稍后再试。';
    }
    addMsg('ai', `❌ 请求失败：${msg}\n\n${hint}`);
  } finally {
    App.isThinking = false;
    // 自动继续播放
    setTimeout(async () => {
      if (App.wasPlaying) {
        if (App.audioCtx && App.audioCtx.state === 'suspended') await App.audioCtx.resume();
        id('audio').play();
        setStatus('AI 全程同步收听中', true);
      } else {
        setStatus('AI 就绪', false);
      }
    }, 600);
  }
}

// ─────────────────────────────────────────────
// 智谱 AI 流式调用（SSE，OpenAI 兼容格式）
// ─────────────────────────────────────────────
async function streamClaude(system, question, thinkEl) {
  const resp = await fetch('https://open.bigmodel.cn/api/paas/v4/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type':  'application/json',
      'Authorization': `Bearer ${App.apiKey}`,
    },
    body: JSON.stringify({
      model:    App.model,
      stream:   true,
      messages: [
        { role: 'system', content: system },
        { role: 'user',   content: question },
      ],
    }),
  });

  if (!resp.ok) {
    let errMsg = `HTTP ${resp.status}`;
    try {
      const e = await resp.json();
      errMsg = e.error?.message || errMsg;
    } catch (_) {}
    throw new Error(errMsg);
  }

  // 移除 thinking 动画，创建消息气泡
  removeEl(thinkEl);
  const msgEl = createAiMsgEl();

  // 读取 SSE 流
  const reader  = resp.body.getReader();
  const decoder = new TextDecoder();
  let buf  = '';
  let full = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buf += decoder.decode(value, { stream: true });
    const lines = buf.split('\n');
    buf = lines.pop() || '';

    for (const line of lines) {
      if (!line.startsWith('data: ')) continue;
      const raw = line.slice(6).trim();
      if (raw === '[DONE]') break;
      try {
        const ev = JSON.parse(raw);
        const delta = ev.choices?.[0]?.delta?.content;
        if (delta) {
          full += delta;
          renderMd(msgEl, full);
          scrollChat();
        }
      } catch (_) {}
    }
  }

  // 检测口音相关内容，更新徽章
  detectAccent(full);
}

// ─────────────────────────────────────────────
// 口音检测 & 徽章
// ─────────────────────────────────────────────
function detectAccent(text) {
  const accentMap = [
    { keys: ['British', '英式', 'Received Pronunciation', 'RP英语'],   label: '🇬🇧 英式英语' },
    { keys: ['American', '美式', 'General American'],                  label: '🇺🇸 美式英语' },
    { keys: ['Indian', '印度', 'Hindi'],                               label: '🇮🇳 印度英语' },
    { keys: ['Irish', '爱尔兰'],                                        label: '🇮🇪 爱尔兰英语' },
    { keys: ['Australian', '澳大利亚', '澳式'],                         label: '🇦🇺 澳式英语' },
  ];
  const badge = id('accentBadge');
  for (const { keys, label } of accentMap) {
    if (keys.some(k => text.includes(k))) {
      badge.textContent = label;
      show('accentBadge');
      return;
    }
  }
}

// ─────────────────────────────────────────────
// 聊天 UI
// ─────────────────────────────────────────────
function addMsg(role, text) {
  const log = id('chatLog');
  const el  = document.createElement('div');
  el.className = role === 'user' ? 'msg-user' : 'msg-ai';

  const ts = fmt(id('audio').currentTime);

  if (role === 'user') {
    el.innerHTML = `
      <div class="msg-label"><i class="ri-user-line"></i> 你</div>
      <div style="font-size:14px;line-height:1.7;">${esc(text)}</div>
      <div style="font-size:11px;color:var(--muted);margin-top:5px;">
        <span class="ts-tag">${ts}</span>
      </div>`;
  } else {
    el.innerHTML = `
      <div class="msg-label"><i class="ri-robot-2-line"></i> AI 助手</div>
      <div class="ai-body ai-content" style="font-size:14px;"></div>`;
    renderMd(el.querySelector('.ai-content'), text);
  }

  log.appendChild(el);
  scrollChat();
  return el;
}

function createAiMsgEl() {
  const log = id('chatLog');
  const el  = document.createElement('div');
  el.className = 'msg-ai';
  el.innerHTML = `
    <div class="msg-label"><i class="ri-robot-2-line"></i> AI 助手</div>
    <div class="ai-body ai-content" style="font-size:14px;"></div>`;
  log.appendChild(el);
  scrollChat();
  return el.querySelector('.ai-content');
}

function addThinking() {
  const log = id('chatLog');
  const el  = document.createElement('div');
  el.className = 'msg-ai';
  el.innerHTML = `
    <div class="msg-label"><i class="ri-robot-2-line"></i> AI 助手</div>
    <div class="typing"><span></span><span></span><span></span></div>
    <div style="font-size:12px;color:var(--muted);margin-top:6px;">正在分析问题...</div>`;
  log.appendChild(el);
  scrollChat();
  return el;
}

function clearChat() {
  id('chatLog').innerHTML = '';
  addMsg('ai', '对话已清空 🗑️\n\n继续提问吧！');
}

function scrollChat() {
  const log = id('chatLog');
  setTimeout(() => { log.scrollTop = log.scrollHeight; }, 40);
}

// ─────────────────────────────────────────────
// Markdown 渲染（简版）
// ─────────────────────────────────────────────
function renderMd(el, raw) {
  // 1. XSS 转义
  let t = esc(raw);

  // 2. Markdown → HTML
  t = t
    // 代码块（```...```）
    .replace(/```[\s\S]*?```/g, m => {
      const code = m.slice(3, -3).replace(/^[a-z]+\n/, '');
      return `<pre style="background:rgba(0,0,0,0.35);border:1px solid var(--border);border-radius:8px;padding:10px 12px;overflow-x:auto;margin:8px 0;"><code style="font-family:monospace;font-size:13px;color:#e2e8f0;">${code}</code></pre>`;
    })
    // 行内代码
    .replace(/`([^`\n]+)`/g, '<code>$1</code>')
    // 粗体
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    // 斜体
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    // ### 标题
    .replace(/^### (.+)$/gm, '<h3 style="font-weight:700;font-size:14px;margin:10px 0 4px;color:var(--accent2);">$1</h3>')
    // ## 标题
    .replace(/^## (.+)$/gm, '<h3 style="font-weight:700;font-size:15px;margin:12px 0 5px;">$1</h3>')
    // # 标题
    .replace(/^# (.+)$/gm, '<h3 style="font-weight:700;font-size:16px;margin:12px 0 6px;">$1</h3>')
    // 无序列表
    .replace(/^[•\-\*] (.+)$/gm, '<li style="margin:3px 0;">$1</li>')
    // 有序列表
    .replace(/^\d+\. (.+)$/gm, '<li style="margin:3px 0;list-style-type:decimal;margin-left:16px;">$1</li>')
    // 双换行 → 段落
    .replace(/\n\n/g, '</p><p style="margin:6px 0;">')
    // 单换行
    .replace(/\n/g, '<br>');

  // 包裹连续 li
  t = t.replace(/(<li[^>]*>[\s\S]*?<\/li>(\s*<br>)*)+/g, m =>
    `<ul style="padding-left:18px;margin:6px 0;">${m.replace(/<br>/g, '')}</ul>`
  );

  el.innerHTML = `<p style="margin:0;">${t}</p>`;
}

// ─────────────────────────────────────────────
// 状态栏
// ─────────────────────────────────────────────
function setStatus(text, active) {
  id('statusText').textContent = text;
  const dot = id('statusDot');
  dot.className = 'dot ' + (active ? 'dot-green' : 'dot-grey');
}

// ─────────────────────────────────────────────
// Toast 提示
// ─────────────────────────────────────────────
function toast(msg, type = 'info') {
  const colors = { info: '#7c6ff7', error: '#ef4444', warning: '#f59e0b', success: '#10b981' };
  const el = document.createElement('div');
  el.className = 'toast';
  el.style.background = colors[type] || colors.info;
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => {
    el.style.opacity = '0';
    el.style.transition = 'opacity 0.3s';
    setTimeout(() => el.remove(), 350);
  }, 3000);
}

// ─────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────
function id(s)      { return document.getElementById(s); }
function show(s)    { const e = typeof s === 'string' ? id(s) : s; if (e) e.style.display = ''; }
function hide(s)    { const e = typeof s === 'string' ? id(s) : s; if (e) e.style.display = 'none'; }
function removeEl(e){ if (e && e.parentNode) e.parentNode.removeChild(e); }

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function showApiModal() {
  show('apiModal');
  toast('请先设置 Claude API Key', 'warning');
}
