#!/bin/bash

# 페이저 비활성화 (탭 닫기 경고 방지)
export GIT_PAGER=cat
export PAGER=cat

# ============================================================
# dstart.sh - 프로젝트 시작
# https://github.com/leesj3857/daily-note-automation
# ============================================================

# --- 설정 파일 로드 ---
CONFIG_FILE="$HOME/.daily-noterc"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 설정 파일이 없어요: $CONFIG_FILE"
    echo "   install.sh를 먼저 실행해주세요."
    exit 1
fi
source "$CONFIG_FILE"

TODAY=$(date +%Y-%m-%d)
TODAY_FILE="$DAILY_DIR/$TODAY.md"

if [ ! -d ".git" ]; then
    echo "❌ 현재 폴더는 git 저장소가 아니에요."
    echo "   프로젝트 루트 폴더에서 실행해주세요."
    exit 1
fi

PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
SNAPSHOT_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME"
SNAPSHOT_DIFF_FILE="$SCRIPT_DIR/.snapshot-$PROJECT_NAME.diff"

mkdir -p "$SCRIPT_DIR"

echo "🚀 프로젝트 시작 요청: $PROJECT_NAME"
echo "   경로: $PROJECT_PATH"
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
        echo "❌ 기준 커밋을 찾을 수 없어요."
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
    
    echo "📸 git 스냅샷 저장 (오늘 이전 기준):"
    echo "   브랜치: $branch"
    echo "   기준 커밋: ${commit:0:7}"
    echo "   커밋 시각: $commit_date"
    echo "   커밋 메시지: $commit_msg"
    
    local upcoming_commits=$(git log --oneline "$commit..HEAD" 2>/dev/null | wc -l | xargs)
    local uncommit_count=$(git status --short 2>/dev/null | wc -l | xargs)
    
    if [ "$upcoming_commits" -gt 0 ]; then
        echo "   📌 이 기준 이후 이미 커밋된 변경: ${upcoming_commits}건"
    fi
    if [ "$uncommit_count" -gt 0 ]; then
        echo "   📌 현재 언커밋: ${uncommit_count}개 파일"
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
        echo "⚠️  오늘 이미 dstart를 실행했어요!"
        echo "   - 마지막 실행: $OLD_HOUR"
        echo "   - 기준 커밋:   $OLD_BRANCH @ ${OLD_COMMIT:0:7}"
        echo "   - 그 시점 이후 커밋: ${CHANGES_SINCE}건"
        if [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
            echo "   - 언커밋 변경: 있음"
        fi
        echo ""
        echo "🤔 어떻게 할까요?"
        echo "   [1] 기존 스냅샷 유지 (권장)"
        echo "   [2] dend 먼저 실행 안내"
        echo "   [3] 강제로 새 스냅샷 ⚠️"
        echo "   [Enter] 취소"
        echo ""
        read -p "선택: " choice
        
        case "$choice" in
            1) echo "✅ 기존 스냅샷 유지"; exit 0 ;;
            2) echo "💡 dend → dstart 순서로 진행하세요."; exit 0 ;;
            3) 
                read -p "정말로 새로 시작할까요? 'yes' 입력: " confirm
                [ "$confirm" != "yes" ] && exit 0
                ;;
            *) exit 0 ;;
        esac
    
    elif [ "$CHANGES_SINCE" -gt 0 ] || [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
        echo "⚠️  $OLD_DATE 작업이 정리되지 않았어요!"
        echo "   - 마지막 dstart: $OLD_DATE $OLD_HOUR"
        echo "   - 정리 안 된 커밋: ${CHANGES_SINCE}건"
        if [ "$UNCOMMIT_CHANGED" -eq 1 ]; then
            echo "   - 언커밋 변경: 있음"
        fi
        echo ""
        echo "💡 그날 dend를 깜빡하신 것 같아요."
        echo ""
        echo "🤔 어떻게 할까요?"
        echo "   [1] dend를 먼저 자동 실행 (권장)"
        echo "   [2] 직접 정리"
        echo "   [3] 이전 작업 버리기 ⚠️"
        echo "   [Enter] 취소"
        echo ""
        read -p "선택: " choice
        
        case "$choice" in
            1)
                echo ""
                echo "🔄 $OLD_DATE 작업을 먼저 정리합니다..."
                echo ""
                
                DEND_SCRIPT="$SCRIPT_DIR/dend.sh"
                if [ ! -f "$DEND_SCRIPT" ]; then
                    echo "❌ dend.sh를 찾을 수 없어요: $DEND_SCRIPT"
                    exit 1
                fi
                
                RETROACTIVE_DATE="$OLD_DATE" "$DEND_SCRIPT"
                DEND_EXIT=$?
                
                if [ $DEND_EXIT -ne 0 ]; then
                    echo ""
                    echo "❌ dend 실행 중 문제."
                    exit 1
                fi
                
                echo ""
                echo "✅ $OLD_DATE 정리 완료. 오늘 작업을 시작합니다."
                echo ""
                ;;
            2)
                echo ""
                echo "💡 dend → dstart 순서로 진행하세요."
                exit 0
                ;;
            3)
                read -p "정말로 이전 작업을 버릴까요? 'yes' 입력: " confirm
                [ "$confirm" != "yes" ] && exit 0
                echo ""
                echo "🗑  이전 작업 무시하고 새로 시작합니다..."
                ;;
            *) exit 0 ;;
        esac
    else
        echo "ℹ️  이전 스냅샷 있지만 변경 없음. 새로 시작합니다."
        echo ""
    fi
fi

# --- 데일리 노트 처리 ---
if [ ! -d "$DAILY_DIR" ]; then
    echo "❌ Daily 폴더가 없어요: $DAILY_DIR"
    echo "   ~/.daily-noterc 설정을 확인해주세요."
    exit 1
fi

if [ ! -f "$TODAY_FILE" ]; then
    YESTERDAY_FILE=$(ls "$DAILY_DIR"/*.md 2>/dev/null | grep -v "$TODAY.md" | sort | tail -1)
    TOMORROW_TODOS=""
    
    if [ -n "$YESTERDAY_FILE" ] && [ -f "$YESTERDAY_FILE" ]; then
        echo "📖 직전 노트: $(basename "$YESTERDAY_FILE" .md)"
        TOMORROW_TODOS=$(awk '
            /^## 📅 내일 할 일|^## 📅 Tomorrow/{flag=1; next}
            /^## /{flag=0}
            flag && /^- /{print}
        ' "$YESTERDAY_FILE")
        
        if [ -n "$TOMORROW_TODOS" ]; then
            TODO_COUNT=$(echo "$TOMORROW_TODOS" | grep -c '^- ')
            echo "📋 이월할 할 일: ${TODO_COUNT}개"
        fi
    fi
    
    WEEKDAY=$(date '+%A')
    
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
    
    echo "✅ 데일리 노트 생성: $TODAY.md"
else
    echo "📝 데일리 노트 이미 존재"
fi

echo ""
save_snapshot

echo ""
echo "☕ 좋은 작업 되세요!"
