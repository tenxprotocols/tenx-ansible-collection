#!/usr/bin/env bash
# Validate that all collections and roles have required files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DEV_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$ANSIBLE_DEV_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Required files for a collection
REQUIRED_COLLECTION_FILES=(
    "galaxy.yml"
    "README.md"
)

# Required directories for a collection
REQUIRED_COLLECTION_DIRS=(
    "roles"
)

# Required files for a role
REQUIRED_ROLE_FILES=(
    "tasks/main.yml"
    "meta/main.yml"
    "defaults/main.yml"
    "README.md"
)

# Optional but recommended files for a role
RECOMMENDED_ROLE_FILES=(
    "handlers/main.yml"
    "vars/main.yml"
)

echo -e "${BLUE}=== Validating TenX Ansible Collections Structure ===${NC}"
echo ""

# Find all collections (directories with galaxy.yml)
for collection_dir in "$REPO_ROOT"/*; do
    if [ ! -d "$collection_dir" ]; then
        continue
    fi

    collection_name=$(basename "$collection_dir")

    # Skip special directories
    if [[ "$collection_name" == "."* ]]; then
        continue
    fi

    # Check if it's a collection (has galaxy.yml)
    if [ ! -f "$collection_dir/galaxy.yml" ]; then
        continue
    fi

    echo -e "${BLUE}Checking collection: $collection_name${NC}"

    # Check required collection files
    for file in "${REQUIRED_COLLECTION_FILES[@]}"; do
        if [ ! -f "$collection_dir/$file" ]; then
            echo -e "${RED}  ✗ Missing required file: $file${NC}"
            ((ERRORS++))
        else
            echo -e "${GREEN}  ✓ $file${NC}"
        fi
    done

    # Check required collection directories
    for dir in "${REQUIRED_COLLECTION_DIRS[@]}"; do
        if [ ! -d "$collection_dir/$dir" ]; then
            echo -e "${YELLOW}  ⚠ Missing directory: $dir${NC}"
            ((WARNINGS++))
        fi
    done

    # Check roles within the collection
    if [ -d "$collection_dir/roles" ]; then
        for role_dir in "$collection_dir/roles"/*; do
            if [ ! -d "$role_dir" ]; then
                continue
            fi

            role_name=$(basename "$role_dir")
            echo -e "  ${BLUE}Checking role: $collection_name/$role_name${NC}"

            # Check required role files
            for file in "${REQUIRED_ROLE_FILES[@]}"; do
                if [ ! -f "$role_dir/$file" ]; then
                    echo -e "${RED}    ✗ Missing required file: $file${NC}"
                    ((ERRORS++))
                else
                    echo -e "${GREEN}    ✓ $file${NC}"
                fi
            done

            # Check recommended role files
            for file in "${RECOMMENDED_ROLE_FILES[@]}"; do
                if [ ! -f "$role_dir/$file" ]; then
                    echo -e "${YELLOW}    ⚠ Missing recommended file: $file${NC}"
                    ((WARNINGS++))
                fi
            done

            # Check for empty README
            if [ -f "$role_dir/README.md" ]; then
                if [ ! -s "$role_dir/README.md" ] || [ "$(wc -l < "$role_dir/README.md")" -lt 5 ]; then
                    echo -e "${YELLOW}    ⚠ README.md appears incomplete or empty${NC}"
                    ((WARNINGS++))
                fi
            fi
        done
    fi

    # Check for placeholder content in galaxy.yml
    if grep -q "your name\|example@domain.com\|your collection description\|http://example.com" "$collection_dir/galaxy.yml" 2>/dev/null; then
        echo -e "${YELLOW}  ⚠ galaxy.yml contains placeholder content${NC}"
        ((WARNINGS++))
    fi

    echo ""
done

# Summary
echo -e "${BLUE}=== Validation Summary ===${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ No errors, but $WARNINGS warning(s) found${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
