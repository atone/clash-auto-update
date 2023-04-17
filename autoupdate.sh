#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
tmp_dir=/tmp
https_proxy=http://127.0.0.1:7890

get_latest_release() {
    curl --silent "https://github.com/Dreamacro/clash/releases/tag/premium" |
    grep '  <title>Release Premium ' |
    sed -E 's/[^.^0-9]//g'
}

is_latest_version_installed() {
    # Check that the installed version is at least as high as the available version.
    local available_version=$1
    local installed_version=$2

    # dpkg version comparison uses exit codes so we'll tolerate errors temporarily.
    set +eu
    dpkg --compare-versions "$available_version" gt "$installed_version"
    local result="$?"
    set -eu

    echo ${result}
}

write_log() {
    local full_message="[clash-auto-updater] $*"
    logger "${full_message}"
}

latest_release_tag=$(get_latest_release)

download_and_install_package() {
    local arch=$(uname -m)
    [ $arch == 'x86_64' ] && local board_id='amd64';
    [ $arch == 'aarch64' ] && local board_id='arm64';
    [ $arch == 'armv7' ] && local board_id='armv7';
    [ $arch == 'armv5' ] && local board_id='armv5';

    wget -q https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-$board_id-$latest_release_tag.gz -P $tmp_dir
    gzip -df $tmp_dir/clash-linux-$board_id-$latest_release_tag.gz
    chmod +x $tmp_dir/clash-linux-$board_id-$latest_release_tag
    systemctl stop clash
    mv $tmp_dir/clash-linux-$board_id-$latest_release_tag /usr/local/bin/clash
    systemctl start clash
}

installed_version=$(clash -v | awk '{print $2}')
is_latest=$(is_latest_version_installed "$latest_release_tag" "$installed_version")

if [ "$is_latest" -eq "0" ]; then
    write_log "Installed version: ${installed_version}"
    write_log "Latest available version: ${latest_release_tag}"
    write_log "Update available. Trying to download and install"
    download_and_install_package
else

    write_log "No updates available"
fi
