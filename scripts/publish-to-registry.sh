#!/bin/bash
set -e

SCHEMA_REGISTRY_URL="http://ondash:30081"

echo "Checking Schema Registry connectivity..."
if ! curl -s -f "$SCHEMA_REGISTRY_URL/subjects" > /dev/null 2>&1; then
  echo "ERROR: Cannot connect to Schema Registry at $SCHEMA_REGISTRY_URL"
  echo "Please ensure the Schema Registry is running and accessible."
  exit 1
fi
echo "✓ Schema Registry is reachable"

# Prepare chat schema for upload
echo "Preparing chat schema..."
CHAT_PAYLOAD=$(jq -n --rawfile schema schemas/chat/v1/chat.proto '{schemaType: "PROTOBUF", schema: $schema}')

# Upload to registry
echo "Uploading chat schema to registry..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "$CHAT_PAYLOAD" \
  "$SCHEMA_REGISTRY_URL/subjects/chat-messages-value/versions")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "✓ Chat schema uploaded successfully: $BODY"
else
  echo "ERROR: Failed to upload chat schema (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

# Prepare upload schema for upload
echo "Preparing upload schema..."
UPLOAD_PAYLOAD=$(jq -n --rawfile schema schemas/upload/v1/upload.proto '{schemaType: "PROTOBUF", schema: $schema}')

# Upload to registry
echo "Uploading upload schema to registry..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "$UPLOAD_PAYLOAD" \
  "$SCHEMA_REGISTRY_URL/subjects/upload-messages-value/versions")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "✓ Upload schema uploaded successfully: $BODY"
else
  echo "ERROR: Failed to upload upload schema (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

echo ""
echo "All schemas uploaded successfully!"