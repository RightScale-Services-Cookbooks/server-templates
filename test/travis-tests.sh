#!/bin/bash
exit_code=0
while IFS= read -r -d $'\0' line; do
    shellcheck -e SC1008 "$line"
    let "exit_code += $?"
    echo $exit_code
done< <(find . -type f -iname "*.sh" -not -path rightlink_scripts -print0)
echo "Number of Errors: $exit_code"
exit $exit_code
