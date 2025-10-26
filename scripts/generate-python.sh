#!/bin/bash
set -e

OUTPUT_DIR="../ondash-llm/src/adapters/kafka/models"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Find all .proto files and pass them to protoc
PROTO_FILES=$(find schemas -name "*.proto")

protoc \
  --python_out=$OUTPUT_DIR \
  --pyi_out=$OUTPUT_DIR \
  $PROTO_FILES

# Create __init__.py files
find $OUTPUT_DIR -type d -exec touch {}/__init__.py \;

echo "Python generation complete"