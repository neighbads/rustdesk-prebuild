#!/bin/bash

DESKTOP_HOME_PAGE="flutter/lib/desktop/pages/desktop_home_page.dart"
DESKTOP_SETTING_PAGE="flutter/lib/desktop/pages/desktop_setting_page.dart"

# Check if files exist
if [ ! -f "$DESKTOP_HOME_PAGE" ]; then
    echo "Error: $DESKTOP_HOME_PAGE not found"
    exit 1
fi

if [ ! -f "$DESKTOP_SETTING_PAGE" ]; then
    echo "Error: $DESKTOP_SETTING_PAGE not found"
    exit 1
fi

echo "Applying view_hide_uac_install_tip patch..."

# Patch 1: Hide UAC install tip in desktop_home_page.dart
# Check if already patched
if grep -q '// UAC提示被隐藏 - 不显示install_tip' "$DESKTOP_HOME_PAGE"; then
    echo "✓ UAC install tip already hidden in desktop_home_page.dart"
elif grep -q 'if (!bind\.mainIsInstalled()) {' "$DESKTOP_HOME_PAGE" && grep -A 10 'if (!bind\.mainIsInstalled()) {' "$DESKTOP_HOME_PAGE" | grep -q 'return buildInstallCard('; then
    # Apply the patch - replace the buildInstallCard call with SizedBox
    sed -i '/if (!bind\.mainIsInstalled()) {/,/});$/{
        /return buildInstallCard(/,/});$/c\
        // UAC提示被隐藏 - 不显示install_tip\
        return const SizedBox();
    }' "$DESKTOP_HOME_PAGE"
    echo "✓ UAC install tip hidden in desktop_home_page.dart"
else
    echo "✗ UAC install pattern not found or already modified in desktop_home_page.dart"
fi

# Patch 2: Modify service button layout in desktop_setting_page.dart
# Check if already patched
if grep -q 'Row(' "$DESKTOP_SETTING_PAGE" && grep -q 'if (isWindows && !bind.mainIsInstalled())' "$DESKTOP_SETTING_PAGE"; then
    echo "✓ Service button layout already modified in desktop_setting_page.dart"
elif grep -q 'Obx(() => _Button(serviceStop.value ? '\''Start'\'' : '\''Stop'\'',' "$DESKTOP_SETTING_PAGE"; then
    # Apply the patch - replace the _Button with Row layout
    sed -i '/Obx(() => _Button(serviceStop.value ? '\''Start'\'' : '\''Stop'\'',/,/enabled: serviceBtnEnabled.value))/c\
      Row(\
        children: [\
          Obx(() => ElevatedButton(\
            onPressed: serviceBtnEnabled.value ? () {\
              () async {\
                serviceBtnEnabled.value = false;\
                await start_service(serviceStop.value);\
                // enable the button after 1 second\
                Future.delayed(const Duration(seconds: 1), () {\
                  serviceBtnEnabled.value = true;\
                });\
              }();\
            } : null,\
            child: Text(translate(serviceStop.value ? '\''Start'\'' : '\''Stop'\''))\
                .marginSymmetric(horizontal: 15),\
          )),\
          const SizedBox(width: 10),\
          if (isWindows && !bind.mainIsInstalled())\
            ElevatedButton(\
              onPressed: () async {\
                await bind.mainGotoInstall();\
              },\
              child: Text(translate('\''Install'\''))\
                  .marginSymmetric(horizontal: 15),\
            ),\
        ],\
      ).marginOnly(left: _kContentHMargin),' "$DESKTOP_SETTING_PAGE"
    echo "✓ Service button layout modified in desktop_setting_page.dart"
else
    echo "✗ Service button pattern not found or already modified in desktop_setting_page.dart"
fi

echo "View hide UAC install tip patch completed"
