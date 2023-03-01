#!/usr/bin/env bash
# should set MIRRORZ_HELP_HOME and MIRROR_WEB_HOME
# dependencies: node, perl, jq, curl

if ! command -v node &> /dev/null
then
    echo "node could not be found"
    exit 1
fi

if ! command -v perl &> /dev/null
then
    echo "perl could not be found"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit 1
fi

if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    exit 1
fi

if [ -z "$MIRRORZ_HELP_HOME" ]; then
    echo "MIRRORZ_HELP_HOME not set"
    exit 1
fi

MIRRORZ_HELP_CONTENT_PATH="${MIRRORZ_HELP_HOME}/contents"
TRANSPILER_PATH="${MIRRORZ_HELP_HOME}/custom/tuna/transpiler.js"

if [ -z "$MIRROR_WEB_HOME" ]; then
    echo "MIRROR_WEB_HOME not set"
    exit 1
fi

CNAME_JSON_URL=${CNAME_JSON_URL:-"https://mirrorz.org/static/json/cname.json"}

CNAME_JSON_PATH=$(mktemp $TMPDIR/cname.json.XXXXXX)
trap 'rm -rf -- "$CNAME_JSON_PATH"' EXIT

curl -qo $CNAME_JSON_PATH $CNAME_JSON_URL

declare -a TRANSPILE_LIST=(
    "1970-01-01-archlinux.md"
    "1970-01-01-chef.md"
    "1970-01-01-debian.md"
    "1970-01-01-gitlab-ce.md"
    "1970-01-01-gitlab-runner.md"
    "1970-01-01-mongodb.md"
    "1970-01-01-mysql.md"
    "1970-01-01-proxmox.md"
    "1970-01-01-raspbian.md"
    "1970-01-01-ros2.md"
    "1970-01-01-ros.md"
    "1970-01-01-rudder.md"
    "1970-01-01-ubuntu.md"
    "1970-01-01-ubuntu-ports.md"
    "2016-06-19-virtualbox.md"
    "2019-02-15-grafana.md"
    "2021-05-25-influxdata.md"
    "2022-01-07-erlang-solutions.md"
    "2022-07-23-llvm-apt.md"
    "2022-08-03-wine-builds.md"
)

for md in "${TRANSPILE_LIST[@]}"; do
    md="${MIRROR_WEB_HOME}/help/_posts/${md}"
    # 'mirrorid: '.length == 10, then xargs to trim
    tuna_name=$(grep mirrorid $md | cut -c 11- | xargs)
    cname=$(jq ".\"${tuna_name}\"" $CNAME_JSON_PATH | tr -d '"')
    if [[ $cname -eq "" ]]; then
        cname=$tuna_name
    fi
    if [ -f "$MIRRORZ_HELP_CONTENT_PATH/$cname.mdx" ]; then
        echo "$tuna_name"
        node $TRANSPILER_PATH "$MIRRORZ_HELP_CONTENT_PATH/$cname.mdx" $tuna_name > $md
        # replace [text](/slug/) to [text](/help/slug/)
        perl -pi -e 's|\[([\s\S]*?)\]\(/([\s\S]*?)/\)|[\1](/help/\2)|g' $md
    else
        echo "! $tuna_name: $cname.mdx"
    fi
done
