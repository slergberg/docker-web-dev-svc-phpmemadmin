#!/usr/bin/env bash

set -x

healthcheck_server() {
  curl --fail --user "admin:admin" http://0.0.0.0:80 \
    || exit 1
}

healthcheck_server
