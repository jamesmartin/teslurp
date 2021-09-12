#!/bin/bash
#
# Shows the current State of Charge and Charging State of the Tesla.

export PATH="/usr/local/bin:$PATH"
eval "$(rbenv init -)"

cd ~/dev/teslurp
#bundle install > /dev/null 2>&1
bundle exec ruby t.rb --car
