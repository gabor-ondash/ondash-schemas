# Chat Protocol Buffers Schemas v1

This directory contains Protocol Buffer schema definitions for the ONDASH LLM chat system.

## Schema Files

### `events.proto`

**Purpose**: Real-time event streaming during task execution

**Used for**: Kafka topics for live status updates to frontend

**Message Types**:
- `EventEnvelope` - Base wrapper for all events
- `StatusEvent` - Step-by-step execution status
- `TextEvent` - Text content to display (before/after/standalone)
- `ChartEvent` - Chart visualizations (ECharts JSON config)
- `ErrorEvent` - Error notifications
- `CompletionEvent` - Task/conversation completion

**Kafka Topics**:
- `ondash.llm.status` - StatusEvent messages
- `ondash.llm.text` - TextEvent messages
- `ondash.llm.chart` - ChartEvent messages
- `ondash.llm.error` - ErrorEvent messages
- `ondash.llm.complete` - CompletionEvent messages

**Example Flow**:
```
User: "Create a chart with sales data"

Backend emits to Kafka:
  1. StatusEvent: "Decomposing query..."
  2. StatusEvent: "Executing chart_generation..."
  3. StatusEvent: "Querying database..."
  4. TextEvent: "Here is your sales chart" (BEFORE)
  5. ChartEvent: {chart_type: "bar", config_json: "..."}
  6. TextEvent: "Sales increased in Q4" (AFTER)
  7. CompletionEvent: "Task completed"
```

### `chat.proto`

**Purpose**: Persistent conversation messages

**Used for**: Storing and retrieving full conversation history

**Message Types**:
- `Message` - A single message (user or assistant)
- `ContentBlock` - Content within message (text, chart, etc.)
- `MessageMetadata` - Execution info, token usage, errors

**Example**:
```json
Message {
  id: "msg_123"
  conversation_id: "conv_456"
  role: "assistant"
  timestamp: 2025-10-29T10:30:00Z
  content: [
    TextBlock { text: "Here is your chart" },
    ChartBlock { chart_type: "bar", config_json: "{...}" },
    TextBlock { text: "Sales increased in Q4" }
  ]
  metadata: {
    tasks: [
      { task_id: "task_1", scenario: "chart_generation", state: "completed" }
    ]
    execution_time_ms: 2500
    tokens_used: 1200
  }
}
```

## Design Principles

1. **Events vs Messages**:
   - Events = Real-time updates during execution (streaming)
   - Messages = Final conversation records (persistence)

2. **JSON for Dynamic Content**:
   - Chart configs use `string config_json` for flexibility
   - Frontend parses and passes directly to ECharts

3. **Timestamps**:
   - Use `google.protobuf.Timestamp` for consistency

4. **Enums**:
   - Defined for fixed sets (TextPosition, ErrorSeverity, CompletionType)

## Code Generation

Generate Python code:
```bash
cd /Users/monogab/Workspace/ondash/ondash-schemas

protoc --python_out=../ondash-llm/src/adapters/kafka/models/ \
       --pyi_out=../ondash-llm/src/adapters/kafka/models/ \
       --proto_path=. \
       schemas/chat/v1/*.proto
```

Generated files will be in:
- `ondash-llm/src/adapters/kafka/models/schemas/chat/v1/events_pb2.py`
- `ondash-llm/src/adapters/kafka/models/schemas/chat/v1/chat_pb2.py`

## Versioning

This is version 1 (`v1`). When making breaking changes:
1. Create new directory: `schemas/chat/v2/`
2. Update package: `package chat.v2;`
3. Support both versions during transition
