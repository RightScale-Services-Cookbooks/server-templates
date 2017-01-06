#!/bin/bash

echo "Starting ShellCheck Tests"
exit_code=0
while IFS= read -r -d $'\0' line; do
    echo "ShellChecking File:$line"
    shellcheck -x -e SC1008 -e SC1091 "$line"
    let "exit_code += $?"
done< <(find . -type f -iname "*.sh" -not -path "./rightlink_scripts/*" -print0)
echo "Number of ShellCheck Errors: $exit_code"

echo "Starting right_st validation"
curl -o /tmp/right_st-linux-amd64.tgz https://binaries.rightscale.com/rsbin/right_st/v1/right_st-linux-amd64.tgz
tar -xvzf /tmp/right_st-linux-amd64.tgz -C /tmp
export PATH=$PATH:/tmp/right_st
echo "$TRAVIS"
if [ "$TRAVIS" == true ]; then
cat <<-EOF> .right_st.yml
login:
  accounts:
    02-ci:
      host: us-4.rightscale.com
      id: $RIGHTST_ACCOUNT
      refresh_token: $RIGHTST_SERVER_TOKEN
  default_account: 02-pub
update:
  check: true
EOF
fi

right_st config show

exit $exit_code
