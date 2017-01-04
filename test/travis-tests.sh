#!/bin/bash -ex
cd ..
find . -name *.sh -exec shellcheck {} \;
