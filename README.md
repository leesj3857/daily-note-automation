# Daily Note Automation 📝

> Git 변경사항을 분석해서 Obsidian 데일리 노트에 자동으로 기록하는 CLI 도구

Claude Code를 활용해 매일 작업 내용을 자동으로 정리합니다. 더 이상 "오늘 뭐 했지?" 회상하면서 노트 쓰지 마세요.

## ✨ 주요 기능

- 🚀 **`dstart`**: 작업 시작 시 데일리 노트 생성 + git 스냅샷 저장
- 🏁 **`dend`**: 작업 마감 시 git 변경사항을 AI가 분석하여 노트에 자동 정리
- 📊 **`dusage`**: Claude Code 토큰 사용량 및 비용 통계
- 🔄 **여러 프로젝트 지원**: 프로젝트별로 독립적인 섹션과 코드 변경 노트
- 📅 **회고 모드**: 어제 dend를 깜빡해도 다음 날 자동 복구
- 🎯 **스마트 비교**: "오늘 자정 이전 마지막 커밋"을 기준으로 잡아, 오늘 이미 한 커밋도 추적 대상에 포함

## 🎬 사용 예시

### 작업 전

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

### 작업 종료

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
- **Obsidian** — `[[wiki link]]` 문법과 폴더 구조(`01_Daily`, `05_CodeChanges`)에 맞춰 작성됩니다. 다른 마크다운 노트 앱에서도 파일은 열리지만, wiki 링크가 깨질 수 있어요.
- (선택) **jq** - 토큰 파싱 정확도 향상 (`brew install jq`)

## 🚀 설치

```bash
# 1. 레포지토리 클론
git clone https://github.com/leesj3857/daily-note-automation.git
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

스냅샷은 **프로젝트(폴더명)별로 독립**되어 있어서, A의 `dend`를 까먹은 채로 B에서 `dstart`를 해도 A의 스냅샷은 그대로 유지됩니다.

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
dend       # 12:00 — 데일리에 섹션 추가 (오전 작업분)

# 오후 추가 작업...
dend       # 18:00 — 같은 섹션을 다시 작성 (오전+오후 누적분)
```

> **갱신 방식**: 스냅샷은 `dstart` 시점에 고정되므로, 두 번째 `dend`는 **오전부터 지금까지 전체 변경분**을 다시 분석해서 섹션을 통째로 새로 씁니다. 오전 작업이 누락되지 않습니다.

### 어제 dend를 깜빡한 경우

`dstart`를 실행하면 자동으로 감지해서 물어봅니다.

```bash
# 화요일 출근
cd ~/work/my-project
dstart

# ⚠️  2026-05-18 작업이 정리되지 않았어요!
#    - 마지막 dstart: 2026-05-18 09:12
#    - 정리 안 된 커밋: 4건
#
# 🤔 어떻게 할까요?
#    [1] dend를 먼저 자동 실행 (권장) — 어제 데일리 노트에 자동 정리 후 오늘 시작
#    [2] 직접 정리                    — 종료하고 사용자가 dend → dstart 순서로 진행
#    [3] 이전 작업 버리기 ⚠️           — 'yes' 입력 시 어제 변경 무시하고 새로 시작
#    [Enter] 취소
```

### 오늘 이미 dstart를 실행한 경우

같은 날 두 번째 `dstart`도 안전합니다.

```
# ⚠️  오늘 이미 dstart를 실행했어요!
#    [1] 기존 스냅샷 유지 (권장)
#    [2] dend 먼저 실행 안내
#    [3] 강제로 새 스냅샷 ⚠️
#    [Enter] 취소
```

### 토큰 사용량 확인

`dend` 실행 시 자동으로 `~/.daily-note-automation/.token-usage.log`에 기록됩니다. 프로젝트 단위는 **현재 폴더명**(`basename $(pwd)`) 기준입니다.

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

큰 diff는 기본 40,000자에서 잘립니다. `~/.daily-noterc`의 `MAX_DIFF_LEN` 값을 수정해 조정할 수 있어요.

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

만든이: [@leesj3857](https://github.com/leesj3857) | 문제 발견 시 [Issue](https://github.com/leesj3857/daily-note-automation/issues) 등록 부탁드려요.
