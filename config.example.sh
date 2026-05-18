# Daily Note Automation config
# This file lives at ~/.daily-noterc
# install.sh creates it automatically, but you can also edit it by hand.

# Note language for daily-note templates and the dend prompt.
#   ko = 한국어
#   en = English
NOTE_LANG="ko"

# Folder under which daily/changes notes are stored.
#
# This can be either:
#   - The Obsidian vault root, e.g.
#       "/Users/you/Documents/Obsidian/MyVault"
#   - A sub-folder inside the vault, if you want to keep work notes
#     organized under a specific area, e.g.
#       "/Users/you/Documents/Obsidian/MyVault/Work"
#
# The DAILY_DIR_NAME and CHANGES_DIR_NAME folders below will be created
# under this path (not under the vault root).
VAULT=""

# Daily-notes folder name (relative to VAULT)
# e.g. "01_Daily" or "Daily Notes"
DAILY_DIR_NAME="01_Daily"

# Code-changes folder name (relative to VAULT)
CHANGES_DIR_NAME="05_CodeChanges"

# (Optional) custom daily-note template path. Leave empty for the built-in.
# e.g. "_Templates/daily.md"
TEMPLATE_DAILY=""

# Derived (do not edit)
DAILY_DIR="$VAULT/$DAILY_DIR_NAME"
CHANGES_DIR="$VAULT/$CHANGES_DIR_NAME"

# Where snapshots and the token-usage log are stored
SCRIPT_DIR="$HOME/.daily-note-automation"

# Max diff length sent to Claude Code (context-window guard)
MAX_DIFF_LEN=40000
