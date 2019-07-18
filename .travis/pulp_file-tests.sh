#!/usr/bin/env bash
# coding=utf-8

# From the pulp-server/pulp-api config-map
echo "machine localhost
login admin
password password\
" > ~/.netrc

pushd pulp_file/docs/_scripts
# Let's only do sync tests.
# So as to check that Pulp can work in containers, including writing to disk.
# If the upload tests are simpler in the long run, just use them.
#
# TODO: Investigate why launching this script the regular way
# works in Fedora, but not in Ubuntu.
# Probably because sh is bash in Fedora, but dash in Ubuntu.
  bash -x docs_check_sync_publish.sh
popd

