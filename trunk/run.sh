#/bin/bash -eu

# /usr/local/bin/dev_appserver.py --clear_datastore .  "$@"
# /usr/local/bin/dev_appserver.py --clear_datastore --debug .  "$@"
/usr/local/bin/dev_appserver.py . "$@"