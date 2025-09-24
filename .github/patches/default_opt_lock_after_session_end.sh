#!/bin/bash

CONFIG_FILE="libs/hbb_common/src/config.rs"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

echo "Applying default_opt_lock_after_session_end patch..."

# Check if OPTION_LOCK_AFTER_SESSION_END constant exists
if ! grep -q 'OPTION_LOCK_AFTER_SESSION_END' "$CONFIG_FILE"; then
    echo "✗ OPTION_LOCK_AFTER_SESSION_END constant not found in keys module"
    exit 1
fi

# Find and patch the UserDefaultConfig get method
if grep -q 'keys::OPTION_ENABLE_FILE_COPY_PASTE => self\.get_string(key, "Y", vec!\["", "N"\]),' "$CONFIG_FILE"; then
    # Check if already patched
    if grep -q 'keys::OPTION_LOCK_AFTER_SESSION_END => self\.get_string(key, "Y", vec!\["", "N"\]),' "$CONFIG_FILE"; then
        echo "✓ OPTION_LOCK_AFTER_SESSION_END already patched"
    else
        # Apply the patch
        sed -i '/keys::OPTION_ENABLE_FILE_COPY_PASTE => self\.get_string(key, "Y", vec!\["", "N"\]),/a\            keys::OPTION_LOCK_AFTER_SESSION_END => self.get_string(key, "Y", vec!["", "N"]),' "$CONFIG_FILE"
        echo "✓ OPTION_LOCK_AFTER_SESSION_END patched"
    fi
else
    echo "✗ OPTION_ENABLE_FILE_COPY_PASTE pattern not found"
fi

echo "Default opt lock after session end patch completed"
