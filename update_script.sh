#!/bin/bash
set -e

GIT_DIR=`mktemp -d`
SCRIPT_DIR=`mktemp -d`
trap "rm -rf $GIT_DIR $SCRIPT_DIR" 0 2 3 15

SCRIPT=$(realpath "$0")
CUR_DIR=$(pwd)

pushd "$GIT_DIR" > /dev/null
git clone "https://github.com/durenworks/laravel-script.git" .
HASH=$(git rev-parse HEAD)

mv "$SCRIPT" "$SCRIPT_DIR"
cp -Rf src/* "$CUR_DIR"
echo "$HASH" > "$CUR_DIR/script.ver"
