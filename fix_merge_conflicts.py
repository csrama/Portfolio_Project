#!/usr/bin/env python3
"""
Fix remaining Git merge conflict markers in home_screen.dart.
Keeps the "stashed changes" version (after =======, before >>>>>>> Stashed changes).
"""

import re

filepath = r'c:/Users/janab/Portfolio_Project/frontend/lib/views/dashboard/home_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to match merge conflict blocks
# <<<<<<< Updated upstream
# ... (old content)
# =======
# ... (new/stashed content)
# >>>>>>> Stashed changes

def resolve_conflict(match):
    """Keep the stashed changes version (after =======)."""
    groups = match.groups()
    # groups[0] = upstream content, groups[1] = stashed content
    # Return the stashed version
    return groups[1]

# Find all merge conflict blocks
# Pattern: <<<<<<< .*?\n(.*?)=======\n(.*?)>>>>>>> .*?\n
pattern = r'<<<<<<< .*?\n(.*?)=======\n(.*?)>>>>>>> .*?\n'

count_before = content.count('<<<<<<<')
print(f"Found {count_before} conflict markers before fix.")

# Resolve by keeping stashed changes
new_content = re.sub(pattern, resolve_conflict, content, flags=re.DOTALL)

count_after = new_content.count('<<<<<<<')
print(f"Found {count_after} conflict markers after fix.")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Merge conflicts resolved. File saved to {filepath}")

