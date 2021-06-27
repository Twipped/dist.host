#!/bin/bash
TARGET="$(dirname $0)/dist"
HASH=$(find $TARGET -type f -print0 | sort -z | xargs -0 shasum | shasum | awk '{print $1;}')
echo -n "{\"hash\":\"${HASH}\"}"