#!/bin/bash
set -e
rm -f /debunker-api/tmp/pids/server.pid
bundle exec rake db:create
bundle exec rake db:migrate
exec "$@"
