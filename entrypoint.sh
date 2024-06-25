#!/bin/bash
set -e
rm -f /debunker-web/tmp/pids/server.pid
bundle exec rake db:create
bundle exec rake db:migrate
exec "$@"
