/* Next5h site behaviour: i18n, theme, and the three interactive demos. */

(() => {
  'use strict';

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const i18n = window.Next5h_i18n;
  const store = {
    get(k) { try { return localStorage.getItem(k); } catch { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch { /* unavailable */ } },
  };

  /* ---------------- Language ---------------- */

  let lang = i18n.getPreferredLanguage();
  const t = (key) => (i18n.translations[lang] || i18n.translations.en)[key] || '';
  const langListeners = [];

  // The copy carries decorative emoji and arrows; the new design draws its own
  // markers, so strip them on elements marked data-strip.
  const LEADING = /^(?:[\p{Extended_Pictographic}☀-➿️‍]+\s*)+/u;
  const TRAILING = /\s*[➔→]\s*$/u;
  function stripDecor() {
    $$('[data-strip]').forEach((el) => {
      if (el.hasAttribute('data-i18n-html')) {
        el.innerHTML = el.innerHTML.replace(LEADING, '').replace(TRAILING, '');
      } else {
        el.textContent = el.textContent.replace(LEADING, '').replace(TRAILING, '');
      }
    });
  }

  function setLang(next) {
    lang = next;
    i18n.applyLanguage(next);
    stripDecor();
    langListeners.forEach((fn) => fn());
  }

  $('#lang-toggle-btn').addEventListener('click', () => setLang(lang === 'zh' ? 'en' : 'zh'));

  /* ---------------- Theme ---------------- */

  const lightQuery = window.matchMedia('(prefers-color-scheme: light)');
  const theme = () => document.documentElement.getAttribute('data-theme') || (lightQuery.matches ? 'light' : 'dark');
  $('#theme-toggle-btn').addEventListener('click', () => {
    const next = theme() === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    store.set('next5h-theme', next);
  });

  /* ---------------- Hero: wake → dispatch sequence ---------------- */

  const instrument = $('#instrument');
  const clock = $('#clock');
  const hand = $('#hand');
  const tip = $('#hand-tip');
  const arc = $('#window-arc');
  const seqItems = $$('#seq li');
  const stateText = $('#ins-state-text');

  // Hour ticks on a 12-hour face.
  const ticks = $('#ticks');
  for (let i = 0; i < 60; i += 1) {
    const major = i % 5 === 0;
    const a = (i / 60) * Math.PI * 2;
    const r1 = major ? 128 : 133;
    const r2 = 140;
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    line.setAttribute('x1', 160 + r1 * Math.sin(a));
    line.setAttribute('y1', 160 - r1 * Math.cos(a));
    line.setAttribute('x2', 160 + r2 * Math.sin(a));
    line.setAttribute('y2', 160 - r2 * Math.cos(a));
    line.setAttribute('class', major ? 'tick major' : 'tick');
    ticks.append(line);
  }

  const toSec = (hms) => hms.split(':').reduce((acc, n) => acc * 60 + Number(n), 0);
  const fmt = (s) => [Math.floor(s / 3600), Math.floor((s % 3600) / 60), Math.floor(s % 60)].map((n) => String(n).padStart(2, '0')).join(':');
  const START = toSec('06:58:40');
  const END = toSec('07:00:20');
  const SPEED = 16; // simulated seconds per real second
  const marks = seqItems.map((li) => toSec(li.dataset.at));
  let simStart = 0;
  let phase = 'sleep';
  let heroTimer = null;
  let heroVisible = true;

  function setHand(sec) {
    const deg = ((sec / 3600) % 12) * 30;
    hand.setAttribute('transform', `rotate(${deg} 160 160)`);
    tip.setAttribute('transform', `rotate(${deg} 160 160)`);
  }

  function setPhase(next) {
    phase = next;
    instrument.classList.toggle('is-awake', next !== 'sleep');
    instrument.classList.toggle('is-live', next === 'live');
    stateText.textContent = t({ sleep: 'x.stSleep', wake: 'x.stWake', send: 'x.stSend', live: 'x.stLive' }[next]);
    // The window arc spans 07:00 → 12:00: five of twelve hours on the face.
    arc.setAttribute('transform', 'rotate(120 160 160)');
    arc.setAttribute('stroke-dasharray', next === 'live' ? '41.67 100' : '0 100');
  }

  function renderAt(sec) {
    clock.textContent = fmt(sec);
    setHand(sec);
    seqItems.forEach((li, i) => li.classList.toggle('is-done', sec >= marks[i]));
    const next = sec >= marks[3] ? 'live' : sec >= marks[2] ? 'send' : sec >= marks[0] ? 'wake' : 'sleep';
    if (next !== phase) setPhase(next);
  }

  function runHero() {
    cancelAnimationFrame(heroTimer);
    phase = '';
    simStart = performance.now();
    const loop = (now) => {
      const sec = Math.min(END, START + ((now - simStart) / 1000) * SPEED);
      renderAt(sec);
      if (sec < END) {
        heroTimer = requestAnimationFrame(loop);
      } else {
        heroTimer = setTimeout(() => { if (heroVisible) runHero(); else heroTimer = null; }, 3600);
      }
    };
    heroTimer = requestAnimationFrame(loop);
  }

  if (reduceMotion) {
    renderAt(END);
  } else {
    new IntersectionObserver((entries) => {
      heroVisible = entries[0].isIntersecting;
      if (heroVisible && heroTimer === null) runHero();
    }).observe(instrument);
    runHero();
  }
  langListeners.push(() => setPhase(phase || 'sleep'));

  /* ---------------- Pillar 1: queue dispatch on reset ---------------- */

  const queue = $('#queue');
  const quotaNum = $('#quota-num');
  const quotaBar = $('#quota-bar');
  const quotaCount = $('#quota-count');
  const qItems = $$('#q-list li');
  let queueTimers = [];
  let queueState = { quota: 0, count: 6, states: qItems.map(() => 'x.qWaiting') };

  function renderQueue() {
    quotaNum.textContent = `${queueState.quota}%`;
    quotaBar.style.width = `${queueState.quota}%`;
    quotaCount.textContent = fmt(queueState.count);
    queue.classList.toggle('is-open', queueState.quota > 0);
    qItems.forEach((li, i) => {
      const s = queueState.states[i];
      li.classList.toggle('is-sending', s === 'x.qSending');
      li.classList.toggle('is-sent', s === 'x.qSent');
      const label = $('.q-state', li);
      label.textContent = t(s);
      label.setAttribute('data-i18n', s);
    });
  }

  function runQueue() {
    queueTimers.forEach(clearTimeout);
    queueTimers = [];
    queueState = { quota: 0, count: 6, states: qItems.map(() => 'x.qWaiting') };
    renderQueue();
    const later = (ms, fn) => queueTimers.push(setTimeout(fn, ms));
    for (let i = 1; i <= 6; i += 1) {
      later(i * 1000, () => { queueState.count = 6 - i; renderQueue(); });
    }
    later(6200, () => { queueState.quota = 100; renderQueue(); });
    const usage = [12, 9, 6];
    qItems.forEach((_, i) => {
      const base = 7000 + i * 1500;
      later(base, () => { queueState.states[i] = 'x.qSending'; renderQueue(); });
      later(base + 900, () => {
        queueState.states[i] = 'x.qSent';
        queueState.quota -= usage[i];
        renderQueue();
      });
    });
  }

  $('#queue-replay').addEventListener('click', runQueue);
  const queueObserver = new IntersectionObserver((entries) => {
    if (!entries[0].isIntersecting) return;
    queueObserver.disconnect();
    runQueue();
  }, { threshold: 0.4 });
  queueObserver.observe(queue);
  renderQueue();
  langListeners.push(renderQueue);

  /* ---------------- Pillar 2: how many 5H windows fit the day ---------------- */

  const slider = $('#day-slider');
  const dayTime = $('#day-time');
  const dayNum = $('#day-num');
  const windowsEl = $('#windows');
  const hhmm = (h) => `${String(Math.floor(h)).padStart(2, '0')}:${h % 1 ? '30' : '00'}`;
  const pos = (h) => ((h - 6) / 18) * 100;
  let lastCount = null;

  function renderDay() {
    const start = Number(slider.value);
    dayTime.textContent = hhmm(start);
    windowsEl.innerHTML = '';
    let full = 0;
    for (let s = start, n = 1; s < 24; s += 5, n += 1) {
      const end = Math.min(s + 5, 24);
      const fits = s + 5 <= 22;
      if (fits) full += 1;
      const win = document.createElement('div');
      win.className = fits ? 'win' : 'win is-partial';
      win.style.left = `${pos(s)}%`;
      win.style.width = `${pos(end) - pos(s)}%`;
      win.innerHTML = `<b>W${n}</b>${hhmm(s)}`;
      windowsEl.append(win);
    }
    dayNum.textContent = String(full);
    if (lastCount !== null && lastCount !== full) {
      dayNum.classList.remove('bump');
      void dayNum.offsetWidth;
      dayNum.classList.add('bump');
      setTimeout(() => dayNum.classList.remove('bump'), 250);
    }
    lastCount = full;
  }

  slider.addEventListener('input', renderDay);
  $('#day-reset').addEventListener('click', () => {
    slider.value = '7';
    renderDay();
  });
  renderDay();

  /* ---------------- Pipeline progress ---------------- */

  const circuit = $('#circuit');
  const nodes = $$('.node', circuit);
  function updateCircuit() {
    const r = circuit.getBoundingClientRect();
    const vh = window.innerHeight;
    const p = Math.max(0, Math.min(1, (vh * 0.8 - r.top) / (vh * 0.45)));
    circuit.style.setProperty('--p', p.toFixed(3));
    nodes.forEach((node, i) => node.classList.toggle('is-on', p >= (i / (nodes.length - 1)) - 0.001 && p > 0));
  }
  window.addEventListener('scroll', updateCircuit, { passive: true });
  window.addEventListener('resize', updateCircuit);
  updateCircuit();

  /* ---------------- Copy + toast ---------------- */

  function toast(text) {
    let el = $('.toast');
    if (!el) {
      el = document.createElement('div');
      el.className = 'toast';
      el.setAttribute('role', 'status');
      document.body.append(el);
    }
    el.textContent = text;
    el.classList.add('show');
    clearTimeout(toast.timer);
    toast.timer = setTimeout(() => el.classList.remove('show'), 2200);
  }

  $$('[data-copy-target]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const text = $(`#${btn.dataset.copyTarget}`).innerText.trim();
      try {
        await navigator.clipboard.writeText(text);
        btn.classList.add('is-done');
        $('span', btn).textContent = t('hero.copied');
        toast(t('toast.copied'));
        setTimeout(() => {
          btn.classList.remove('is-done');
          $('span', btn).textContent = t('hero.copyBtn');
        }, 1800);
      } catch {
        const range = document.createRange();
        range.selectNodeContents($(`#${btn.dataset.copyTarget}`));
        getSelection().removeAllRanges();
        getSelection().addRange(range);
      }
    });
  });

  /* ---------------- FAQ: animated open/close ---------------- */

  $$('.faq details').forEach((details) => {
    const summary = $('summary', details);
    const body = $('.faq-a', details);
    summary.addEventListener('click', (e) => {
      if (reduceMotion) return;
      e.preventDefault();
      if (details.dataset.busy) return;
      details.dataset.busy = '1';
      const opening = !details.open;
      if (opening) details.open = true;
      const h = body.scrollHeight;
      const anim = body.animate(
        { height: opening ? ['0px', `${h}px`] : [`${h}px`, '0px'], opacity: opening ? [0, 1] : [1, 0] },
        { duration: 260, easing: 'cubic-bezier(0.2, 0.7, 0.2, 1)' }
      );
      anim.onfinish = () => {
        if (!opening) details.open = false;
        delete details.dataset.busy;
      };
    });
  });

  /* ---------------- Latest release ---------------- */

  fetch('https://api.github.com/repos/KhalilHsu/next5h/releases/latest', { headers: { Accept: 'application/vnd.github+json' } })
    .then((res) => (res.ok ? res.json() : null))
    .then((release) => {
      const dmg = release && (release.assets || []).find((a) => /\.dmg$/i.test(a.name));
      if (!dmg) return;
      const version = release.tag_name.startsWith('v') ? release.tag_name : `v${release.tag_name}`;
      $$('[data-release-link]').forEach((a) => { a.href = dmg.browser_download_url; });
      $$('[data-release-version]').forEach((el) => { el.textContent = version; });
      $$('[data-release-size]').forEach((el) => { el.textContent = `${(dmg.size / 1048576).toFixed(1)} MB`; });
    })
    .catch(() => { /* keep static links */ });

  /* ---------------- Reveal ---------------- */

  if (!reduceMotion && 'IntersectionObserver' in window) {
    const targets = $$('.sec-head, .pillar-copy, .widget, .node, .matrix, .dl, .src, .check, .shot, .faq');
    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-in');
        io.unobserve(entry.target);
      });
    }, { rootMargin: '0px 0px -8% 0px' });
    targets.forEach((el) => {
      el.classList.add('reveal');
      io.observe(el);
    });
  }

  setLang(lang);
})();
