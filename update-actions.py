#!/usr/bin/env python3
import os
import sys
import requests
import yaml
import re
from datetime import datetime

# GitHub API configuration
GITHUB_API = "https://api.github.com"
HEADERS = {
    "Accept": "application/vnd.github.v3+json"
}

# Add GitHub token if available
if 'GITHUB_TOKEN' in os.environ:
    HEADERS['Authorization'] = f"token {os.environ['GITHUB_TOKEN']}"

# Actions to check and update
ACTIONS_TO_CHECK = {
    'actions/checkout': 'v4',
    'docker/setup-buildx-action': 'v3',
    'docker/login-action': 'v3',
    'docker/metadata-action': 'v3',
    'docker/build-push-action': 'v3'
}


def get_latest_commit_hash(repo, tag):
    """Get the latest commit hash for a given action and tag."""
    try:
        # Get the tag reference
        response = requests.get(
            f"{GITHUB_API}/repos/{repo}/git/refs/tags/{tag}",
            headers=HEADERS
        )
        response.raise_for_status()
        data = response.json()

        if data['object']['type'] == 'tag':
            # If it's an annotated tag, get the commit it points to
            response = requests.get(data['object']['url'], headers=HEADERS)
            response.raise_for_status()
            return response.json()['object']['sha']

        return data['object']['sha']
    except Exception as e:
        print(f"Error getting commit hash for {repo}@{tag}: {e}")
        return None


def update_workflow_file(file_path, commit_hashes):
    """Update a workflow file with new commit hashes."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()

        # Create backup
        backup_path = f"{file_path}.bak"
        with open(backup_path, 'w') as f:
            f.write(content)

        # Update each action reference
        for action, hash_info in commit_hashes.items():
            # Pattern matches both with and without existing hash
            pattern = f"uses: {action}@[a-f0-9]+|uses: {action}@v\\d+"
            replacement = f"uses: {action}@{hash_info['hash']} # {hash_info['tag']}"
            content = re.sub(pattern, replacement, content)

        # Write updated content
        with open(file_path, 'w') as f:
            f.write(content)

        print(f"Updated {file_path}")
        return True

    except Exception as e:
        print(f"Error updating {file_path}: {e}")
        # Restore from backup if it exists
        if os.path.exists(backup_path):
            os.replace(backup_path, file_path)
        return False


def main():
    # Get current date for logging
    current_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"Starting action update check at {current_date}")

    # Collect latest commit hashes
    commit_hashes = {}
    for action, tag in ACTIONS_TO_CHECK.items():
        hash = get_latest_commit_hash(action, tag)
        if hash:
            commit_hashes[action] = {
                'hash': hash,
                'tag': tag
            }
            print(f"Found latest hash for {action}@{tag}: {hash}")

    if not commit_hashes:
        print("No commit hashes found. Exiting.")
        return 1

    # Update workflow files
    workflow_dir = ".github/workflows"
    success = True

    if not os.path.exists(workflow_dir):
        print(f"Workflow directory not found: {workflow_dir}")
        return 1

    for filename in os.listdir(workflow_dir):
        if filename.endswith('.yml') or filename.endswith('.yaml'):
            file_path = os.path.join(workflow_dir, filename)
            if not update_workflow_file(file_path, commit_hashes):
                success = False

    # Generate update report
    report = f"""
Action Update Report - {current_date}
=====================================
"""
    for action, info in commit_hashes.items():
        report += f"{action}@{info['tag']}: {info['hash']}\n"

    report_path = "action-update-report.txt"
    with open(report_path, 'w') as f:
        f.write(report)

    print(f"\nUpdate report saved to {report_path}")
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())