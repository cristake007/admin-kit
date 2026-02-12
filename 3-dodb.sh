#!/bin/bash

# Import common functions
source functions.sh
export STEP="ILIAS LMS - DATABASE CREATION"
echo_log "Script initiated"
#======================================================
# DATABASE
#======================================================



if [[ -f /opt/env ]]; then
    source /opt/env
    echo_log "ENV File present"
else
    echo_error "Configuration variables not found. Please run init.sh first."
    exit 1
fi

display_box "Domain Configuration Script
This script will configure:
1. Get domain name (e.g., example.com)
2. Get admin email address
3. Get ILIAS database name and create DB
4. Get database user name and create user
5. Save credentials to env for later use"

confirm_continue

#===========================================
# VALIDATION FUNCTIONS
#===========================================

# Validate domain name format
validate_domain() {
    local domain=$1
    local domain_regex='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$'
    [[ $domain =~ $domain_regex ]]
}

# Validate email address format
validate_email() {
    local email=$1
    local email_regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    [[ $email =~ $email_regex ]]
}

# Execute MySQL commands with transaction support
execute_mysql_transaction() {
    local commands="$1"
    local error_msg="$2"
    
    local tmp_file=$(mktemp)
    cat > "$tmp_file" << EOL
START TRANSACTION;
$commands
COMMIT;
EOL

    if mysql < "$tmp_file" 2>/dev/null; then
        rm "$tmp_file"
        return 0
    else
        mysql -e "ROLLBACK;"
        rm "$tmp_file"
        echo_error "$error_msg"
        return 1
    fi
}

#===========================================
# DOMAIN CONFIGURATION
#===========================================

echo_info "Domain Configuration"

while true; do
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    if validate_domain "$DOMAIN"; then
        echo_success "Domain name validated: $DOMAIN"
        echo_log "Domain valid"
        break
    else
        echo_error "Invalid domain format: $DOMAIN"
        echo_info "Domain name should:"
        echo_info "- Start with a letter or number"
        echo_info "- Contain only letters, numbers, and hyphens"
        echo_info "- End with a valid TLD (e.g., .com, .org, .net)"
    fi
done

#===========================================
# ADMIN EMAIL CONFIGURATION
#===========================================

echo_info "Administrator Email Configuration"

while true; do
    read -p "Enter administrator email address: " ADMIN_EMAIL
    if validate_email "$ADMIN_EMAIL"; then
        echo_success "Email address validated: $ADMIN_EMAIL"
        echo_log "Admin email valid"
        break
    else
        echo_error "Invalid email format: $ADMIN_EMAIL"
        echo_info "Email should:"
        echo_info "- Be in standard format (user@domain.com)"
        echo_info "- Contain valid characters only"
        echo_info "- Have a valid domain extension"
    fi
done

#===========================================
# DATABASE CREATION
#===========================================

echo_info "Database Creation"

while true; do
    read -p "Enter ILIAS database name: " ILIAS_DB_NAME

    if [[ -z "${ILIAS_DB_NAME}" ]]; then
        echo_error "Database name cannot be empty"
        continue
    fi

    if [[ ! "${ILIAS_DB_NAME}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo_error "Invalid database name format"
        echo_info "Requirements:"
        echo_info "- Must start with a letter or underscore"
        echo_info "- Can contain letters, numbers, and underscores"
        continue
    fi

    if mysql -e "SHOW DATABASES LIKE '${ILIAS_DB_NAME}'" | grep -q "${ILIAS_DB_NAME}"; then
        echo_error "Database '${ILIAS_DB_NAME}' already exists"
        continue
    fi

    DB_COMMANDS="CREATE DATABASE \`${ILIAS_DB_NAME}\` CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    if execute_mysql_transaction "$DB_COMMANDS" "Database creation failed"; then
        echo_success "Database '${ILIAS_DB_NAME}' created successfully"
        echo_log "Database created"
        break
    fi
done

#===========================================
# DATABASE USER CREATION
#===========================================

echo_info "Database User Creation"

while true; do
    read -p "Enter ILIAS database username: " ILIAS_DB_USER

    if [[ -z "${ILIAS_DB_USER}" ]]; then
        echo_error "Username cannot be empty"
        continue
    fi

    if [[ ! "${ILIAS_DB_USER}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo_error "Invalid username format"
        echo_info "Requirements:"
        echo_info "- Must start with a letter or underscore"
        echo_info "- Can contain letters, numbers, and underscores"
        continue
    fi

    if mysql -e "SELECT 1 FROM mysql.user WHERE user = '${ILIAS_DB_USER}'" | grep -q '1'; then
        echo_error "User '${ILIAS_DB_USER}' already exists"
        continue
    fi

    ILIAS_DB_PASS=$(openssl rand -base64 32)
    USER_COMMANDS="
    CREATE USER '${ILIAS_DB_USER}'@'localhost' IDENTIFIED BY '${ILIAS_DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${ILIAS_DB_NAME}\`.* TO '${ILIAS_DB_USER}'@'localhost';
    FLUSH PRIVILEGES;"
    
    if execute_mysql_transaction "$USER_COMMANDS" "User creation failed"; then
        echo_success "Database user created successfully"
        echo_log "Database user created"
        break
    fi
done

#===========================================
# SAVE CREDENTIALS
#===========================================

echo_info "Saving DB credentials..."

cat > /root/ilias_db_credentials.txt << EOL
Database Name: ${ILIAS_DB_NAME}
Database User: ${ILIAS_DB_USER}
Database Password: ${ILIAS_DB_PASS}
EOL

chmod 600 /root/ilias_db_credentials.txt

if save_env_var "DOMAIN" "ADMIN_EMAIL" "ILIAS_DB_NAME" "ILIAS_DB_USER" "ILIAS_DB_PASS"; then
    echo_success "Configuration saved successfully"
    echo_info "Domain: $DOMAIN"
    echo_info "Admin Email: $ADMIN_EMAIL"
    echo_info "ILIAS_DB_NAME: $ILIAS_DB_NAME"
    echo_info "ILIAS_DB_USER: $ILIAS_DB_USER"
    echo_info "ILIAS_DB_PASS: $ILIAS_DB_PASS"
    echo_info "Credentials saved to: /root/ilias_db_credentials.txt"
    echo_log "Credentials saved successfully"
else
    echo_error "Failed to save configuration variables"
    exit 1
fi
