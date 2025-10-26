#!/bin/bash
set -e

OUTPUT_DIR="dist"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

protoc \
  --plugin=./node_modules/.bin/protoc-gen-ts_proto \
  --ts_proto_out=$OUTPUT_DIR \
  --ts_proto_opt=esModuleInterop=true \
  --ts_proto_opt=outputIndex=true \
  schemas/**/*.proto

echo "TypeScript generation complete"