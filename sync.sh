#! /usr/bin/env bash

set -e

cur_hash=$(git rev-parse HEAD)

while IFS= read -r sync_path; do

   remote_hash=$(git ls-remote "$sync_path" HEAD 2>/dev/null | cut -f1 || echo "")

   if [ "$cur_hash" != "$remote_hash" ]; then
        git push --force "$sync_path" main
   fi

  done < ".sync/sync_locs"
