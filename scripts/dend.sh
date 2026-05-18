#!/bin/bash

# 페이저 비활성화 (탭 닫기 경고 방지)
export GIT_PAGER=cat
export PAGER=cat

# ============================================================
# dend.sh - 프로젝트 마감 + git 변경 분석 / wrap up + diff analysis
# https://github.com/leesj3857/daily-note-automation
# ============================================================

CONFIG_FILE="$HOME/.daily-noterc"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config not found: $CONFIG_FILE"
    echo "       Run install.sh first."
    exit 1
fi
source "$CONFIG_FILE"
NOTE_LANG="${NOTE_LANG:-ko}"

say() {
    if [ "$NOTE_LANG" = "ko" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}
sayf() {
    local ko="$1" en="$2"; shift 2
    if [ "$NOTE_LANG" = "ko" ]; then
        printf "$ko\n" "$@"
    else
        printf "$en\n" "$@"
    fi
}

USAGE_LOG="$SCRIPT_DIR/.token-usage.log"

# 회고 모드
if [ -n "$RETROACTIVE_DATE" ]; then
    TARGET_DATE="$RETROACTIVE_DATE"
    IS_RETROACTIVE=1
else
    TARGET_DATE=$(date +%Y-%m-%d)
    IS_RETROACTIVE=0
fi

TARGET_FILE="$DAILY_DIR/$TARGET_DATE.md"

if [ ! -d ".git" ]; then
    say "❌ 현재 폴더는 git 저장소가 아니에요." \
        "❌ Current folder is not a git repository."
    exit 1
fi

PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
SNAPSHOT_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME"
SNAPSHOT_DIFF_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME.diff"

if [ "$IS_RETROACTIVE" -eq 1 ]; then
    sayf "🔙 회고 모드: %s 작업을 정리합니다" \
         "🔙 Retroactive mode: wrapping up %s" "$TARGET_DATE"
else
    sayf "🏁 프로젝트 마감: %s" \
         "🏁 Wrapping up project: %s" "$PROJECT_NAME"
fi
echo ""

# --- 대상 데일리 노트가 없을 때 ---
if [ ! -f "$TARGET_FILE" ]; then
    if [ "$IS_RETROACTIVE" -eq 1 ]; then
        WEEKDAY=$(date -j -f "%Y-%m-%d" "$TARGET_DATE" "+%A" 2>/dev/null || echo "")
        if [ "$NOTE_LANG" = "ko" ]; then
            cat > "$TARGET_FILE" << EOF
---
date: $TARGET_DATE
type: daily
tags: [daily]
---

# $TARGET_DATE $WEEKDAY

## 🎯 오늘 할 일
- [ ]

## 📝 작업 로그
*(프로젝트별 작업 로그)*

## 🚧 막힌 것 / 이슈
-

## 💡 배운 것
-

## 🔗 관련 노트
-

## 📅 내일 할 일
- [ ]
EOF
        else
            cat > "$TARGET_FILE" << EOF
---
date: $TARGET_DATE
type: daily
tags: [daily]
---

# $TARGET_DATE $WEEKDAY

## 🎯 Today
- [ ]

## 📝 Work Log
*(per-project work log)*

## 🚧 Blocked / Issues
-

## 💡 Learned
-

## 🔗 Related Notes
-

## 📅 Tomorrow
- [ ]
EOF
        fi
        sayf "✅ %s.md 생성" "✅ Created %s.md" "$TARGET_DATE"
    else
        say "❌ 오늘 데일리 노트가 없어요. dstart를 먼저 실행해주세요." \
            "❌ Today's daily note is missing. Run dstart first."
        exit 1
    fi
fi

if [ ! -f "$SNAPSHOT_FILE" ]; then
    say "❌ 스냅샷 없음. dstart를 먼저 실행해주세요." \
        "❌ No snapshot found. Run dstart first."
    exit 1
fi

START_COMMIT=$(head -1 "$SNAPSHOT_FILE")
SNAPSHOT_TIME=$(sed -n '2p' "$SNAPSHOT_FILE")
START_BRANCH=$(sed -n '3p' "$SNAPSHOT_FILE")

CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git rev-parse HEAD)

COMMITS=$(git log --oneline "$START_COMMIT..HEAD" 2>/dev/null)
COMMIT_COUNT=$(echo "$COMMITS" | grep -c '.' 2>/dev/null || echo 0)
COMMIT_DETAILS=$(git log "$START_COMMIT..HEAD" --stat --pretty=format:'%n=== %h %s ===%n' 2>/dev/null)
DIFF_STAT_COMMITTED=$(git diff --stat "$START_COMMIT..HEAD" 2>/dev/null)
CHANGED_FILES=$(git diff --name-status "$START_COMMIT..HEAD" 2>/dev/null)
FULL_DIFF_COMMITTED=$(git diff "$START_COMMIT..HEAD" 2>/dev/null)

CURRENT_UNCOMMITTED_STATUS=$(git status --short 2>/dev/null)
CURRENT_UNCOMMITTED_DIFF=$(git diff 2>/dev/null)

NEW_UNCOMMITTED_DIFF=""
ALREADY_RECORDED_NOTE=""

if [ -f "$SNAPSHOT_DIFF_FILE" ]; then
    SNAPSHOT_DIFF_CONTENT=$(cat "$SNAPSHOT_DIFF_FILE")

    if [ -z "$SNAPSHOT_DIFF_CONTENT" ]; then
        NEW_UNCOMMITTED_DIFF="$CURRENT_UNCOMMITTED_DIFF"
    elif [ "$SNAPSHOT_DIFF_CONTENT" == "$CURRENT_UNCOMMITTED_DIFF" ]; then
        NEW_UNCOMMITTED_DIFF=""
        if [ "$NOTE_LANG" = "ko" ]; then
            ALREADY_RECORDED_NOTE="(스냅샷 이후 언커밋 변경 없음)"
        else
            ALREADY_RECORDED_NOTE="(no new uncommitted changes since snapshot)"
        fi
    else
        NEW_UNCOMMITTED_DIFF="$CURRENT_UNCOMMITTED_DIFF"
        SNAP_FILES=$(echo "$SNAPSHOT_DIFF_CONTENT" | grep '^diff --git' | awk '{print $3}' | sed 's|a/||' | sort -u)
        if [ -n "$SNAP_FILES" ]; then
            if [ "$NOTE_LANG" = "ko" ]; then
                ALREADY_RECORDED_NOTE="⚠️ 일부 언커밋 변경은 이전 dstart 시점에 이미 있었던 것 (스냅샷 기준 ${SNAPSHOT_TIME})"
            else
                ALREADY_RECORDED_NOTE="⚠️ Some uncommitted changes already existed at the prior dstart (snapshot at ${SNAPSHOT_TIME})"
            fi
        fi
    fi
else
    NEW_UNCOMMITTED_DIFF="$CURRENT_UNCOMMITTED_DIFF"
fi

UNCOMMIT_COUNT=0
if [ -n "$CURRENT_UNCOMMITTED_STATUS" ]; then
    UNCOMMIT_COUNT=$(echo "$CURRENT_UNCOMMITTED_STATUS" | wc -l | xargs)
fi

if [ "$COMMIT_COUNT" -eq 0 ] && [ -z "$NEW_UNCOMMITTED_DIFF" ] && [ -z "$ALREADY_RECORDED_NOTE" ]; then
    say "⏭  변경사항이 없어요. 종료합니다." \
        "⏭  No changes. Exiting."
    exit 0
fi

say "📊 변경 요약:" "📊 Change summary:"
sayf "   브랜치: %s → %s" "   branch:  %s → %s" "$START_BRANCH" "$CURRENT_BRANCH"
sayf "   커밋: %s건, 현재 언커밋: %s개" \
     "   commits: %s, uncommitted: %s" "$COMMIT_COUNT" "$UNCOMMIT_COUNT"
sayf "   정리 대상: %s 데일리 노트" \
     "   target:  %s daily note" "$TARGET_DATE"
echo ""

if [ ${#FULL_DIFF_COMMITTED} -gt $MAX_DIFF_LEN ]; then
    if [ "$NOTE_LANG" = "ko" ]; then
        FULL_DIFF_COMMITTED="${FULL_DIFF_COMMITTED:0:$MAX_DIFF_LEN}

[... 너무 길어서 잘림 ...]"
    else
        FULL_DIFF_COMMITTED="${FULL_DIFF_COMMITTED:0:$MAX_DIFF_LEN}

[... truncated for length ...]"
    fi
fi
if [ ${#NEW_UNCOMMITTED_DIFF} -gt $MAX_DIFF_LEN ]; then
    if [ "$NOTE_LANG" = "ko" ]; then
        NEW_UNCOMMITTED_DIFF="${NEW_UNCOMMITTED_DIFF:0:$MAX_DIFF_LEN}

[... 너무 길어서 잘림 ...]"
    else
        NEW_UNCOMMITTED_DIFF="${NEW_UNCOMMITTED_DIFF:0:$MAX_DIFF_LEN}

[... truncated for length ...]"
    fi
fi

PROJECT_CHANGES_DIR="$CHANGES_DIR/$PROJECT_NAME"
mkdir -p "$PROJECT_CHANGES_DIR"
CHANGES_FILE="$PROJECT_CHANGES_DIR/CC-$TARGET_DATE.md"

SECTION_EXISTS=0
if grep -q "^### .*$PROJECT_NAME$\|^### .*$PROJECT_NAME |" "$TARGET_FILE" 2>/dev/null; then
    SECTION_EXISTS=1
    say "🔄 기존 섹션 발견 — 갱신합니다." \
        "🔄 Existing section found — updating."
else
    say "➕ 새 섹션 추가합니다." \
        "➕ Adding new section."
fi
echo ""

NOW_TIME=$(date '+%H:%M')
NOW_FULL=$(date '+%Y-%m-%d %H:%M')

if [ "$IS_RETROACTIVE" -eq 1 ]; then
    if [ "$NOTE_LANG" = "ko" ]; then
        LOG_TIME="$SNAPSHOT_TIME 작업 (회고 정리: $NOW_FULL)"
    else
        LOG_TIME="$SNAPSHOT_TIME (retroactively wrapped at $NOW_FULL)"
    fi
else
    if [ "$NOTE_LANG" = "ko" ]; then
        LOG_TIME="$NOW_TIME 갱신"
    else
        LOG_TIME="updated $NOW_TIME"
    fi
fi

say "🤖 Claude Code로 분석 중..." "🤖 Analyzing with Claude Code..."
echo ""

GIT_INFO_FILE=$(mktemp)
cat > "$GIT_INFO_FILE" << EOF
==== Project info ====
project: $PROJECT_NAME
path: $PROJECT_PATH
branch: $START_BRANCH -> $CURRENT_BRANCH
snapshot time: $SNAPSHOT_TIME
target date: $TARGET_DATE
now: $NOW_FULL
retroactive: $IS_RETROACTIVE

==== Commits ($COMMIT_COUNT) ====
$COMMITS

==== Commit details ====
$COMMIT_DETAILS

==== Diff stats ====
$DIFF_STAT_COMMITTED

==== Changed files ====
$CHANGED_FILES

==== Current uncommitted status ====
$CURRENT_UNCOMMITTED_STATUS

==== Notes ====
$ALREADY_RECORDED_NOTE

==== Committed diff ====
$FULL_DIFF_COMMITTED

==== Uncommitted diff ====
$NEW_UNCOMMITTED_DIFF
EOF

# ------------------------------------------------------------
# Build the prompt for Claude Code in the chosen language
# ------------------------------------------------------------
if [ "$NOTE_LANG" = "ko" ]; then
    WORK_LOG_HEADER="## 📝 작업 로그"
    if [ "$SECTION_EXISTS" -eq 1 ]; then
        UPDATE_INSTRUCTION="**작업 1 방식**: 기존 '### 🔹 $PROJECT_NAME' 섹션을 찾아서 다음 '### ' 헤더 또는 '## ' 헤더 직전까지를 새 내용으로 교체. 다른 프로젝트 섹션은 절대 건드리지 마."
    else
        UPDATE_INSTRUCTION="**작업 1 방식**: '$WORK_LOG_HEADER' 섹션의 맨 아래에 새 '### 🔹 $PROJECT_NAME' 섹션을 추가. placeholder가 있으면 제거."
    fi

    PROMPT="다음은 '$PROJECT_NAME' 프로젝트의 git 변경 정보야:

$(cat "$GIT_INFO_FILE")

두 가지 작업을 해줘.

============================================================
작업 1: 데일리 노트 업데이트 ($TARGET_DATE)
============================================================

대상 파일: $TARGET_FILE

$UPDATE_INSTRUCTION

다른 섹션은 절대 건드리지 마.

**섹션 양식**:

### 🔹 $PROJECT_NAME
*브랜치: $CURRENT_BRANCH | $LOG_TIME | [[$PROJECT_NAME/CC-$TARGET_DATE|💻 상세 코드 변경]]*

**🔨 커밋 (N건)**
- \`커밋메시지\` _(파일수, +추가 -삭제)_

**📌 작업 요약**
- 의미 있는 동사형 요약

**🚧 언커밋 변경사항** (있으면만)
- 파일경로: 추정 작업

============================================================
작업 2: 코드 변경 상세 노트 생성/덮어쓰기
============================================================

대상 파일: $CHANGES_FILE
방식: 새로 생성 (덮어쓰기)

양식:

---
date: $TARGET_DATE
type: code-changes
tags: [code-changes, $PROJECT_NAME, $CURRENT_BRANCH]
project: $PROJECT_NAME
branch: $CURRENT_BRANCH
related_daily: \"[[$TARGET_DATE]]\"
updated: $NOW_FULL
---

# 💻 $PROJECT_NAME - 코드 변경 상세 ($TARGET_DATE)

> 📅 [[$TARGET_DATE|데일리 노트로 돌아가기]]
> 🔄 마지막 갱신: $NOW_FULL

## 개요
3-5줄 요약.

---

## 주요 변경 1: [제목]

### 의도
1-3줄

### 핵심 변경

Before:
\\\`\\\`\\\`typescript
\\\`\\\`\\\`

After:
\\\`\\\`\\\`typescript
\\\`\\\`\\\`

### 설명
- 무엇이 / 왜

### 관련 파일
- \\\`경로\\\`

---

## 작은 변경들
- \\\`파일\\\`: 무슨 변경

---

## 💭 회고

### 잘 된 점
-

### 아쉬운 점
-

### 다음에 적용할 것
-

---

## 🔗 참고
- [[]]

규칙:
1. 코드는 핵심만 (5-15줄)
2. 큰 변경 2-4개, 작은 건 작은 변경들에
3. 한국어
4. 회고는 비워둠
5. 변경 적으면 주요 변경 1만 OK

작업:
- 작업 1: Edit으로 $TARGET_FILE 업데이트
- 작업 2: Write로 $CHANGES_FILE 생성 (덮어쓰기)"

else
    WORK_LOG_HEADER="## 📝 Work Log"
    if [ "$SECTION_EXISTS" -eq 1 ]; then
        UPDATE_INSTRUCTION="**Task 1 method**: find the existing '### 🔹 $PROJECT_NAME' section and replace it (up to but not including the next '### ' or '## ' header) with the new content. Never touch any other project's section."
    else
        UPDATE_INSTRUCTION="**Task 1 method**: append a new '### 🔹 $PROJECT_NAME' section at the bottom of the '$WORK_LOG_HEADER' section. Remove any placeholder line if present."
    fi

    PROMPT="Here is the git change info for project '$PROJECT_NAME':

$(cat "$GIT_INFO_FILE")

Please do two things.

============================================================
Task 1: update the daily note ($TARGET_DATE)
============================================================

Target file: $TARGET_FILE

$UPDATE_INSTRUCTION

Do not touch any other section.

**Section format**:

### 🔹 $PROJECT_NAME
*branch: $CURRENT_BRANCH | $LOG_TIME | [[$PROJECT_NAME/CC-$TARGET_DATE|💻 code change details]]*

**🔨 Commits (N)**
- \`commit message\` _(N files, +added -removed)_

**📌 Summary**
- meaningful verb-led bullets

**🚧 Uncommitted changes** (only if any)
- path: inferred change

============================================================
Task 2: create/overwrite the code-changes detail note
============================================================

Target file: $CHANGES_FILE
Method: create new (overwrite)

Format:

---
date: $TARGET_DATE
type: code-changes
tags: [code-changes, $PROJECT_NAME, $CURRENT_BRANCH]
project: $PROJECT_NAME
branch: $CURRENT_BRANCH
related_daily: \"[[$TARGET_DATE]]\"
updated: $NOW_FULL
---

# 💻 $PROJECT_NAME - Code change details ($TARGET_DATE)

> 📅 [[$TARGET_DATE|back to daily note]]
> 🔄 last updated: $NOW_FULL

## Overview
3-5 line summary.

---

## Major change 1: [title]

### Intent
1-3 lines

### Core change

Before:
\\\`\\\`\\\`typescript
\\\`\\\`\\\`

After:
\\\`\\\`\\\`typescript
\\\`\\\`\\\`

### Explanation
- what / why

### Related files
- \\\`path\\\`

---

## Minor changes
- \\\`file\\\`: what changed

---

## 💭 Retrospective

### What went well
-

### What was lacking
-

### To apply next time
-

---

## 🔗 References
- [[]]

Rules:
1. Code excerpts: essentials only (5-15 lines)
2. 2-4 major changes; smaller ones under 'Minor changes'
3. Write in English
4. Leave the retrospective blank
5. If changes are small, a single 'Major change 1' is fine

Actions:
- Task 1: use Edit to update $TARGET_FILE
- Task 2: use Write to create $CHANGES_FILE (overwrite)"
fi

START_TIME=$(date +%s)
CLAUDE_OUTPUT=$(claude -p "$PROMPT" --output-format json 2>&1)
CLAUDE_EXIT=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

rm -f "$GIT_INFO_FILE"

if [ $CLAUDE_EXIT -ne 0 ]; then
    echo ""
    say "⚠️  Claude Code 실행 문제." "⚠️  Claude Code failed."
    echo "$CLAUDE_OUTPUT" | tail -20
    exit 1
fi

say "✅ 정리 완료!" "✅ Wrap-up complete!"
sayf "   📝 데일리:    %s" "   📝 daily:        %s" "$TARGET_FILE"
sayf "   💻 코드 변경: %s" "   💻 code changes: %s" "$CHANGES_FILE"
echo ""

# 토큰 사용량
if command -v jq &> /dev/null; then
    INPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | jq -r '.usage.input_tokens // 0' 2>/dev/null)
    OUTPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | jq -r '.usage.output_tokens // 0' 2>/dev/null)
    CACHE_CREATE=$(echo "$CLAUDE_OUTPUT" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null)
    CACHE_READ=$(echo "$CLAUDE_OUTPUT" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null)
    TOTAL_COST=$(echo "$CLAUDE_OUTPUT" | jq -r '.total_cost_usd // 0' 2>/dev/null)
else
    INPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | grep -o '"input_tokens":[0-9]*' | head -1 | grep -o '[0-9]*' || echo 0)
    OUTPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | grep -o '"output_tokens":[0-9]*' | head -1 | grep -o '[0-9]*' || echo 0)
    CACHE_CREATE=$(echo "$CLAUDE_OUTPUT" | grep -o '"cache_creation_input_tokens":[0-9]*' | head -1 | grep -o '[0-9]*' || echo 0)
    CACHE_READ=$(echo "$CLAUDE_OUTPUT" | grep -o '"cache_read_input_tokens":[0-9]*' | head -1 | grep -o '[0-9]*' || echo 0)
    TOTAL_COST=$(echo "$CLAUDE_OUTPUT" | grep -o '"total_cost_usd":[0-9.]*' | head -1 | grep -o '[0-9.]*' || echo 0)
fi

TOTAL_INPUT=$((INPUT_TOKENS + CACHE_READ + CACHE_CREATE))
GRAND_TOTAL=$((TOTAL_INPUT + OUTPUT_TOKENS))

say "📊 Claude Code 사용량:" "📊 Claude Code usage:"
sayf "   ⏱  소요:   %s초"  "   ⏱  elapsed: %ss"   "$ELAPSED"
sayf "   📥 입력:   %s"    "   📥 input:   %s"    "$INPUT_TOKENS"
[ "$CACHE_READ" != "0" ] && sayf "   💾 캐시 R: %s" "   💾 cache R: %s" "$CACHE_READ"
[ "$CACHE_CREATE" != "0" ] && sayf "   📝 캐시 C: %s" "   📝 cache C: %s" "$CACHE_CREATE"
sayf "   📤 출력:   %s"    "   📤 output:  %s"    "$OUTPUT_TOKENS"
sayf "   🔢 총:     %s"    "   🔢 total:   %s"    "$GRAND_TOTAL"
[ "$TOTAL_COST" != "0" ] && sayf "   💰 비용:   \$%s" "   💰 cost:    \$%s" "$TOTAL_COST"
echo ""

mkdir -p "$SCRIPT_DIR"
echo "$NOW_FULL|$PROJECT_NAME|$IS_RETROACTIVE|$INPUT_TOKENS|$CACHE_READ|$CACHE_CREATE|$OUTPUT_TOKENS|$GRAND_TOTAL|$TOTAL_COST|$ELAPSED" >> "$USAGE_LOG"

TODAY_LOG=$(date +%Y-%m-%d)
TODAY_LINES=$(grep "^$TODAY_LOG " "$USAGE_LOG" 2>/dev/null)
if [ -n "$TODAY_LINES" ]; then
    TODAY_COUNT=$(echo "$TODAY_LINES" | wc -l | xargs)
    TODAY_TOTAL_TOKENS=$(echo "$TODAY_LINES" | awk -F'|' '{sum+=$8} END {print sum}')
    TODAY_TOTAL_COST=$(echo "$TODAY_LINES" | awk -F'|' '{sum+=$9} END {printf "%.4f", sum}')
    sayf "📈 오늘 누적: %s회 / %s 토큰 / \$%s" \
         "📈 today total: %s runs / %s tokens / \$%s" \
         "$TODAY_COUNT" "$TODAY_TOTAL_TOKENS" "$TODAY_TOTAL_COST"
    echo ""
fi

if [ "$IS_RETROACTIVE" -eq 1 ]; then
    say "💡 회고 정리 완료. 이어서 dstart를 진행합니다." \
        "💡 Retroactive wrap-up done. Continuing with dstart."
fi

say "🏠 수고하셨습니다!" "🏠 Nice work!"
