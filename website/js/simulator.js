/**
 * Next5h Official Website - Interactive macOS Simulator
 * Showcases 28pt Status Bar Capsule, Plus/Pro switching, and Silent Dispatch
 */

document.addEventListener('DOMContentLoaded', () => {
  initSimulator();
});

function initSimulator() {
  const simContainer = document.getElementById('sim-container');
  const capsuleTrigger = document.getElementById('sim-capsule-trigger');
  const simDropdown = document.getElementById('sim-dropdown');
  const btnPlus = document.getElementById('sim-btn-plus');
  const btnPro = document.getElementById('sim-btn-pro');
  const btnDispatch = document.getElementById('sim-btn-dispatch');

  if (!simContainer || !capsuleTrigger || !simDropdown) return;

  // Plus / Pro data states
  const states = {
    plus: {
      capsuleTop: '5H: 82%',
      capsuleBottom: '周: 65%',
      card1Title: '5 小时滑动窗口 (5H Quota)',
      card1Badge: '监控中',
      card1BadgeClass: 'badge-blue',
      card1Val: '82%',
      card1Sub: '剩余可用额度',
      card1Fill: '82%',
      card1FillClass: 'fill-blue',
      card1FooterLeft: '重置倒计时: 01:24:18',
      card1FooterRight: '策略: 额度解封自动唤醒',

      card2Title: '7 天周周期限额 (Weekly Quota)',
      card2Badge: '充裕',
      card2BadgeClass: 'badge-green',
      card2Val: '65%',
      card2Sub: '周限额剩余可用',
      card2Fill: '65%',
      card2FillClass: 'fill-green',
      card2FooterLeft: '周重置时间: 周日 23:59',
      card2FooterRight: '排定任务: 1 个待触发',

      menuHeader: 'ChatGPT Plus · 5H 自动续航模式',
      menuItem1: '⏱️ 5H 额度解封自动发送：已开启',
      menuItem2: '⏰ 下次硬件唤醒：明天 07:00'
    },
    pro: {
      capsuleTop: 'PRO',
      capsuleBottom: '周: 85%',
      card1Title: 'PRO 尊享全速通道 (Unlimited)',
      card1Badge: '无 5H 频次限制',
      card1BadgeClass: 'badge-green',
      card1Val: '∞',
      card1Sub: '标准/高级模型无限畅用',
      card1Fill: '100%',
      card1FillClass: 'fill-green',
      card1FooterLeft: '通道状态: 全并发即时就绪',
      card1FooterRight: '策略: 无人值守自动化流水线',

      card2Title: 'o1-pro 深度推理算力池 (Weekly Pool)',
      card2Badge: '健康',
      card2BadgeClass: 'badge-purple',
      card2Val: '85%',
      card2Sub: '高阶重构算力剩余',
      card2Fill: '85%',
      card2FillClass: 'fill-purple',
      card2FooterLeft: '周重置时间: 周五 14:00',
      card2FooterRight: '排定流水线: 3 个深夜任务',

      menuHeader: '👑 ChatGPT Pro 专属权益 · 5H 限制已解除',
      menuItem1: '⚡️ 批量连续派发流水线：就绪',
      menuItem2: '⏰ 下次硬件唤醒：凌晨 03:00 (RTC 守护)'
    }
  };

  let currentMode = 'plus';

  function applyMode(mode) {
    currentMode = mode;
    simContainer.setAttribute('data-sim-mode', mode);
    const data = states[mode];

    // Update capsule
    document.getElementById('sim-capsule-top').textContent = data.capsuleTop;
    document.getElementById('sim-capsule-bottom').textContent = data.capsuleBottom;

    // Update buttons
    if (mode === 'plus') {
      btnPlus.classList.add('active');
      btnPro.classList.remove('active');
    } else {
      btnPro.classList.add('active');
      btnPlus.classList.remove('active');
    }

    // Update Card 1
    document.getElementById('sim-c1-title').innerHTML = `<span>⚡️</span> ${data.card1Title}`;
    const b1 = document.getElementById('sim-c1-badge');
    b1.textContent = data.card1Badge;
    b1.className = `sim-badge ${data.card1BadgeClass}`;
    document.getElementById('sim-c1-val').textContent = data.card1Val;
    document.getElementById('sim-c1-sub').textContent = data.card1Sub;
    const f1 = document.getElementById('sim-c1-fill');
    f1.style.width = data.card1Fill;
    f1.className = `sim-progress-fill ${data.card1FillClass}`;
    document.getElementById('sim-c1-foot-left').textContent = data.card1FooterLeft;
    document.getElementById('sim-c1-foot-right').textContent = data.card1FooterRight;

    // Update Card 2
    document.getElementById('sim-c2-title').innerHTML = `<span>📊</span> ${data.card2Title}`;
    const b2 = document.getElementById('sim-c2-badge');
    b2.textContent = data.card2Badge;
    b2.className = `sim-badge ${data.card2BadgeClass}`;
    document.getElementById('sim-c2-val').textContent = data.card2Val;
    document.getElementById('sim-c2-sub').textContent = data.card2Sub;
    const f2 = document.getElementById('sim-c2-fill');
    f2.style.width = data.card2Fill;
    f2.className = `sim-progress-fill ${data.card2FillClass}`;
    document.getElementById('sim-c2-foot-left').textContent = data.card2FooterLeft;
    document.getElementById('sim-c2-foot-right').textContent = data.card2FooterRight;

    // Update Menu
    document.getElementById('sim-menu-header').textContent = data.menuHeader;
    document.getElementById('sim-menu-item1').textContent = data.menuItem1;
    document.getElementById('sim-menu-item2').textContent = data.menuItem2;
  }

  // Event handlers
  btnPlus.addEventListener('click', () => applyMode('plus'));
  btnPro.addEventListener('click', () => applyMode('pro'));

  // Toggle capsule dropdown
  capsuleTrigger.addEventListener('click', (e) => {
    e.stopPropagation();
    simDropdown.classList.toggle('show');
    capsuleTrigger.classList.toggle('active');
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!simDropdown.contains(e.target) && !capsuleTrigger.contains(e.target)) {
      simDropdown.classList.remove('show');
      capsuleTrigger.classList.remove('active');
    }
  });

  // Simulate dispatch
  btnDispatch.addEventListener('click', () => {
    const originalTop = document.getElementById('sim-capsule-top').textContent;
    const originalBottom = document.getElementById('sim-capsule-bottom').textContent;

    // Visual feedback on capsule
    document.getElementById('sim-capsule-top').textContent = '⚡️';
    document.getElementById('sim-capsule-bottom').textContent = 'EXEC';

    // Show simulated toast
    if (typeof showToast === 'function') {
      showToast('🚀 触发静默派发: 已调用 local codex CLI，并在 ChatGPT 窗口内即时呈现！');
    }

    setTimeout(() => {
      document.getElementById('sim-capsule-top').textContent = originalTop;
      document.getElementById('sim-capsule-bottom').textContent = originalBottom;
    }, 2500);
  });
}
