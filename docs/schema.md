# Schema Documentation

## Overview

This repository contains the **single source of truth** for Protocol Buffer schema definitions used across all Ondash services. It contains only `.proto` files - no generated code.

## Architecture

```
ondash-schemas/
├── schemas/                    # Protocol Buffer definitions
│   ├── chat/v1/
│   │   ├── chat.proto         # Chat messages and content blocks
│   │   └── events.proto       # Real-time event streaming
│   └── upload/v1/
│       └── upload.proto       # File upload metadata
├── scripts/                    # Kafka/Schema Registry scripts
│   ├── publish-to-registry.sh
│   ├── configure-topics.sh
│   └── test-produce.sh
└── docs/
    └── schema.md              # This file
```

## Consuming Services

This repository is referenced by three services, each generating code locally:

| Service | Language | Build Tool | Generation Command |
|---------|----------|------------|-------------------|
| ondash-socket | Go | Mage | `mage schemas` |
| ondash-llm | Python | Invoke | `invoke schemas` |
| ondash-frontend | TypeScript | npm | `npm run schemas` |

## Schema Organization

### Versioning Strategy

Schemas are organized by domain and version:
- `{domain}/{version}/{schema}.proto`
- Example: `chat/v1/chat.proto`, `chat/v1/events.proto`

**Version incrementing:**
- **v1 → v2**: Breaking changes (field removal, type changes)
- **Patch updates**: Additive changes (new optional fields)

### Go Package Options

All schemas include `go_package` option for Go code generation:

```protobuf
option go_package = "github.com/looptroops/socket/internal/pb/schemas/{domain}/{version}";
```

## Schema Domains

### chat/v1

**chat.proto** - Persistent chat messages
- `Message` - Complete chat message with metadata
- `ContentBlock` - Union type for different content (text, chart, confirmation, data preview)
- `MessageMetadata` - Tool calls, token usage, errors, user context

**events.proto** - Real-time event streaming
- `EventEnvelope` - Base envelope for all Kafka events
- `StatusEvent` - Progress updates during execution
- `TextEvent` - Text content chunks
- `ChartEvent` - Chart visualizations
- `ErrorEvent` - Error reporting with severity levels
- `CompletionEvent` - Task/conversation completion

### upload/v1

**upload.proto** - File upload tracking
- `Message` - File upload metadata (id, filename, path, timestamp)

## Workflow: Updating Schemas

### 1. Make Schema Changes

Edit the `.proto` files in the `schemas/` directory:

```bash
# Example: Add a new field to chat message
vim schemas/chat/v1/chat.proto
```

**Guidelines:**
- Use optional fields for non-breaking changes
- Never remove or rename existing fields (breaks compatibility)
- Add new message types for major changes
- Increment version (v1 → v2) for breaking changes

### 2. Upload to Schema Registry (Optional)

If using Kafka schema validation:

```bash
npm run kafka                # Upload schemas to Redpanda
npm run kafka:configure      # Enable topic validation
```

### 3. Notify Consuming Services

Consuming services decide when to pull updates:
- Create a GitHub release/tag
- Notify teams in Slack/email
- Document breaking changes in CHANGELOG

Services will regenerate code on their own schedule.

## Kafka Integration

### Schema Registry

Schemas are published to Redpanda Schema Registry at `http://ondash:30081`

**Commands:**
```bash
npm run kafka                # Upload schemas
npm run kafka:configure      # Enable validation
npm run kafka:test          # Test with sample messages
npm run console:configure    # Setup Redpanda Console UI
```

### Topics

- `chat-messages` - Uses `chat.v1.Message`
- `upload-messages` - Uses `upload.v1.Message`

### Message Production

Using `rpk` CLI:

```bash
# Chat messages (schema id: 2)
rpk topic produce chat-messages --profile ondash \
  --schema-id 2 \
  --schema-type chat.v1.Message

# Upload messages (schema id: 1)
rpk topic produce upload-messages --profile ondash \
  --schema-id 1 \
  --schema-type upload.v1.Message
```

Provide JSON matching the proto structure - `rpk` encodes to protobuf automatically.

## Development Setup

### Prerequisites

- `jq` - JSON processor for Kafka scripts
- `rpk` - Redpanda CLI for testing
- Access to Redpanda cluster at `ondash:30081`

### Installation

```bash
# macOS
brew install jq

# Install rpk
brew install redpanda-data/tap/redpanda
```

### Scripts

```bash
npm install              # Install jq dependency check
npm run kafka            # Upload to registry
npm run kafka:configure  # Configure topics
npm run kafka:test       # Test message production
```

## Best Practices

### Schema Design

✅ **Do:**
- Use optional fields for flexibility
- Add descriptive comments
- Use semantic versioning for packages
- Keep messages focused and cohesive
- Use `oneof` for union types

❌ **Don't:**
- Remove or rename existing fields
- Change field types (breaks deserialization)
- Use `required` (deprecated in proto3)
- Mix concerns in a single message

### Compatibility

**Backward Compatible Changes:**
- Adding new optional fields
- Adding new message types
- Adding new enum values (with default)

**Breaking Changes:**
- Removing fields
- Renaming fields
- Changing field types
- Changing field numbers

## Troubleshooting

### Schema Registry Upload Fails

Check Redpanda connectivity:
```bash
curl http://ondash:30081/subjects
```

### Kafka Topic Configuration Fails

Verify topics exist:
```bash
rpk topic list --profile ondash
```

### Message Production Fails

Validate JSON structure matches proto:
```bash
# Check schema structure
protoc --decode=chat.v1.Message schemas/chat/v1/chat.proto < message.bin
```

## References

- [Protocol Buffers Documentation](https://protobuf.dev/)
- [Redpanda Schema Registry](https://docs.redpanda.com/current/manage/schema-reg/)
- [ts-proto Documentation](https://github.com/stephenh/ts-proto)
- [Python Protobuf Guide](https://protobuf.dev/reference/python/)
- [Go Protobuf Tutorial](https://protobuf.dev/reference/go/)
