// 웹 API 라우트와 CLI(bin/todo.js)가 함께 쓰는 순수 DB 로직.
// Express(req/res)나 process.argv에 묶이지 않은 형태로 여기에만 두고,
// 두 진입점은 이 함수들을 호출하기만 한다.
import db from './db.js';

// todo 목록에 태그를 붙여 반환
export function attachTags(todos) {
  if (todos.length === 0) return [];
  const ids = todos.map((t) => t.id);
  const placeholders = ids.map(() => '?').join(',');
  const rows = db
    .prepare(
      `SELECT tt.todo_id AS todo_id, t.id AS id, t.name AS name, t.color AS color
       FROM todo_tags tt JOIN tags t ON t.id = tt.tag_id
       WHERE tt.todo_id IN (${placeholders})`
    )
    .all(...ids);

  const byTodo = new Map();
  for (const r of rows) {
    if (!byTodo.has(r.todo_id)) byTodo.set(r.todo_id, []);
    byTodo.get(r.todo_id).push({ id: r.id, name: r.name, color: r.color });
  }
  return todos.map((t) => ({
    ...t,
    is_done: !!t.is_done,
    tags: byTodo.get(t.id) || [],
  }));
}

export function setTodoTags(todoId, tagIds) {
  db.prepare('DELETE FROM todo_tags WHERE todo_id = ?').run(todoId);
  if (!Array.isArray(tagIds) || tagIds.length === 0) return;
  const insert = db.prepare(
    'INSERT OR IGNORE INTO todo_tags (todo_id, tag_id) VALUES (?, ?)'
  );
  const insertMany = db.transaction((ids) => {
    for (const tagId of ids) insert.run(todoId, tagId);
  });
  insertMany(tagIds);
}

export function getTodo(id) {
  return db.prepare('SELECT * FROM todos WHERE id = ?').get(id);
}

// q(검색어) / tag(태그 id) / today(오늘 마감만) 필터를 지원하는 목록 조회
export function listTodos({ q, tag, today } = {}) {
  let sql = 'SELECT DISTINCT todos.* FROM todos';
  const clauses = [];
  const params = [];

  if (tag) {
    sql += ' JOIN todo_tags ON todo_tags.todo_id = todos.id';
    clauses.push('todo_tags.tag_id = ?');
    params.push(tag);
  }
  if (q) {
    clauses.push('(todos.title LIKE ? OR todos.memo LIKE ?)');
    params.push(`%${q}%`, `%${q}%`);
  }
  if (today === '1' || today === true || today === 'true') {
    clauses.push("todos.due_date = date('now')");
  }
  if (clauses.length) sql += ' WHERE ' + clauses.join(' AND ');
  sql += ' ORDER BY (todos.due_date IS NULL), todos.due_date ASC, todos.created_at DESC';

  return attachTags(db.prepare(sql).all(...params));
}

export function addTodo({ title, memo, due_date, tag_ids } = {}) {
  if (!title || !String(title).trim()) {
    const err = new Error('title은 필수입니다.');
    err.code = 'VALIDATION';
    throw err;
  }
  const result = db
    .prepare('INSERT INTO todos (title, memo, due_date) VALUES (?, ?, ?)')
    .run(String(title).trim(), memo || null, due_date || null);
  setTodoTags(result.lastInsertRowid, tag_ids);
  return attachTags([getTodo(result.lastInsertRowid)])[0];
}

export function updateTodo(id, { title, memo, due_date, is_done, tag_ids } = {}) {
  const existing = getTodo(id);
  if (!existing) return null;

  const newTitle = title !== undefined ? String(title).trim() : existing.title;
  const newMemo = memo !== undefined ? memo : existing.memo;
  const newDue = due_date !== undefined ? due_date : existing.due_date;
  const newDone = is_done !== undefined ? (is_done ? 1 : 0) : existing.is_done;

  db.prepare(
    `UPDATE todos SET title = ?, memo = ?, due_date = ?, is_done = ?, updated_at = datetime('now')
     WHERE id = ?`
  ).run(newTitle, newMemo, newDue, newDone, id);

  if (tag_ids !== undefined) setTodoTags(id, tag_ids);

  return attachTags([getTodo(id)])[0];
}

export function deleteTodo(id) {
  const result = db.prepare('DELETE FROM todos WHERE id = ?').run(id);
  return result.changes > 0;
}

export function listTags() {
  return db.prepare('SELECT * FROM tags ORDER BY name').all();
}

export function createTag({ name, color } = {}) {
  if (!name || !String(name).trim()) {
    const err = new Error('name은 필수입니다.');
    err.code = 'VALIDATION';
    throw err;
  }
  try {
    const result = db
      .prepare('INSERT INTO tags (name, color) VALUES (?, ?)')
      .run(String(name).trim(), color || null);
    return db.prepare('SELECT * FROM tags WHERE id = ?').get(result.lastInsertRowid);
  } catch (err) {
    if (String(err.message).includes('UNIQUE')) {
      const dupErr = new Error('이미 있는 태그입니다.');
      dupErr.code = 'DUPLICATE_TAG';
      throw dupErr;
    }
    throw err;
  }
}

export function deleteTag(id) {
  const result = db.prepare('DELETE FROM tags WHERE id = ?').run(id);
  return result.changes > 0;
}

export function findTagByName(name) {
  return db.prepare('SELECT * FROM tags WHERE name = ?').get(String(name).trim());
}

// 이름 배열을 태그 id 배열로 변환, 없는 이름은 새로 만든다 (CLI `add --tags`용)
export function resolveTagIds(names) {
  if (!names || names.length === 0) return [];
  const ids = [];
  for (const raw of names) {
    const name = String(raw).trim();
    if (!name) continue;
    const tag = findTagByName(name) || createTag({ name });
    ids.push(tag.id);
  }
  return ids;
}

// 오늘 완료 처리된 할 일 요약 (CLI `summary`용)
export function todayCompletedSummary() {
  const items = db
    .prepare(
      `SELECT * FROM todos WHERE is_done = 1 AND date(updated_at) = date('now')
       ORDER BY updated_at ASC`
    )
    .all();
  const withTags = attachTags(items);
  return { count: withTags.length, items: withTags };
}
