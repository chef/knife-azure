#!/bin/bash

# Script to implement knife-azure integration in chef/knife habitat plans
# Usage: Run this script from the chef/knife repository root
# This script works with the branch that has knife-ec2 bundling (sanjain/CHEF-15864/knife_google_bundled)

set -e

KNIFE_REPO="/Users/asaidala/Projects/knife"
BASE_BRANCH="sanjain/CHEF-15864/knife_google_bundled"
NEW_BRANCH="sanjain/CHEF-15721/knife_azure_bundled"

echo "🔧 CHEF-15721: Adding knife-azure to chef/knife habitat plans..."
echo "📋 Base branch: $BASE_BRANCH"
echo "🌿 New branch: $NEW_BRANCH"

# Function to run commands in knife repo
run_in_knife_repo() {
    (cd "$KNIFE_REPO" && "$@")
}

# Check if we're in the right directory
if [ ! -f "$KNIFE_REPO/habitat/plan.sh" ]; then
    echo "❌ Error: Could not find $KNIFE_REPO/habitat/plan.sh"
    echo "Please ensure the chef/knife repository is at $KNIFE_REPO"
    exit 1
fi

echo ""
echo "🎯 STEP 1: Checkout and create new branch based on $BASE_BRANCH"
echo "================================================================"

# Navigate to knife repo and checkout base branch
echo "📍 Fetching latest changes..."
run_in_knife_repo git fetch origin

echo "📍 Checking out base branch: $BASE_BRANCH"
if run_in_knife_repo git checkout "$BASE_BRANCH" 2>/dev/null; then
    echo "✅ Successfully checked out $BASE_BRANCH"
else
    echo "📍 Base branch not found locally, checking out from origin..."
    run_in_knife_repo git checkout -b "$BASE_BRANCH" "origin/$BASE_BRANCH"
fi

echo "📍 Pulling latest changes from $BASE_BRANCH..."
run_in_knife_repo git pull origin "$BASE_BRANCH"

echo "📍 Creating new branch: $NEW_BRANCH"
if run_in_knife_repo git checkout -b "$NEW_BRANCH" 2>/dev/null; then
    echo "✅ Successfully created and checked out $NEW_BRANCH"
else
    echo "📍 Branch $NEW_BRANCH already exists, checking it out..."
    run_in_knife_repo git checkout "$NEW_BRANCH"
fi

echo ""
echo "🎯 STEP 2: Analyze current habitat plans for knife-ec2 installation"
echo "================================================================"

# Check current branch
echo "📍 Current branch:"
run_in_knife_repo git branch --show-current

# Backup original files
echo "📋 Creating backups..."
cp "$KNIFE_REPO/habitat/plan.sh" "$KNIFE_REPO/habitat/plan.sh.backup"
cp "$KNIFE_REPO/habitat/plan.ps1" "$KNIFE_REPO/habitat/plan.ps1.backup"
echo "✅ Backups created: plan.sh.backup and plan.ps1.backup"

# Show the current content around the installation area
echo ""
echo "📍 Current knife-ec2 installation in plan.sh:"
echo "=============================================="
grep -n -A 10 -B 5 "knife-ec2\|specific_install\|gem install.*ec2" "$KNIFE_REPO/habitat/plan.sh" || echo "No knife-ec2 installation found in plan.sh"

echo ""
echo "📍 Current knife-ec2 installation in plan.ps1:"
echo "==============================================="
grep -n -A 10 -B 5 "knife-ec2\|specific_install\|gem install.*ec2" "$KNIFE_REPO/habitat/plan.ps1" || echo "No knife-ec2 installation found in plan.ps1"

echo ""
echo "🎯 STEP 3: Implementation Plan"
echo "================================"
echo ""
echo "Based on the knife-ec2 pattern found above, you need to add knife-azure installation:"
echo ""
echo "FOR plan.sh (Linux):"
echo "-------------------"
echo "Add these lines after the knife-ec2 installation:"
echo ""
echo '    build_line "Installing the knife-azure plugin"'
echo '    gem specific_install -l https://github.com/chef/knife-azure.git'
echo ""
echo "FOR plan.ps1 (Windows):"
echo "----------------------"
echo "Add these lines after the knife-ec2 installation:"
echo ""
echo '    Write-BuildLine "Installing the knife-azure plugin"'
echo '    gem specific_install -l https://github.com/chef/knife-azure.git'
echo '    If ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }'
echo ""

echo ""
echo "🎯 STEP 4: Next Actions Required"
echo "================================="
echo ""
echo "1. 📝 Edit the habitat plans manually with the changes shown above"
echo "2. 🧪 Test the habitat package build locally"
echo "3. ✅ Commit and push the changes"
echo "4. 🚀 Create PR for knife-azure integration"
echo ""
echo "� After making the changes, run this command to see what files were modified:"
echo "   cd $KNIFE_REPO && git status"
echo ""
echo "📋 To commit the changes:"
echo "   cd $KNIFE_REPO && git add . && git commit -m 'CHEF-15721: Add knife-azure plugin to habitat package'"
echo ""
echo "🚀 To push the branch:"
echo "   cd $KNIFE_REPO && git push origin $NEW_BRANCH"
echo ""
echo "✅ Branch setup completed! Ready for manual habitat plan modifications."