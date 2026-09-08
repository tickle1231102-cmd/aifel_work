import { Router } from 'express';
import { listTags, createTag, deleteTag } from '../todoRepo.js';

const router = Router();

// GET /api/tags
router.get('/', (req, res) => {
  res.json(listTags());
});

// POST /api/tags
router.post('/', (req, res) => {
  try {
    const tag = createTag(req.body ?? {});
    res.status(201).json(tag);
  } catch (err) {
    if (err.code === 'VALIDATION') return res.status(400).json({ error: err.message });
    if (err.code === 'DUPLICATE_TAG') return res.status(409).json({ error: err.message });
    throw err;
  }
});

// DELETE /api/tags/:id
router.delete('/:id', (req, res) => {
  const ok = deleteTag(req.params.id);
  if (!ok) return res.status(404).json({ error: '태그를 찾을 수 없습니다.' });
  res.status(204).end();
});

export default router;
