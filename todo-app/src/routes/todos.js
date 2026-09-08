import { Router } from 'express';
import { listTodos, addTodo, updateTodo, deleteTodo } from '../todoRepo.js';

const router = Router();

// GET /api/todos?q=&tag=&today=1
router.get('/', (req, res) => {
  const { q, tag, today } = req.query;
  res.json(listTodos({ q, tag, today }));
});

// POST /api/todos
router.post('/', (req, res) => {
  try {
    const todo = addTodo(req.body ?? {});
    res.status(201).json(todo);
  } catch (err) {
    if (err.code === 'VALIDATION') return res.status(400).json({ error: err.message });
    throw err;
  }
});

// PATCH /api/todos/:id
router.patch('/:id', (req, res) => {
  const todo = updateTodo(Number(req.params.id), req.body ?? {});
  if (!todo) return res.status(404).json({ error: '할 일을 찾을 수 없습니다.' });
  res.json(todo);
});

// DELETE /api/todos/:id
router.delete('/:id', (req, res) => {
  const ok = deleteTodo(req.params.id);
  if (!ok) return res.status(404).json({ error: '할 일을 찾을 수 없습니다.' });
  res.status(204).end();
});

export default router;
