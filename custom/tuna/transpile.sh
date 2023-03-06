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
    "1970-01-01-adoptium.md"
    #"1970-01-01-anaconda.md"
    #"1970-01-01-aosp.md"
    "1970-01-01-archlinuxarm.md"
    "1970-01-01-archlinuxcn.md"
    "1970-01-01-archlinux.md"
    #"1970-01-01-binutils-gdb.git.md"
    #"1970-01-01-centos-altarch.md"
    "1970-01-01-centos.md"
    "1970-01-01-centos-vault.md"
    "1970-01-01-chef.md"
    #"1970-01-01-chromiumos.md"
    #"1970-01-01-clickhouse.md"
    #"1970-01-01-CocoaPods.md"
    #"1970-01-01-crates.io-index.git.md"
    #"1970-01-01-cygwin.md"
    "1970-01-01-debian.md"
    #"1970-01-01-docker-ce.md"
    #"1970-01-01-elpa.md"
    "1970-01-01-elrepo.md"
    "1970-01-01-epel.md"
    "1970-01-01-fdroid.md"
    "1970-01-01-fedora.md"
    #"1970-01-01-flutter-sdk.git.md"
    #"1970-01-01-gcc.git.md"
    "1970-01-01-gitlab-ce.md"
    #"1970-01-01-gitlab-ci-multi-runner.md"
    "1970-01-01-gitlab-runner.md"
    #"1970-01-01-git-repo.md"
    #"1970-01-01-glibc.git.md"
    #"1970-01-01-hackage.md"
    #"1970-01-01-homebrew-bottles.md"
    #"1970-01-01-homebrew.md"
    #"1970-01-01-kubernetes.md"
    #"1970-01-01-lineageos.md"
    #"1970-01-01-lineage-rom.md"
    #"1970-01-01-linux-firmware.git.md"
    #"1970-01-01-linux.git.md"
    "1970-01-01-linuxmint.md"
    #"1970-01-01-linux-next.git.md"
    #"1970-01-01-linux-stable.git.md"
    "1970-01-01-lxc-images.md"
    "1970-01-01-mariadb.md"
    "1970-01-01-mongodb.md"
    "1970-01-01-msys2.md"
    "1970-01-01-mysql.md"
    #"1970-01-01-nodejs-release.md"
    #"1970-01-01-nodesource.md"
    #"1970-01-01-openmediavault.md"
    #"1970-01-01-openwrt.md"
    #"1970-01-01-packagist.md"
    "1970-01-01-proxmox.md"
    #"1970-01-01-pybombs.md"
    #"1970-01-01-pypi.md"
    #"1970-01-01-qemu.git.md"
    "1970-01-01-raspbian.md"
    "1970-01-01-repo-ck.md"
    "1970-01-01-ros2.md"
    "1970-01-01-ros.md"
    "1970-01-01-rpmfusion.md"
    "1970-01-01-rudder.md"
    "1970-01-01-stackage.md"
    #"1970-01-01-tensorflow.md"
    #"1970-01-01-termux.md"
    "1970-01-01-ubuntu.md"
    "1970-01-01-ubuntu-ports.md"
    "1970-01-01-voidlinux.md"
    #"2007-08-31-alpine.md"
    "2016-06-19-virtualbox.md"
    #"2016-06-21-repoforge.md"
    "2016-08-18-rubygems.md"
    "2017-01-12-bioconductor.md"
    "2017-01-17-CRAN.md"
    #"2017-05-28-llvm.md"
    #"2017-08-10-CTAN.md"
    #"2017-11-28-openthos-src.md"
    #"2017-12-29-gentoo-portage.md"
    "2018-09-28-anthon.md"
    "2019-02-15-grafana.md"
    "2019-02-15-rustup.md"
    #"2019-02-17-nix.md"
    "2019-02-25-dart-pub.md"
    #"2019-02-27-flutter.md"
    "2019-03-18-arch4edu.md"
    "2019-05-03-qubesos.md"
    "2019-06-25-solus.md"
    "2019-07-23-kicad.md"
    #"2020-02-21-gentoo-prefix.md"
    "2020-03-06-tlpretest.md"
    #"2020-05-05-gentoo-portage.git.md"
    #"2020-05-25-julia.md"
    #"2020-05-25-julia-releases.md"
    #"2020-09-10-llvm-project.git.md"
    #"2020-12-29-CPAN.md"
    "2021-01-01-ceph.md"
    "2021-03-11-opensuse.md"
    "2021-05-25-influxdata.md"
    "2021-07-14-ubuntu-cloud-images.md"
    "2021-12-23-qt.md"
    "2022-01-07-erlang-solutions.md"
    #"2022-01-08-ohmyzsh.git.md"
    #"2022-01-17-postmarketOS.md"
    #"2022-05-16-rosdistro.md"
    "2022-07-23-llvm-apt.md"
    "2022-08-03-bazel-apt.md"
    "2022-08-03-wine-builds.md"
    "2022-08-22-elasticsearch.md"
    "2022-09-05-entware.md"
    #"2022-09-22-pkgsrc.git.md"
    #"2022-09-22-pkgsrc.md"
    "2022-11-14-kali.md"
    "2023-01-23-openbsd.md"
    #"2023-01-30-netbsd.md"
    "2023-02-08-crates.io-index.md"
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
