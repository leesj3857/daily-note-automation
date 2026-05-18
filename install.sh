#!/bin/bash
# ============================================================
# install.sh - Daily Note Automation installer
# ============================================================

set -e

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="$HOME/.daily-note-automation"
CONFIG_FILE="$HOME/.daily-noterc"

# ------------------------------------------------------------
# 0. Pre-language messages (English only)
# ------------------------------------------------------------
echo "Daily Note Automation installer"
echo "==============================="
echo ""

# --- Dependency check ---
echo "Checking dependencies..."

if ! command -v git &> /dev/null; then
    echo "ERROR: git is not installed."
    echo "  Install git first: https://git-scm.com/"
    exit 1
fi
echo "  ok  git"

if ! command -v claude &> /dev/null; then
    echo "ERROR: Claude Code is not installed."
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    echo "  Docs:    https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi
echo "  ok  claude code"

if command -v jq &> /dev/null; then
    echo "  ok  jq (improves token-usage parsing)"
else
    echo "  --  jq missing (optional; recommended: brew install jq)"
fi
echo ""

# ------------------------------------------------------------
# 1. Existing config check + language selection (English)
# ------------------------------------------------------------
note_lang=""

if [ -f "$CONFIG_FILE" ]; then
    echo "Existing config found: $CONFIG_FILE"
    read -p "  Overwrite? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        # Keep existing config; load NOTE_LANG from it (default ko)
        existing_lang=$(grep -E '^NOTE_LANG=' "$CONFIG_FILE" 2>/dev/null \
            | head -1 \
            | sed -E 's/^NOTE_LANG="?([^"]*)"?$/\1/')
        note_lang="${existing_lang:-ko}"
        KEEP_EXISTING=1
    else
        rm "$CONFIG_FILE"
        KEEP_EXISTING=0
    fi
fi

# Language picker (bilingual labels, English instructions)
if [ -z "$note_lang" ]; then
    echo ""
    echo "Note language / 노트 언어"
    echo "  [1] 한국어 (Korean)"
    echo "  [2] English"
    while true; do
        read -p "  Choose [1]: " lang_choice
        lang_choice="${lang_choice:-1}"
        case "$lang_choice" in
            1) note_lang="ko"; break ;;
            2) note_lang="en"; break ;;
            *) echo "  ! Enter 1 or 2." ;;
        esac
    done
    echo "  -> ${note_lang}"
fi

# ------------------------------------------------------------
# Localization helper — from here on, all output uses note_lang
# ------------------------------------------------------------
say() {
    if [ "$note_lang" = "ko" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}
ask() {
    local var="$1" ko_prompt="$2" en_prompt="$3" default="${4:-}"
    if [ "$note_lang" = "ko" ]; then
        read -p "$ko_prompt" "$var"
    else
        read -p "$en_prompt" "$var"
    fi
}

# ------------------------------------------------------------
# 2. Config creation (in chosen language)
# ------------------------------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    say "📝 설정 파일을 만들게요" "📝 Creating config file"
    echo ""

    # --- Vault / notes-root path ---
    say "📂 노트가 저장될 폴더" "📂 Folder where notes will live"
    say "   - Obsidian vault 루트 경로를 그대로 쓰거나" \
        "   - Use the Obsidian vault root, or"
    say "     예: ~/Documents/Obsidian/MyVault" \
        "     e.g. ~/Documents/Obsidian/MyVault"
    say "   - vault 안의 특정 하위 폴더 경로도 가능합니다." \
        "   - point to a sub-folder inside the vault."
    say "     예: ~/Documents/Obsidian/MyVault/Work" \
        "     e.g. ~/Documents/Obsidian/MyVault/Work"
    say "   이 경로 아래에 데일리/코드변경 폴더가 생성됩니다." \
        "   The daily/code-changes folders will be created under this path."
    echo ""

    while true; do
        ask vault_path "절대 경로: " "Absolute path: "
        # trim whitespace
        vault_path="${vault_path#"${vault_path%%[![:space:]]*}"}"
        vault_path="${vault_path%"${vault_path##*[![:space:]]}"}"
        # strip wrapping quotes
        if [[ "$vault_path" =~ ^\'(.*)\'$ ]] || [[ "$vault_path" =~ ^\"(.*)\"$ ]]; then
            vault_path="${BASH_REMATCH[1]}"
        fi
        # expand ~
        vault_path="${vault_path/#\~/$HOME}"

        if [ -z "$vault_path" ]; then
            say "   ❌ 경로를 입력해주세요." "   ! Please enter a path."
            continue
        fi

        if [ ! -d "$vault_path" ]; then
            say "   ⚠️  폴더가 존재하지 않습니다: $vault_path" \
                "   ! Folder does not exist: $vault_path"
            ask use_anyway "   그래도 사용할까요? (y/N): " \
                           "   Use it anyway? (y/N): "
            if [[ ! "$use_anyway" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        break
    done

    # --- Daily folder name ---
    ask daily_dir "데일리 노트 폴더 이름 [01_Daily]: " \
                  "Daily-notes folder name [01_Daily]: "
    daily_dir="${daily_dir:-01_Daily}"

    # --- Code-changes folder name ---
    ask changes_dir "코드 변경 노트 폴더 이름 [05_CodeChanges]: " \
                    "Code-changes folder name [05_CodeChanges]: "
    changes_dir="${changes_dir:-05_CodeChanges}"

    # --- Write config ---
    cat > "$CONFIG_FILE" << EOF
# Daily Note Automation config
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

# Note language: ko | en
NOTE_LANG="$note_lang"

# Folder under which daily/changes notes are stored.
# Can be the Obsidian vault root, or any sub-folder inside it.
VAULT="$vault_path"

DAILY_DIR_NAME="$daily_dir"
CHANGES_DIR_NAME="$changes_dir"
TEMPLATE_DAILY=""

# Derived (do not edit)
DAILY_DIR="\$VAULT/\$DAILY_DIR_NAME"
CHANGES_DIR="\$VAULT/\$CHANGES_DIR_NAME"
SCRIPT_DIR="\$HOME/.daily-note-automation"
MAX_DIFF_LEN=40000
EOF

    say "   ✅ 설정 파일 생성: $CONFIG_FILE" \
        "   ok  Config created: $CONFIG_FILE"
    echo ""
else
    say "   ℹ️  기존 설정을 그대로 사용합니다." \
        "   -- Keeping existing config."
    echo ""
fi

# ------------------------------------------------------------
# 3. Copy scripts
# ------------------------------------------------------------
say "📦 스크립트 설치 중..." "📦 Installing scripts..."
mkdir -p "$INSTALL_DIR"

cp "$REPO_DIR/scripts/dstart.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/scripts/dend.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/scripts/dusage.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/dstart.sh"
chmod +x "$INSTALL_DIR/dend.sh"
chmod +x "$INSTALL_DIR/dusage.sh"

say "   ✅ 스크립트 복사 완료: $INSTALL_DIR" \
    "   ok  Scripts copied to: $INSTALL_DIR"
echo ""

# ------------------------------------------------------------
# 4. Shell alias registration
# ------------------------------------------------------------
say "🔗 alias 등록 중..." "🔗 Registering shell aliases..."

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

MARKER_START="# >>> daily-note-automation >>>"
MARKER_END="# <<< daily-note-automation <<<"

if grep -q "$MARKER_START" "$RC_FILE" 2>/dev/null; then
    say "   기존 alias 블록 발견 — 갱신합니다." \
        "   Existing alias block found — refreshing."
    sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$RC_FILE"
fi

{
    echo ""
    echo "$MARKER_START"
    for alias_line in "${ALIASES[@]}"; do
        echo "$alias_line"
    done
    echo "$MARKER_END"
} >> "$RC_FILE"

say "   ✅ alias 등록 완료: $RC_FILE" \
    "   ok  Aliases registered in: $RC_FILE"
echo ""

# ------------------------------------------------------------
# 5. Done
# ------------------------------------------------------------
echo "================================"
say "✅ 설치 완료!" "✅ Installation complete!"
echo "================================"
echo ""
say "📌 다음 단계:" "📌 Next steps:"
echo ""
say "1. 새 터미널을 열거나 다음을 실행하세요:" \
    "1. Open a new terminal, or run:"
echo "   source $RC_FILE"
echo ""
say "2. 프로젝트 폴더로 이동 후 사용:" \
    "2. Go to your project folder and use:"
echo "   cd /path/to/your/project"
if [ "$note_lang" = "ko" ]; then
    echo "   dstart    # 작업 시작"
    echo "   # ... 코딩 ..."
    echo "   dend      # 작업 정리"
else
    echo "   dstart    # start work"
    echo "   # ... code ..."
    echo "   dend      # wrap up"
fi
echo ""
say "3. 사용량 통계:" "3. Token usage stats:"
echo "   dusage"
echo ""
say "📖 더 자세한 사용법은 README.md를 참고하세요." \
    "📖 See README.en.md for full usage."
