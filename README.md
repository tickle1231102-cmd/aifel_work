# aifel_work

> 크리에이티브 개발자 YB의 프로젝트 저장소

## 👋 자기소개

안녕하세요! 저는 **YB**라고 합니다. 저는 기술과 예술의 경계를 넘나드는 크리에이티브 개발자로, 다양한 분야에서 프로젝트를 진행하고 있습니다.

### 🎯 주요 관심 분야

- **크리에이티브 코딩**: Processing, Arduino 활용한 인터랙티브 아트 및 피지컬 컴퓨팅
- **게임 & VR 개발**: Roblox, Insta360 등을 통한 몰입형 콘텐츠 제작
- **영상 & 그래픽 디자인**: Adobe Creative Suite, DaVinci Resolve를 활용한 시각 콘텐츠 제작
- **데이터 시각화**: Tableau를 활용한 데이터 분석 및 인사이트 도출
- **프로젝션 맵핑**: MadMapper를 활용한 공간 기반 미디어 아트

### 💻 기술 스택

```
Languages:     Python, JavaScript, Processing, Arduino C++
Creative:      Adobe CC, DaVinci Resolve, MadMapper
Data:          Tableau, SQL
Game Engines:  Roblox Studio
Version Control: Git, GitHub
```

### 🚀 최근 프로젝트 분야

- 학술 자료 관리 및 문헌 분석 (EndNote)
- 프로토타입 및 아이디어 검증
- 크로스플랫폼 인터랙티브 콘텐츠 개발

### 📫 연락처

- **Email**: tickle1231102@gmail.com
- **GitHub**: [@tickle1231102-cmd](https://github.com/tickle1231102-cmd)

---

## 📚 학습 기록 블로그 (blog_jack 연동)

이 저장소에서 마크다운으로 학습 내용을 기록하면, **[blog_jack](https://github.com/tickle1231102-cmd/blog_jack)**
(Jekyll + GitHub Pages)으로 자동 동기화되어 블로그 형태로 발행됩니다.

🌐 **배포된 블로그**: https://tickle1231102-cmd.github.io/blog_jack/

### 구조

```
aifel_work/                        blog_jack/ (별도 저장소, ~/Desktop/blog_jack)
├── blog/                          ├── _config.yml
│   ├── 01_python/*.md             ├── _posts/            ← 발행되는 글
│   ├── 02_ai/*.md                 ├── _layouts/           (default / post / home)
│   ├── 03_projects/*.md           ├── _includes/          (header / footer)
│   └── .templates/                ├── assets/css/main.css
├── scripts/                       ├── index.html          ← 홈(목차+카테고리+글목록)
│   └── sync-to-jekyll.py          └── .github/workflows/pages.yml (자동 빌드·배포)
├── .githooks/pre-commit
└── .github/workflows/sync-blog.yml
```

- **글 작성**: `blog/` 아래 카테고리 폴더에 프론트매터(title/date/category/tags/author)를
  갖춘 마크다운 파일 작성
- **동기화**: `python3 scripts/sync-to-jekyll.py` (또는 git commit 시 pre-commit hook이 자동 실행)
  → `blog_jack/_posts/YYYY-MM-DD-slug.md`로 복사
- **배포**: blog_jack 저장소에 push → GitHub Actions가 Jekyll로 빌드 후 GitHub Pages에 자동 배포
- **홈페이지**: 카테고리별 목차(TOC)와 최신순 글 목록이 `site.posts` 기준으로 매 빌드마다 자동 생성

자세한 사용법은 [BLOG_GUIDE.md](BLOG_GUIDE.md) 참고.

---

**이 저장소는 다양한 크리에이티브 프로젝트들을 보관하고 공유하는 공간입니다.**  
새로운 기술 학습, 실험, 협업을 통해 계속 성장하고 있습니다.
