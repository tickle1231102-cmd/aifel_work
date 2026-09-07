import { Router } from 'express';
import db from '../db.js';

const router = Router();

// todo 목록에 태그를 붙여 반환
function attachTags(todos) {
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

function setTodoTags(todoId, tagIds) {
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

// GET /api/todos?q=&tag=&today=1
router.get('/', (req, res) => {
  const { q, tag, today } = req.query;
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
  if (today === '1' || today === 'true') {
    clauses.push("todos.due_date = date('now')");
  }
  if (clauses.length) sql += ' WHERE ' + clauses.join(' AND ');
  sql += ' ORDER BY (todos.due_date IS NULL), todos.due_date ASC, todos.created_at DESC';

  const todos = db.prepare(sql).all(...params);
  res.json(attachTags(todos));
});

// POST /api/todos
router.post('/', (req, res) => {
  const { title, memo, due_date, tag_ids } = req.body ?? {};
  if (!title || !String(title).trim()) {
    return res.status(400).json({ error: 'title은 필수입니다.' });
  }

  const result = db
    .prepare('INSERT INTO todos (title, memo, due_date) VALUES (?, ?, ?)')
    .run(String(title).trim(), memo || null, due_date || null);
  setTodoTags(result.lastInsertRowid, tag_ids);

  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(attachTags([todo])[0]);
});

// PATCH /api/todos/:id
router.patch('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM todos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: '할 일을 찾을 수 없습니다.' });

  const { title, memo, due_date, is_done, tag_ids } = req.body ?? {};
  const newTitle = title !== undefined ? String(title).trim() : existing.title;
  const newMemo = memo !== undefined ? memo : existing.memo;
  const newDue = due_date !== undefined ? due_date : existing.due_date;
  const newDone = is_done !== undefined ? (is_done ? 1 : 0) : existing.is_done;

  db.prepare(
    `UPDATE todos SET title = ?, memo = ?, due_date = ?, is_done = ?, updated_at = datetime('now')
     WHERE id = ?`
  ).run(newTitle, newMemo, newDue, newDone, id);

  if (tag_ids !== undefined) setTodoTags(id, tag_ids);

  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(id);
  res.json(attachTags([todo])[0]);
});

// DELETE /api/todos/:id
router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM todos WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: '할 일을 찾을 수 없습니다.' });
  res.status(204).end();
});

export default router;
