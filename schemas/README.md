# Ondash Schemas

Protocol Buffer schema definitions for Ondash AI services.

## Using These Schemas

This directory contains `.proto` files only. To use them in your service:

### 1. Reference the schemas

The schemas are expected to be in a sibling directory `../ondash-schemas/schemas/` relative to consuming repositories.

### 2. Add code generation to your project

Below are example scripts for different languages:

#### Go (example for ondash-socket)

Create `scripts/generate-schemas.sh`:
```bash
#!/bin/bash
set -e

SCHEMA_DIR="../ondash-schemas"
OUTPUT_DIR="internal/pb"

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Find all .proto files
PROTO_FILES=$(find $SCHEMA_DIR/schemas -name "*.proto")

protoc \
  --go_out=$OUTPUT_DIR \
  --go_opt=paths=source_relative \
  --proto_path=$SCHEMA_DIR \
  $PROTO_FILES

echo "✓ Go schemas generated -> $OUTPUT_DIR"
```

Add to your Go project's Makefile or run manually:
```bash
chmod +x scripts/generate-schemas.sh
./scripts/generate-schemas.sh
```

**Prerequisites**:
```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go get google.golang.org/protobuf
```

#### Python (example for ondash-llm)

Create `scripts/generate-schemas.sh`:
```bash
#!/bin/bash
set -e

SCHEMA_DIR="../ondash-schemas"
OUTPUT_DIR="src/adapters/kafka/models"

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Find all .proto files
PROTO_FILES=$(find $SCHEMA_DIR/schemas -name "*.proto")

protoc \
  --python_out=$OUTPUT_DIR \
  --pyi_out=$OUTPUT_DIR \
  --proto_path=$SCHEMA_DIR \
  $PROTO_FILES

# Create __init__.py files
find $OUTPUT_DIR -type d -exec touch {}/__init__.py \;

echo "✓ Python schemas generated -> $OUTPUT_DIR"
```

**Prerequisites**: `protoc` installed (Python support is built-in)

#### TypeScript (example for ondash-frontend)

Create `scripts/generate-schemas.sh`:
```bash
#!/bin/bash
set -e

SCHEMA_DIR="../ondash-schemas"
OUTPUT_DIR="src/types/schemas"

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Find all .proto files
PROTO_FILES=$(find $SCHEMA_DIR/schemas -name "*.proto")

protoc \
  --plugin=./node_modules/.bin/protoc-gen-ts_proto \
  --ts_proto_out=$OUTPUT_DIR \
  --ts_proto_opt=esModuleInterop=true \
  --ts_proto_opt=outputIndex=true \
  --proto_path=$SCHEMA_DIR \
  $PROTO_FILES

echo "✓ TypeScript schemas generated -> $OUTPUT_DIR"
```

Add to package.json:
```json
{
  "scripts": {
    "generate:schemas": "bash scripts/generate-schemas.sh"
  },
  "devDependencies": {
    "ts-proto": "^2.4.0"
  }
}
```

**Prerequisites**: `npm install ts-proto`

### 3. Usage in code

#### Go
```go
import (
    chatpb "github.com/looptroops/socket/internal/pb/schemas/chat/v1"
)

func handleMessage(data []byte) error {
    var msg chatpb.Message
    if err := proto.Unmarshal(data, &msg); err != nil {
        return err
    }

    // Filter by chat_id
    if msg.ConversationId == targetChatID {
        // Process message
    }
    return nil
}
```

#### Python
```python
from adapters.kafka.models.schemas.chat.v1 import chat_pb2

def handle_message(data: bytes):
    msg = chat_pb2.Message()
    msg.ParseFromString(data)

    # Filter by chat_id
    if msg.conversation_id == target_chat_id:
        # Process message
        pass
```

#### TypeScript
```typescript
import { Message } from '@/types/schemas/schemas/chat/v1/chat';

function handleMessage(msg: Message) {
    // Filter by chat_id
    if (msg.conversationId === targetChatId) {
        // Process message
    }
}
```

## Schema Versions

- `chat/v1` - Chat messages and event streams
- `upload/v1` - File upload metadata

Breaking changes require incrementing the version directory (e.g., `v1` -> `v2`).
