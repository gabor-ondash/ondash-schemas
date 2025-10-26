# Code Generation


Use the scripts from the scripts folder. 

If that is not enough, here are the commands:

```bash
#!/bin/bash
# generate.sh

# TypeScript for Frontend
protoc --ts_proto_out=frontend/src/types schemas/chat.proto

# Python for AI Agent & Backend
protoc --python_out=backend/generated --pyi_out=backend/generated schemas/chat.proto

# GraphQL Schema (via intermediate JSON)
protoc --plugin=protoc-gen-jsonschema --jsonschema_out=. schemas/chat.proto
node scripts/jsonschema-to-graphql.js

# Kafka Schema Registry
protoc --descriptor_set_out=schemas/chat.desc schemas/chat.proto
# Upload to Schema Registry
curl -X POST -H "Content-Type: application/octet-stream" \
  --data-binary @schemas/chat.desc \
  http://schema-registry:8081/subjects/chat-messages-value/versions
```