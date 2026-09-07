import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 기본값: 프로젝트 루트의 todo.db (환경변수 DB_FILE로 덮어쓸 수 있음)
const DB_PATH = process.env.DB_FILE
  ? path.resolve(process.cwd(), process.env.DB_FILE)
  : path.resolve(__dirname, '..', 'todo.db');

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// 서버 기동 시 스키마를 멱등하게 적용 (테이블이 이미 있으면 아무 일도 안 함)
const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
db.exec(schema);

export default db;
export { DB_PATH };
