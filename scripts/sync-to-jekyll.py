#!/usr/bin/env python3
"""
aifel_work/blog의 마크다운 글을 blog_jack(Jekyll 사이트)의 _posts/로 동기화합니다.

이제 HTML 변환은 Jekyll(GitHub Pages)이 담당하므로, 이 스크립트는:
  1. blog/**/*.md 파일을 읽고
  2. 프론트매터를 Jekyll 규격(categories, tags, author)으로 맞추고
  3. Jekyll이 요구하는 파일명 규칙(YYYY-MM-DD-slug.md)으로
  4. blog_jack/_posts/ 에 복사합니다.

외부 의존성 없이 표준 라이브러리만 사용합니다.
"""

import os
import re
import shutil
from pathlib import Path
from datetime import datetime


def read_frontmatter(content):
    """마크다운 파일의 프론트매터(메타데이터) 추출"""
    if not content.startswith('---'):
        return {}, content

    lines = content.split('\n')
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            end_idx = i
            break

    if end_idx is None:
        return {}, content

    meta_str = '\n'.join(lines[1:end_idx])
    body = '\n'.join(lines[end_idx + 1:])

    metadata = {}
    for line in meta_str.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip()] = value.strip().strip('"\'')

    return metadata, body


def slugify(text):
    text = text.strip().lower()
    text = re.sub(r'[^a-z0-9가-힣\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-') or 'post'


def parse_list_field(raw):
    """"[a, b, c]" 형태의 문자열을 리스트로 변환"""
    raw = raw.strip().strip('[]')
    items = [x.strip().strip('"\'') for x in raw.split(',')]
    return [x for x in items if x]


def strip_leading_duplicate_title(body, title):
    """본문 맨 앞의 '# 제목'이 title과 같으면 제거 (post 레이아웃이 h1을 렌더링하므로 중복 방지)"""
    lines = body.lstrip('\n').split('\n')
    if lines and lines[0].strip('# ').strip() == title.strip():
        return '\n'.join(lines[1:]).lstrip('\n')
    return body


def build_jekyll_frontmatter(metadata):
    title = metadata.get('title', 'Untitled')
    date = metadata.get('date', datetime.now().strftime('%Y-%m-%d'))
    category = metadata.get('category', 'Learning')
    tags = parse_list_field(metadata.get('tags', ''))
    author = metadata.get('author', '')

    lines = ['---']
    lines.append(f'title: "{title}"')
    lines.append(f'date: {date}')
    lines.append(f'categories: [{category}]')
    if tags:
        lines.append(f"tags: [{', '.join(tags)}]")
    if author:
        lines.append(f'author: {author}')
    lines.append('---')
    return '\n'.join(lines), title, date


def slug_from_filename(stem):
    """'01_python_basics' -> 'python-basics' (앞의 순번 접두사 제거, _를 -로)"""
    stem = re.sub(r'^\d+[_-]', '', stem)
    return slugify(stem.replace('_', '-'))


def sync_post(md_file, posts_dir):
    content = md_file.read_text(encoding='utf-8')
    metadata, body = read_frontmatter(content)

    frontmatter, title, date = build_jekyll_frontmatter(metadata)
    body = strip_leading_duplicate_title(body, title)

    # Jekyll 파일명 규칙: YYYY-MM-DD-slug.md (파일명 기반 — 안정적이고 영문 친화적)
    date_part = str(date)[:10]
    slug = slug_from_filename(md_file.stem)
    out_name = f"{date_part}-{slug}.md"
    out_path = Path(posts_dir) / out_name

    out_path.write_text(frontmatter + '\n\n' + body.strip() + '\n', encoding='utf-8')
    return out_path


def sync_all(blog_dir, blog_jack_dir):
    blog_path = Path(blog_dir)
    posts_dir = Path(blog_jack_dir) / '_posts'
    posts_dir.mkdir(parents=True, exist_ok=True)

    md_files = [f for f in blog_path.rglob('*.md') if '.templates' not in str(f)]

    if not md_files:
        print("📝 동기화할 마크다운 파일이 없습니다.")
        return

    print(f"\n🔄 {len(md_files)}개의 글을 Jekyll _posts/로 동기화 중입니다...\n")

    for md_file in md_files:
        try:
            out_path = sync_post(md_file, posts_dir)
            print(f"✅ {md_file.name} → _posts/{out_path.name}")
        except Exception as e:
            print(f"❌ {md_file.name} - {e}")

    print(f"\n✨ 완료: blog_jack/_posts/ 에 {len(md_files)}개 글 동기화")
    print("   Jekyll(GitHub Pages)이 push 시 자동으로 HTML을 빌드합니다.")


if __name__ == '__main__':
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    blog_dir = project_root / 'blog'

    blog_jack_path = os.getenv('BLOG_JACK_PATH') or os.path.expanduser('~/Desktop/blog_jack')
    blog_jack_dir = Path(blog_jack_path)

    if not blog_jack_dir.exists():
        print(f"❌ blog_jack 디렉토리를 찾을 수 없습니다: {blog_jack_dir}")
        print("💡 다음 경로에 blog_jack을 클론하세요:")
        print("   git clone git@github.com:tickle1231102-cmd/blog_jack.git ~/Desktop/blog_jack")
        exit(1)

    sync_all(blog_dir, blog_jack_dir)
