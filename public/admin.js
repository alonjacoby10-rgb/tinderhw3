// admin.js — the User Management (Admin) panel: full CRUD over /api/users.

(function () {
  const adminBtn    = document.getElementById('adminBtn');
  const adminModal  = document.getElementById('adminModal');
  const adminSearch = document.getElementById('adminSearch');
  const adminGender = document.getElementById('adminGender');
  const adminSort   = document.getElementById('adminSort');
  const adminStatus = document.getElementById('adminStatus');
  const adminList   = document.getElementById('adminList');
  const addUserBtn  = document.getElementById('addUserBtn');

  const formModal = document.getElementById('userFormModal');
  const form      = document.getElementById('userForm');
  const formTitle = document.getElementById('formTitle');
  const formError = document.getElementById('formError');
  const pwdLabel  = document.getElementById('pwdLabel');

  const FALLBACK_IMG = 'https://placehold.co/100x100/1b1f27/9aa0ab?text=%3F';
  let editingId = null; // null → creating, otherwise → editing that user id

  // Attach the logged-in user's id so the server can authorize admin actions.
  function authHeaders(extra) {
    const h = extra ? { ...extra } : {};
    if (window.SESSION && window.SESSION.user_id) h['x-user-id'] = String(window.SESSION.user_id);
    return h;
  }

  function esc(s) {
    return String(s ?? '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // ---- Read + render the user list (with filters) ----
  async function loadUsers() {
    adminStatus.className = 'admin-status';
    adminStatus.textContent = 'Loading…';
    const params = new URLSearchParams();
    if (adminSearch.value.trim()) params.set('search', adminSearch.value.trim());
    if (adminGender.value) params.set('gender', adminGender.value);
    if (adminSort.value) params.set('sort', adminSort.value);

    try {
      const res = await fetch('/api/users?' + params.toString(), { headers: authHeaders() });
      if (!res.ok) throw new Error(`Server responded ${res.status}`);
      const users = await res.json();

      if (!users.length) {
        adminList.innerHTML = '';
        adminStatus.textContent = 'No users match your filters.';
        return;
      }
      adminStatus.textContent = `${users.length} users`;
      adminList.innerHTML = users.map((u) => `
        <div class="user-row">
          <img src="${esc(u.photo_url) || FALLBACK_IMG}" onerror="this.src='${FALLBACK_IMG}'">
          <div class="u-main">
            <div class="u-name">${esc(u.first_name)} ${esc(u.last_name)}
              <span style="color:#6b7280;font-weight:400">#${u.user_id}</span></div>
            <div class="u-sub">@${esc(u.username)} · ${esc(u.email)}</div>
          </div>
          <div class="u-meta">${u.age != null ? u.age + 'y' : ''}<br>${esc(u.location_name) || ''}</div>
          <div class="u-actions">
            <button class="icon-btn edit" data-id="${u.user_id}" title="Edit">✏️</button>
            <button class="icon-btn del" data-id="${u.user_id}" data-name="${esc(u.first_name)} ${esc(u.last_name)}" title="Delete">🗑️</button>
          </div>
        </div>`).join('');
    } catch (err) {
      adminStatus.className = 'admin-status error';
      adminStatus.textContent = '⚠️ ' + err.message;
    }
  }

  // ---- Open the form for creating ----
  function openCreate() {
    editingId = null;
    formTitle.textContent = '➕ Add User';
    form.reset();
    formError.textContent = '';
    form.password.required = true;
    pwdLabel.style.display = '';
    formModal.classList.add('open');
  }

  // ---- Open the form for editing (prefill from GET /:id) ----
  async function openEdit(id) {
    editingId = id;
    formTitle.textContent = '✏️ Edit User #' + id;
    formError.textContent = '';
    form.reset();
    // On edit, password is optional (blank = keep current).
    form.password.required = false;
    pwdLabel.style.display = '';
    form.password.placeholder = '(leave blank to keep)';

    try {
      const res = await fetch('/api/users/' + id, { headers: authHeaders() });
      if (!res.ok) throw new Error(`Server responded ${res.status}`);
      const u = await res.json();
      form.username.value = u.username || '';
      form.email.value = u.email || '';
      form.first_name.value = u.first_name || '';
      form.last_name.value = u.last_name || '';
      form.birth_date.value = u.birth_date ? u.birth_date.slice(0, 10) : '';
      form.gender.value = u.gender || 'O';
      form.location_name.value = u.location_name || '';
      form.profile_photo_url.value = u.profile_photo_url || '';
      form.bio.value = u.bio || '';
      formModal.classList.add('open');
    } catch (err) {
      alert('Could not load user: ' + err.message);
    }
  }

  // ---- Create or Update on submit ----
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.textContent = '';
    const data = Object.fromEntries(new FormData(form).entries());
    // Don't send an empty password on edit.
    if (editingId && !data.password) delete data.password;

    const url = editingId ? '/api/users/' + editingId : '/api/users';
    const method = editingId ? 'PUT' : 'POST';

    try {
      const res = await fetch(url, {
        method,
        headers: authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify(data),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || `Server responded ${res.status}`);
      formModal.classList.remove('open');
      if (window.toast) window.toast(editingId ? 'User updated ✓' : 'User created ✓', 'success');
      loadUsers();
    } catch (err) {
      formError.textContent = '⚠️ ' + err.message;
    }
  });

  // ---- Delete ----
  adminList.addEventListener('click', (e) => {
    const btn = e.target.closest('.icon-btn');
    if (!btn) return;
    const id = btn.dataset.id;
    if (btn.classList.contains('edit')) return openEdit(id);
    if (btn.classList.contains('del')) {
      if (!confirm(`Delete ${btn.dataset.name} (#${id}) and all their data?\nThis cannot be undone.`)) return;
      deleteUser(id);
    }
  });

  async function deleteUser(id) {
    try {
      const res = await fetch('/api/users/' + id, { method: 'DELETE', headers: authHeaders() });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || `Server responded ${res.status}`);
      if (window.toast) window.toast('User deleted', 'success');
      loadUsers();
    } catch (err) {
      adminStatus.className = 'admin-status error';
      adminStatus.textContent = '⚠️ ' + err.message;
      if (window.toast) window.toast('⚠️ ' + err.message, 'error');
    }
  }

  // ---- Wire up ----
  adminBtn.addEventListener('click', () => { adminModal.classList.add('open'); loadUsers(); });
  addUserBtn.addEventListener('click', openCreate);
  adminSearch.addEventListener('input', loadUsers);
  adminGender.addEventListener('change', loadUsers);
  adminSort.addEventListener('change', loadUsers);

  // Close modals on overlay / close-button click.
  [adminModal, formModal].forEach((m) => {
    m.addEventListener('click', (e) => {
      if (e.target === m || e.target.closest('.close-modal')) m.classList.remove('open');
    });
  });
})();
