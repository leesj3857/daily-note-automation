#!/bin/bash
# ============================================================
# dusage.sh - dend 토큰 사용량 통계
# https://github.com/yourname/daily-note-automation
# ============================================================

CONFIG_FILE="$HOME/.daily-noterc"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 설정 파일이 없어요: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

USAGE_LOG="$SCRIPT_DIR/.token-usage.log"

if [ ! -f "$USAGE_LOG" ]; then
    echo "📭 토큰 사용 기록이 아직 없어요."
    echo "   (dend를 실행하면 로그가 쌓이기 시작합니다)"
    exit 0
fi

MODE="${1:-summary}"

format_num() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

format_cost() {
    printf "%.4f" "$1" 2>/dev/null || echo "$1"
}

analyze_lines() {
    awk -F'|' '
    BEGIN { count=0; input=0; cache_r=0; cache_c=0; output=0; total=0; cost=0; }
    {
        count++; input+=$4; cache_r+=$5; cache_c+=$6;
        output+=$7; total+=$8; cost+=$9;
    }
    END {
        printf "%d|%d|%d|%d|%d|%d|%.4f\n", count, input, cache_r, cache_c, output, total, cost;
    }'
}

case "$MODE" in
    today)
        TODAY=$(date +%Y-%m-%d)
        LINES=$(grep "^$TODAY " "$USAGE_LOG" 2>/dev/null)
        TITLE="📅 오늘 ($TODAY)"
        ;;
    week)
        SEVEN_DAYS_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null)
        LINES=$(awk -F'|' -v cutoff="$SEVEN_DAYS_AGO" '{ split($1, d, " "); if (d[1] >= cutoff) print }' "$USAGE_LOG")
        TITLE="📅 최근 7일 ($SEVEN_DAYS_AGO ~ 오늘)"
        ;;
    month)
        THIRTY_DAYS_AGO=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d 2>/dev/null)
        LINES=$(awk -F'|' -v cutoff="$THIRTY_DAYS_AGO" '{ split($1, d, " "); if (d[1] >= cutoff) print }' "$USAGE_LOG")
        TITLE="📅 최근 30일 ($THIRTY_DAYS_AGO ~ 오늘)"
        ;;
    all)
        LINES=$(cat "$USAGE_LOG")
        TITLE="📅 전체 기록"
        ;;
    projects)
        echo "📦 프로젝트별 토큰 사용량"
        echo "================================================"
        awk -F'|' '{
            proj_count[$2]++; proj_total[$2]+=$8; proj_cost[$2]+=$9;
        }
        END {
            for (p in proj_count) {
                printf "%-25s %3d회  %10d 토큰  $%.4f\n", p, proj_count[p], proj_total[p], proj_cost[p];
            }
        }' "$USAGE_LOG" | sort -k 4 -n -r
        echo "================================================"
        exit 0
        ;;
    summary|*)
        TODAY=$(date +%Y-%m-%d)
        TODAY_LINES=$(grep "^$TODAY " "$USAGE_LOG" 2>/dev/null)
        ALL_LINES=$(cat "$USAGE_LOG")
        
        echo "📊 Claude Code 토큰 사용량 요약"
        echo "================================================"
        echo ""
        
        if [ -n "$TODAY_LINES" ]; then
            STATS=$(echo "$TODAY_LINES" | analyze_lines)
            IFS='|' read -r count input cache_r cache_c output total cost <<< "$STATS"
            echo "📅 오늘 ($TODAY)"
            echo "   실행 횟수: $count회"
            echo "   총 토큰:   $(format_num $total)"
            echo "   비용:      \$$(format_cost $cost)"
            echo ""
        else
            echo "📅 오늘 ($TODAY): 사용 기록 없음"
            echo ""
        fi
        
        STATS=$(echo "$ALL_LINES" | analyze_lines)
        IFS='|' read -r count input cache_r cache_c output total cost <<< "$STATS"
        FIRST_DATE=$(head -1 "$USAGE_LOG" | cut -d'|' -f1 | cut -d' ' -f1)
        echo "📊 전체 ($FIRST_DATE ~ 오늘)"
        echo "   실행 횟수: $count회"
        echo "   총 토큰:   $(format_num $total)"
        echo "   비용:      \$$(format_cost $cost)"
        echo ""
        echo "💡 자세히:"
        echo "   dusage today    # 오늘 상세"
        echo "   dusage week     # 최근 7일"
        echo "   dusage month    # 최근 30일"
        echo "   dusage projects # 프로젝트별"
        echo "   dusage all      # 전체 상세"
        exit 0
        ;;
esac

if [ -z "$LINES" ]; then
    echo "$TITLE"
    echo "📭 해당 기간 기록 없음."
    exit 0
fi

echo "$TITLE"
echo "================================================"
echo ""

echo "📝 실행 기록 (최근 → 오래된 순)"
echo "------------------------------------------------"
echo "$LINES" | tac | awk -F'|' '{
    retroactive = ($3 == "1") ? "🔙" : "  ";
    printf "%s %s  %s\n", retroactive, $1, $2;
    printf "     토큰 %s  비용 $%.4f  %s초\n\n", $8, $9, $10;
}'

STATS=$(echo "$LINES" | analyze_lines)
IFS='|' read -r count input cache_r cache_c output total cost <<< "$STATS"

echo "📊 요약"
echo "------------------------------------------------"
echo "   실행 횟수:     $count회"
echo "   입력 토큰:     $(format_num $input)"
[ "$cache_r" != "0" ] && echo "   캐시 읽기:     $(format_num $cache_r)"
[ "$cache_c" != "0" ] && echo "   캐시 생성:     $(format_num $cache_c)"
echo "   출력 토큰:     $(format_num $output)"
echo "   ───────────────"
echo "   총 토큰:       $(format_num $total)"
echo "   총 비용:       \$$(format_cost $cost)"
echo ""

if [ "$count" -gt 0 ]; then
    AVG_TOKENS=$((total / count))
    AVG_COST=$(awk -v c="$cost" -v n="$count" 'BEGIN { printf "%.4f", c/n }')
    echo "   평균 / 1회:    $(format_num $AVG_TOKENS) 토큰 / \$${AVG_COST}"
fi
