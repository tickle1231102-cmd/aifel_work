import { Router } from 'express';
import db from '../db.js';

const router = Router();

// GET /api/tags
router.get('/', (req, res) => {
  res.json(db.prepare('SELECT * FROM tags ORDER BY name').all());
});

// POST /api/tags
router.post('/', (req, res) => {
  const { name, color } = req.body ?? {};
  if (!name || !String(name).trim()) {
    return res.status(400).json({ error: 'name은 필수입니다.' });
  }
  try {
    const result = db
      .prepare('INSERT INTO tags (name, color) VALUES (?, ?)')
      .run(String(name).trim(), color || null);
    res.status(201).json(db.prepare('SELECT * FROM tags WHERE id = ?').get(result.lastInsertRowid));
  } catch (err) {
    if (String(err.message).includes('UNIQUE')) {
      return res.status(409).json({ error: '이미 있는 태그입니다.' });
    }
    throw err;
  }
});

// DELETE /api/tags/:id
router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM tags WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: '태그를 찾을 수 없습니다.' });
  res.status(204).end();
});

export default router;
