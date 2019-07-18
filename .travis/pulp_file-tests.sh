#!/usr/bin/env bash
# coding=utf-8

# We would do this in .travis.yml before_install:, but then we do not know
# where it clones it.
git clone https://github.com/pulp/pulp_file.git

pushd pulp_file/docs/scripts
# Let's only do sync tests.
# So as to check that Pulp can work in containers, including writing to disk.
# If the upload tests are simpler in the long run, just use them.
source docs_check_sync_publish.sh
popd

