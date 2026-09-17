-- 할 일 본체
CREATE TABLE IF NOT EXISTS todos (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  memo        TEXT,
  is_done     INTEGER NOT NULL DEFAULT 0,
  due_date    TEXT,                          -- 'YYYY-MM-DD', 없으면 NULL
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 태그(카테고리)
CREATE TABLE IF NOT EXISTS tags (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  name   TEXT NOT NULL UNIQUE,
  color  TEXT
);

-- todos ↔ tags 다대다 연결
CREATE TABLE IF NOT EXISTS todo_tags (
  todo_id  INTEGER NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  tag_id   INTEGER NOT NULL REFERENCES tags(id)  ON DELETE CASCADE,
  PRIMARY KEY (todo_id, tag_id)
);

-- 자주 걸리는 조회 조건에 인덱스
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_is_done  ON todos(is_done);
CREATE INDEX IF NOT EXISTS idx_todo_tags_tag  ON todo_tags(tag_id);
