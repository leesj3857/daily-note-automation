#!/bin/bash
# ============================================================
# install.sh - Daily Note Automation 설치
# ============================================================

set -e

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="$HOME/.daily-note-automation"
CONFIG_FILE="$HOME/.daily-noterc"

echo "🚀 Daily Note Automation 설치"
echo "================================"
echo ""

# --- 1. 의존성 확인 ---
echo "🔍 의존성 확인 중..."

# git 확인
if ! command -v git &> /dev/null; then
    echo "❌ git이 설치되지 않았습니다."
    echo "   먼저 git을 설치해주세요: https://git-scm.com/"
    exit 1
fi
echo "   ✅ git"

# claude code 확인
if ! command -v claude &> /dev/null; then
    echo "❌ Claude Code가 설치되지 않았습니다."
    echo "   설치: npm install -g @anthropic-ai/claude-code"
    echo "   또는: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi
echo "   ✅ claude code"

# jq 확인 (선택)
if command -v jq &> /dev/null; then
    echo "   ✅ jq (토큰 파싱 정확도 향상)"
else
    echo "   ⚠️  jq 없음 (작동은 하지만 설치 권장: brew install jq)"
fi
echo ""

# --- 2. 설정 파일 생성 ---
if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  기존 설정 파일이 있습니다: $CONFIG_FILE"
    read -p "   덮어쓸까요? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "   기존 설정 유지"
        echo ""
    else
        rm "$CONFIG_FILE"
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 설정 파일 생성"
    echo ""
    
    # Vault 경로 입력
    while true; do
        read -p "Obsidian vault의 절대 경로를 입력하세요: " vault_path
        # ~ 확장
        vault_path="${vault_path/#\~/$HOME}"
        
        if [ -z "$vault_path" ]; then
            echo "   ❌ 경로를 입력해주세요."
            continue
        fi
        
        if [ ! -d "$vault_path" ]; then
            echo "   ⚠️  폴더가 존재하지 않습니다: $vault_path"
            read -p "   그래도 사용할까요? (y/N): " use_anyway
            if [[ ! "$use_anyway" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        break
    done
    
    # 데일리 폴더명
    read -p "데일리 노트 폴더 이름 [01_Daily]: " daily_dir
    daily_dir="${daily_dir:-01_Daily}"
    
    # 코드 변경 폴더명
    read -p "코드 변경 노트 폴더 이름 [05_CodeChanges]: " changes_dir
    changes_dir="${changes_dir:-05_CodeChanges}"
    
    # 설정 파일 작성
    cat > "$CONFIG_FILE" << EOF
# Daily Note Automation 설정
# 자동 생성됨: $(date '+%Y-%m-%d %H:%M:%S')

VAULT="$vault_path"
DAILY_DIR_NAME="$daily_dir"
CHANGES_DIR_NAME="$changes_dir"
TEMPLATE_DAILY=""

# 자동 계산
DAILY_DIR="\$VAULT/\$DAILY_DIR_NAME"
CHANGES_DIR="\$VAULT/\$CHANGES_DIR_NAME"
SCRIPT_DIR="\$HOME/.daily-note-automation"
MAX_DIFF_LEN=40000
EOF
    
    echo "   ✅ 설정 파일 생성: $CONFIG_FILE"
    echo ""
fi

# --- 3. 스크립트 복사 ---
echo "📦 스크립트 설치 중..."
mkdir -p "$INSTALL_DIR"

cp "$REPO_DIR/scripts/dstart.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/scripts/dend.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/scripts/dusage.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/dstart.sh"
chmod +x "$INSTALL_DIR/dend.sh"
chmod +x "$INSTALL_DIR/dusage.sh"

echo "   ✅ 스크립트 복사 완료: $INSTALL_DIR"
echo ""

# --- 4. Alias 등록 ---
echo "🔗 alias 등록 중..."

# 쉘 감지
case "$SHELL" in
    */zsh)  RC_FILE="$HOME/.zshrc" ;;
    */bash) RC_FILE="$HOME/.bash_profile" ;;
    *)      RC_FILE="$HOME/.profile" ;;
esac

ALIASES=(
    "alias dstart=\"$INSTALL_DIR/dstart.sh\""
    "alias dend=\"$INSTALL_DIR/dend.sh\""
    "alias dusage=\"$INSTALL_DIR/dusage.sh\""
)

# 마커로 기존 alias 블록 찾기/추가
MARKER_START="# >>> daily-note-automation >>>"
MARKER_END="# <<< daily-note-automation <<<"

if grep -q "$MARKER_START" "$RC_FILE" 2>/dev/null; then
    echo "   기존 alias 블록 발견 — 갱신합니다."
    # 기존 블록 삭제
    sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$RC_FILE"
fi

# 새 블록 추가
{
    echo ""
    echo "$MARKER_START"
    for alias_line in "${ALIASES[@]}"; do
        echo "$alias_line"
    done
    echo "$MARKER_END"
} >> "$RC_FILE"

echo "   ✅ alias 등록 완료: $RC_FILE"
echo ""

# --- 5. 완료 ---
echo "================================"
echo "✅ 설치 완료!"
echo "================================"
echo ""
echo "📌 다음 단계:"
echo ""
echo "1. 새 터미널을 열거나 다음을 실행하세요:"
echo "   source $RC_FILE"
echo ""
echo "2. 프로젝트 폴더로 이동 후 사용:"
echo "   cd /path/to/your/project"
echo "   dstart    # 작업 시작"
echo "   # ... 코딩 ..."
echo "   dend      # 작업 정리"
echo ""
echo "3. 사용량 통계:"
echo "   dusage"
echo ""
echo "📖 더 자세한 사용법은 README.md를 참고하세요."
