#!/usr/bin/env powershell
#
# This script runs a passed in command, but first sets up the bundler caching on the repo
# for Windows environments with network resilience

# Set error handling
$ErrorActionPreference = "Stop"

# Set UTF-8 encoding for consistency
$env:LANG = "en_US.UTF-8"
$env:LC_ALL = "en_US.UTF-8"

Write-Host "--- Setting up bundle configuration for Windows"

# Configure bundler for local caching and network resilience
bundle config --local path vendor/bundle
bundle config set --local without docs debug
bundle config set --local retry 5
bundle config set --local timeout 30
bundle config set --local jobs 3

Write-Host "--- bundle install with network resilience"

# Retry bundle install with exponential backoff for network issues
$maxAttempts = 3
$attempt = 1
$success = $false

while ($attempt -le $maxAttempts -and -not $success) {
    try {
        Write-Host "Bundle install attempt $attempt of $maxAttempts"
        bundle install --retry=5
        $success = $true
        Write-Host "Bundle install successful on attempt $attempt"
    }
    catch {
        Write-Host "Bundle install failed on attempt $attempt`: $($_.Exception.Message)"
        if ($attempt -lt $maxAttempts) {
            $waitTime = [math]::Pow(2, $attempt) * 5  # Exponential backoff: 10s, 20s
            Write-Host "Waiting $waitTime seconds before retry..."
            Start-Sleep -Seconds $waitTime
        }
        $attempt++
    }
}

if (-not $success) {
    Write-Host "Bundle install failed after $maxAttempts attempts"
    exit 1
}

Write-Host "+++ bundle exec task"

# Execute the passed command
$command = $args -join " "
if ($command) {
    Invoke-Expression "bundle exec $command"
} else {
    Write-Host "No command specified"
    exit 1
}