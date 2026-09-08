import 'dotenv/config';
import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import './db.js'; // 서버 기동 시 DB/스키마 초기화
import todosRouter from './routes/todos.js';
import tagsRouter from './routes/tags.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;

const app = express();
app.use(express.json());

app.use('/api/todos', todosRouter);
app.use('/api/tags', tagsRouter);

app.use(express.static(path.join(__dirname, '..', 'public')));

app.listen(PORT, () => {
  console.log(`Todo 앱 실행 중: http://localhost:${PORT}`);
});
