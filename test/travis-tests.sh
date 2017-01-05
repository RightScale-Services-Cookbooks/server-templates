#!/bin/bash -ex
cd ..
find . -name '*.sh' -exec shellcheck -e SC1008 {} \;
