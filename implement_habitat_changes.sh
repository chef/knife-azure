#!/bin/bash

# Script to implement knife-azure habitat plan changes
# This script will make the actual edits to add knife-azure plugin installation

set -e

KNIFE_REPO="/Users/asaidala/Projects/knife"

echo "🔧 CHEF-15721: Implementing knife-azure habitat plan changes..."

# Check if we're on the right branch
cd "$KNIFE_REPO"
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

if [[ "$CURRENT_BRANCH" != "sanjain/CHEF-15721/knife_azure_bundled" ]]; then
    echo "⚠️  Warning: Not on expected branch (sanjain/CHEF-15721/knife_azure_bundled)"
    echo "Current branch: $CURRENT_BRANCH"
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo "❌ Aborting. Please checkout the correct branch first."
        exit 1
    fi
fi

echo ""
echo "🔧 STEP 1: Modifying Linux habitat plan (plan.sh)"
echo "================================================="

# Backup the file first
cp habitat/plan.sh habitat/plan.sh.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created: habitat/plan.sh.backup.$(date +%Y%m%d_%H%M%S)"

# Add knife-azure installation to plan.sh
# We need to add it after the knife-google installation (around line 89-90)
sed -i.tmp '/gem specific_install -l https:\/\/github.com\/chef\/knife-google.git -b sanjain\/CHEF-15864\/ruby_support_3.4/a\
\
    build_line "Installing the knife-azure plugin"\
    gem specific_install -l https://github.com/chef/knife-azure.git
' habitat/plan.sh

echo "✅ Added knife-azure installation to plan.sh"

echo ""
echo "🔧 STEP 2: Modifying Windows habitat plan (plan.ps1)"
echo "===================================================="

# Backup the file first
cp habitat/plan.ps1 habitat/plan.ps1.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created: habitat/plan.ps1.backup.$(date +%Y%m%d_%H%M%S)"

# Add knife-azure installation to plan.ps1
# We need to add it after the knife gem installation (around line 80)
# Looking for the pattern and adding our lines
awk '
/gem install knife\*\.gem --no-document/ {
    print $0
    print ""
    print "        Write-BuildLine \"Installing the knife-azure plugin\""
    print "        gem install specific_install"
    print "        gem specific_install -l https://github.com/chef/knife-azure.git"
    print "        If ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }"
    next
}
{ print }
' habitat/plan.ps1 > habitat/plan.ps1.tmp && mv habitat/plan.ps1.tmp habitat/plan.ps1

echo "✅ Added knife-azure installation to plan.ps1"

echo ""
echo "🔧 STEP 3: Verification and Summary"
echo "==================================="

echo ""
echo "📍 Changes made to plan.sh:"
echo "----------------------------"
grep -n -A 5 -B 2 "knife-azure" habitat/plan.sh || echo "Error: knife-azure not found in plan.sh"

echo ""
echo "📍 Changes made to plan.ps1:"
echo "-----------------------------"
grep -n -A 5 -B 2 "knife-azure" habitat/plan.ps1 || echo "Error: knife-azure not found in plan.ps1"

echo ""
echo "📊 Git Status:"
echo "--------------"
git status

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo ""
echo "1. ✅ Review the changes shown above"
echo "2. 🧪 Test the habitat build (optional):"
echo "   hab pkg build ."
echo ""
echo "3. 📋 Commit the changes:"
echo "   git add habitat/plan.sh habitat/plan.ps1"
echo "   git commit -m 'CHEF-15721: Add knife-azure plugin to habitat package"
echo ""
echo "   - Add knife-azure plugin installation to Linux habitat plan"
echo "   - Add knife-azure plugin installation to Windows habitat plan"  
echo "   - Follow same pattern as knife-ec2 and knife-google plugin integration'"
echo ""
echo "4. 🚀 Push the changes:"
echo "   git push origin sanjain/CHEF-15721/knife_azure_bundled"
echo ""
echo "✅ Implementation completed successfully!"