#!/bin/bash
# colors from: http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURP='\033[0;35m'

echo -e "${PURP}Starting ShellCheck Tests!!${NC}"
sc_exit_code=0
while IFS= read -r -d $'\0' line; do
  echo -e "${CYAN}ShellChecking File:$line${NC}"
  shellcheck -x -e SC1008 -e SC1091 "$line"
  ((sc_exit_code += $?))
done< <(find . -type f -iname "*.sh" -not -path "./rightlink_scripts/*" -print0)
COLOR=$GREEN
if [ "$sc_exit_code" -gt 0 ]; then
  COLOR=$RED
fi

echo -e "${COLOR}Number of ShellCheck Errors: $sc_exit_code${NC}\n"

echo -e "${PURP}Starting PSScriptAnalyzer Tests!!${NC}"
ps_exit_code=0
while IFS= read -r -d $'\0' line; do
  echo -e "${CYAN}PSScriptAnalyzer File:$line${NC}"
  echo $PWD
  pwsh -File "$PWD/travis-tests.ps1" "$line"
  ((ps_exit_code += $?))
done< <(find . -type f -iname "*.sh" -not -path "./rightlink_scripts/*" -print0)
COLOR=$GREEN
if [ "$ps_exit_code" -gt 0 ]; then
  COLOR=$RED
fi

echo -e "${COLOR}Number of PSScriptAnalyzerErrors: $ps_exit_code${NC}\n"

echo "Installing right_st"
curl -s -o /tmp/right_st-linux-amd64.tgz https://binaries.rightscale.com/rsbin/right_st/v1.9.4/right_st-linux-amd64.tgz
tar -xzf /tmp/right_st-linux-amd64.tgz -C /tmp
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

echo -e "${PURP}Starting right_st validation!!${NC}"
rst_exit_code=0
while IFS= read -r -d $'\0' line; do
  echo -e "${YELLOW}right_st checking: $line${NC}"
  /tmp/right_st/right_st st validate "$line"
  ((rst_exit_code += $?))
done< <(find . -type f -iname '*.yml' -not -path './.travis.yml' -not -path './rightlink_scripts/*' -not -path './comparison/*' -print0)

COLOR=$GREEN
if [ "$rst_exit_code" -gt 0 ]; then
  COLOR=$RED
fi

echo -e "${COLOR}Number of right_st errors: $rst_exit_code${NC}"
# shellcheck disable=SC2219
let exit_code=sc_exit_code+rst_exit_code

exit "$exit_code"
