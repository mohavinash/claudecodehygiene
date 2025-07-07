#!/bin/bash

# jsdoc-validator.sh - Validate JSDoc comments in JavaScript/TypeScript files
# Usage: ./hooks/jsdoc-validator.sh [--strict] [files...]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for strict mode
STRICT_MODE=false
if [ "$1" == "--strict" ]; then
    STRICT_MODE=true
    shift
fi

# Get files to process
FILES="$@"

if [ -z "$FILES" ]; then
    echo -e "${YELLOW}No files specified. Exiting.${NC}"
    exit 0
fi

# Validation counters
TOTAL_FILES=0
VALID_FILES=0
WARNING_FILES=0
ERROR_FILES=0

# Function to check if a function/class needs JSDoc
needs_jsdoc() {
    local line="$1"
    
    # Check for function declarations, class methods, exported functions
    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]+[a-zA-Z] ]] || \
       [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?const[[:space:]]+[a-zA-Z]+[[:space:]]*=[[:space:]]*(\([^)]*\)|async[[:space:]]*\([^)]*\))[[:space:]]*=> ]] || \
       [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?class[[:space:]]+[a-zA-Z] ]] || \
       [[ "$line" =~ ^[[:space:]]*(public|private|protected|static)[[:space:]]+[a-zA-Z]+\( ]]; then
        return 0
    fi
    
    return 1
}

# Function to check if previous lines contain JSDoc
has_jsdoc() {
    local file="$1"
    local line_num="$2"
    local check_line=$((line_num - 1))
    
    # Look for JSDoc ending */ in previous lines
    while [ $check_line -gt 0 ]; do
        local prev_line=$(sed -n "${check_line}p" "$file")
        
        # Found JSDoc end
        if [[ "$prev_line" =~ \*/ ]]; then
            # Now check if there's a JSDoc start
            while [ $check_line -gt 0 ]; do
                local doc_line=$(sed -n "${check_line}p" "$file")
                if [[ "$doc_line" =~ /\*\* ]]; then
                    return 0
                fi
                ((check_line--))
            done
            return 1
        fi
        
        # Stop if we hit a non-comment, non-empty line
        if [[ ! "$prev_line" =~ ^[[:space:]]*$ ]] && [[ ! "$prev_line" =~ ^[[:space:]]*\* ]]; then
            return 1
        fi
        
        ((check_line--))
    done
    
    return 1
}

# Function to validate JSDoc content
validate_jsdoc_content() {
    local file="$1"
    local start_line="$2"
    local warnings=()
    
    # Extract JSDoc block
    local in_jsdoc=false
    local jsdoc_content=""
    local line_num=$start_line
    
    while read -r line; do
        if [[ "$line" =~ /\*\* ]]; then
            in_jsdoc=true
        fi
        
        if $in_jsdoc; then
            jsdoc_content+="$line"$'\n'
            
            if [[ "$line" =~ \*/ ]]; then
                break
            fi
        fi
    done < <(tail -n +$start_line "$file")
    
    # Check for basic JSDoc tags in strict mode
    if $STRICT_MODE; then
        if [[ ! "$jsdoc_content" =~ @description ]] && [[ ! "$jsdoc_content" =~ \*[[:space:]]+[A-Z] ]]; then
            warnings+=("Missing description")
        fi
        
        if [[ "$jsdoc_content" =~ function ]] || [[ "$jsdoc_content" =~ \=\> ]]; then
            if [[ ! "$jsdoc_content" =~ @param ]]; then
                warnings+=("Missing @param tags")
            fi
            if [[ ! "$jsdoc_content" =~ @returns ]] && [[ ! "$jsdoc_content" =~ @return ]]; then
                warnings+=("Missing @returns tag")
            fi
        fi
    fi
    
    printf '%s\n' "${warnings[@]}"
}

# Process each file
for file in $FILES; do
    # Skip if file doesn't exist
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Check file extension
    case "$file" in
        *.js|*.jsx|*.ts|*.tsx)
            ((TOTAL_FILES++))
            echo -e "${BLUE}Checking $file...${NC}"
            
            local_errors=0
            local_warnings=0
            line_num=0
            
            while IFS= read -r line; do
                ((line_num++))
                
                # Check if this line needs JSDoc
                if needs_jsdoc "$line"; then
                    if ! has_jsdoc "$file" "$line_num"; then
                        echo -e "${RED}  ✗ Line $line_num: Missing JSDoc comment${NC}"
                        echo -e "${YELLOW}    $line${NC}"
                        ((local_errors++))
                    elif $STRICT_MODE; then
                        # Validate JSDoc content
                        jsdoc_line=$((line_num - 1))
                        while [ $jsdoc_line -gt 0 ]; do
                            check_line=$(sed -n "${jsdoc_line}p" "$file")
                            if [[ "$check_line" =~ /\*\* ]]; then
                                warnings=($(validate_jsdoc_content "$file" "$jsdoc_line"))
                                if [ ${#warnings[@]} -gt 0 ]; then
                                    echo -e "${YELLOW}  ⚠ Line $line_num: JSDoc issues:${NC}"
                                    for warning in "${warnings[@]}"; do
                                        echo -e "${YELLOW}    - $warning${NC}"
                                    done
                                    ((local_warnings++))
                                fi
                                break
                            fi
                            ((jsdoc_line--))
                        done
                    fi
                fi
            done < "$file"
            
            # File summary
            if [ $local_errors -eq 0 ] && [ $local_warnings -eq 0 ]; then
                echo -e "${GREEN}  ✓ All functions properly documented${NC}"
                ((VALID_FILES++))
            elif [ $local_errors -eq 0 ]; then
                echo -e "${YELLOW}  ⚠ File has $local_warnings warnings${NC}"
                ((WARNING_FILES++))
            else
                echo -e "${RED}  ✗ File has $local_errors errors${NC}"
                ((ERROR_FILES++))
            fi
            ;;
        *)
            # Skip non-JS/TS files
            ;;
    esac
done

# Summary
echo -e "\n${BLUE}JSDoc Validation Summary:${NC}"
echo -e "Total files checked: $TOTAL_FILES"
echo -e "${GREEN}Valid files: $VALID_FILES${NC}"
if [ $WARNING_FILES -gt 0 ]; then
    echo -e "${YELLOW}Files with warnings: $WARNING_FILES${NC}"
fi
if [ $ERROR_FILES -gt 0 ]; then
    echo -e "${RED}Files with errors: $ERROR_FILES${NC}"
fi

# Exit code based on mode and results
if $STRICT_MODE && [ $WARNING_FILES -gt 0 ]; then
    exit 1
elif [ $ERROR_FILES -gt 0 ]; then
    exit 1
fi

exit 0