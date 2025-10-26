#!/bin/bash
set -e

echo "Configuring Kafka topics with schema validation..."

# Configure chat-messages topic with schema validation
echo "Configuring chat-messages topic..."
rpk topic alter-config chat-messages --profile ondash \
  --set redpanda.value.schema.id.validation=true \
  --set redpanda.value.schema.id.validation.compat.level=BACKWARD

echo "✓ chat-messages configured with schema validation"

# Configure upload-messages topic with schema validation
echo "Configuring upload-messages topic..."
rpk topic alter-config upload-messages --profile ondash \
  --set redpanda.value.schema.id.validation=true \
  --set redpanda.value.schema.id.validation.compat.level=BACKWARD

echo "✓ upload-messages configured with schema validation"

echo ""
echo "Schema validation enabled! The topics will now enforce:"
echo "  - chat-messages → uses schema chat-messages-value (id: 2)"
echo "  - upload-messages → uses schema upload-messages-value (id: 1)"
echo ""
echo "Test producing messages with:"
echo "  npm run kafka:test"
echo ""
echo "Or manually:"
echo "  rpk topic produce chat-messages --profile ondash --schema-id 2 --schema-type chat.v1.Message"
echo "  rpk topic produce upload-messages --profile ondash --schema-id 1 --schema-type upload.v1.Message"
