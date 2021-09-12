#!/bin/bash
#
# Shows the current net energy consumption of the house. A positive value
# means that we're producing more energy from solar than we're consuming.  A
# negative value means we're using more energy than we're producing.

export PATH="/usr/local/bin:$PATH"
eval "$(rbenv init -)"

cd ~/dev/teslurp
source .env
#bundle install > /dev/null 2>&1
bundle exec ruby t.rb --load
