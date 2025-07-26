#!/bin/sh

# Create htpasswd file if FILE_SERVER_AUTH is set
if [ -n "$FILE_SERVER_AUTH" ]; then
    echo "Setting up basic auth for file server..."
    
    # Parse username:password from env var
    USERNAME=$(echo "$FILE_SERVER_AUTH" | cut -d':' -f1)
    PASSWORD=$(echo "$FILE_SERVER_AUTH" | cut -d':' -f2)
    
    if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        # Install apache2-utils for htpasswd
        apk add --no-cache apache2-utils
        
        # Create htpasswd file
        htpasswd -cb /etc/nginx/.htpasswd "$USERNAME" "$PASSWORD"
        echo "Basic auth configured for user: $USERNAME"
    else
        echo "Invalid FILE_SERVER_AUTH format. Use: username:password"
        rm -f /etc/nginx/.htpasswd
    fi
else
    echo "No FILE_SERVER_AUTH set - file server will be open"
    rm -f /etc/nginx/.htpasswd
fi

# Start nginx
exec nginx -g 'daemon off;'