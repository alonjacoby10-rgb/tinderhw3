// dashboard.js — the admin analytics dashboard.
// Fetches aggregated metrics from GET /api/stats and draws them as charts
// on <canvas> (no external chart library — CSP-safe, self-contained).

(function () {
  const dashBtn    = document.getElementById('dashBtn');
  const statsModal = document.getElementById('statsModal');
  const statsError = document.getElementById('statsError');
  const kpiRow     = document.getElementById('kpiRow');

  // Brand palette (kept in sync with styles.css).
  const C = {
    pink:  '#fd267d',
    orange:'#ff7854',
    blue:  '#4a9fff',
    green: '#2dd36f',
    muted: '#9aa0ab',
    text:  '#f5f6fa',
    grid:  'rgba(255,255,255,.07)',
  };
  const FONT = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  const GENDER = { M: { label: 'Male', color: C.blue }, F: { label: 'Female', color: C.pink }, O: { label: 'Other', color: C.muted } };

  let lastData = null; // keep the latest payload so we can redraw on resize

  function authHeaders() {
    const h = {};
    if (window.SESSION && window.SESSION.user_id) h['x-user-id'] = String(window.SESSION.user_id);
    return h;
  }

  // Prepare a canvas for crisp drawing at the current device pixel ratio.
  // Returns the 2D context and the CSS (logical) width/height to draw in.
  function setup(canvas) {
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    const w = Math.max(1, Math.round(rect.width));
    const h = Math.max(1, Math.round(rect.height));
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    const ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);
    return { ctx, w, h };
  }

  function roundRect(ctx, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    if (h <= 0) return;
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  // ---- Donut: gender split ----
  function drawDonut(canvas, items) {
    const { ctx, w, h } = setup(canvas);
    const total = items.reduce((s, i) => s + i.count, 0);
    const cx = w / 2, cy = h / 2;
    const r = Math.min(w, h) / 2 - 6;
    const inner = r * 0.62;

    if (!total) { emptyText(ctx, w, h); return; }

    let start = -Math.PI / 2;
    items.forEach((it) => {
      const ang = (it.count / total) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, r, start, start + ang);
      ctx.closePath();
      ctx.fillStyle = (GENDER[it.gender] || GENDER.O).color;
      ctx.fill();
      start += ang;
    });
    // Punch the hole.
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath(); ctx.arc(cx, cy, inner, 0, Math.PI * 2); ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
    // Center label.
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillStyle = C.text; ctx.font = `700 24px ${FONT}`;
    ctx.fillText(String(total), cx, cy - 5);
    ctx.fillStyle = C.muted; ctx.font = `500 11px ${FONT}`;
    ctx.fillText('profiles', cx, cy + 15);
  }

  function renderLegend(el, items) {
    const total = items.reduce((s, i) => s + i.count, 0) || 1;
    el.innerHTML = items.map((it) => {
      const g = GENDER[it.gender] || GENDER.O;
      const pct = Math.round((it.count / total) * 100);
      return `<span class="lg"><i style="background:${g.color}"></i>${g.label} · ${it.count} (${pct}%)</span>`;
    }).join('');
  }

  // ---- Vertical bars: age distribution ----
  function drawVBars(canvas, labels, values) {
    const { ctx, w, h } = setup(canvas);
    const max = Math.max(...values, 1);
    const pad = { l: 8, r: 8, t: 20, b: 22 };
    const plotW = w - pad.l - pad.r;
    const plotH = h - pad.t - pad.b;
    const slot = plotW / values.length;
    const bw = Math.min(slot * 0.62, 46);

    ctx.textAlign = 'center';
    values.forEach((v, i) => {
      const bh = plotH * (v / max);
      const x = pad.l + i * slot + (slot - bw) / 2;
      const y = pad.t + plotH - bh;
      const grad = ctx.createLinearGradient(0, y, 0, y + bh);
      grad.addColorStop(0, C.orange); grad.addColorStop(1, C.pink);
      ctx.fillStyle = grad;
      roundRect(ctx, x, y, bw, Math.max(bh, 2), 6); ctx.fill();
      // Value on top.
      ctx.fillStyle = C.text; ctx.font = `700 12px ${FONT}`;
      ctx.textBaseline = 'bottom';
      ctx.fillText(String(v), x + bw / 2, y - 4);
      // Axis label.
      ctx.fillStyle = C.muted; ctx.font = `500 11px ${FONT}`;
      ctx.textBaseline = 'top';
      ctx.fillText(labels[i], x + bw / 2, pad.t + plotH + 6);
    });
  }

  // ---- Horizontal bars: top cities ----
  function drawHBars(canvas, items) {
    const { ctx, w, h } = setup(canvas);
    if (!items.length) { emptyText(ctx, w, h); return; }
    const max = Math.max(...items.map((i) => i.count), 1);
    const labelW = 92;
    const valW = 34;
    const pad = { t: 4, b: 4 };
    const barMax = w - labelW - valW;
    const slot = (h - pad.t - pad.b) / items.length;
    const bh = Math.min(slot * 0.6, 26);

    items.forEach((it, i) => {
      const cy = pad.t + i * slot + slot / 2;
      // City name (right-aligned into the bar).
      ctx.fillStyle = C.muted; ctx.font = `500 12px ${FONT}`;
      ctx.textAlign = 'right'; ctx.textBaseline = 'middle';
      ctx.fillText(truncate(it.city, 13), labelW - 10, cy);
      // Bar.
      const bw = Math.max(barMax * (it.count / max), 3);
      const grad = ctx.createLinearGradient(labelW, 0, labelW + bw, 0);
      grad.addColorStop(0, C.pink); grad.addColorStop(1, C.orange);
      ctx.fillStyle = grad;
      roundRect(ctx, labelW, cy - bh / 2, bw, bh, 5); ctx.fill();
      // Count.
      ctx.fillStyle = C.text; ctx.font = `700 12px ${FONT}`;
      ctx.textAlign = 'left';
      ctx.fillText(String(it.count), labelW + bw + 7, cy);
    });
  }

  function truncate(s, n) { s = String(s); return s.length > n ? s.slice(0, n - 1) + '…' : s; }
  function emptyText(ctx, w, h) {
    ctx.fillStyle = C.muted; ctx.font = `500 12px ${FONT}`;
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText('No data yet', w / 2, h / 2);
  }

  function paint(data) {
    // KPIs.
    const t = data.totals;
    const setKpi = (k, v) => { const el = kpiRow.querySelector(`[data-kpi="${k}"]`); if (el) el.textContent = v; };
    setKpi('users', t.users);
    setKpi('swipes', t.swipes);
    setKpi('likes', t.likes);
    setKpi('matches', t.matches);
    setKpi('matchRate', t.matchRate + '%');

    // Charts.
    drawDonut(document.getElementById('genderChart'), data.byGender);
    renderLegend(document.getElementById('genderLegend'), data.byGender);
    drawVBars(document.getElementById('ageChart'),
      data.ageDistribution.map((d) => d.bucket), data.ageDistribution.map((d) => d.count));
    drawHBars(document.getElementById('cityChart'), data.byCity);
  }

  async function load() {
    statsError.style.display = 'none';
    try {
      const res = await fetch('/api/stats', { headers: authHeaders() });
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        throw new Error(b.error || `Server responded ${res.status}`);
      }
      lastData = await res.json();
      // Draw after the modal has laid out so canvases have real dimensions.
      requestAnimationFrame(() => paint(lastData));
    } catch (err) {
      statsError.textContent = '⚠️ ' + err.message;
      statsError.style.display = 'block';
    }
  }

  function open() { statsModal.classList.add('open'); load(); }

  if (dashBtn) dashBtn.addEventListener('click', open);
  statsModal.addEventListener('click', (e) => {
    if (e.target === statsModal || e.target.closest('.close-modal')) statsModal.classList.remove('open');
  });

  // Redraw on resize while the dashboard is open (charts are pixel-sized).
  let resizeTimer = null;
  window.addEventListener('resize', () => {
    if (!statsModal.classList.contains('open') || !lastData) return;
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => paint(lastData), 150);
  });
})();
