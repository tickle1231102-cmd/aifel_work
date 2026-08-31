# 📚 Blog Jack - 학습 기록 블로그 가이드 (Jekyll 버전)

> aifel_work에서 마크다운으로 작성하면 **blog_jack**(Jekyll + GitHub Pages)으로 동기화되어 자동 배포됩니다.

## 🎯 시스템 개요

```
~/Desktop/
├── aifel_work/                    # 글 작성
│   ├── blog/
│   │   ├── 01_python/*.md
│   │   ├── 02_ai/*.md
│   │   ├── 03_projects/*.md
│   │   └── .templates/post-template.md
│   └── scripts/
│       └── sync-to-jekyll.py      # blog/*.md → blog_jack/_posts/*.md 동기화
│
└── blog_jack/                     # Jekyll 사이트 (GitHub Pages 배포)
    ├── _config.yml
    ├── Gemfile
    ├── _posts/                    # 실제 발행되는 글 (Jekyll 규격)
    ├── _layouts/{default,post,home}.html
    ├── _includes/{header,footer}.html
    ├── assets/css/main.css
    └── index.html                 # 홈(목차 + 카테고리 + 글 목록)
```

**핵심 변화**: 이제 HTML 변환은 직접 하지 않습니다. `sync-to-jekyll.py`는 마크다운을
Jekyll이 이해하는 `_posts/YYYY-MM-DD-slug.md` 형식으로 옮기기만 하고,
**Jekyll(GitHub Pages)이 push 시 자동으로 HTML을 빌드**합니다.

## 🚀 포스트 작성 방법

### 1. 마크다운 작성

```bash
cd ~/Desktop/aifel_work/blog/01_python
cp ../.templates/post-template.md 02_my-post.md
```

```markdown
---
title: "포스트 제목"
date: 2026-09-01
category: "Python"
tags: ["python", "example"]
author: "tickle1231102"
---

본문 내용을 작성하세요.
```

### 2. Jekyll _posts/로 동기화

```bash
cd ~/Desktop/aifel_work
python3 scripts/sync-to-jekyll.py
```

또는 git commit 시 pre-commit hook이 자동 실행됩니다.

### 3. blog_jack에서 배포(push)

```bash
cd ~/Desktop/blog_jack
git add _posts
git commit -m "Add new post"
git push origin main
```

→ GitHub Pages가 push를 감지해 Jekyll로 자동 빌드 & 배포합니다 (보통 1분 이내).

## 🖥️ 로컬에서 미리보기 (선택)

```bash
cd ~/Desktop/blog_jack
bundle install
bundle exec jekyll serve
# http://localhost:4000/blog_jack/ 에서 확인
```

## 🌐 GitHub Pages 설정

1. [blog_jack 저장소](https://github.com/tickle1231102-cmd/blog_jack) → **Settings → Pages**
2. **Source**: `Deploy from a branch`
3. **Branch**: `main` / `(root)`
4. 저장 후 몇 분 뒤 다음 주소에서 확인:
   👉 **https://tickle1231102-cmd.github.io/blog_jack/**

## 🤖 GitHub Actions로 완전 자동화 (선택)

aifel_work에 push하면 자동으로 blog_jack까지 동기화하고 싶다면 PAT(개인 액세스 토큰)이 필요합니다.

1. GitHub → 우측 상단 프로필 → **Settings → Developer settings → Personal access tokens
   → Fine-grained tokens** → New token
   - Repository access: `blog_jack`만 선택
   - Permissions: `Contents: Read and write`
2. 생성된 토큰 복사
3. **aifel_work 저장소** → Settings → Secrets and variables → Actions
   → New repository secret
   - Name: `PAT_TOKEN`
   - Value: (복사한 토큰)
4. 이후 `blog/**/*.md`를 push하면 `.github/workflows/sync-blog.yml`이
   자동으로 blog_jack의 `_posts/`에 커밋 & 푸시합니다.

> PAT 생성/시크릿 등록은 보안이 걸린 작업이라 직접 진행해주세요.

## 📝 프론트매터 필드

| 필드 | 설명 | 예시 |
|------|------|------|
| title | 포스트 제목 | "Python 기초" |
| date | 작성 날짜 | 2026-09-01 |
| category | 카테고리 (Jekyll `categories`로 변환) | "Python" |
| tags | 태그 목록 | ["python", "basics"] |
| author | 작성자 | "tickle1231102" |

## 📂 홈페이지 구성

`blog_jack/index.html` (layout: `home`)이 자동으로:
- 카테고리별 **목차(TOC)** 네비게이션
- 카테고리별 **섹션**과 글 개수
- 각 섹션 아래 **최신순 글 목록** (제목/날짜/태그)

를 `site.posts`를 기반으로 **매 빌드마다 자동 생성**합니다. 별도 관리 불필요.

## 🐛 문제 해결

**Q. 글이 홈페이지에 안 보여요**
- 파일명이 `YYYY-MM-DD-slug.md` 형식인지 확인 (Jekyll 필수 규칙)
- `date`가 미래 날짜면 기본 설정상 노출되지 않을 수 있습니다

**Q. GitHub Pages 빌드 실패**
- blog_jack 저장소 → **Actions** 탭에서 `pages build and deployment` 로그 확인
- `_config.yml`의 YAML 문법 오류 여부 확인

**Q. 로컬 jekyll 명령이 없어요**
```bash
gem install bundler jekyll
```

---

**Happy Blogging! 🚀**
