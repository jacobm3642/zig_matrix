#! /usr/bin/env bash

set -e

cur_hash=$(git rev-parse HEAD)

while IFS= read -r sync_path; do
    remote_hash=$(git ls-remote "$sync_path" HEAD | cut -f1)
    
    if [ "$cur_hash" != "$remote_hash" ]; then
        git push "$sync_path" main
    fi
done < ".sync/sync_locs"
