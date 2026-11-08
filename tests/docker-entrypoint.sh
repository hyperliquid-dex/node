#!/usr/bin/env bash
# Offline path-resolution regression; does not build an image or run hl-visor.
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workdir=''
download_path=''
entrypoint=''
default_username=''
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    case "$line" in
        'ARG USERNAME='*) default_username=${line#ARG USERNAME=} ;;
        'WORKDIR '*) workdir=${line#WORKDIR } ;;
        'RUN curl -o '*)
            path=${line#RUN curl -o }
            path=${path%% *}
            [[ "$path" != */hl-visor ]] || download_path=$path
            ;;
        'ENTRYPOINT ["'*)
            entrypoint=${line#ENTRYPOINT [\"}
            entrypoint=${entrypoint%%\"*}
            ;;
    esac
done < "$repo_dir/Dockerfile"

[[ -n "$default_username" && -n "$workdir" && -n "$download_path" && -n "$entrypoint" ]]
image_root=$(mktemp -d)
trap 'rm -rf "$image_root"' EXIT

for username in "$default_username" entrypoint_test_user; do
    image="$image_root/$username"
    working_dir=${workdir//\$USERNAME/$username}
    binary_path=${download_path//\$USERNAME/$username}
    mkdir -p "$image$working_dir" "$(dirname "$image$binary_path")"
    # Stand in for the downloaded executable without contacting a node/network.
    printf '#!/bin/sh\nexit 0\n' > "$image$binary_path"
    chmod +x "$image$binary_path"
    executable=$entrypoint
    [[ "$executable" != /* ]] || executable="$image$executable"
    if ! (cd "$image$working_dir" && "$executable"); then
        printf 'FAIL USERNAME=%s: ENTRYPOINT %s cannot run from %s\n' "$username" "$entrypoint" "$working_dir" >&2
        exit 1
    fi
    printf 'PASS USERNAME=%s: ENTRYPOINT %s runs from %s\n' "$username" "$entrypoint" "$working_dir"
done
