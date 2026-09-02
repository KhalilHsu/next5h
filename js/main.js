/**
 * Next5h Official Website - Main JavaScript
 * Handles theme toggle, clipboard copy with feedback, tab switching, accordion, smooth scroll, and i18n.
 */

document.addEventListener('DOMContentLoaded', () => {
  initI18n();
  initThemeToggle();
  initCopyButtons();
  initInstallTabs();
  initFaqAccordion();
  initSmoothScroll();
});

/* --------------------------------------------------------------------------
   0. Internationalization (i18n) Initialization & Toggle
   -------------------------------------------------------------------------- */
function initI18n() {
  if (!window.Next5h_i18n) return;
  const lang = window.Next5h_i18n.getPreferredLanguage();
  window.Next5h_i18n.applyLanguage(lang);

  const langBtn = document.getElementById('lang-toggle-btn');
  if (langBtn) {
    langBtn.addEventListener('click', () => {
      window.Next5h_i18n.toggleLanguage();
    });
  }
}

/* --------------------------------------------------------------------------
   1. Theme Toggle (Dark / Light with System Preference & Storage)
   -------------------------------------------------------------------------- */
function initThemeToggle() {
  const themeToggleBtn = document.getElementById('theme-toggle-btn');
  const themeIcon = document.getElementById('theme-icon');
  if (!themeToggleBtn) return;

  function updateThemeUI(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    const metaColorScheme = document.querySelector('meta[name="color-scheme"]');
    if (metaColorScheme) {
      metaColorScheme.setAttribute('content', theme === 'light' ? 'light' : 'dark');
    }
    if (themeIcon) {
      themeIcon.textContent = theme === 'light' ? '🌙' : '☀️';
    }
  }

  // Determine current theme: localStorage -> system preference -> dark
  const savedTheme = localStorage.getItem('next5h-theme');
  const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const initialTheme = savedTheme || (systemPrefersDark ? 'dark' : 'light');
  updateThemeUI(initialTheme);

  // Toggle button click handler
  themeToggleBtn.addEventListener('click', () => {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    localStorage.setItem('next5h-theme', newTheme);
    updateThemeUI(newTheme);
  });

  // System preference change listener
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('next5h-theme')) {
      updateThemeUI(e.matches ? 'dark' : 'light');
    }
  });
}

/* --------------------------------------------------------------------------
   2. Copy to Clipboard with Feedback & Toast
   -------------------------------------------------------------------------- */
function showToast(message) {
  const currentLang = window.Next5h_i18n ? window.Next5h_i18n.getCurrentLanguage() : 'zh';
  const defaultMsg = (window.Next5h_i18n && window.Next5h_i18n.translations[currentLang]) 
    ? window.Next5h_i18n.translations[currentLang]['toast.copied'] 
    : '已复制到剪贴板！';

  const text = message || defaultMsg;
  let toast = document.getElementById('toast-notice');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast-notice';
    toast.className = 'toast-notice';
    document.body.appendChild(toast);
  }
  toast.innerHTML = `<span>✓</span> <span>${text}</span>`;
  toast.classList.add('show');

  clearTimeout(window._toastTimeout);
  window._toastTimeout = setTimeout(() => {
    toast.classList.remove('show');
  }, 2400);
}

function initCopyButtons() {
  document.querySelectorAll('[data-copy-target]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const targetId = btn.getAttribute('data-copy-target');
      const targetElement = document.getElementById(targetId);
      if (!targetElement) return;

      const textToCopy = targetElement.innerText || targetElement.textContent;
      try {
        await navigator.clipboard.writeText(textToCopy.trim());
        const originalHtml = btn.innerHTML;
        const currentLang = window.Next5h_i18n ? window.Next5h_i18n.getCurrentLanguage() : 'zh';
        const copiedLabel = (window.Next5h_i18n && window.Next5h_i18n.translations[currentLang])
          ? window.Next5h_i18n.translations[currentLang]['hero.copied']
          : '已复制';

        btn.innerHTML = `<span>✓ ${copiedLabel}</span>`;
        btn.style.borderColor = 'rgba(52, 211, 153, 0.6)';
        showToast();

        setTimeout(() => {
          btn.innerHTML = originalHtml;
          btn.style.borderColor = '';
        }, 2000);
      } catch (err) {
        console.error('Failed to copy: ', err);
      }
    });
  });
}

/* --------------------------------------------------------------------------
   3. Installation Methods Tab Switcher
   -------------------------------------------------------------------------- */
function initInstallTabs() {
  const tabs = document.querySelectorAll('.install-tab-btn');
  const panels = document.querySelectorAll('.install-content-panel');

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const targetPanelId = tab.getAttribute('data-tab');

      // Update tabs state
      tabs.forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');

      // Update panels state
      panels.forEach((p) => {
        if (p.id === targetPanelId) {
          p.classList.add('active');
        } else {
          p.classList.remove('active');
        }
      });
    });
  });
}

/* --------------------------------------------------------------------------
   4. FAQ Accordion
   -------------------------------------------------------------------------- */
function initFaqAccordion() {
  const faqItems = document.querySelectorAll('.faq-item');

  faqItems.forEach((item) => {
    const questionBtn = item.querySelector('.faq-question');
    if (!questionBtn) return;

    questionBtn.addEventListener('click', () => {
      const isActive = item.classList.contains('active');

      // Close all other items for clean UX
      faqItems.forEach((other) => {
        if (other !== item) other.classList.remove('active');
      });

      // Toggle current item
      if (isActive) {
        item.classList.remove('active');
      } else {
        item.classList.add('active');
      }
    });
  });
}

/* --------------------------------------------------------------------------
   5. Smooth Anchor Scrolling & Clean URL Hash Handling
   -------------------------------------------------------------------------- */
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (!targetId || targetId === '#') {
        e.preventDefault();
        window.scrollTo({ top: 0, behavior: 'smooth' });
        history.replaceState(null, null, window.location.pathname);
        return;
      }

      const targetEl = document.querySelector(targetId);
      if (targetEl) {
        e.preventDefault();
        const headerOffset = 80;
        const elementPosition = targetEl.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });

        // Update URL hash without causing a page jump
        history.replaceState(null, null, targetId);
      }
    });
  });
}
