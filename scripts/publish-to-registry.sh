#!/bin/bash

SCHEMA_REGISTRY_URL="http://localhost:8081"

# Compile to descriptor
protoc --descriptor_set_out=chat.desc \
  --include_imports \
  schemas/chat/v1/message.proto

# Upload to registry
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary @chat.desc \
  "$SCHEMA_REGISTRY_URL/subjects/chat-messages-value/versions"