#!/usr/bin/env node
// 터미널용 얇은 진입점. DB 접근/할 일 로직은 전부 src/todoRepo.js(웹 API와 공유)에 있고,
// 여기서는 argv를 해석해서 그 함수들을 부르고 결과를 사람이 읽기 좋게 찍기만 한다.
import {
  addTodo,
  listTodos,
  updateTodo,
  resolveTagIds,
  findTagByName,
  todayCompletedSummary,
} from '../src/todoRepo.js';

function parseArgs(argv) {
  const flags = {};
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (next !== undefined && !next.startsWith('--')) {
        flags[key] = next;
        i++;
      } else {
        flags[key] = true;
      }
    } else {
      positional.push(arg);
    }
  }
  return { flags, positional };
}

function formatTodoLine(todo) {
  const check = todo.is_done ? '✔' : ' ';
  const due = todo.due_date ? `  📅${todo.due_date}` : '';
  const tags = todo.tags.length ? '  ' + todo.tags.map((t) => `#${t.name}`).join(' ') : '';
  return `[${check}] #${todo.id}  ${todo.title}${due}${tags}`;
}

function printHelp() {
  console.log(`사용법: todo <명령> [옵션]

  add <제목> [--due YYYY-MM-DD] [--tags 태그1,태그2] [--memo 메모]   할 일 추가
  list [--today] [--tag 태그이름] [--q 검색어]                        목록 보기
  done <id>                                                          완료 표시
  summary                                                             오늘 완료 요약

예시:
  todo add "우유 사기" --due 2026-09-10 --tags 장보기,개인
  todo list --today
  todo done 3
  todo summary`);
}

function cmdAdd(positional, flags) {
  const title = positional.join(' ').trim();
  if (!title) {
    console.error('할 일 제목을 입력해 주세요. 예: todo add "우유 사기"');
    process.exitCode = 1;
    return;
  }
  const tagNames = flags.tags
    ? String(flags.tags).split(',').map((s) => s.trim()).filter(Boolean)
    : [];
  const tag_ids = resolveTagIds(tagNames);

  try {
    const todo = addTodo({
      title,
      memo: typeof flags.memo === 'string' ? flags.memo : null,
      due_date: typeof flags.due === 'string' ? flags.due : null,
      tag_ids,
    });
    console.log(`추가했어요: ${formatTodoLine(todo)}`);
  } catch (err) {
    console.error(err.message);
    process.exitCode = 1;
  }
}

function cmdList(flags) {
  let tagId;
  if (flags.tag) {
    const tag = findTagByName(flags.tag);
    if (!tag) {
      console.log(`'${flags.tag}' 태그가 없어요.`);
      return;
    }
    tagId = tag.id;
  }

  const todos = listTodos({
    q: typeof flags.q === 'string' ? flags.q : undefined,
    tag: tagId,
    today: flags.today ? '1' : undefined,
  });

  if (todos.length === 0) {
    console.log('표시할 할 일이 없어요.');
    return;
  }
  for (const todo of todos) console.log(formatTodoLine(todo));
}

function cmdDone(positional) {
  const id = Number(positional[0]);
  if (!positional[0] || Number.isNaN(id)) {
    console.error('사용법: todo done <id>  (id는 todo list에 나오는 #번호)');
    process.exitCode = 1;
    return;
  }
  const todo = updateTodo(id, { is_done: true });
  if (!todo) {
    console.error(`#${id} 할 일을 찾을 수 없어요.`);
    process.exitCode = 1;
    return;
  }
  console.log(`완료 처리했어요: ${formatTodoLine(todo)}`);
}

function cmdSummary() {
  const { count, items } = todayCompletedSummary();
  if (count === 0) {
    console.log('오늘 완료한 할 일이 없어요.');
    return;
  }
  console.log(`오늘 완료한 할 일: ${count}개`);
  for (const todo of items) {
    const time = todo.updated_at.slice(11, 16); // 'YYYY-MM-DD HH:MM:SS' -> 'HH:MM'
    console.log(`  ✔ ${todo.title} (${time})`);
  }
}

const [command, ...rest] = process.argv.slice(2);
const { flags, positional } = parseArgs(rest);

switch (command) {
  case 'add':
    cmdAdd(positional, flags);
    break;
  case 'list':
    cmdList(flags);
    break;
  case 'done':
    cmdDone(positional);
    break;
  case 'summary':
    cmdSummary();
    break;
  default:
    printHelp();
    process.exitCode = command ? 1 : 0;
}
