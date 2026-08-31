# 📚 Blog Jack - 학습 기록 블로그 가이드

> aifel_work에서 마크다운으로 작성하면 자동으로 blog_jack에서 HTML 블로그로 변환되는 시스템입니다.

## 🎯 시스템 개요

```
aifel_work (메인 리포지토리)
  ├── blog/                     # 📝 마크다운 포스트 작성 폴더
  │   ├── 01_python/
  │   ├── 02_ai/
  │   ├── 03_projects/
  │   └── .templates/
  ├── scripts/
  │   └── md-to-html.py         # 변환 스크립트
  └── blog_jack/                # 🌐 생성된 HTML 블로그 (자동 동기화)
```

## 🚀 빠른 시작

### 1️⃣ 블로그 포스트 작성

**블로그 폴더에서 마크다운 파일 생성:**

```bash
cd blog/01_python
cp ../../.templates/post-template.md my-first-post.md
```

**my-first-post.md를 텍스트 에디터에서 수정:**

```markdown
---
title: "Python 함수 알아보기"
date: 2026-08-31
category: "Python"
tags: ["python", "functions"]
author: "tickle1231102"
---

# Python 함수 알아보기

## 함수란?

함수는 특정 작업을 수행하는 재사용 가능한 코드 블록입니다.

```python
def greet(name):
    return f"Hello, {name}!"

print(greet("Jack"))  # Hello, Jack!
```

## 함수의 구성요소
...
```

### 2️⃣ 자동 변환 및 동기화

**로컬에서 테스트:**
```bash
python scripts/md-to-html.py
```

**git에 커밋하면 자동 변환:**
```bash
git add blog/01_python/my-first-post.md
git commit -m "Add Python 함수 알아보기"
git push origin main
```

→ GitHub Actions가 자동으로:
1. `blog/` 폴더의 모든 `.md` 파일을 HTML로 변환
2. `blog_jack/` 폴더에 저장
3. `blog_jack`을 자동으로 커밋 & 푸시

### 3️⃣ blog_jack에서 직접 수정

blog_jack 리포지토리에서도 HTML을 직접 수정할 수 있습니다:

```bash
cd blog_jack
# HTML 파일 직접 편집
git add .
git commit -m "Update post styling"
git push origin main
```

## 📝 마크다운 가이드

### 프론트매터 (필수)

```markdown
---
title: "포스트 제목"
date: 2026-08-31
category: "카테고리"
tags: ["태그1", "태그2"]
author: "작성자명"
---
```

| 필드 | 설명 | 예시 |
|------|------|------|
| title | 포스트 제목 | "Python 기초" |
| date | 작성 날짜 | 2026-08-31 |
| category | 카테고리 | "Python", "AI", "Projects" |
| tags | 태그 (배열) | ["python", "basics"] |
| author | 작성자 | "tickle1231102" |

### 마크다운 작성

```markdown
# 제목 1
## 제목 2
### 제목 3

**굵은 텍스트**
*기울임 텍스트*
~~취소선~~

- 리스트 항목 1
- 리스트 항목 2

1. 번호 항목 1
2. 번호 항목 2

[링크](https://example.com)

![이미지](image.png)

`인라인 코드`

\`\`\`python
# 코드 블록
print("Hello, World!")
\`\`\`

> 인용문
> 여러 줄도 가능합니다
```

## 📂 폴더 구조

**카테고리별로 폴더 구성:**

```
blog/
├── 01_python/          # Python 학습
│   ├── 01_basics.md
│   ├── 02_functions.md
│   └── 03_classes.md
├── 02_ai/              # AI/ML 학습
│   ├── 01_numpy.md
│   └── 02_pandas.md
├── 03_projects/        # 프로젝트
│   └── 01_first_project.md
└── .templates/
    └── post-template.md
```

## ⚙️ 설정 및 커스터마이징

### 블로그 스타일 수정

`blog_jack/styles/main.css`를 수정하면 모든 포스트의 스타일이 변경됩니다.

```css
:root {
    --primary-color: #3498db;      /* 주 색상 */
    --secondary-color: #2ecc71;    /* 보조 색상 */
    --bg-color: #f8f9fa;           /* 배경 색상 */
}
```

### HTML 템플릿 수정

`scripts/md-to-html.py`에서 `create_html_template()` 함수를 수정하면 
HTML 구조를 변경할 수 있습니다.

## 🔄 자동화 워크플로우

### Git Hook (로컬)
```bash
# .githooks/pre-commit 실행
# git commit 시마다 자동으로 마크다운 → HTML 변환
```

### GitHub Actions
```yaml
# .github/workflows/sync-blog.yml 실행
# main 브랜치에 push 시 자동으로:
# 1. 마크다운 → HTML 변환
# 2. blog_jack으로 동기화
```

## 🐛 문제 해결

### 1. 변환 스크립트 실행 오류

```bash
# markdown 라이브러리 설치
pip install markdown pygments
```

### 2. Git Hook이 실행되지 않음

```bash
# 권한 확인
ls -la .githooks/pre-commit

# 권한이 없으면 추가
chmod +x .githooks/pre-commit

# Git config 확인
git config core.hooksPath
# 결과: .githooks
```

### 3. HTML 파일이 생성되지 않음

```bash
# 스크립트 직접 실행 테스트
python scripts/md-to-html.py

# 에러 메시지 확인
```

## 📊 파일 동기화 상태 확인

```bash
# blog_jack의 metadata.json 확인
cat blog_jack/metadata.json

# 최근 동기화 시간 확인
cat sync-timestamp.txt
```

## 💡 팁

### 1. 여러 포스트 한 번에 작성

```bash
# blog/01_python/ 폴더에서 여러 파일 작성 후
git add blog/01_python/*.md
git commit -m "Add Python series posts"
git push
# 한 번의 push로 모두 변환 & 동기화!
```

### 2. 초안 작성

포스트 프론트매터에 `draft: true`를 추가하면 
(향후 기능) 초안 상태로 관리 가능합니다.

### 3. 이미지 추가

```markdown
# blog/images/ 폴더에 이미지 저장
![설명](images/my-image.png)
```

## 🤝 blog_jack 리포지토리

blog_jack은 독립적인 리포지토리로도 운영 가능합니다:

```bash
# blog_jack 클론
git clone git@github.com:tickle1231102-cmd/blog_jack.git

# 블로그 구조
blog_jack/
├── index.html
├── posts/
│   └── 01_python_basics.html
├── styles/
│   └── main.css
└── metadata.json
```

## 📚 다음 단계

1. ✅ 첫 포스트 작성
2. ⬜ 블로그 스타일 커스터마이징
3. ⬜ GitHub Pages 배포 설정
4. ⬜ 댓글 기능 추가
5. ⬜ RSS 피드 생성

---

**Happy Blogging! 🚀**
