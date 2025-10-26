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
npm install  # Install dependencies (ts-proto) - required before first build
```

### Build Commands
```bash
npm run build:ts    # Generate TypeScript code from proto files
npm run build:py    # Generate Python code from proto files
npm run build       # Generate both TypeScript and Python
```

### Publishing
```bash
npm version [major|minor|patch]  # Automatically runs build and stages changes
bash scripts/publish-to-registry.sh  # Upload proto descriptor to Kafka Schema Registry (requires registry at localhost:8081)
```

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

## Important Notes

- The Python output directory is currently `src/yourcompany_schemas/` - this should be updated to match the actual company/project name
- The `publish-to-registry.sh` script is configured for a local Schema Registry at `http://localhost:8081` and only handles the chat schema
- npm lifecycle hooks run builds automatically before publishing (`prepublishOnly`) and on version bumps (`version`)
