#!/bin/bash
set -e

# =============================================================================
# TOPICS TO CONFIGURE
# Add new topics here - they will be configured with schema validation
# =============================================================================
declare -a TOPICS=(
  "chat-messages"
  "upload-messages"
  "ondash.llm.status"
  "ondash.llm.complete"
  "ondash.llm.chart"
  "ondash.llm.text"
)

# Compatibility level: BACKWARD, FORWARD, FULL, NONE
COMPAT_LEVEL="BACKWARD"

# =============================================================================
# Configuration Function
# =============================================================================
configure_topic() {
  local topic=$1

  echo "🔧 Configuring topic: $topic"

  if rpk topic alter-config "$topic" --profile ondash \
    --set redpanda.value.schema.id.validation=true \
    --set redpanda.value.schema.id.validation.compat.level="$COMPAT_LEVEL" 2>/dev/null; then
    echo "   ✅ Configured with schema validation (compat: $COMPAT_LEVEL)"
  else
    echo "   ⚠️  Failed to configure (topic may not exist yet)"
    return 1
  fi
  echo ""
}

# =============================================================================
# Main Execution
# =============================================================================
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Configuring Kafka Topics with Schema Validation         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Topics to configure:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for topic in "${TOPICS[@]}"; do
  echo "   - $topic"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configure each topic
success_count=0
total_count=${#TOPICS[@]}

for topic in "${TOPICS[@]}"; do
  if configure_topic "$topic"; then
    ((success_count++))
  fi
done

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Summary                                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo "   Configured: $success_count / $total_count topics"
echo ""

if [ $success_count -gt 0 ]; then
  echo "✅ Schema validation enabled for configured topics!"
  echo ""
  echo "💡 Topics will now enforce schemas registered in Schema Registry"
  echo "💡 Compatibility level: $COMPAT_LEVEL"
  echo ""
  echo "📝 Test producing messages:"
  echo "   npm run kafka:test"
  echo ""
  echo "📝 Or manually with rpk:"
  echo "   rpk topic produce <topic> --profile ondash --schema-id <id> --schema-type <type>"
fi

if [ $success_count -lt $total_count ]; then
  echo ""
  echo "⚠️  Note: Some topics failed to configure (may not exist yet)"
  echo "   Create missing topics first, then run this script again"
fi
