#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

#======================================================
# ILIAS DIRECTORIES
#======================================================
main(){
    # Array of directories with their descriptions
    declare -A ilias_directories=(
        ["/opt/iliasdata"]="ILIASDATA main folder"
        ["/opt/iliasdata/log"]="ILIASDATA log subfolder"
        ["/opt/iliasdata/lucene"]="ILIASDATA lucene subfolder"
        ["/opt/iliasdata/errorlog"]="ILIASDATA errorlog subfolder"
        ["/opt/iliasdata/temp"]="ILIASDATA temp subfolder"
        ["/var/www/logs"]="ILIAS logs directory"
        ["/var/www/files"]="ILIAS web directory"
        ["/var/www/html"]="Apache2 web directory"
    )

    # Counter for successful and failed operations
    ilias_success_count=0
    ilias_failed_count=0


    # Display what will happen
    echo_info "ILIAS DIRECTORY CHECK:"
    echo_info "The following directories will be processed:"

    for dir in "${!ilias_directories[@]}"; do
        if [ -d "$dir" ] && directory_has_content "$dir"; then
            echo "  - $dir (${ilias_directories[$dir]}) - EXISTS WITH CONTENT (will be preserved)"
        else
            echo "  - $dir (${ilias_directories[$dir]}) - WILL BE CREATED"
        fi
    done

    if ! confirm "Do you want to continue?"; then
        echo_info "Cancelled."; exit 0
    fi

    # Create each directory and track success/failure
    for dir in "${!ilias_directories[@]}"; do
        if clean_and_create_directory "$dir" "${ilias_directories[$dir]}"; then
            echo_info "Directory $dir created succesufully!"
            ilias_success_count=$((ilias_success_count + 1))
        else
            ilias_failed_count=$((ilias_failed_count + 1))
        fi
    done

    # Summary
    echo_info "Directory operations summary:"
    echo_info "Successfully processed: $ilias_success_count"
    if [ $ilias_failed_count -gt 0 ]; then
        echo_error "Failed operations: $ilias_failed_count"
        echo_error "Please check the log file for details: $LOG_FILE"
        exit 1
    else
        echo_success "All directory operations completed successfully!"
    fi
}
main