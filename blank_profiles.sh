#!/bin/bash

# chmod +x blank_profiles.sh
# ./blank_profiles.sh path/to/profiles/

github_repo_path="${1:-/profiles}"

if [ ! -d "$github_repo_path" ]; then
  echo "❌ ❌ ❌ ❌ ❌ ❌ Folder '$github_repo_path' not found.❌ ❌ ❌ ❌ ❌ "
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
git pull origin "$current_branch"

total_files=$(find "$github_repo_path" -maxdepth 1 -type f -name "*.profile" | wc -l | tr -d ' ')
count_modified=0
count_skipped=0

echo "🔍 Total .profile files in '$github_repo_path': $total_files"

# Define the desired blank content
blank_content='<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
</Profile>'

for file in "$github_repo_path"/*.profile; do
  if [ -f "$file" ]; then
    existing_content=$(<"$file")
    if [[ "$existing_content" != "$blank_content" ]]; then
      echo "$blank_content" > "$file"
      ((count_modified++))
    else
      ((count_skipped++))
    fi
  fi
done

echo "✅ ✅ ✅ ✅ ✅ Blanked $count_modified profile files. Skipped (already blank): $count_skipped ✅ ✅ ✅ ✅ ✅ "

read -p "🚀 🚀 🚀 🚀 🚀 Push $count_modified modified files to '$current_branch'❓❓❓❓❓ (y/n): " confirm 
if [ "$confirm" != "y" ]; then
  echo "❌ ❌ ❌ ❌ ❌ Aborted. No changes were pushed.❌ ❌ ❌ ❌ ❌ "
  exit 0
fi

git add "$github_repo_path"
commit_message="🔒 Profile files blanked and XML tags added on $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$commit_message"
git push origin "$current_branch"

echo "🎉 Done. Total: $total_files, Blanked: $count_modified, Skipped: $count_skipped. Changes pushed to '$current_branch'."
# Optional: Discard local changes to this script after push
script_name=$(basename "$0")

if git ls-files --error-unmatch "$script_name" > /dev/null 2>&1; then
  echo "🧹 Resetting '$script_name' to committed version to avoid Git tracking local edits."
  git checkout -- "$script_name"
fi
