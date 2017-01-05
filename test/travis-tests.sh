#!/bin/bash -ex
cd ..
find . -name '*.sh' ! -path ./rightlink_scripts -exec shellcheck -e SC1008 {} \;
