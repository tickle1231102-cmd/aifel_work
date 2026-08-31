#!/usr/bin/env python3
"""
마크다운을 HTML로 변환하고 blog_jack에 동기화하는 스크립트
"""

import os
import re
from pathlib import Path
from datetime import datetime
import json
import markdown
from markdown.extensions import meta, tables, fenced_code, toc

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
    markdown_content = '\n'.join(lines[end_idx+1:])

    metadata = {}
    for line in meta_str.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip()] = value.strip().strip('"\'')

    return metadata, markdown_content

def strip_duplicate_title(content, title):
    """마크다운 본문 맨 앞의 '# 제목'이 프론트매터 title과 같으면 제거 (중복 방지)"""
    pattern = r'^\s*<h1[^>]*>\s*' + re.escape(title) + r'\s*</h1>\s*'
    return re.sub(pattern, '', content, count=1, flags=re.IGNORECASE)


def create_html_template(title, content, metadata):
    """HTML 템플릿 생성 - 심플하고 읽기 좋은 미니멀 디자인"""
    date = metadata.get('date', datetime.now().strftime('%Y-%m-%d'))
    category = metadata.get('category', 'Learning')
    tags = metadata.get('tags', '').strip('[]').split(',')
    tags = [tag.strip().strip('"\'') for tag in tags if tag.strip()]
    author = metadata.get('author', 'tickle1231102')

    content = strip_duplicate_title(content, title)

    tags_html = ''.join([f'<span class="tag">#{tag}</span>' for tag in tags])

    html = f"""<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} · Blog Jack</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Pretendard:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styles/main.css">
</head>
<body>
    <nav class="navbar">
        <div class="wrap">
            <a class="logo" href="index.html">Blog Jack</a>
        </div>
    </nav>

    <main class="wrap">
        <article class="post">
            <header class="post-header">
                <p class="category">{category}</p>
                <h1>{title}</h1>
                <div class="meta">
                    <span>{date}</span>
                    <span>·</span>
                    <span>{author}</span>
                </div>
                <div class="tags">
                    {tags_html}
                </div>
            </header>

            <div class="post-content">
                {content}
            </div>

            <footer class="post-footer">
                <p>이 글은 <a href="https://github.com/tickle1231102-cmd/aifel_work" target="_blank" rel="noopener">aifel_work</a>에서 작성되어 자동으로 동기화되었습니다.</p>
            </footer>
        </article>
    </main>

    <footer class="site-footer">
        <p>&copy; 2026 Blog Jack</p>
    </footer>
</body>
</html>"""

    return html

def convert_md_to_html(md_file_path, output_dir):
    """마크다운 파일을 HTML로 변환. 성공 시 목록 페이지용 메타데이터 dict, 실패 시 None 반환"""
    try:
        # 마크다운 파일 읽기
        with open(md_file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 프론트매터 추출
        metadata, md_content = read_frontmatter(content)

        # 마크다운을 HTML로 변환
        md_html = markdown.markdown(
            md_content,
            extensions=[
                'tables',
                'fenced_code',
                'toc',
                'codehilite'
            ]
        )

        # 전체 HTML 생성
        title = metadata.get('title', md_file_path.stem)
        full_html = create_html_template(title, md_html, metadata)

        # 출력 파일명 생성
        output_filename = md_file_path.stem + '.html'
        output_path = Path(output_dir) / output_filename

        # HTML 파일 저장
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(full_html)

        print(f"✅ 변환 완료: {md_file_path.name} → {output_path.name}")

        tags = metadata.get('tags', '').strip('[]').split(',')
        tags = [t.strip().strip('"\'') for t in tags if t.strip()]

        return {
            'title': title,
            'date': metadata.get('date', ''),
            'category': metadata.get('category', 'Learning'),
            'tags': tags,
            'author': metadata.get('author', ''),
            'filename': output_filename,
        }

    except Exception as e:
        print(f"❌ 오류: {md_file_path.name} - {str(e)}")
        return None


def build_index_html(posts, blog_jack_path):
    """카테고리 목차 + 전체 글 목록을 담은 홈페이지(index.html) 생성"""
    # 최신순 정렬 (날짜 없는 값은 뒤로)
    posts_sorted = sorted(posts, key=lambda p: p.get('date') or '', reverse=True)

    # 카테고리별로 묶기 (등장 순서 유지)
    categories = []
    by_category = {}
    for p in posts_sorted:
        cat = p['category']
        if cat not in by_category:
            by_category[cat] = []
            categories.append(cat)
        by_category[cat].append(p)

    def slugify(text):
        return re.sub(r'[^a-z0-9가-힣]+', '-', text.lower()).strip('-')

    # 목차 (카테고리 앵커 링크)
    toc_items = ''.join(
        f'<li><a href="#{slugify(cat)}">{cat}</a> <span class="count">{len(by_category[cat])}</span></li>'
        for cat in categories
    )

    # 카테고리별 섹션 + 글 목록
    sections_html = ''
    for cat in categories:
        items = ''.join(f'''
                <li class="post-item">
                    <a class="post-item-title" href="{p['filename']}">{p['title']}</a>
                    <div class="post-item-meta">
                        <span>{p['date']}</span>
                        {''.join(f'<span class="tag">#{t}</span>' for t in p['tags'])}
                    </div>
                </li>''' for p in by_category[cat])

        sections_html += f'''
        <section class="category-section" id="{slugify(cat)}">
            <h2 class="category-title">{cat} <span class="count">{len(by_category[cat])}</span></h2>
            <ul class="post-list">{items}
            </ul>
        </section>'''

    html = f"""<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blog Jack · 학습 기록</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Pretendard:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styles/main.css">
</head>
<body>
    <nav class="navbar">
        <div class="wrap">
            <a class="logo" href="index.html">Blog Jack</a>
        </div>
    </nav>

    <main class="wrap">
        <header class="home-header">
            <h1>학습 기록</h1>
            <p class="home-sub">aifel_work에서 작성하고 자동으로 동기화되는 학습 블로그입니다. 총 {len(posts_sorted)}개의 글이 있습니다.</p>
        </header>

        <nav class="toc">
            <h3>카테고리</h3>
            <ul>{toc_items}</ul>
        </nav>

        {sections_html}
    </main>

    <footer class="site-footer">
        <p>&copy; 2026 Blog Jack</p>
    </footer>
</body>
</html>"""

    index_path = Path(blog_jack_path) / 'index.html'
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"🏠 홈페이지 생성 완료: {index_path.name}")

def sync_to_blog_jack(blog_dir, blog_jack_dir):
    """변환된 HTML을 blog_jack으로 동기화"""
    blog_path = Path(blog_dir)
    blog_jack_path = Path(blog_jack_dir)

    # blog_jack 디렉토리가 없으면 생성
    blog_jack_path.mkdir(parents=True, exist_ok=True)

    # 모든 마크다운 파일 처리
    md_files = list(blog_path.rglob('*.md'))
    md_files = [f for f in md_files if '.templates' not in str(f)]

    if not md_files:
        print("📝 변환할 마크다운 파일이 없습니다.")
        return

    print(f"\n🔄 {len(md_files)}개의 마크다운 파일을 처리 중입니다...\n")

    posts = []
    for md_file in md_files:
        post_meta = convert_md_to_html(md_file, blog_jack_path)
        if post_meta:
            posts.append(post_meta)

    success_count = len(posts)
    print(f"\n✨ 완료: {success_count}/{len(md_files)}개 파일 변환")

    # 카테고리/목차/글 목록을 담은 홈페이지 생성
    build_index_html(posts, blog_jack_path)

    # 변환 결과 메타데이터 생성
    metadata = {
        'last_updated': datetime.now().isoformat(),
        'total_posts': success_count,
        'blog_dir': str(blog_path),
        'blog_jack_dir': str(blog_jack_path)
    }

    metadata_path = blog_jack_path / 'metadata.json'
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    import os

    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    blog_dir = project_root / 'blog'

    # blog_jack 디렉토리 경로 설정
    # 1. 환경변수 확인
    blog_jack_path = os.getenv('BLOG_JACK_PATH')

    # 2. 환경변수가 없으면 기본 경로 사용
    if not blog_jack_path:
        blog_jack_path = os.path.expanduser('~/Desktop/blog_jack')

    blog_jack_dir = Path(blog_jack_path)

    # blog_jack 디렉토리 존재 확인
    if not blog_jack_dir.exists():
        print(f"❌ blog_jack 디렉토리를 찾을 수 없습니다: {blog_jack_dir}")
        print(f"💡 다음 경로에 blog_jack을 클론하세요:")
        print(f"   git clone git@github.com:tickle1231102-cmd/blog_jack.git ~/Desktop/blog_jack")
        exit(1)

    sync_to_blog_jack(blog_dir, blog_jack_dir)
