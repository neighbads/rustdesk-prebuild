#!/bin/bash

CONFIG_FILE="libs/hbb_common/src/config.rs"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi







# Patch 6: default_opt_view_style_adaptive
if grep -q '#\[cfg(not(any(target_os = "android", target_os = "ios")))\]' "$CONFIG_FILE"; then
    # Check if already patched (default is "adaptive")
    if grep -A1 '#\[cfg(not(any(target_os = "android", target_os = "ios")))\]' "$CONFIG_FILE" | grep -q 'keys::OPTION_VIEW_STYLE => self\.get_string(key, "adaptive", vec!\["original"\])'; then
        echo "✓ OPTION_VIEW_STYLE already patched to use 'adaptive' as default"
    elif grep -A1 '#\[cfg(not(any(target_os = "android", target_os = "ios")))\]' "$CONFIG_FILE" | grep -q 'keys::OPTION_VIEW_STYLE => self\.get_string(key, "original", vec!\["adaptive"\])'; then
        # Apply the patch - change from "original" to "adaptive"
        sed -i '/^[[:space:]]*#\[cfg(not(any(target_os = "android", target_os = "ios")))\]/,/keys::OPTION_VIEW_STYLE/ {
            s/keys::OPTION_VIEW_STYLE => self\.get_string(key, "original", vec!\["adaptive"\])/keys::OPTION_VIEW_STYLE => self.get_string(key, "adaptive", vec!["original"])/
        }' "$CONFIG_FILE"
        echo "✓ OPTION_VIEW_STYLE patched: changed default from 'original' to 'adaptive'"
    else
        echo "✗ OPTION_VIEW_STYLE pattern not found in expected format"
    fi
else
    echo "✗ Platform-specific configuration block not found"
fi

echo "Custom server and key patches completed"
