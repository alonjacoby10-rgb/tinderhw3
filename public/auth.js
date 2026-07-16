// auth.js — authentication (login/register), session, and the personal area.
// Exposes window.SESSION (the logged-in user) for app.js and admin.js.

(function () {
  const KEY = 'tinderhw3_session';
  const FALLBACK_IMG = 'https://placehold.co/200x200/1b1f27/9aa0ab?text=%3F';

  // ---- Elements ----
  const authScreen = document.getElementById('authScreen');
  const topbar     = document.getElementById('topbar');
  const appRoot    = document.getElementById('appRoot');
  const adminBtn   = document.getElementById('adminBtn');
  const meBtn      = document.getElementById('meBtn');

  const tabLogin      = document.getElementById('tabLogin');
  const tabRegister   = document.getElementById('tabRegister');
  const loginForm     = document.getElementById('loginForm');
  const registerForm  = document.getElementById('registerForm');
  const loginError    = document.getElementById('loginError');
  const registerError = document.getElementById('registerError');

  const meModal    = document.getElementById('meModal');
  const meView     = document.getElementById('meView');
  const meForm     = document.getElementById('meForm');
  const meAvatar   = document.getElementById('meAvatar');
  const meName     = document.getElementById('meName');
  const meHandle   = document.getElementById('meHandle');
  const meBio      = document.getElementById('meBio');
  const meAdminTag = document.getElementById('meAdminTag');
  const statLikes  = document.getElementById('statLikes');
  const statMatches= document.getElementById('statMatches');
  const statAge    = document.getElementById('statAge');
  const meEditBtn  = document.getElementById('meEditBtn');
  const meCancelBtn= document.getElementById('meCancelBtn');
  const meError    = document.getElementById('meError');
  const logoutBtn  = document.getElementById('logoutBtn');
  const likesBtn   = document.getElementById('likesBtn');
  const matchesBtn = document.getElementById('matchesBtn');

  // ---- Session helpers ----
  function saveSession(user) {
    window.SESSION = user;
    localStorage.setItem(KEY, JSON.stringify(user));
  }
  function clearSession() {
    window.SESSION = null;
    localStorage.removeItem(KEY);
  }

  function setMeButtonAvatar(url) {
    if (url && !url.includes('placehold')) {
      meBtn.style.backgroundImage = `url('${url}')`;
      meBtn.textContent = '';
      meBtn.classList.add('has-photo');
    } else {
      meBtn.style.backgroundImage = '';
      meBtn.textContent = '👤';
      meBtn.classList.remove('has-photo');
    }
  }

  // Reveal the app for the logged-in user.
  function enterApp() {
    const u = window.SESSION;
    authScreen.style.display = 'none';
    topbar.style.display = 'flex';
    appRoot.style.display = 'block';
    adminBtn.style.display = u.is_admin ? '' : 'none';   // gear = admins only
    setMeButtonAvatar(u.photo_url);
    if (window.startApp) window.startApp();
  }

  // ---- Auth screen tabs ----
  function showTab(which) {
    const login = which === 'login';
    tabLogin.classList.toggle('active', login);
    tabRegister.classList.toggle('active', !login);
    loginForm.style.display = login ? '' : 'none';
    registerForm.style.display = login ? 'none' : '';
    loginError.textContent = '';
    registerError.textContent = '';
  }
  tabLogin.addEventListener('click', () => showTab('login'));
  tabRegister.addEventListener('click', () => showTab('register'));

  // ---- Login ----
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    loginError.textContent = '';
    const data = Object.fromEntries(new FormData(loginForm).entries());
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || `Server responded ${res.status}`);
      saveSession(body.user);
      loginForm.reset();
      enterApp();
    } catch (err) {
      loginError.textContent = '⚠️ ' + err.message;
    }
  });

  // ---- Register ----
  registerForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    registerError.textContent = '';
    const data = Object.fromEntries(new FormData(registerForm).entries());
    try {
      const res = await fetch('/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || `Server responded ${res.status}`);
      saveSession(body.user);
      registerForm.reset();
      enterApp();
    } catch (err) {
      registerError.textContent = '⚠️ ' + err.message;
    }
  });

  // ---- Personal area ----
  async function openMe() {
    const u = window.SESSION;
    if (!u) return;
    meForm.style.display = 'none';
    meView.style.display = '';
    meAvatar.src = u.photo_url || FALLBACK_IMG;
    meAvatar.onerror = () => { meAvatar.src = FALLBACK_IMG; };
    meName.textContent = `${u.first_name || ''} ${u.last_name || ''}`.trim() || u.username;
    meHandle.textContent = `@${u.username} · ${u.email}`;
    meAdminTag.style.display = u.is_admin ? '' : 'none';
    meBio.textContent = u.bio || 'No bio yet.';
    statAge.textContent = (u.age != null) ? u.age : '–';
    statLikes.textContent = '…';
    statMatches.textContent = '…';
    meModal.classList.add('open');

    // Live activity counts.
    try {
      const [likes, matches] = await Promise.all([
        fetch(`/api/likes/${u.user_id}`).then((r) => r.json()).catch(() => []),
        fetch(`/api/matches/${u.user_id}`).then((r) => r.json()).catch(() => []),
      ]);
      statLikes.textContent = Array.isArray(likes) ? likes.length : 0;
      statMatches.textContent = Array.isArray(matches) ? matches.length : 0;
    } catch {
      statLikes.textContent = '0';
      statMatches.textContent = '0';
    }
  }
  meBtn.addEventListener('click', openMe);

  // ---- Edit my profile ----
  meEditBtn.addEventListener('click', () => {
    const u = window.SESSION;
    meForm.first_name.value = u.first_name || '';
    meForm.last_name.value = u.last_name || '';
    meForm.location_name.value = u.location_name || '';
    meForm.gender.value = u.gender || 'O';
    meForm.birth_date.value = u.birth_date ? u.birth_date.slice(0, 10) : '';
    meForm.profile_photo_url.value = (u.photo_url && !u.photo_url.includes('placehold')) ? u.photo_url : '';
    meForm.bio.value = u.bio || '';
    meForm.email.value = u.email || '';
    meForm.password.value = '';
    meError.textContent = '';
    meView.style.display = 'none';
    meForm.style.display = '';
  });
  meCancelBtn.addEventListener('click', () => {
    meForm.style.display = 'none';
    meView.style.display = '';
  });

  meForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    meError.textContent = '';
    const u = window.SESSION;
    const data = Object.fromEntries(new FormData(meForm).entries());
    // Drop empty values so we don't overwrite with blanks (except bio/city which
    // a user may intentionally clear).
    Object.keys(data).forEach((k) => {
      if (data[k] === '' && !['bio', 'location_name'].includes(k)) delete data[k];
    });

    try {
      const res = await fetch(`/api/users/${u.user_id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', 'x-user-id': String(u.user_id) },
        body: JSON.stringify(data),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || `Server responded ${res.status}`);

      // Refresh the session from the server so the UI reflects the changes.
      const meRes = await fetch(`/api/auth/me/${u.user_id}`);
      const meBody = await meRes.json();
      saveSession(meBody.user);
      setMeButtonAvatar(meBody.user.photo_url);
      openMe();
    } catch (err) {
      meError.textContent = '⚠️ ' + err.message;
    }
  });

  // ---- Logout ----
  logoutBtn.addEventListener('click', () => {
    clearSession();
    meModal.classList.remove('open');
    location.reload();
  });

  // Close the personal area on overlay / ✕.
  meModal.addEventListener('click', (e) => {
    if (e.target === meModal || e.target.closest('.me-x')) meModal.classList.remove('open');
  });
  // When opening Likes/Matches from the personal area, close the personal area.
  [likesBtn, matchesBtn].forEach((b) => b && b.addEventListener('click', () => meModal.classList.remove('open')));

  // ---- Boot: restore session or show the auth screen ----
  const saved = localStorage.getItem(KEY);
  if (saved) {
    try {
      window.SESSION = JSON.parse(saved);
      enterApp();
    } catch {
      showTab('login');
    }
  } else {
    showTab('login');
  }
})();
