#!/bin/bash

echo "Starting ShellCheck Tests"
sc_exit_code=0
while IFS= read -r -d $'\0' line; do
  echo "ShellChecking File:$line"
  shellcheck -x -e SC1008 -e SC1091 "$line"
  let "sc_exit_code += $?"
done< <(find . -type f -iname "*.sh" -not -path "./rightlink_scripts/*" -print0)
echo "Number of ShellCheck Errors: $sc_exit_code"

echo "Starting right_st validation"
curl -o /tmp/right_st-linux-amd64.tgz https://binaries.rightscale.com/rsbin/right_st/v1/right_st-linux-amd64.tgz
tar -xvzf /tmp/right_st-linux-amd64.tgz -C /tmp
export PATH=$PATH:/tmp/right_st
echo "$TRAVIS"
if [ "$TRAVIS" == true ]; then
echo "creating travis config"
cat > /home/travis/.right_st.yml <<-EOF
login:
  accounts:
    02-ci:
      host: us-4.rightscale.com
      id: $RIGHTST_ACCOUNT
      refresh_token: $RIGHTST_SERVER_TOKEN
  default_account: 02-ci
update:
  check: true
EOF
fi

rst_exit_code=0
while IFS= read -r -d $'\0' line; do
  echo "right_st checking: $line"
  /tmp/right_st/right_st st validate "$line"
  let "rst_exit_code += $?"
done< <(find . -type f -iname '*.yml' -not -path './.travis.yml' -print0)
echo "Number of right_st errors: $rst_exit_code"
let exit_code=sc_exit_code+rst_exit_code
exit $exit_code
