#!/bin/bash

# prettier-eslint.sh - Combined Prettier and ESLint formatting
# Usage: ./hooks/prettier-eslint.sh [files...]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get files to process
FILES="$@"

if [ -z "$FILES" ]; then
    echo -e "${YELLOW}No files specified. Exiting.${NC}"
    exit 0
fi

# Check if prettier is installed
if ! command -v prettier &> /dev/null; then
    echo -e "${RED}Error: prettier is not installed${NC}"
    echo "Install with: npm install -g prettier"
    exit 1
fi

# Check if eslint is installed
if ! command -v eslint &> /dev/null; then
    echo -e "${RED}Error: eslint is not installed${NC}"
    echo "Install with: npm install -g eslint"
    exit 1
fi

# Process each file
FAILED_FILES=()
FORMATTED_COUNT=0

for file in $FILES; do
    echo -e "Processing ${file}..."
    
    # Skip if file doesn't exist
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}  Skipping (file not found)${NC}"
        continue
    fi
    
    # Check file extension
    case "$file" in
        *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md)
            # Run prettier
            if prettier --write "$file" 2>/dev/null; then
                echo -e "${GREEN}  ✓ Prettier formatted${NC}"
                ((FORMATTED_COUNT++))
                
                # Run ESLint only on JS/TS files
                case "$file" in
                    *.js|*.jsx|*.ts|*.tsx)
                        if eslint --fix "$file" 2>/dev/null; then
                            echo -e "${GREEN}  ✓ ESLint fixed${NC}"
                        else
                            echo -e "${YELLOW}  ⚠ ESLint found issues${NC}"
                            FAILED_FILES+=("$file")
                        fi
                        ;;
                esac
            else
                echo -e "${RED}  ✗ Prettier failed${NC}"
                FAILED_FILES+=("$file")
            fi
            ;;
        *)
            echo -e "${YELLOW}  Skipping (unsupported file type)${NC}"
            ;;
    esac
done

# Summary
echo -e "\n${GREEN}Formatted ${FORMATTED_COUNT} files${NC}"

if [ ${#FAILED_FILES[@]} -gt 0 ]; then
    echo -e "${RED}Failed to process ${#FAILED_FILES[@]} files:${NC}"
    for file in "${FAILED_FILES[@]}"; do
        echo -e "${RED}  - $file${NC}"
    done
    exit 1
fi

exit 0