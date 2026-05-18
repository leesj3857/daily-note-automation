# Daily Note Automation 설정
# 이 파일은 ~/.daily-noterc 에 위치합니다.
# install.sh가 자동으로 생성하지만, 직접 편집해도 됩니다.

# Obsidian vault의 절대 경로
# 예: "/Users/yourname/Documents/Obsidian Vault/MyVault"
VAULT=""

# 데일리 노트 폴더 이름 (vault 안의 상대 경로)
# 예: "01_Daily" 또는 "Daily Notes"
DAILY_DIR_NAME="01_Daily"

# 코드 변경 노트 폴더 이름
CHANGES_DIR_NAME="05_CodeChanges"

# (선택) 데일리 노트 템플릿 경로 - 비워두면 기본 양식 사용
# 예: "_Templates/daily.md"
TEMPLATE_DAILY=""

# 자동 계산되는 경로 (수정하지 마세요)
DAILY_DIR="$VAULT/$DAILY_DIR_NAME"
CHANGES_DIR="$VAULT/$CHANGES_DIR_NAME"

# 스크립트 디렉토리 (스냅샷, 로그 저장 위치)
SCRIPT_DIR="$HOME/.daily-note-automation"

# diff 최대 길이 (Claude Code 컨텍스트 제한)
MAX_DIFF_LEN=40000
