#!/bin/bash

PEER_CARD_FILE="flutter/lib/common/widgets/peer_card.dart"

if [ ! -f "$PEER_CARD_FILE" ]; then
    echo "Error: $PEER_CARD_FILE not found"
    exit 1
fi

echo "Applying view_use_list_type_peercard patch..."

# Check if PeerUiType enum exists
if ! grep -q 'enum PeerUiType { grid, tile, list }' "$PEER_CARD_FILE"; then
    echo "✗ PeerUiType enum not found"
    exit 1
fi

# Check if peerCardUiType variable exists
if ! grep -q 'final peerCardUiType' "$PEER_CARD_FILE"; then
    echo "✗ peerCardUiType variable not found"
    exit 1
fi

# Find and patch the peerCardUiType default value
if grep -q 'final peerCardUiType = PeerUiType\.grid\.obs;' "$PEER_CARD_FILE"; then
    # Apply the patch - change from grid to list
    sed -i 's/final peerCardUiType = PeerUiType\.grid\.obs;/final peerCardUiType = PeerUiType.list.obs;/' "$PEER_CARD_FILE"
    echo "✓ peerCardUiType patched: changed default from 'grid' to 'list'"
elif grep -q 'final peerCardUiType = PeerUiType\.list\.obs;' "$PEER_CARD_FILE"; then
    echo "✓ peerCardUiType already patched to use 'list' as default"
else
    echo "✗ peerCardUiType pattern not found in expected format"
    exit 1
fi

echo "View use list type peercard patch completed"
