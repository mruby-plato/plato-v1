#!/bin/bash
if [ "$(uname)" == 'Darwin' ]; then
  open -a ~/plato/.plato/plato-darwin-x64/plato.app
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  ~/plato/.plato/plato-linux-ia32/plato &
fi
