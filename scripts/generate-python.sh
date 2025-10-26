
#!/bin/bash
set -e

OUTPUT_DIR="src/yourcompany_schemas"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

protoc \
  --python_out=$OUTPUT_DIR \
  --pyi_out=$OUTPUT_DIR \
  schemas/**/*.proto

# Create __init__.py files
find $OUTPUT_DIR -type d -exec touch {}/__init__.py \;

echo "Python generation complete"