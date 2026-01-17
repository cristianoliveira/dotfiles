#!/usr/bin/env bash
# Integration test for command discovery caching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SH="${SCRIPT_DIR}/commands.sh"

echo "=== Command Discovery Cache Integration Test ==="
echo "Script: ${COMMANDS_SH}"
echo

# Change to repository root
cd /Users/cristianoliveira/.dotfiles

# Test 1: Clear any existing cache
echo "1. Clearing existing cache..."
"${COMMANDS_SH}" --clear
echo "✓ Cache cleared"
echo

# Test 2: List should return empty array
echo "2. Testing --list with empty cache..."
result=$("${COMMANDS_SH}" --list)
if [ "$result" = "[]" ]; then
    echo "✓ Empty cache returns []"
else
    echo "✗ Expected [], got: $result"
    exit 1
fi
echo

# Test 3: Cache some commands
echo "3. Caching test commands..."
"${COMMANDS_SH}" --cache "Makefile" "build" '["make build", "make test"]'
"${COMMANDS_SH}" --cache "Makefile" "lint" '["make lint"]'
echo "✓ Commands cached"
echo

# Test 4: List should return cached commands
echo "4. Testing --list with cached commands..."
result=$("${COMMANDS_SH}" --list | jq -r 'length')
if [ "$result" -eq 3 ]; then
    echo "✓ Found $result cached commands"
else
    echo "✗ Expected 3 commands, got $result"
    exit 1
fi
echo

# Test 5: Verify cache structure
echo "5. Verifying cache structure..."
cached=$("${COMMANDS_SH}" --list)
echo "$cached" | jq -e '.[] | select(.source == "Makefile" and .category == "build" and .command == "make build")' >/dev/null
echo "✓ 'make build' found in cache"
echo "$cached" | jq -e '.[] | select(.source == "Makefile" and .category == "build" and .command == "make test")' >/dev/null
echo "✓ 'make test' found in cache"
echo "$cached" | jq -e '.[] | select(.source == "Makefile" and .category == "lint" and .command == "make lint")' >/dev/null
echo "✓ 'make lint' found in cache"
echo

# Test 6: Test deduplication
echo "6. Testing deduplication (adding same command again)..."
before_count=$("${COMMANDS_SH}" --list | jq -r 'length')
"${COMMANDS_SH}" --cache "Makefile" "build" '["make build"]'  # Duplicate
after_count=$("${COMMANDS_SH}" --list | jq -r 'length')
if [ "$before_count" -eq "$after_count" ]; then
    echo "✓ Deduplication works (count unchanged: $before_count)"
else
    echo "✗ Deduplication failed: before=$before_count, after=$after_count"
    exit 1
fi
echo

# Test 7: Test hash invalidation simulation
echo "7. Testing hash invalidation (simulated by clearing cache)..."
"${COMMANDS_SH}" --clear
result=$("${COMMANDS_SH}" --list)
if [ "$result" = "[]" ]; then
    echo "✓ Clear works, cache empty"
else
    echo "✗ Clear failed, got: $result"
    exit 1
fi
echo

# Test 8: Test invalid JSON handling
echo "8. Testing invalid JSON rejection..."
if ! "${COMMANDS_SH}" --cache "test.txt" "test" '["cmd1", 123]' 2>/dev/null; then
    echo "✓ Invalid JSON rejected"
else
    echo "✗ Invalid JSON should have been rejected"
    exit 1
fi
echo

# Test 9: Test missing source file handling
echo "9. Testing missing source file handling..."
"${COMMANDS_SH}" --cache "non-existent-file.txt" "test" '["echo test"]' >/dev/null
result=$("${COMMANDS_SH}" --list | jq -r '.[] | select(.source == "non-existent-file.txt") | .hash')
if [ "$result" = "missing" ]; then
    echo "✓ Missing source file handled (hash: 'missing')"
else
    echo "✗ Missing source file hash should be 'missing', got: $result"
    exit 1
fi
echo

# Clean up
echo "10. Cleaning up..."
"${COMMANDS_SH}" --clear
echo "✓ Cache cleared"
echo

echo "=== All tests passed! ==="
echo
echo "Cache script is working correctly."
echo "Integration with land-the-plane skill:"
echo "1. Agent should call 'commands.sh --list' first"
echo "2. If returns non-empty array, use cached commands"
echo "3. If returns empty array, discover commands and cache them"
echo "4. Cache each source/category with 'commands.sh --cache'"