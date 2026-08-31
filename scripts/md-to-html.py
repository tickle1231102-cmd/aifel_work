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

def create_html_template(title, content, metadata):
    """HTML 템플릿 생성"""
    date = metadata.get('date', datetime.now().strftime('%Y-%m-%d'))
    category = metadata.get('category', 'Learning')
    tags = metadata.get('tags', '').strip('[]').split(',')
    tags = [tag.strip().strip('"\'') for tag in tags if tag.strip()]
    author = metadata.get('author', 'tickle1231102')

    tags_html = ''.join([f'<span class="tag">{tag}</span>' for tag in tags])

    html = f"""<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} | Blog Jack</title>
    <link rel="stylesheet" href="../styles/main.css">
    <link rel="stylesheet" href="../styles/highlight.css">
</head>
<body>
    <nav class="navbar">
        <div class="container">
            <div class="logo"><a href="/">Blog Jack</a></div>
            <ul class="nav-links">
                <li><a href="/">Home</a></li>
                <li><a href="/posts">Posts</a></li>
                <li><a href="/categories">Categories</a></li>
            </ul>
        </div>
    </nav>

    <main class="container">
        <article class="post">
            <header class="post-header">
                <h1>{title}</h1>
                <div class="meta">
                    <span class="date">📅 {date}</span>
                    <span class="category">📂 {category}</span>
                    <span class="author">✍️ {author}</span>
                </div>
                <div class="tags">
                    {tags_html}
                </div>
            </header>

            <div class="post-content">
                {content}
            </div>

            <footer class="post-footer">
                <p>이 포스트는 <a href="https://github.com/tickle1231102-cmd/aifel_work">aifel_work</a>에서 작성되고 자동으로 동기화됩니다.</p>
            </footer>
        </article>

        <aside class="sidebar">
            <div class="widget">
                <h3>최근 포스트</h3>
                <ul id="recent-posts"></ul>
            </div>
        </aside>
    </main>

    <footer class="site-footer">
        <p>&copy; 2026 Blog Jack. All rights reserved.</p>
    </footer>

    <script src="../scripts/main.js"></script>
</body>
</html>"""

    return html

def convert_md_to_html(md_file_path, output_dir):
    """마크다운 파일을 HTML로 변환"""
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
        return True

    except Exception as e:
        print(f"❌ 오류: {md_file_path.name} - {str(e)}")
        return False

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

    success_count = 0
    for md_file in md_files:
        if convert_md_to_html(md_file, blog_jack_path):
            success_count += 1

    print(f"\n✨ 완료: {success_count}/{len(md_files)}개 파일 변환")

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
