#!/bin/bash

# Helper function to gracefully shut down our child processes when we exit.
clean_exit() {
    for PID in "${NGINX_PID}" "${CERTBOT_LOOP_PID}"; do
        if kill -0 "${PID}" 2>/dev/null; then
            kill -SIGTERM "${PID}"
            wait "${PID}"
        fi
    done
}

# Other function to trigger certbot webroot renewal, TBD
