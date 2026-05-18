#!/bin/bash

# 페이저 비활성화 (탭 닫기 경고 방지)
export GIT_PAGER=cat
export PAGER=cat

# ============================================================
# dstart.sh - 프로젝트 시작 / start work
# https://github.com/leesj3857/daily-note-automation
# ============================================================

# --- 설정 파일 로드 ---
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
    # printf-style; $1=ko fmt, $2=en fmt, rest=args
    local ko="$1" en="$2"; shift 2
    if [ "$NOTE_LANG" = "ko" ]; then
        printf "$ko\n" "$@"
    else
        printf "$en\n" "$@"
    fi
}

TODAY=$(date +%Y-%m-%d)
TODAY_FILE="$DAILY_DIR/$TODAY.md"

if [ ! -d ".git" ]; then
    say "❌ 현재 폴더는 git 저장소가 아니에요." \
        "❌ Current folder is not a git repository."
    say "   프로젝트 루트 폴더에서 실행해주세요." \
        "   Run this from the project root."
    exit 1
fi

PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
SNAPSHOT_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME"
SNAPSHOT_DIFF_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME.diff"

mkdir -p "$SCRIPT_DIR"

sayf "🚀 프로젝트 시작 요청: %s" "🚀 Starting project: %s" "$PROJECT_NAME"
sayf "   경로: %s" "   path: %s" "$PROJECT_PATH"
echo ""

# "오늘 자정 이전 마지막 커밋" 찾기
find_pre_today_commit() {
    local cutoff="$TODAY 00:00:00"
    local pre_commit=$(git log --before="$cutoff" -1 --format=%H 2>/dev/null)

    if [ -n "$pre_commit" ]; then
        echo "$pre_commit"
        return 0
    fi

    local first_commit=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
    if [ -n "$first_commit" ]; then
        echo "$first_commit"
        return 0
    fi

    return 1
}

save_snapshot() {
    local commit=$(find_pre_today_commit)
    local branch=$(git branch --show-current 2>/dev/null)

    if [ -z "$commit" ]; then
        say "❌ 기준 커밋을 찾을 수 없어요." \
            "❌ No baseline commit found."
        return 1
    fi

    local commit_date=$(git log -1 --format="%ai" "$commit" 2>/dev/null)
    local commit_msg=$(git log -1 --format="%s" "$commit" 2>/dev/null)

    {
        echo "$commit"
        date '+%Y-%m-%d %H:%M:%S'
        echo "$branch"
        echo "$PROJECT_PATH"
    } > "$SNAPSHOT_FILE"

    git diff > "$SNAPSHOT_DIFF_FILE" 2>/dev/null

    say "📸 git 스냅샷 저장 (오늘 이전 기준):" \
        "📸 git snapshot saved (baseline = before today):"
    sayf "   브랜치: %s" "   branch:  %s" "$branch"
    sayf "   기준 커밋: %s" "   commit:  %s" "${commit:0:7}"
    sayf "   커밋 시각: %s" "   when:    %s" "$commit_date"
    sayf "   커밋 메시지: %s" "   message: %s" "$commit_msg"

    local upcoming_commits=$(git log --oneline "$commit..HEAD" 2>/dev/null | wc -l | xargs)
    local uncommit_count=$(git status --short 2>/dev/null | wc -l | xargs)

    if [ "$upcoming_commits" -gt 0 ]; then
        sayf "   📌 이 기준 이후 이미 커밋된 변경: %s건" \
             "   📌 commits already on top of baseline: %s" "$upcoming_commits"
    fi
    if [ "$uncommit_count" -gt 0 ]; then
        sayf "   📌 현재 언커밋: %s개 파일" \
             "   📌 uncommitted files: %s" "$uncommit_count"
    fi
}

# --- 기존 스냅샷 분석 ---
if [ -f "$SNAPSHOT_FILE" ]; then
    OLD_COMMIT=$(head -1 "$SNAPSHOT_FILE")
    OLD_TIME=$(sed -n '2p' "$SNAPSHOT_FILE")
    OLD_BRANCH=$(sed -n '3p' "$SNAPSHOT_FILE")
    OLD_DATE=$(echo "$OLD_TIME" | cut -d' ' -f1)
    OLD_HOUR=$(echo "$OLD_TIME" | cut -d' ' -f2)

    CHANGES_SINCE=$(git log --oneline "$OLD_COMMIT..HEAD" 2>/dev/null | wc -l | xargs)

    CURRENT_DIFF=$(git diff 2>/dev/null)
    OLD_DIFF=""
    if [ -f "$SNAPSHOT_DIFF_FILE" ]; then
        OLD_DIFF=$(cat "$SNAPSHOT_DIFF_FILE")
    fi

    UNCOMMIT_CHANGED=0
    if [ "$CURRENT_DIFF" != "$OLD_DIFF" ]; then
        UNCOMMIT_CHANGED=1
    fi

    if [ "$OLD_DATE" == "$TODAY" ]; then
        say "⚠️  오늘 이미 dstart를 실행했어요!" \
            "⚠️  dstart already ran today!"
        sayf "   - 마지막 실행: %s" "   - last run:        %s" "$OLD_HOUR"
        sayf "   - 기준 커밋:   %s @ %s" "   - baseline commit: %s @ %s" "$OLD_BRANCH" "${OLD_COMMIT:0:7}"
        sayf "   - 그 시점 이후 커밋: %s건" "   - commits since:   %s" "$CHANGES_SINCE"
        if [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
            say "   - 언커밋 변경: 있음" "   - uncommitted changes: yes"
        fi
        echo ""
        say "🤔 어떻게 할까요?" "🤔 What would you like to do?"
        say "   [1] 기존 스냅샷 유지 (권장)" "   [1] Keep existing snapshot (recommended)"
        say "   [2] dend 먼저 실행 안내" "   [2] Run dend first (you'll be prompted)"
        say "   [3] 강제로 새 스냅샷 ⚠️" "   [3] Force new snapshot ⚠️"
        say "   [Enter] 취소" "   [Enter] Cancel"
        echo ""
        if [ "$NOTE_LANG" = "ko" ]; then
            read -p "선택: " choice
        else
            read -p "Choice: " choice
        fi

        case "$choice" in
            1) say "✅ 기존 스냅샷 유지" "✅ Keeping existing snapshot."; exit 0 ;;
            2) say "💡 dend → dstart 순서로 진행하세요." \
                   "💡 Run dend first, then dstart."; exit 0 ;;
            3)
                if [ "$NOTE_LANG" = "ko" ]; then
                    read -p "정말로 새로 시작할까요? 'yes' 입력: " confirm
                else
                    read -p "Really start fresh? Type 'yes': " confirm
                fi
                [ "$confirm" != "yes" ] && exit 0
                ;;
            *) exit 0 ;;
        esac

    elif [ "$CHANGES_SINCE" -gt 0 ] || [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
        sayf "⚠️  %s 작업이 정리되지 않았어요!" \
             "⚠️  Work from %s wasn't wrapped up!" "$OLD_DATE"
        sayf "   - 마지막 dstart: %s %s" \
             "   - last dstart:    %s %s" "$OLD_DATE" "$OLD_HOUR"
        sayf "   - 정리 안 된 커밋: %s건" \
             "   - unsaved commits: %s" "$CHANGES_SINCE"
        if [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
            say "   - 언커밋 변경: 있음" "   - uncommitted changes: yes"
        fi
        echo ""
        say "💡 그날 dend를 깜빡하신 것 같아요." \
            "💡 Looks like dend was forgotten that day."
        echo ""
        say "🤔 어떻게 할까요?" "🤔 What would you like to do?"
        say "   [1] dend를 먼저 자동 실행 (권장)" \
            "   [1] Auto-run dend first (recommended)"
        say "   [2] 직접 정리" "   [2] Handle manually"
        say "   [3] 이전 작업 버리기 ⚠️" "   [3] Discard previous work ⚠️"
        say "   [Enter] 취소" "   [Enter] Cancel"
        echo ""
        if [ "$NOTE_LANG" = "ko" ]; then
            read -p "선택: " choice
        else
            read -p "Choice: " choice
        fi

        case "$choice" in
            1)
                echo ""
                sayf "🔄 %s 작업을 먼저 정리합니다..." \
                     "🔄 Wrapping up %s first..." "$OLD_DATE"
                echo ""

                DEND_SCRIPT="$SCRIPT_DIR/dend.sh"
                if [ ! -f "$DEND_SCRIPT" ]; then
                    sayf "❌ dend.sh를 찾을 수 없어요: %s" \
                         "❌ dend.sh not found: %s" "$DEND_SCRIPT"
                    exit 1
                fi

                RETROACTIVE_DATE="$OLD_DATE" "$DEND_SCRIPT"
                DEND_EXIT=$?

                if [ $DEND_EXIT -ne 0 ]; then
                    echo ""
                    say "❌ dend 실행 중 문제." "❌ dend failed."
                    exit 1
                fi

                echo ""
                sayf "✅ %s 정리 완료. 오늘 작업을 시작합니다." \
                     "✅ %s wrapped up. Starting today's work." "$OLD_DATE"
                echo ""
                ;;
            2)
                echo ""
                say "💡 dend → dstart 순서로 진행하세요." \
                    "💡 Run dend first, then dstart."
                exit 0
                ;;
            3)
                if [ "$NOTE_LANG" = "ko" ]; then
                    read -p "정말로 이전 작업을 버릴까요? 'yes' 입력: " confirm
                else
                    read -p "Really discard previous work? Type 'yes': " confirm
                fi
                [ "$confirm" != "yes" ] && exit 0
                echo ""
                say "🗑  이전 작업 무시하고 새로 시작합니다..." \
                    "🗑  Ignoring previous work, starting fresh..."
                ;;
            *) exit 0 ;;
        esac
    else
        say "ℹ️  이전 스냅샷 있지만 변경 없음. 새로 시작합니다." \
            "ℹ️  Previous snapshot found but no changes. Starting fresh."
        echo ""
    fi
fi

# --- 데일리 노트 처리 ---
if [ ! -d "$DAILY_DIR" ]; then
    sayf "❌ Daily 폴더가 없어요: %s" \
         "❌ Daily folder missing: %s" "$DAILY_DIR"
    say "   ~/.daily-noterc 설정을 확인해주세요." \
        "   Check ~/.daily-noterc."
    exit 1
fi

if [ ! -f "$TODAY_FILE" ]; then
    YESTERDAY_FILE=$(ls "$DAILY_DIR"/*.md 2>/dev/null | grep -v "$TODAY.md" | sort | tail -1)
    TOMORROW_TODOS=""

    if [ -n "$YESTERDAY_FILE" ] && [ -f "$YESTERDAY_FILE" ]; then
        sayf "📖 직전 노트: %s" "📖 Previous note: %s" "$(basename "$YESTERDAY_FILE" .md)"
        TOMORROW_TODOS=$(awk '
            /^## 📅 내일 할 일|^## 📅 Tomorrow/{flag=1; next}
            /^## /{flag=0}
            flag && /^- /{print}
        ' "$YESTERDAY_FILE")

        if [ -n "$TOMORROW_TODOS" ]; then
            TODO_COUNT=$(echo "$TOMORROW_TODOS" | grep -c '^- ')
            sayf "📋 이월할 할 일: %s개" \
                 "📋 Tasks carried over: %s" "$TODO_COUNT"
        fi
    fi

    WEEKDAY=$(date '+%A')

    if [ "$NOTE_LANG" = "ko" ]; then
        cat > "$TODAY_FILE" << EOF
---
date: $TODAY
type: daily
tags: [daily]
---

# $TODAY $WEEKDAY

## 🎯 오늘 할 일
$TOMORROW_TODOS

## 📝 작업 로그
*(프로젝트별로 dend 실행 시 자동 추가됩니다)*

## 🚧 막힌 것 / 이슈
-

## 💡 배운 것
-

## 🔗 관련 노트
-

## 📅 내일 할 일
- [ ]
EOF

        if [ -z "$TOMORROW_TODOS" ]; then
            perl -i -pe 's|## 🎯 오늘 할 일\n\n## |## 🎯 오늘 할 일\n- [ ] \n\n## |g' "$TODAY_FILE"
        fi
    else
        cat > "$TODAY_FILE" << EOF
---
date: $TODAY
type: daily
tags: [daily]
---

# $TODAY $WEEKDAY

## 🎯 Today
$TOMORROW_TODOS

## 📝 Work Log
*(auto-filled per project when dend runs)*

## 🚧 Blocked / Issues
-

## 💡 Learned
-

## 🔗 Related Notes
-

## 📅 Tomorrow
- [ ]
EOF

        if [ -z "$TOMORROW_TODOS" ]; then
            perl -i -pe 's|## 🎯 Today\n\n## |## 🎯 Today\n- [ ] \n\n## |g' "$TODAY_FILE"
        fi
    fi

    sayf "✅ 데일리 노트 생성: %s.md" "✅ Daily note created: %s.md" "$TODAY"
else
    say "📝 데일리 노트 이미 존재" "📝 Daily note already exists"
fi

echo ""
save_snapshot

echo ""
say "☕ 좋은 작업 되세요!" "☕ Happy hacking!"
