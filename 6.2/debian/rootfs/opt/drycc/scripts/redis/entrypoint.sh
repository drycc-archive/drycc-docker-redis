#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load Redis environment variables
. /opt/drycc/scripts/redis-env.sh

# Load libraries
# . /opt/drycc/scripts/libbitnami.sh
. /opt/drycc/scripts/libredis.sh

# print_welcome_page

if [[ "$*" = *"/opt/drycc/scripts/redis/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting Redis setup **"
    /opt/drycc/scripts/redis/setup.sh
    info "** Redis setup finished! **"
fi

echo ""
exec "$@"
