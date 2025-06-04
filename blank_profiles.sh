#!/bin/bash

# Usage: chmod +x blank_profiles.sh
#        ./blank_profiles.sh profiles/

github_repo_path="${1:-/profiles}"

if [ ! -d "$github_repo_path" ]; then
  echo "❌ Folder '$github_repo_path' not found."
  exit 1
fi

# Ensure xmllint is available
if ! command -v xmllint &>/dev/null; then
  echo "❌ xmllint not found. Please install libxml2-utils (Ubuntu) or libxml2 (Mac)."
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
git pull origin "$current_branch"

total_files=$(find "$github_repo_path" -maxdepth 1 -type f -name "*.profile" | wc -l | tr -d ' ')
count_modified=0
count_skipped=0

echo "🔍 Total .profile files in '$github_repo_path': $total_files"

for file in "$github_repo_path"/*.profile; do
  if [ -f "$file" ]; then
    # Extract only <userPermissions> using namespace-aware XPath
    user_permissions=$(xmllint --xpath 'declare namespace sf="http://soap.sforce.com/2006/04/metadata"; //sf:userPermissions' "$file" 2>/dev/null)

    # Fallback if none found
    if [ -z "$user_permissions" ]; then
      user_permissions=""
    fi

    # Construct new XML content
    new_content='<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
'"$user_permissions"'
</Profile>'

    echo "$new_content" > "$file"
    echo "✏️ Rewritten (userPermissions preserved): $file"
    ((count_modified++))
  else
    ((count_skipped++))
  fi
done

echo "✅ Modified: $count_modified, Skipped: $count_skipped"

read -p "🚀 Push $count_modified modified files to '$current_branch'? (y/n): " confirm 
if [ "$confirm" != "y" ]; then
  echo "❌ Aborted. No changes were pushed."
  exit 0
fi

git add "$github_repo_path"
commit_message="🔒 Profiles blanked except userPermissions on $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$commit_message"
git push origin "$current_branch"

echo "🎉 Done. Pushed to '$current_branch'."

# Reset script itself if tracked
script_name=$(basename "$0")
if git ls-files --error-unmatch "$script_name" > /dev/null 2>&1; then
  echo "🧹 Resetting '$script_name' to committed version."
  git checkout -- "$script_name"
fi
