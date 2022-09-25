#!/bin/bash

# Get credentials from AWS for the initial run
. "$(cd "$(dirname "$0")"; pwd)/utils.sh"

# Helper function to gracefully shut down our child processes when we exit.
clean_exit() {
    for PID in "${NGINX_PID}" "${CERTBOT_LOOP_PID}"; do
        if kill -0 "${PID}" 2>/dev/null; then
            kill -SIGTERM "${PID}"
            wait "${PID}"
        fi
    done
}

# Run nginx in non daemon mode
nginx -g "daemon off;"
NGINX_PID=$!
RENEWAL_INTERVAL='10'

(
set -e
while [ true ]; do
    storeAWSTemporarySecurityCredentials
    # Calling Lua script to renew certificates
    # /usr/bin/lua /etc/nginx/conf.d/lua/renew_certificates.lua

    # The "if" statement afterwards is to enable us to terminate this sleep
    # process (via the HUP trap) without tripping the "set -e" setting.
    info "Autorenewal service will now sleep ${RENEWAL_INTERVAL}"
    sleep "${RENEWAL_INTERVAL}" || x=$?; if [ -n "${x}" ] && [ "${x}" -ne "143" ]; then exit "${x}"; fi
done
) &
CERTBOT_LOOP_PID=$!

# A helper function to prematurely terminate the sleep process, inside the
# autorenewal loop process, in order to immediately restart the loop again
# and thus reload any configuration files.
reload_configs() {
    info "Received SIGHUP signal; terminating the autorenewal sleep process"
    if ! pkill -15 -P ${CERTBOT_LOOP_PID} -fx "sleep ${RENEWAL_INTERVAL}"; then
        warning "No sleep process found, this most likely means that a renewal process is currently running"
    fi
    # On success we return 128 + SIGHUP in order to reduce the complexity of
    # the final wait loop.
    return 129
}

# Create a trap that listens to SIGHUP and runs the reloader function in case
# such a signal is received.
trap "reload_configs" HUP

# Nginx and the certbot update-loop process are now our children. As a parent
# we will wait for both of their PIDs, and if one of them exits we will follow
# suit and use the same status code as the program which exited first.
# The loop is necessary since the HUP trap will make any "wait" return
# immediately when triggered, and to not exit the entire program we will have
# to wait on the original PIDs again.
while [ -z "${exit_code}" ] || [ "${exit_code}" = "129" ]; do
    wait -n ${NGINX_PID} ${CERTBOT_LOOP_PID}
    exit_code=$?
done
exit ${exit_code}

