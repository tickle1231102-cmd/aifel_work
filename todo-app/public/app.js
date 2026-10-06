const state = {
  q: '',
  tag: null,
  today: false,
};

const els = {
  form: document.getElementById('add-form'),
  title: document.getElementById('title-input'),
  due: document.getElementById('due-input'),
  tagsInput: document.getElementById('tags-input'),
  search: document.getElementById('search-input'),
  todayToggle: document.getElementById('today-toggle'),
  tagChips: document.getElementById('tag-chips'),
  list: document.getElementById('todo-list'),
  empty: document.getElementById('empty-state'),
};

async function jsonFetch(url, options) {
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `요청 실패 (${res.status})`);
  }
  if (res.status === 204) return null;
  return res.json();
}

function todayStr() {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

async function fetchTags() {
  return jsonFetch('/api/tags');
}

async function resolveTagIds(names) {
  const existing = await fetchTags();
  const byName = new Map(existing.map((t) => [t.name, t.id]));
  const ids = [];
  for (const raw of names) {
    const name = raw.trim();
    if (!name) continue;
    if (byName.has(name)) {
      ids.push(byName.get(name));
      continue;
    }
    const created = await jsonFetch('/api/tags', {
      method: 'POST',
      body: JSON.stringify({ name }),
    });
    ids.push(created.id);
    byName.set(name, created.id);
  }
  return ids;
}

function buildQuery() {
  const params = new URLSearchParams();
  if (state.q) params.set('q', state.q);
  if (state.tag) params.set('tag', state.tag);
  if (state.today) params.set('today', '1');
  return params.toString();
}

async function loadTodos() {
  const query = buildQuery();
  const todos = await jsonFetch(`/api/todos${query ? '?' + query : ''}`);
  renderTodos(todos);
}

async function loadTagChips() {
  const tags = await fetchTags();
  els.tagChips.innerHTML = '';
  for (const tag of tags) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'tag-chip' + (state.tag === String(tag.id) ? ' active' : '');
    btn.textContent = tag.name;
    btn.addEventListener('click', () => {
      state.tag = state.tag === String(tag.id) ? null : String(tag.id);
      loadTagChips();
      loadTodos();
    });
    els.tagChips.appendChild(btn);
  }
}

function renderTodos(todos) {
  els.list.innerHTML = '';
  els.empty.hidden = todos.length > 0;

  for (const todo of todos) {
    const li = document.createElement('li');
    li.className = 'todo-item' + (todo.is_done ? ' done' : '');

    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.checked = todo.is_done;
    checkbox.addEventListener('change', async () => {
      await jsonFetch(`/api/todos/${todo.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_done: checkbox.checked }),
      });
      loadTodos();
    });

    const main = document.createElement('div');
    main.className = 'todo-main';

    const title = document.createElement('div');
    title.className = 'todo-title';
    title.textContent = todo.title;
    main.appendChild(title);

    if (todo.memo) {
      const memo = document.createElement('div');
      memo.className = 'todo-memo';
      memo.textContent = todo.memo;
      main.appendChild(memo);
    }

    if (todo.due_date || todo.tags.length > 0) {
      const meta = document.createElement('div');
      meta.className = 'todo-meta';

      if (todo.due_date) {
        const badge = document.createElement('span');
        const overdue = !todo.is_done && todo.due_date < todayStr();
        badge.className = 'due-badge' + (overdue ? ' overdue' : '');
        badge.textContent = `📅 ${todo.due_date}`;
        meta.appendChild(badge);
      }
      for (const tag of todo.tags) {
        const badge = document.createElement('span');
        badge.className = 'tag-badge';
        badge.textContent = tag.name;
        meta.appendChild(badge);
      }
      main.appendChild(meta);
    }

    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button';
    deleteBtn.className = 'delete-btn';
    deleteBtn.textContent = '✕';
    deleteBtn.title = '삭제';
    deleteBtn.addEventListener('click', async () => {
      await jsonFetch(`/api/todos/${todo.id}`, { method: 'DELETE' });
      loadTodos();
    });

    li.appendChild(checkbox);
    li.appendChild(main);
    li.appendChild(deleteBtn);
    els.list.appendChild(li);
  }
}

els.form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const title = els.title.value.trim();
  if (!title) return;

  const tagNames = els.tagsInput.value.split(',').map((s) => s.trim()).filter(Boolean);
  const tag_ids = tagNames.length > 0 ? await resolveTagIds(tagNames) : [];

  await jsonFetch('/api/todos', {
    method: 'POST',
    body: JSON.stringify({
      title,
      due_date: els.due.value || null,
      tag_ids,
    }),
  });

  els.form.reset();
  await loadTagChips();
  await loadTodos();
});

let searchTimer;
els.search.addEventListener('input', () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    state.q = els.search.value.trim();
    loadTodos();
  }, 250);
});

els.todayToggle.addEventListener('change', () => {
  state.today = els.todayToggle.checked;
  loadTodos();
});

(async function init() {
  await loadTagChips();
  await loadTodos();
})();
