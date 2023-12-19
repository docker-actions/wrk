#!/usr/bin/env bash
set -Eeuo pipefail

set -Eeuo pipefail
exec wrk "$@"
