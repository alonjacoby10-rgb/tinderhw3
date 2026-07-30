// app.js — frontend logic for the TinderHW3 PoC.

// ---- Element references ----
const loadBtn   = document.getElementById('loadBtn');
const matchesBtn = document.getElementById('matchesBtn');
const matchesModal = document.getElementById('matchesModal');
const matchesList = document.getElementById('matchesList');
const likesBtn = document.getElementById('likesBtn');
const likesModal = document.getElementById('likesModal');
const likesList = document.getElementById('likesList');
const controls  = document.getElementById('controls');
const searchEl  = document.getElementById('search');
const genderSel = document.getElementById('genderFilter');
const minAgeEl  = document.getElementById('minAge');
const maxAgeEl  = document.getElementById('maxAge');
const sortSel   = document.getElementById('sortBy');
const hintEl    = document.getElementById('hint');
const statusEl  = document.getElementById('status');
const grid      = document.getElementById('grid');
const modal     = document.getElementById('matchModal');

const FALLBACK_IMG = 'https://placehold.co/400x400/1b1f27/9aa0ab?text=No+Photo';

// ---- Toast notifications (shared across app.js / admin.js / auth.js) ----
window.toast = function (msg, type = '') {
  const wrap = document.getElementById('toast');
  if (!wrap) return;
  const el = document.createElement('div');
  el.className = 'toast-item' + (type ? ' ' + type : '');
  el.textContent = msg;
  wrap.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => el.remove(), 300);
  }, 2600);
};

// ---- State ----
let allProfiles = [];     // everything from the API (source of truth)
let currentUserId = null; // the profile "you" are acting as

// ---- Helpers ----
function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function genderClass(g) { return g === 'M' ? 'male' : g === 'F' ? 'female' : 'other'; }
function genderLabel(g) { return g === 'M' ? 'Male' : g === 'F' ? 'Female' : 'Other'; }

// ---- Rendering ----
function renderSkeletons(n = 8) {
  grid.innerHTML = Array.from({ length: n }).map(() => `
    <div class="card skeleton">
      <div class="photo"></div>
      <div class="body"><div class="line"></div><div class="line short"></div></div>
    </div>`).join('');
}

function cardHtml(p) {
  const superYou = p.superliked_you;
  return `
    <div class="card${superYou ? ' superliked-you' : ''}" data-id="${p.user_id}">
      <div class="photo">
        <span class="stamp like-stamp">LIKE</span>
        <span class="stamp nope-stamp">NOPE</span>
        <span class="stamp super-stamp">SUPER</span>
        ${superYou ? '<span class="super-ribbon">⭐ Superliked you</span>' : ''}
        <img src="${escapeHtml(p.photo_url) || FALLBACK_IMG}" alt="${escapeHtml(p.first_name)}"
             onerror="this.src='${FALLBACK_IMG}'">
        <div class="name-age">
          ${escapeHtml(p.first_name)} ${escapeHtml(p.last_name)}
          <span class="age">${p.age != null ? ', ' + p.age : ''}</span>
        </div>
      </div>
      <div class="body">
        <div class="meta">
          <span class="badge ${genderClass(p.gender)}">${genderLabel(p.gender)}</span>
          <span>📍 ${escapeHtml(p.location_name) || 'Unknown'}</span>
        </div>
        <div class="bio">${escapeHtml(p.bio) || '<em style="color:#666">No bio yet</em>'}</div>
        <div class="actions">
          <button class="action-btn nope" data-act="dislike"
                  data-tip="Nope — not interested. They won't know." title="Nope (←)">✖️</button>
          <button class="action-btn super" data-act="superlike"
                  data-tip="Superlike — you really like them. They'll see it before deciding." title="Superlike (↑)">⭐</button>
          <button class="action-btn like" data-act="like"
                  data-tip="Like — interested. It's a match only if they like you back." title="Like (→)">❤️</button>
        </div>
      </div>
    </div>`;
}

// Apply the "you are" exclusion + search + filters + sort, then render.
function applyFilters() {
  const q = searchEl.value.trim().toLowerCase();
  const gender = genderSel.value;                 // '', 'M', 'F'
  const minAge = parseInt(minAgeEl.value, 10);
  const maxAge = parseInt(maxAgeEl.value, 10);

  let list = allProfiles.filter((p) => p.user_id !== currentUserId);

  if (q) {
    list = list.filter((p) => {
      const name = `${p.first_name} ${p.last_name}`.toLowerCase();
      const city = (p.location_name || '').toLowerCase();
      return name.includes(q) || city.includes(q);
    });
  }
  if (gender) list = list.filter((p) => p.gender === gender);
  if (Number.isInteger(minAge)) list = list.filter((p) => p.age != null && p.age >= minAge);
  if (Number.isInteger(maxAge)) list = list.filter((p) => p.age != null && p.age <= maxAge);

  // Sorting
  const sort = sortSel.value;
  const by = {
    age_asc:  (a, b) => (a.age ?? 999) - (b.age ?? 999),
    age_desc: (a, b) => (b.age ?? -1) - (a.age ?? -1),
    name:     (a, b) => a.first_name.localeCompare(b.first_name),
    city:     (a, b) => (a.location_name || '').localeCompare(b.location_name || ''),
  }[sort];
  if (by) list = [...list].sort(by);

  // People who superliked you jump the queue (as in the real app).
  list = [...list.filter((p) => p.superliked_you), ...list.filter((p) => !p.superliked_you)];

  renderList(list);
}

function renderList(list) {
  if (!list.length) {
    grid.innerHTML = '<div class="empty">No profiles match your filters.</div>';
    statusEl.textContent = `Showing 0 of ${allProfiles.length} profiles`;
    return;
  }
  grid.innerHTML = list.map(cardHtml).join('');
  statusEl.textContent = `Showing ${list.length} of ${allProfiles.length} profiles`;
  grid.querySelectorAll('.card:not(.skeleton)').forEach(enableDrag);
  markFocus();
}

// Keep the first visible card marked as "focused" for keyboard swiping.
function markFocus() {
  const first = grid.querySelector('.card:not(.skeleton)');
  grid.querySelectorAll('.card.focused').forEach((c) => c.classList.remove('focused'));
  if (first) first.classList.add('focused');
}

// ---- Swiping ----
const SWIPE_CLASS = { like: 'liked', superlike: 'superliked', dislike: 'noped' };

async function swipe(card, act) {
  if (!card || card.dataset.done) return;
  card.dataset.done = '1';
  const swipedId = parseInt(card.dataset.id, 10);
  const name = card.querySelector('.name-age')?.textContent.trim().split(',')[0] || 'them';
  card.style.transform = ''; // hand off to the CSS fly-off animation
  card.classList.add(SWIPE_CLASS[act] || 'noped');

  if (act === 'like') window.toast(`You liked ${name} ❤️`);
  else if (act === 'superlike') window.toast(`Superliked ${name} ⭐`, 'super');

  try {
    const res = await fetch('/api/swipes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ swiperId: currentUserId, swipedId, swipeType: act }),
    });
    const data = await res.json();
    if (res.ok && data.match) showMatch(data.matchedProfile);
  } catch (err) {
    console.error('swipe failed:', err);
  } finally {
    setTimeout(() => { card.remove(); markFocus(); }, 450);
  }
}

// Drag-to-swipe: grab a card and throw it right (like), left (nope) or up (super).
function enableDrag(card) {
  let startX = 0, startY = 0, dx = 0, dy = 0, active = false;

  card.addEventListener('pointerdown', (e) => {
    if (e.target.closest('.action-btn') || card.dataset.done) return;
    active = true;
    startX = e.clientX; startY = e.clientY; dx = 0; dy = 0;
    card.classList.add('dragging');
    card.setPointerCapture(e.pointerId);
  });

  card.addEventListener('pointermove', (e) => {
    if (!active) return;
    dx = e.clientX - startX;
    dy = e.clientY - startY;
    card.style.transform = `translate(${dx}px, ${dy}px) rotate(${dx / 18}deg)`;
    const up = dy < -60 && Math.abs(dy) > Math.abs(dx);
    card.style.setProperty('--like-op', up ? 0 : Math.max(0, Math.min(1, dx / 110)));
    card.style.setProperty('--nope-op', up ? 0 : Math.max(0, Math.min(1, -dx / 110)));
    card.style.setProperty('--super-op', up ? Math.max(0, Math.min(1, -dy / 120)) : 0);
  });

  const end = () => {
    if (!active) return;
    active = false;
    card.classList.remove('dragging');
    const goUp = dy < -110 && Math.abs(dy) > Math.abs(dx);
    if (goUp) swipe(card, 'superlike');
    else if (dx > 110) swipe(card, 'like');
    else if (dx < -110) swipe(card, 'dislike');
    else {
      // Snap back.
      card.style.transform = '';
      card.style.setProperty('--like-op', 0);
      card.style.setProperty('--nope-op', 0);
      card.style.setProperty('--super-op', 0);
    }
  };
  card.addEventListener('pointerup', end);
  card.addEventListener('pointercancel', end);
}

grid.addEventListener('click', (e) => {
  const btn = e.target.closest('.action-btn');
  if (!btn) return;
  swipe(btn.closest('.card'), btn.dataset.act);
});

// Keyboard: ← = nope, → = like, ↑ = superlike (the focused card).
document.addEventListener('keydown', (e) => {
  if (controls.style.display === 'none') return;
  if (document.activeElement && ['INPUT', 'SELECT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;
  const card = grid.querySelector('.card.focused');
  if (!card) return;
  if (e.key === 'ArrowRight') swipe(card, 'like');
  else if (e.key === 'ArrowLeft') swipe(card, 'dislike');
  else if (e.key === 'ArrowUp') { e.preventDefault(); swipe(card, 'superlike'); }
});

// ---- Match modal ----
function showMatch(profile) {
  const me = allProfiles.find((p) => p.user_id === currentUserId);
  modal.querySelector('.avatars').innerHTML = `
    <img src="${escapeHtml(me?.photo_url) || FALLBACK_IMG}" onerror="this.src='${FALLBACK_IMG}'">
    <img src="${escapeHtml(profile?.photo_url) || FALLBACK_IMG}" onerror="this.src='${FALLBACK_IMG}'">`;
  modal.querySelector('.match-name').textContent =
    `You and ${profile?.first_name ?? 'someone'} liked each other!`;
  modal.classList.add('open');
}
modal.addEventListener('click', (e) => {
  if (e.target === modal || e.target.closest('.close-modal')) modal.classList.remove('open');
});

// ---- My Matches panel ----
async function loadMatches() {
  if (currentUserId == null) return;
  const me = allProfiles.find((p) => p.user_id === currentUserId);
  matchesModal.querySelector('.matches-sub').textContent =
    `Matches for ${me ? me.first_name + ' ' + me.last_name : 'you'}`;
  matchesList.innerHTML = '<p style="text-align:center;color:#9aa0ab">Loading…</p>';
  matchesModal.classList.add('open');

  try {
    const res = await fetch(`/api/matches/${currentUserId}`);
    if (!res.ok) throw new Error(`Server responded ${res.status}`);
    const matches = await res.json();

    if (!matches.length) {
      matchesList.innerHTML =
        '<p style="text-align:center;color:#9aa0ab;padding:20px">No matches yet — start swiping! 💜</p>';
      return;
    }
    matchesList.innerHTML = matches.map((m) => `
      <div class="match-row">
        <img src="${escapeHtml(m.photo_url) || FALLBACK_IMG}" onerror="this.src='${FALLBACK_IMG}'">
        <div class="info">
          <span class="mname">${escapeHtml(m.first_name)} ${escapeHtml(m.last_name)}</span>
          <span class="mcity">📍 ${escapeHtml(m.location_name) || 'Unknown'}</span>
        </div>
      </div>`).join('');
  } catch (err) {
    matchesList.innerHTML =
      `<p style="text-align:center;color:#ff6b6b;padding:20px">⚠️ ${escapeHtml(err.message)}</p>`;
  }
}

matchesModal.addEventListener('click', (e) => {
  if (e.target === matchesModal || e.target.closest('.close-modal')) matchesModal.classList.remove('open');
});
matchesBtn.addEventListener('click', loadMatches);

// ---- My Likes panel ----
async function loadLikes() {
  if (currentUserId == null) return;
  const me = allProfiles.find((p) => p.user_id === currentUserId);
  likesModal.querySelector('.matches-sub').textContent =
    `People ${me ? me.first_name : 'you'} liked`;
  likesList.innerHTML = '<p style="text-align:center;color:#9aa0ab">Loading…</p>';
  likesModal.classList.add('open');

  try {
    const res = await fetch(`/api/likes/${currentUserId}`);
    if (!res.ok) throw new Error(`Server responded ${res.status}`);
    const likes = await res.json();

    if (!likes.length) {
      likesList.innerHTML =
        '<p style="text-align:center;color:#9aa0ab;padding:20px">You haven\'t liked anyone yet 💜</p>';
      return;
    }
    likesList.innerHTML = likes.map((l) => `
      <div class="match-row">
        <img src="${escapeHtml(l.photo_url) || FALLBACK_IMG}" onerror="this.src='${FALLBACK_IMG}'">
        <div class="info">
          <span class="mname">${escapeHtml(l.first_name)} ${escapeHtml(l.last_name)}
            ${l.swipetype === 'superlike' ? '<span class="super-tag" title="You superliked them">⭐ Superlike</span>' : ''}
          </span>
          <span class="mcity">📍 ${escapeHtml(l.location_name) || 'Unknown'}</span>
        </div>
        ${l.is_mutual ? '<span class="mutual">Matched ✅</span>' : ''}
      </div>`).join('');
  } catch (err) {
    likesList.innerHTML =
      `<p style="text-align:center;color:#ff6b6b;padding:20px">⚠️ ${escapeHtml(err.message)}</p>`;
  }
}

likesModal.addEventListener('click', (e) => {
  if (e.target === likesModal || e.target.closest('.close-modal')) likesModal.classList.remove('open');
});
likesBtn.addEventListener('click', loadLikes);

// ---- Loading ----
// Called by auth.js right after a successful login/registration.
window.startApp = function () {
  currentUserId = window.SESSION ? window.SESSION.user_id : null;
  loadProfiles();
};

async function loadProfiles() {
  loadBtn.disabled = true;
  statusEl.className = '';
  statusEl.textContent = 'Loading profiles…';
  renderSkeletons();

  try {
    const url = currentUserId != null ? `/api/profiles?viewer=${currentUserId}` : '/api/profiles';
    const res = await fetch(url);
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || `Server responded ${res.status}`);
    }
    allProfiles = await res.json();

    if (!allProfiles.length) {
      statusEl.textContent = '';
      grid.innerHTML = '<div class="empty">No profiles found in the database.</div>';
      return;
    }

    controls.style.display = 'flex';
    hintEl.style.display = 'block';
    const legend = document.getElementById('swipeLegend');
    if (legend) legend.style.display = 'flex';
    matchesBtn.style.display = '';
    likesBtn.style.display = '';
    loadBtn.textContent = '🔄 Reload';
    applyFilters();
  } catch (err) {
    statusEl.className = 'error';
    grid.innerHTML = '';
    statusEl.textContent = '⚠️ ' + err.message + ' — is the server and SQL Server running?';
  } finally {
    loadBtn.disabled = false;
  }
}

// ---- Wire up events ----
loadBtn.addEventListener('click', loadProfiles);
searchEl.addEventListener('input', applyFilters);
genderSel.addEventListener('change', applyFilters);
minAgeEl.addEventListener('input', applyFilters);
maxAgeEl.addEventListener('input', applyFilters);
sortSel.addEventListener('change', applyFilters);
