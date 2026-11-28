/* Jednotný vzhľad disciplín na celom webe (hlavná stránka aj stránka testov).
   Farba = kategória, ikona = konkrétna disciplína. Novú disciplínu stačí pridať do zoznamu nižšie;
   ak v ňom nie je, kategória sa odhadne z názvu a dostane ikonu kategórie. */
(function () {
  // Kategórie v poradí, v akom sa zobrazujú (najprv hlava, potom telo)
  const CATS = {
    rychlost: { color: '#2563eb', icon: 'bolt', kind: 'cognitive' },
    pamat:    { color: '#9333ea', icon: 'grid', kind: 'cognitive' },
    postreh:  { color: '#d97706', icon: 'eye', kind: 'cognitive' },
    odhad:    { color: '#0d9488', icon: 'clock', kind: 'cognitive' },
    logika:   { color: '#16a34a', icon: 'puzzle', kind: 'cognitive' },
    sila:     { color: '#dc2626', icon: 'dumbbell', kind: 'sport' },
    vytrvalost: { color: '#ea580c', icon: 'run', kind: 'sport' },
    voda:     { color: '#0284c7', icon: 'wave', kind: 'sport' }
  };
  const ORDER = Object.keys(CATS);

  const LABELS = {
    sk: ['Rýchlosť a reakcia', 'Pamäť', 'Postreh a vnímanie', 'Odhad', 'Logika a jazyk', 'Sila', 'Vytrvalosť', 'Voda'],
    cz: ['Rychlost a reakce', 'Paměť', 'Postřeh a vnímání', 'Odhad', 'Logika a jazyk', 'Síla', 'Vytrvalost', 'Voda'],
    en: ['Speed & reaction', 'Memory', 'Perception', 'Estimation', 'Logic & language', 'Strength', 'Endurance', 'Water'],
    de: ['Tempo & Reaktion', 'Gedächtnis', 'Wahrnehmung', 'Schätzen', 'Logik & Sprache', 'Kraft', 'Ausdauer', 'Wasser'],
    fr: ['Vitesse & réaction', 'Mémoire', 'Perception', 'Estimation', 'Logique & langue', 'Force', 'Endurance', 'Eau'],
    es: ['Velocidad y reacción', 'Memoria', 'Percepción', 'Estimación', 'Lógica y lenguaje', 'Fuerza', 'Resistencia', 'Agua'],
    it: ['Velocità e reazione', 'Memoria', 'Percezione', 'Stima', 'Logica e linguaggio', 'Forza', 'Resistenza', 'Acqua'],
    pt: ['Velocidade e reação', 'Memória', 'Perceção', 'Estimativa', 'Lógica e linguagem', 'Força', 'Resistência', 'Água'],
    pl: ['Szybkość i reakcja', 'Pamięć', 'Spostrzegawczość', 'Szacowanie', 'Logika i język', 'Siła', 'Wytrzymałość', 'Woda'],
    hu: ['Gyorsaság és reakció', 'Memória', 'Észlelés', 'Becslés', 'Logika és nyelv', 'Erő', 'Állóképesség', 'Víz'],
    uk: ['Швидкість і реакція', 'Пам’ять', 'Сприйняття', 'Оцінка', 'Логіка та мова', 'Сила', 'Витривалість', 'Вода'],
    ro: ['Viteză și reacție', 'Memorie', 'Percepție', 'Estimare', 'Logică și limbaj', 'Forță', 'Rezistență', 'Apă'],
    nl: ['Snelheid & reactie', 'Geheugen', 'Waarneming', 'Schatten', 'Logica & taal', 'Kracht', 'Uithoudingsvermogen', 'Water'],
    hi: ['गति और प्रतिक्रिया', 'स्मृति', 'बोध', 'अनुमान', 'तर्क और भाषा', 'ताकत', 'सहनशक्ति', 'पानी'],
    zh: ['速度与反应', '记忆', '感知', '估算', '逻辑与语言', '力量', '耐力', '水上'],
    ja: ['スピードと反応', '記憶', '知覚', '推定', '論理と言語', '筋力', '持久力', '水泳'],
    ko: ['속도와 반응', '기억', '지각', '추정', '논리와 언어', '근력', '지구력', '수영'],
    id: ['Kecepatan & reaksi', 'Memori', 'Persepsi', 'Perkiraan', 'Logika & bahasa', 'Kekuatan', 'Daya tahan', 'Air'],
    th: ['ความเร็วและปฏิกิริยา', 'ความจำ', 'การรับรู้', 'การประมาณ', 'ตรรกะและภาษา', 'ความแข็งแรง', 'ความอดทน', 'ทางน้ำ'],
    my: ['အမြန်နှုန်းနှင့် တုံ့ပြန်မှု', 'မှတ်ဉာဏ်', 'အာရုံခံမှု', 'ခန့်မှန်းခြင်း', 'ယုတ္တိနှင့် ဘာသာစကား', 'ခွန်အား', 'ကြံ့ခိုင်မှု', 'ရေ'],
    fil: ['Bilis at reaksiyon', 'Memorya', 'Persepsiyon', 'Pagtantiya', 'Lohika at wika', 'Lakas', 'Tibay', 'Tubig']
  };

  // Test (hb_test) → [kategória, ikona]
  const TESTS = {
    reakcia: ['rychlost', 'bolt'], mierenie: ['rychlost', 'target'], klikanie: ['rychlost', 'cursor'],
    gonogo: ['rychlost', 'light'], ciara: ['rychlost', 'finish'],
    sekvencia: ['pamat', 'grid'], cisla: ['pamat', 'hash'], slova: ['pamat', 'chat'],
    vizualna: ['pamat', 'squares'], simpanz: ['pamat', 'circles'], nback: ['pamat', 'layers'],
    farby: ['postreh', 'palette'], bodky: ['postreh', 'dots'], lopticky: ['postreh', 'orbit'],
    pismeno: ['postreh', 'search'], schulte: ['postreh', 'table'],
    cas: ['odhad', 'clock'], uhol: ['odhad', 'angle'],
    pocty: ['logika', 'math'], stroop: ['logika', 'letter'], anagramy: ['logika', 'shuffle'],
    rotacia: ['logika', 'rotate'], pisanie: ['logika', 'keyboard'], skcz: ['logika', 'speech'], vybrane: ['logika', 'pencil']
  };
  // Športové disciplíny podľa id
  const SPORTS = {
    biceps_1m: ['sila', 'dumbbell'], bench_1m: ['sila', 'barbell'], squats_1m: ['sila', 'kettlebell'],
    s_f6b5817d5a: ['sila', 'updown'], s_dbbc7a517c: ['sila', 'plank'],
    treadmill_10m: ['vytrvalost', 'run'], treadmill_20m: ['vytrvalost', 'run'], treadmill_30m: ['vytrvalost', 'run'], treadmill_1h: ['vytrvalost', 'run'],
    swim_25m_25: ['voda', 'wave'], swim_50m_25: ['voda', 'wave'], swim_50m_50: ['voda', 'wave']
  };

  // Ikony 24×24, kreslené čiarou (stroke = farba kategórie)
  const ICONS = {
    bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',
    target: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/>',
    cursor: '<path d="M5 3l14 7-6 2-2 6z"/><path d="M13 12l5 5"/>',
    light: '<rect x="8" y="2" width="8" height="20" rx="3"/><circle cx="12" cy="7" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="12" cy="17" r="1.8"/>',
    finish: '<path d="M3 12h11"/><path d="M10 7l5 5-5 5"/><path d="M19 3v18"/>',
    grid: '<rect x="3" y="3" width="5" height="5" rx="1"/><rect x="9.5" y="3" width="5" height="5" rx="1"/><rect x="16" y="3" width="5" height="5" rx="1"/><rect x="3" y="9.5" width="5" height="5" rx="1"/><rect x="9.5" y="9.5" width="5" height="5" rx="1" fill="currentColor"/><rect x="16" y="9.5" width="5" height="5" rx="1"/><rect x="3" y="16" width="5" height="5" rx="1"/><rect x="9.5" y="16" width="5" height="5" rx="1"/><rect x="16" y="16" width="5" height="5" rx="1"/>',
    hash: '<path d="M9 3 7 21M17 3l-2 18M4 8h17M3 16h17"/>',
    chat: '<path d="M4 5h16v11H9l-5 4z"/><path d="M8 9h8M8 12h5"/>',
    squares: '<rect x="3" y="3" width="8" height="8" rx="1.5" fill="currentColor"/><rect x="13" y="3" width="8" height="8" rx="1.5"/><rect x="3" y="13" width="8" height="8" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5" fill="currentColor"/>',
    circles: '<circle cx="6" cy="6" r="3"/><circle cx="18" cy="7" r="3"/><circle cx="8" cy="17" r="3"/><circle cx="17" cy="17" r="3" fill="currentColor"/>',
    layers: '<path d="M12 3 2 8l10 5 10-5z"/><path d="M2 13l10 5 10-5"/><path d="M2 18l10 5 10-5"/>',
    palette: '<circle cx="9" cy="9" r="5"/><circle cx="15" cy="9" r="5"/><circle cx="12" cy="15" r="5"/>',
    dots: '<circle cx="6" cy="7" r="1.6" fill="currentColor"/><circle cx="13" cy="5" r="1.6" fill="currentColor"/><circle cx="18" cy="11" r="1.6" fill="currentColor"/><circle cx="9" cy="13" r="1.6" fill="currentColor"/><circle cx="15" cy="18" r="1.6" fill="currentColor"/><circle cx="6" cy="19" r="1.6" fill="currentColor"/>',
    orbit: '<ellipse cx="12" cy="12" rx="10" ry="5"/><circle cx="12" cy="12" r="2.2" fill="currentColor"/><circle cx="21" cy="11" r="1.6" fill="currentColor"/><circle cx="4" cy="15" r="1.6" fill="currentColor"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="M15.5 15.5 21 21"/>',
    table: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>',
    clock: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2"/><path d="M9 2h6"/>',
    angle: '<path d="M4 20h16"/><path d="M4 20 15 5"/><path d="M10 20a6 6 0 0 0-2.4-4.8"/>',
    math: '<path d="M7 4v6M4 7h6"/><path d="M14 7h6"/><path d="M5 15l4 4M9 15l-4 4"/><path d="M14 16h6M14 19h6"/>',
    letter: '<path d="M4 20 10 4h1l6 16"/><path d="M6.5 14h8"/><circle cx="19.5" cy="5.5" r="2" fill="currentColor"/>',
    shuffle: '<path d="M3 7h4l10 10h4"/><path d="M3 17h4l3-3M14 10l3-3h4"/><path d="M18 4l3 3-3 3M18 14l3 3-3 3"/>',
    rotate: '<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/><rect x="9" y="9" width="6" height="6" rx="1"/>',
    keyboard: '<rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M7 14h10"/>',
    speech: '<path d="M3 4h11v7H7l-4 3z"/><path d="M10 14h7l4 3v-9h-4"/>',
    pencil: '<path d="M4 20l1-5L16 4l4 4L9 19z"/><path d="M13 7l4 4"/>',
    puzzle: '<path d="M4 8h4a2 2 0 1 1 4 0h4v4a2 2 0 1 1 0 4v4H4z"/>',
    eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    dumbbell: '<path d="M6 7v10M3 9v6M18 7v10M21 9v6M6 12h12"/>',
    barbell: '<path d="M2 12h20"/><rect x="4" y="7" width="3" height="10" rx="1"/><rect x="17" y="7" width="3" height="10" rx="1"/><path d="M9 8v8M15 8v8"/>',
    kettlebell: '<path d="M8 8a4 4 0 0 1 8 0"/><path d="M6.5 10h11l1.5 6a4 4 0 0 1-4 5H9a4 4 0 0 1-4-5z"/>',
    updown: '<path d="M12 3v18"/><path d="M8 7l4-4 4 4M8 17l4 4 4-4"/>',
    plank: '<circle cx="5" cy="9" r="2"/><path d="M7 11l13 3"/><path d="M8 11v6M20 14v3"/><path d="M3 19h19"/>',
    run: '<circle cx="15" cy="4" r="2"/><path d="M13 8l-3 5 4 2-2 6"/><path d="M13 8l4 4 3-1"/><path d="M10 13l-5 1"/>',
    wave: '<path d="M2 16c2 2 4 2 6 0s4-2 6 0 4 2 6 0"/><path d="M2 20c2 2 4 2 6 0s4-2 6 0 4 2 6 0"/><circle cx="14" cy="7" r="2"/><path d="M5 12l5-4 4 3 4-2"/>'
  };

  function guessCat(s) {
    const n = String((s && s.name) || '').toLowerCase();
    if (/pláv|plav|swim/.test(n)) return 'voda';
    if (/beh|bež|pás|run|km/.test(n)) return 'vytrvalost';
    if (s && (s.kind === 'cognitive' || s.hb_test || s.hbTest)) return 'logika';
    return 'sila';
  }
  function info(s) {
    if (!s) return { cat: 'logika', icon: 'puzzle' };
    const t = s.hb_test || s.hbTest;
    const hit = (t && TESTS[t]) || SPORTS[s.id];
    if (hit) return { cat: hit[0], icon: hit[1] };
    const cat = guessCat(s);
    return { cat, icon: CATS[cat].icon };
  }

  window.DISC = {
    CATS, ORDER, LABELS, TESTS, ICONS,
    catOf: s => info(s).cat,
    catOfTest: id => (TESTS[id] || ['logika'])[0],
    color: s => CATS[info(s).cat].color,
    colorOfTest: id => CATS[(TESTS[id] || ['logika'])[0]].color,
    order: s => ORDER.indexOf(info(s).cat),
    label: (cat, lang) => (LABELS[lang] || LABELS.en)[ORDER.indexOf(cat)] || cat,
    // ikona disciplíny ako SVG; size v px
    icon: (s, size) => svg(info(s).icon, size),
    iconOfTest: (id, size) => svg((TESTS[id] || [0, 'puzzle'])[1], size),
    svg
  };
  function svg(name, size) {
    const z = size || 18;
    return `<svg aria-hidden="true" width="${z}" height="${z}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:block">${ICONS[name] || ICONS.puzzle}</svg>`;
  }
})();
