#!/bin/bash
set -e

OUTPUT_DIR="../ondash-frontend/src/types/schemas"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Find all .proto files and pass them to protoc
PROTO_FILES=$(find schemas -name "*.proto")

protoc \
  --plugin=./node_modules/.bin/protoc-gen-ts_proto \
  --ts_proto_out=$OUTPUT_DIR \
  --ts_proto_opt=esModuleInterop=true \
  --ts_proto_opt=outputIndex=true \
  $PROTO_FILES

echo "TypeScript generation complete"