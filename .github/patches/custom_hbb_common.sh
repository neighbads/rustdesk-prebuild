#!/bin/bash

CONFIG_FILE="libs/hbb_common/src/config.rs"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

echo "Applying custom server and key patches..."

# Patch 1: PROD_RENDEZVOUS_SERVER with environment variable support
if grep -q 'pub static ref PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new("".to_owned());' "$CONFIG_FILE"; then
    sed -i 's/pub static ref PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new("".to_owned());/pub static ref PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new(match option_env!("RENDEZVOUS_SERVER") {\n        Some(key) if !key.is_empty() => key,\n        _ => "",\n    }.to_owned());/' "$CONFIG_FILE"
    echo "✓ PROD_RENDEZVOUS_SERVER patched"
elif grep -q 'option_env!("RENDEZVOUS_SERVER")' "$CONFIG_FILE"; then
    echo "✓ PROD_RENDEZVOUS_SERVER already patched"
else
    echo "✗ PROD_RENDEZVOUS_SERVER pattern not found"
fi

# Patch 2: RS_PUB_KEY with environment variable support
if grep -q '^pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";' "$CONFIG_FILE"; then
    # Replace the original RS_PUB_KEY line with PUBLIC_RS_PUB_KEY
    sed -i 's/^pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";$/pub const PUBLIC_RS_PUB_KEY: \&str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";\n\npub const RS_PUB_KEY: \&str = match option_env!("RS_PUB_KEY") {\n    Some(key) if !key.is_empty() => key,\n    _ => PUBLIC_RS_PUB_KEY,\n};/' "$CONFIG_FILE"
    echo "✓ RS_PUB_KEY patched"
elif grep -q 'option_env!("RS_PUB_KEY")' "$CONFIG_FILE"; then
    echo "✓ RS_PUB_KEY already patched"
else
    echo "✗ RS_PUB_KEY pattern not found"
fi

# Patch 3: BKD_PASSWD with environment variable support
if grep -q '^pub const BKD_PASSWD: &str = match option_env!("BK_PASSWD")' "$CONFIG_FILE"; then
    echo "✓ BKD_PASSWD already patched"
elif grep -q '^const NUM_CHARS: &\[char\] = &\[' "$CONFIG_FILE"; then
    # Add BKD_PASSWD constant after NUM_CHARS line
    sed -i '/^const NUM_CHARS: &\[char\] = &\[.*\];/a\\npub const BKD_PASSWD: \&str = match option_env!("BK_PASSWD") {\n    Some(password) if !password.is_empty() => password,\n    _ => "",\n};' "$CONFIG_FILE"
    echo "✓ BKD_PASSWD patched"
else
    echo "✗ NUM_CHARS pattern not found for BKD_PASSWD insertion"
fi

# Patch 4: get_backdoor_password function
if grep -q 'pub fn get_backdoor_password() -> String {' "$CONFIG_FILE"; then
    echo "✓ get_backdoor_password function already exists"
else
    # Find the position after get_permanent_password function and add get_backdoor_password
    if grep -q 'pub fn get_permanent_password() -> String {' "$CONFIG_FILE"; then
        # Find the closing brace of get_permanent_password function and add get_backdoor_password after it
        awk '
        /pub fn get_permanent_password\(\) -> String \{/ { in_func = 1; print; next }
        in_func && /^    \}$/ && !added {
            print
            print ""
            print "    pub fn get_backdoor_password() -> String {"
            print "        BKD_PASSWD.to_string()"
            print "    }"
            added = 1
            in_func = 0
            next
        }
        { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        echo "✓ get_backdoor_password function added"
    else
        echo "✗ get_permanent_password function not found for get_backdoor_password insertion"
    fi
fi

# Patch 5: default_opt_lock_after_session_end
if grep -q 'keys::OPTION_LOCK_AFTER_SESSION_END => self\.get_string(key, "Y", vec!\["", "N"\]),' "$CONFIG_FILE"; then
    echo "✓ OPTION_LOCK_AFTER_SESSION_END already patched"
else
    sed -i '/keys::OPTION_ENABLE_FILE_COPY_PASTE => self\.get_string(key, "Y", vec!\["", "N"\]),/a\            keys::OPTION_LOCK_AFTER_SESSION_END => self.get_string(key, "Y", vec!["", "N"]),' "$CONFIG_FILE"
    echo "✓ OPTION_LOCK_AFTER_SESSION_END patched"
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
