#!bin/bash

# export TZ=UTC
# export COFIG_FILE=./config.json
# export GITHUB_STEP_SUMMARY=./summary.md

function dateFrom2Date() {
  DATE_FROM=$1
  DATE_FORMAT="+%Y-%m-%dT%H:%M:%SZ"

  # date -v $DATE_FROM $DATE_FORMAT // for Mac
  date --date "$DATE_FROM" $DATE_FORMAT
}

function retriveField() {
  TARGET=$1
  FIELD=$2
  echo -e $TARGET | jq ".$FIELD" | tr -d '"'
}

function searchUrl() {
  MAP=$1
  TYPE=$2

  AUTHOR=$(retriveField "$MAP" 'author')
  OWNER=$(retriveField "$MAP" 'owner')
  REPO=$(retriveField "$MAP" 'repo')
  DATE_FROM=$(retriveField "$MAP" 'date_from')
  DATE=$(dateFrom2Date "$DATE_FROM")

  BASE=$(echo "https://api.github.com/search/issues?q=repo:$OWNER/$REPO+author:$AUTHOR+created:>$DATE")
  case $TYPE in
    pr)
      echo $BASE+is:pull-request
      ;;
    issue)
      echo $BASE+is:issue
      ;;
    *)
      echo 'search url type must be one of [pr, issue]'
      exit 1
      ;;
  esac
}

# fetch and save date to tmp file
tmpfile=$(mktemp)
cat $COFIG_FILE | jq -c '.[]' | while read item;do
  urls=("$(searchUrl "$item" 'issue')" "$(searchUrl "$item" 'pr')")

  for url in "${urls[@]}"; do
    echo $url
    result=$(curl -sSL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN"\
      -H "X-GitHub-Api-Version: 2022-11-28" \
      $url)

    err=$(echo $result | jq 'select(.items==null)')
    if [[ $err =~ .+ ]]; then
      echo $err | jq .
      continue
    fi

    echo $result | jq -r '.items[] | {title: .title, author: .user.login, url: .html_url, created_at: .created_at}' >> $tmpfile
  done
done

# write header
cat <<EOS >> $GITHUB_STEP_SUMMARY
| Author | Title | URL | CreatedAt |
| ------ | ----- | --- | --------- |
EOS

# write rows
jq -s . $tmpfile | jq -c '.[]' | while read line;do
  AUTHOR=$(retriveField "$line" 'author')
  TITLE=$(retriveField "$line" 'title')
  URL=$(retriveField "$line" 'url')
  CREATED_AT=$(retriveField "$line" 'created_at')
  echo "| $AUTHOR | $TITLE | $URL | $CREATED_AT |" >> $GITHUB_STEP_SUMMARY
done

rm $tmpfile
