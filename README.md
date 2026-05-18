# Daily Note Automation 📝

> Git 변경사항을 분석해서 Obsidian 데일리 노트에 자동으로 기록하는 CLI 도구

Claude Code를 활용해 매일 작업 내용을 자동으로 정리합니다. 더 이상 "오늘 뭐 했지?" 회상하면서 노트 쓰지 마세요.

![Demo](docs/demo.png) <!-- 데모 스크린샷이 있다면 -->

## ✨ 주요 기능

- 🚀 **`dstart`**: 작업 시작 시 데일리 노트 생성 + git 스냅샷 저장
- 🏁 **`dend`**: 작업 마감 시 git 변경사항을 AI가 분석하여 노트에 자동 정리
- 📊 **`dusage`**: Claude Code 토큰 사용량 및 비용 통계
- 🔄 **여러 프로젝트 지원**: 프로젝트별로 독립적인 섹션과 코드 변경 노트
- 📅 **회고 모드**: 어제 dend를 깜빡해도 다음 날 자동 복구
- 🎯 **스마트 비교**: "오늘 자정 이전 마지막 커밋" 기준으로 변경사항 정확히 추적

## 🎬 사용 예시

### 출근 후

```bash
cd ~/work/my-project
dstart
```

```
🚀 프로젝트 시작 요청: my-project
✅ 데일리 노트 생성: 2026-05-19.md
📸 git 스냅샷 저장 (오늘 이전 기준):
   브랜치: main
   기준 커밋: a1b2c3d
   커밋 시각: 2026-05-18 17:30:00
```

### 퇴근 전

```bash
dend
```

```
🏁 프로젝트 마감: my-project
📊 변경 요약: 커밋 3건, 언커밋 5개
🤖 Claude Code로 분석 중...
✅ 정리 완료!
   📝 데일리: ~/Obsidian/.../2026-05-19.md
   💻 코드 변경: ~/Obsidian/.../05_CodeChanges/my-project/CC-2026-05-19.md

📊 Claude Code 사용량:
   ⏱  소요: 42초
   🔢 총:   18,158 토큰
   💰 비용: $0.0234
```

### 생성되는 데일리 노트

```markdown
# 2026-05-19 Tuesday

## 🎯 오늘 할 일
- [x] GraphQL 에러 처리 강화
- [ ] AuthModal 리팩터링

## 📝 작업 로그

### 🔹 my-project
*브랜치: main | 18:15 갱신 | [[my-project/CC-2026-05-19|💻 상세 코드 변경]]*

**🔨 커밋 (3건)**
- `feat: GraphQL 에러 처리 강화` _(2 files, +45 -12)_
- `refactor: AuthModal 분리` _(5 files, +89 -67)_
- ...

**📌 작업 요약**
- GraphQL 클라이언트가 HTTP 200이라도 errors 배열이 있으면 throw하도록 변경
- AuthModal을 login/register/resetpassword로 분리
- ...
```

## 📋 필수 조건

- **macOS** 또는 **Linux** (Windows는 WSL 권장)
- **Git** 설치
- **Claude Code** 설치 ([공식 가이드](https://docs.claude.com/en/docs/claude-code))
- **Obsidian** (또는 마크다운 파일 기반의 노트 시스템)
- (선택) **jq** - 토큰 파싱 정확도 향상 (`brew install jq`)

## 🚀 설치

```bash
# 1. 레포지토리 클론
git clone https://github.com/yourname/daily-note-automation.git
cd daily-note-automation

# 2. 설치 스크립트 실행
./install.sh
```

설치 시 다음을 물어봅니다:
- Obsidian vault 경로 (예: `~/Documents/Obsidian Vault/MyVault`)
- 데일리 노트 폴더명 (기본: `01_Daily`)
- 코드 변경 노트 폴더명 (기본: `05_CodeChanges`)

설치 후 새 터미널을 열거나:
```bash
source ~/.zshrc   # zsh 사용자
source ~/.bash_profile   # bash 사용자
```

## 🎯 사용법

### 일상 워크플로우

```bash
# 출근 후 — 프로젝트 폴더에서 실행
cd ~/work/my-project
dstart

# 작업, 커밋, 작업, 커밋...

# 퇴근 전 — 같은 프로젝트 폴더에서 실행
dend

# 데일리 노트에 자동으로 정리됨!
```

### 여러 프로젝트 다루기

```bash
# 오전: 프로젝트 A
cd ~/work/project-a
dstart
# 작업...
dend       # 데일리에 "### 🔹 project-a" 섹션 추가

# 오후: 프로젝트 B
cd ~/work/project-b
dstart
# 작업...
dend       # 데일리에 "### 🔹 project-b" 섹션 추가
```

### 같은 프로젝트 여러 번 정리

```bash
cd ~/work/my-project
dstart

# 오전 작업...
dend       # 12:00 — 데일리에 섹션 추가

# 오후 추가 작업...
dend       # 18:00 — 같은 섹션을 새 내용으로 갱신
```

### 어제 dend를 깜빡한 경우

```bash
# 화요일 출근
cd ~/work/my-project
dstart

# 자동 감지:
# ⚠️  2026-05-18 작업이 정리되지 않았어요!
#    [1] dend를 먼저 자동 실행 (권장)
#    ...
# → [1] 선택하면 어제 데일리 노트에 자동 정리
```

### 토큰 사용량 확인

```bash
dusage              # 오늘 + 전체 요약
dusage today        # 오늘 상세
dusage week         # 최근 7일
dusage month        # 최근 30일
dusage projects     # 프로젝트별 합계
dusage all          # 전체 상세
```

## 📁 폴더 구조

```
your-vault/
├── 01_Daily/                       # 데일리 노트
│   ├── 2026-05-18.md
│   └── 2026-05-19.md
└── 05_CodeChanges/                 # 코드 변경 상세
    ├── project-a/
    │   ├── CC-2026-05-18.md
    │   └── CC-2026-05-19.md
    └── project-b/
        └── CC-2026-05-19.md
```

스크립트 내부 데이터:
```
~/.daily-note-automation/
├── dstart.sh
├── dend.sh
├── dusage.sh
├── .snapshot-project-a            # 프로젝트별 git 스냅샷
├── .snapshot-project-a.diff
└── .token-usage.log               # 토큰 사용 누적 로그
```

설정 파일:
```
~/.daily-noterc                     # vault 경로 등 설정
```

## ⚙️ 설정 변경

설정 파일을 직접 편집:

```bash
nano ~/.daily-noterc
```

또는 다시 설치 스크립트 실행:

```bash
cd daily-note-automation
./install.sh
```

## 🔧 작동 원리

### git 스냅샷 기반 변경 추적

1. `dstart`: **오늘 자정 이전의 마지막 커밋**을 스냅샷으로 저장
2. 작업 진행
3. `dend`: 스냅샷부터 현재까지의 변경사항을 수집
   - 커밋된 변경: `git diff snapshot..HEAD`
   - 언커밋 변경: `git diff` (현재 작업 디렉토리)
4. Claude Code가 분석하여 의미 있는 단위로 요약
5. Obsidian 데일리 노트의 해당 프로젝트 섹션에 작성

### 데일리 노트 섹션 관리

- 처음 dend → "## 📝 작업 로그" 아래에 "### 🔹 프로젝트명" 섹션 추가
- 같은 프로젝트 dend 재실행 → 해당 섹션만 새 내용으로 교체
- 다른 프로젝트 dend → 별도 섹션 추가, 기존 섹션은 유지

## 🐛 트러블슈팅

### "command not found: dstart"

```bash
source ~/.zshrc  # 또는 ~/.bash_profile
```

또는 터미널을 완전히 닫았다가 다시 열기.

### "현재 폴더는 git 저장소가 아니에요"

프로젝트 루트(`.git` 폴더가 있는 위치)에서 실행하세요:
```bash
ls -la | grep .git
```

### "스냅샷 없음" 에러

`dstart`를 먼저 실행해야 `dend`가 작동합니다.

### Claude Code가 노트 수정을 못 함

vault 경로에 특수문자(공백 등)가 있을 때 발생할 수 있어요. 심볼릭 링크로 해결:

```bash
ln -s "/path/with spaces/MyVault" ~/my-vault
```

`~/.daily-noterc`에서 `VAULT="~/my-vault"` 로 변경.

### 토큰이 0으로 표시됨

`jq` 설치 권장:
```bash
brew install jq    # macOS
sudo apt install jq # Ubuntu
```

또는 Claude Code 버전 확인:
```bash
claude --version
claude -p "test" --output-format json | head -30
```

## 🗑 제거

```bash
# 스크립트 삭제
rm -rf ~/.daily-note-automation
rm ~/.daily-noterc

# alias 제거: ~/.zshrc (또는 ~/.bash_profile) 열어서
# "# >>> daily-note-automation >>>" 부터
# "# <<< daily-note-automation <<<" 까지 삭제
```

데일리 노트와 코드 변경 노트는 **삭제되지 않음** (사용자가 직접 관리).

## 💰 비용

Claude Code는 API 사용량에 따라 과금됩니다. 평균:
- **1회 dend**: 약 $0.02 ~ $0.05 (15,000 ~ 50,000 토큰)
- **하루 평균** (3~5회): $0.10 ~ $0.20
- **월간** (20일 작업): $2 ~ $5

큰 diff (50,000 토큰 이상)는 자동으로 잘립니다. `MAX_DIFF_LEN` 설정으로 조정 가능.

## 🤝 기여

PR 환영합니다! 다음과 같은 개선이 있으면 좋겠어요:

- [ ] Windows 지원 (PowerShell 버전)
- [ ] 영문 데일리 노트 템플릿
- [ ] Logseq, Notion 등 다른 노트 앱 지원
- [ ] 주간/월간 자동 회고
- [ ] GitHub Actions 통합

## 📄 라이선스

MIT License - 자유롭게 사용/수정/배포하세요.

## 🙏 영감

- [Anthropic의 Claude Code](https://docs.claude.com/en/docs/claude-code)
- Obsidian 커뮤니티의 PARA, Zettelkasten 방법론
- 매일 "오늘 뭐 했지?" 회상하던 나의 어제

---

만든이: [@yourname](https://github.com/yourname) | 문제 발견 시 [Issue](https://github.com/yourname/daily-note-automation/issues) 등록 부탁드려요.
