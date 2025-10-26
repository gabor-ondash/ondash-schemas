# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Protocol Buffer schema repository for Ondash AI, serving as the single source of truth for data structures shared across multiple services (frontend TypeScript, backend Python, Kafka, etc.). The repository uses protobuf to generate type-safe code in multiple languages.

## Architecture

**Schema Organization**: Schemas are organized by domain under `schemas/` with versioned subdirectories:
- `schemas/chat/v1/` - Chat message structures with content blocks (text, confirmation, chart, data preview)
- `schemas/upload/v1/` - File upload metadata

**Multi-Language Code Generation**:
- TypeScript output goes to `dist/` (for npm publishing)
- Python output goes to `src/yourcompany_schemas/` (package name should be updated)
- Uses `ts-proto` for TypeScript generation and `protoc` native compiler for Python

**Publishing**: Package is published to GitHub Package Registry as `@ondash-ai/schemas` (see `publishConfig` in package.json)

## Common Commands

### Setup
```bash
npm install  # Install dependencies (ts-proto, jq) - required before first build
```

Note: `jq` is also required for the Kafka registry upload script. Install with: `brew install jq` (macOS)

### Build Commands
```bash
npm run build:ts    # Generate TypeScript code to ../ondash-frontend/src/types/schemas
npm run build:py    # Generate Python code to ../ondash-llm/src/adapters/kafka/models
npm run build       # Generate both TypeScript and Python
```

### Publishing to Schema Registry
```bash
npm run kafka                # Upload proto schemas to Redpanda Schema Registry at ondash:30081
npm run kafka:configure      # Enable schema validation on Kafka topics
npm run console:configure    # Configure Redpanda Console to deserialize protobuf messages (one-time setup)
```

### Versioning
```bash
npm version [major|minor|patch]  # Automatically runs build and stages changes
```

Note: The TypeScript and Python builds output to sibling project directories, not to `dist/` and `src/` within this repo.

### Direct protoc Usage
The scripts use these underlying commands:

**TypeScript**:
```bash
protoc --plugin=./node_modules/.bin/protoc-gen-ts_proto \
  --ts_proto_out=dist \
  --ts_proto_opt=esModuleInterop=true \
  --ts_proto_opt=outputIndex=true \
  schemas/**/*.proto
```

**Python**:
```bash
protoc --python_out=src/yourcompany_schemas \
  --pyi_out=src/yourcompany_schemas \
  schemas/**/*.proto
```

## Schema Design Patterns

**Message Metadata Pattern**: The `chat.v1.Message` includes a comprehensive `MessageMetadata` structure tracking:
- Tool execution (ToolCall records with timing)
- Token usage and model version
- Error information
- User/session context
- Service processing tags

**Content Block Pattern**: Uses protobuf `oneof` to support multiple content types (TextBlock, ConfirmationBlock, ChartBlock, DataPreviewBlock) in a type-safe way.

**Versioning**: Schemas use package versioning (e.g., `chat.v1`) to support backward compatibility. Breaking changes should increment the version directory.

## Kafka Topics and Schema Validation

**Topics**: `chat-messages` and `upload-messages`

**Schema Enforcement**: After uploading schemas, run `npm run kafka:configure` to enable validation. This ensures messages conform to the registered protobuf schemas.

**Redpanda Console**: Run `npm run console:configure` (one-time setup) to enable protobuf deserialization in the UI at http://ondash:30011

**Producing Messages**: Use `rpk` with the ondash profile:
```bash
# Chat messages (schema id: 2)
rpk topic produce chat-messages --profile ondash --schema-id 2 --schema-type chat.v1.Message

# Upload messages (schema id: 1)
rpk topic produce upload-messages --profile ondash --schema-id 1 --schema-type upload.v1.Message
```

Or use the test script:
```bash
npm run kafka:test  # Produces test messages to both topics
```

Provide JSON matching the proto structure - `rpk` will encode to protobuf.

## Important Notes

- **Cross-project builds**: The build scripts output to sibling project directories:
  - TypeScript → `../ondash-frontend/src/types/schemas`
  - Python → `../ondash-llm/src/adapters/kafka/models`
- **Redpanda Schema Registry**: Configured to upload to `http://ondash:30081` (running in Kubernetes)
  - Port mappings: Schema Registry (30081), Kafka (30092), Pandaproxy (30082)
  - The script uploads schemas in JSON format with `schemaType: "PROTOBUF"`
  - Subject naming: `<topic-name>-value` (e.g., `chat-messages-value`)
- **npm lifecycle hooks**: Builds run automatically before publishing (`prepublishOnly`) and on version bumps (`version`)
- **Dependencies**: Requires `protoc` (Protocol Buffers compiler), `jq` (JSON processor), and `rpk` (Redpanda CLI) installed on the system
