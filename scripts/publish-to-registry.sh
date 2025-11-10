#!/bin/bash
set -e

SCHEMA_REGISTRY_URL="http://ondash:30081"

# =============================================================================
# TOPIC → SCHEMA MAPPING
# Add new topics here: "topic-name:path/to/schema.proto"
# =============================================================================
declare -a TOPIC_SCHEMA_MAP=(
  "chat-messages:schemas/chat/v1/chat.proto"
  "upload-messages:schemas/upload/v1/upload.proto"
  "ondash.llm.status:schemas/chat/v1/events.proto"
  "ondash.llm.complete:schemas/chat/v1/events.proto"
  "ondash.llm.chart:schemas/chat/v1/events.proto"
  "ondash.llm.text:schemas/chat/v1/events.proto"
)

# =============================================================================
# Schema Upload Function
# =============================================================================
upload_schema() {
  local topic=$1
  local schema_file=$2
  local subject="${topic}-value"

  echo "📤 Uploading schema for topic: $topic"
  echo "   Schema: $schema_file"
  echo "   Subject: $subject"

  # Prepare payload
  local payload=$(jq -n --rawfile schema "$schema_file" '{schemaType: "PROTOBUF", schema: $schema}')

  # Upload to registry
  local response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    -d "$payload" \
    "$SCHEMA_REGISTRY_URL/subjects/$subject/versions")

  local http_code=$(echo "$response" | tail -n1)
  local body=$(echo "$response" | sed '$d')

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo "   ✅ Success: $body"
  else
    echo "   ❌ ERROR: Failed to upload (HTTP $http_code)"
    echo "   Response: $body"
    return 1
  fi
  echo ""
}

# =============================================================================
# Main Execution
# =============================================================================
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Publishing Schemas to Redpanda Schema Registry          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check connectivity
echo "🔍 Checking Schema Registry connectivity..."
if ! curl -s -f "$SCHEMA_REGISTRY_URL/subjects" > /dev/null 2>&1; then
  echo "❌ ERROR: Cannot connect to Schema Registry at $SCHEMA_REGISTRY_URL"
  echo "Please ensure the Schema Registry is running and accessible."
  exit 1
fi
echo "✅ Schema Registry is reachable at $SCHEMA_REGISTRY_URL"
echo ""

# Display mapping
echo "📋 Topic → Schema Mapping:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for mapping in "${TOPIC_SCHEMA_MAP[@]}"; do
  topic="${mapping%%:*}"
  schema="${mapping##*:}"
  printf "   %-30s → %s\n" "$topic" "$schema"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Upload each schema
success_count=0
total_count=${#TOPIC_SCHEMA_MAP[@]}

for mapping in "${TOPIC_SCHEMA_MAP[@]}"; do
  topic="${mapping%%:*}"
  schema="${mapping##*:}"

  if upload_schema "$topic" "$schema"; then
    ((success_count++))
  else
    echo "⚠️  Continuing with remaining schemas..."
    echo ""
  fi
done

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Summary                                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo "   Uploaded: $success_count / $total_count schemas"
echo ""

if [ $success_count -eq $total_count ]; then
  echo "✅ All schemas uploaded successfully!"
  exit 0
else
  echo "⚠️  Some schemas failed to upload. Check errors above."
  exit 1
fi