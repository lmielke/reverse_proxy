#!/bin/sh
set -e

# Inject both UI_PORT and UI_IP in one pass
envsubst '${UI_PORT} ${UI_IP}' < /etc/nginx/templates/open-web-ui.template \
    > /etc/nginx/conf.d/open-web-ui.conf

exec nginx -g 'daemon off;'
