document.addEventListener('DOMContentLoaded', () => {
  initNav();
  initReveal();
  initStepper();
  initDoseStrip();
  initInteractionChecker();
});

// القائمة العلوية + قائمة الجوال
function initNav() {
  const nav = document.querySelector('.nav');
  const burger = document.querySelector('.nav-burger');
  const mobileMenu = document.querySelector('.mobile-menu');
  const burgerIcon = burger ? burger.querySelector('img') : null;

  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 40);
  });

  if (burger && mobileMenu) {
    burger.addEventListener('click', () => {
      const isOpen = mobileMenu.classList.toggle('open');
      burgerIcon.src = isOpen ? 'assets/icons/close.svg' : 'assets/icons/menu.svg';
    });
    mobileMenu.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        mobileMenu.classList.remove('open');
        burgerIcon.src = 'assets/icons/menu.svg';
      });
    });
  }
}

// إظهار العناصر تدريجيًا وقت وصولها للشاشة
function initReveal() {
  const items = document.querySelectorAll('[data-reveal]');
  if (!('IntersectionObserver' in window)) {
    items.forEach((el) => el.classList.add('in'));
    return;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  items.forEach((el) => observer.observe(el));
}

// خط "كيف يعمل" يمتلئ وقت ما يوصله المستخدم بالتمرير
function initStepper() {
  const wrap = document.querySelector('.how-wrap');
  const fill = document.querySelector('.stepper-line-fill');
  const steps = document.querySelectorAll('.step');
  if (!wrap || !fill) return;

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          fill.style.width = '100%';
          steps.forEach((step, i) => {
            setTimeout(() => step.classList.add('active'), i * 250);
          });
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.3 }
  );
  observer.observe(wrap);
}

// شريط الجرعات: كل قارورة زر يبدّل حالتها ويحدّث العداد
function initDoseStrip() {
  const caps = document.querySelectorAll('.cap');
  const counter = document.querySelector('.strip-foot b');
  if (!caps.length || !counter) return;

  const total = caps.length;

  function updateCounter() {
    const done = document.querySelectorAll('.cap.done').length;
    counter.textContent = `${toArabicDigits(done)} من ${toArabicDigits(total)} جرعات مأخوذة`;
  }

  caps.forEach((cap) => {
    const bottle = cap.querySelector('.cap-bottle');
    bottle.addEventListener('click', () => {
      cap.classList.toggle('done');
      cap.classList.toggle('pending');
      updateCounter();
    });
  });

  updateCounter();
}

function toArabicDigits(num) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return String(num).replace(/[0-9]/g, (d) => arabic[d]);
}

// فاحص التعارضات: تجربة مصغّرة بأزواج أدوية حقيقية وموثّقة
function initInteractionChecker() {
  const chips = document.querySelectorAll('.chip-select');
  const btn = document.querySelector('.check-btn');
  const resultArea = document.querySelector('.result-area');
  if (!chips.length || !btn || !resultArea) return;

  const knownInteractions = [
    {
      pair: ['وارفارين', 'إيبوبروفين'],
      severity: 'خطورة عالية',
      title: 'تعارض دوائي محتمل',
      text: 'إيبوبروفين قد يزيد من خطر النزيف عند أخذه مع وارفارين. يُفضّل استشارة الطبيب قبل الجمع بينهما.',
    },
    {
      pair: ['وارفارين', 'أسبرين'],
      severity: 'خطورة عالية',
      title: 'تعارض دوائي محتمل',
      text: 'الجمع بين وارفارين وأسبرين يزيد من خطر النزيف بشكل ملحوظ، ويُفضّل تجنّبه دون إشراف طبي.',
    },
    {
      pair: ['سيمفاستاتين', 'كلاريثروميسين'],
      severity: 'خطورة متوسطة',
      title: 'تعارض دوائي محتمل',
      text: 'كلاريثروميسين قد يرفع تركيز سيمفاستاتين في الدم، ما يزيد من خطر تأثر العضلات.',
    },
  ];

  let selected = [];

  chips.forEach((chip) => {
    chip.addEventListener('click', () => {
      const name = chip.dataset.med;

      if (chip.classList.contains('active')) {
        chip.classList.remove('active');
        selected = selected.filter((m) => m !== name);
      } else {
        if (selected.length >= 2) {
          const first = [...chips].find((c) => c.dataset.med === selected[0]);
          first.classList.remove('active');
          selected.shift();
        }
        chip.classList.add('active');
        selected.push(name);
      }

      btn.disabled = selected.length !== 2;
      resultArea.innerHTML = '';
    });
  });

  btn.addEventListener('click', () => {
    if (selected.length !== 2) return;

    const found = knownInteractions.find(
      (item) =>
        (item.pair[0] === selected[0] && item.pair[1] === selected[1]) ||
        (item.pair[0] === selected[1] && item.pair[1] === selected[0])
    );

    resultArea.innerHTML = found ? buildDangerCard(found) : buildSafeCard(selected);

    requestAnimationFrame(() => {
      const card = resultArea.querySelector('.result-card');
      if (card) card.classList.add('show');
    });
  });

  function buildDangerCard(item) {
    return `
      <div class="result-card danger">
        <div class="result-icon"><img src="assets/icons/warning.svg" alt=""></div>
        <div>
          <div class="result-title">${item.title}</div>
          <p class="result-text">${item.text}</p>
          <span class="sev-tag">${item.severity}</span>
        </div>
      </div>`;
  }

  function buildSafeCard(pair) {
    return `
      <div class="result-card safe">
        <div class="result-icon"><img src="assets/icons/check.svg" alt=""></div>
        <div>
          <div class="result-title">لا يوجد تعارض معروف</div>
          <p class="result-text">لم نجد تعارضًا موثّقًا بين ${pair[0]} و${pair[1]} في قاعدتنا. هذا لا يغني عن استشارة الطبيب أو الصيدلي دائمًا.</p>
        </div>
      </div>`;
  }
}