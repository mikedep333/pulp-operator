#!/usr/bin/env bash
# coding=utf-8

pushd pulp_file/docs/_scripts
# Let's only do sync tests.
# So as to check that Pulp can work in containers, including writing to disk.
# If the upload tests are simpler in the long run, just use them.
source docs_check_sync_publish.sh
popd

