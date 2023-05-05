#!/bin/bash -e

# Common config
. common/scripts/config.sh
# Cross build functions
. common/functions/relative_source.sh
relative_source common/functions/cross.sh
cross