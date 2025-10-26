#!/bin/bash

echo "Testing message production with schema validation..."
echo ""

# Test upload message
echo "Producing upload message..."
echo '{"id":"test-upload-1","filename":"test.txt","path":"/uploads/test.txt","timestamp":1698765432}' | \
  rpk topic produce upload-messages \
    --profile ondash \
    --schema-id 1 \
    --schema-type upload.v1.Message

echo ""
echo "Producing chat message..."
echo '{"id":"test-msg-1","chat_id":"chat-1","role":"user","timestamp":1698765432,"content":[{"type":"text","text":{"text":"Test message"}}],"metadata":{"user_id":"user1","session_id":"sess1","execution_time_ms":10,"tokens_used":5,"model_version":"test","processed_by_service":"test","tags":{}}}' | \
  rpk topic produce chat-messages \
    --profile ondash \
    --schema-id 2 \
    --schema-type chat.v1.Message

echo ""
echo "✓ Messages produced! Check Redpanda Console at http://ondash:30011"
echo ""
echo "To view messages:"
echo "  rpk topic consume upload-messages --profile ondash --num 1"
echo "  rpk topic consume chat-messages --profile ondash --num 1"
