#!/bin/bash

# Enhanced script to implement knife-azure integration in chef/knife habitat plans
# Handles existing local changes and provides step-by-step guidance

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
echo "🎯 STEP 1: Check current status and handle local changes"
echo "======================================================="

# Check current status
echo "📍 Current status in knife repository:"
run_in_knife_repo git status --porcelain

# Check if there are uncommitted changes
if [ -n "$(run_in_knife_repo git status --porcelain)" ]; then
    echo ""
    echo "⚠️  DETECTED LOCAL CHANGES IN KNIFE REPOSITORY"
    echo "=============================================="
    echo ""
    echo "You have uncommitted changes in the knife repository."
    echo "Please choose one of the following options:"
    echo ""
    echo "Option 1 - Stash changes (recommended):"
    echo "  cd $KNIFE_REPO"
    echo "  git stash push -m 'Temporary stash before knife-azure integration'"
    echo ""
    echo "Option 2 - Commit current changes:"
    echo "  cd $KNIFE_REPO"
    echo "  git add ."
    echo "  git commit -m 'WIP: Current changes before knife-azure integration'"
    echo ""
    echo "Option 3 - Reset changes (CAUTION: will lose changes):"
    echo "  cd $KNIFE_REPO"
    echo "  git reset --hard HEAD"
    echo ""
    echo "After handling the changes, re-run this script."
    echo ""
    echo "🔄 Quick command to stash and continue:"
    echo "  cd $KNIFE_REPO && git stash && cd - && ./habitat_integration_script.sh"
    
    exit 1
fi

echo "✅ No uncommitted changes detected, proceeding..."

echo ""
echo "🎯 STEP 2: Checkout and create new branch"
echo "========================================="

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
echo "🎯 STEP 3: Analyze current habitat plans"
echo "========================================"

# Check current branch
echo "📍 Current branch:"
run_in_knife_repo git branch --show-current

# Show the current content around the installation area
echo ""
echo "📍 Current gem installations in plan.sh:"
echo "========================================"
grep -n -A 5 -B 5 "gem install\|gem specific_install\|knife-" "$KNIFE_REPO/habitat/plan.sh" || echo "No gem installations found in plan.sh"

echo ""
echo "📍 Current gem installations in plan.ps1:"
echo "========================================="
grep -n -A 5 -B 5 "gem install\|gem specific_install\|knife-" "$KNIFE_REPO/habitat/plan.ps1" || echo "No gem installations found in plan.ps1"

echo ""
echo "🎯 STEP 4: Implementation Instructions"
echo "======================================"
echo ""
echo "Now you need to manually add knife-azure installation to both habitat plans."
echo ""
echo "📝 EDIT $KNIFE_REPO/habitat/plan.sh:"
echo "Find the section where plugins are installed (around gem install commands)"
echo "Add these lines after knife-ec2 installation:"
echo ""
echo '    build_line "Installing the knife-azure plugin"'
echo '    gem specific_install -l https://github.com/chef/knife-azure.git'
echo ""
echo "📝 EDIT $KNIFE_REPO/habitat/plan.ps1:"
echo "Find the section where plugins are installed (around gem install commands)" 
echo "Add these lines after knife-ec2 installation:"
echo ""
echo '    Write-BuildLine "Installing the knife-azure plugin"'
echo '    gem specific_install -l https://github.com/chef/knife-azure.git'
echo '    If ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }'
echo ""

echo ""
echo "🎯 STEP 5: Testing and Commit Instructions"
echo "=========================================="
echo ""
echo "After making the edits:"
echo ""
echo "1. 🧪 Test the habitat package (optional but recommended):"
echo "   cd $KNIFE_REPO"
echo "   hab pkg build ."
echo ""
echo "2. ✅ Check what files were modified:"
echo "   cd $KNIFE_REPO"
echo "   git status"
echo "   git diff"
echo ""
echo "3. 📋 Commit the changes:"
echo "   cd $KNIFE_REPO"
echo "   git add habitat/plan.sh habitat/plan.ps1"
echo "   git commit -m 'CHEF-15721: Add knife-azure plugin to habitat package"
echo "   "
echo "   - Add knife-azure plugin installation to Linux habitat plan"
echo "   - Add knife-azure plugin installation to Windows habitat plan"
echo "   - Follow same pattern as knife-ec2 plugin integration'"
echo ""
echo "4. 🚀 Push the branch:"
echo "   cd $KNIFE_REPO"
echo "   git push origin $NEW_BRANCH"
echo ""
echo "✅ Ready for manual implementation! Branch $NEW_BRANCH is set up and ready."