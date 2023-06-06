#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

if [ -z "$secrets.DEV_HUB_URL" ]; then
  echo "set default devhub user"
  execute sfdx config set target-dev-hub=$DEV_HUB_ALIAS
fi

echo "Deleting old scratch org"
sfdx org:delete:scratch -p -o $SCRATCH_ORG_ALIAS

echo "Creating scratch ORG"
execute sfdx org:create:scratch -a $SCRATCH_ORG_ALIAS -f ./config/scratch-org-def.json

sfdx config set target-org=$SCRATCH_ORG_ALIAS

echo "Pushing changes to scratch org"
execute sfdx project deploy start -o $SCRATCH_ORG_ALIAS

echo "Make sure Org user is english"
sfdx force:data:record:update -s User -w "Name='User User'" -v "Languagelocalekey=en_US"

echo "Running Apex Tests"
execute sfdx apex run test -l RunLocalTests -w 30 -c -r human

echo "Running CLI Scanner"
execute sfdx scanner:run --target "force-app" --pmdconfig "ruleset.xml"

if [ -f "package.json" ]; then
  echo "Running jest tests"
  execute npm install
  execute npm run test:unit
fi