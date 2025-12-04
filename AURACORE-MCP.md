# AuraCore MCP Server

> **Project & Context Management for AI Agents**

AuraCore is a Model Context Protocol (MCP) server that provides persistent project management, context storage, and decision tracking for Claude Desktop and other MCP-compatible AI agents.

---

## Purpose

AuraCore solves key challenges for AI agents:

1. **Context Persistence** - Store business rules, patterns, and conventions that persist across conversations
2. **Project Tracking** - Manage projects and tasks with priorities and dependencies
3. **Anti-Hallucination** - Decision logging creates an audit trail of what was decided and why
4. **Session Memory** - Key-value store for temporary information during conversations

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Desktop                        │
│                          │                               │
│                     MCP Protocol                         │
│                          │                               │
│              ┌───────────▼───────────┐                   │
│              │   AuraCore MCP Server │                   │
│              │      (Node.js)        │                   │
│              └───────────┬───────────┘                   │
│                          │                               │
│              ┌───────────▼───────────┐                   │
│              │     SQLite Database   │                   │
│              │   (~/.auracore/db)    │                   │
│              └───────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## Database Schema

### Tables

#### `projects`
Track work initiatives with status and type.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID primary key |
| name | TEXT | Project name |
| description | TEXT | Project description |
| type | TEXT | feature, bugfix, refactor, spike, maintenance |
| status | TEXT | active, paused, completed, archived |
| workspace_path | TEXT | Path to workspace directory |
| created_at | TEXT | ISO timestamp |
| updated_at | TEXT | ISO timestamp |

#### `context`
Store persistent business knowledge.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID primary key |
| project_id | TEXT | Optional project association |
| type | TEXT | business_rule, pattern, convention, glossary, document, decision |
| name | TEXT | Context name/title |
| content | TEXT | Detailed content |
| category | TEXT | Organization category |
| priority | TEXT | critical, high, medium, low |
| created_at | TEXT | ISO timestamp |
| updated_at | TEXT | ISO timestamp |

#### `tasks`
Manage work items within projects.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID primary key |
| project_id | TEXT | Parent project |
| title | TEXT | Task title |
| description | TEXT | Task description |
| status | TEXT | pending, in_progress, completed, blocked |
| priority | TEXT | critical, high, medium, low |
| type | TEXT | setup, implementation, testing, documentation |
| depends_on | TEXT | JSON array of task IDs |
| estimated_time | TEXT | Time estimate (e.g., "2h", "1d") |
| completed_at | TEXT | Completion timestamp |

#### `session_memory`
Temporary key-value storage with optional TTL.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID primary key |
| session_id | TEXT | Session identifier |
| key | TEXT | Memory key |
| value | TEXT | Stored value |
| expires_at | TEXT | Optional expiration timestamp |

#### `decision_log`
Audit trail for AI decisions.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID primary key |
| project_id | TEXT | Associated project |
| decision_type | TEXT | Type (architecture, implementation, etc.) |
| input_context | TEXT | Context that led to decision |
| decision | TEXT | The decision made |
| confidence | REAL | Confidence level 0-1 |
| reasoning | TEXT | Explanation of reasoning |
| was_correct | INTEGER | Feedback flag |

---

## Available Tools (15 total)

### Project Management

| Tool | Description |
|------|-------------|
| `auracore_create_project` | Create a new project |
| `auracore_list_projects` | List projects by status |
| `auracore_get_project` | Get project details with tasks |
| `auracore_update_project` | Update project properties |

### Context Management

| Tool | Description |
|------|-------------|
| `auracore_store_context` | Store business rules, patterns, conventions |
| `auracore_query_context` | Search context by type, category, or keyword |
| `auracore_delete_context` | Remove context entry |

### Task Management

| Tool | Description |
|------|-------------|
| `auracore_create_task` | Create task with priority and dependencies |
| `auracore_update_task` | Update task status or priority |
| `auracore_get_next_tasks` | Get prioritized next tasks |

### Session Memory

| Tool | Description |
|------|-------------|
| `auracore_remember` | Store key-value with optional TTL |
| `auracore_recall` | Retrieve value by key |
| `auracore_forget` | Delete key from memory |

### Decision Logging

| Tool | Description |
|------|-------------|
| `auracore_log_decision` | Log decision with reasoning |
| `auracore_get_decisions` | Retrieve decision history |

---

## Tool Schemas

### auracore_create_project
```json
{
  "name": "string (required)",
  "description": "string",
  "type": "feature | bugfix | refactor | spike | maintenance",
  "workspace_path": "string"
}
```

### auracore_store_context
```json
{
  "type": "business_rule | pattern | convention | glossary | document | decision (required)",
  "name": "string (required)",
  "content": "string (required)",
  "project_id": "string",
  "category": "string",
  "priority": "critical | high | medium | low"
}
```

### auracore_create_task
```json
{
  "project_id": "string (required)",
  "title": "string (required)",
  "description": "string",
  "priority": "critical | high | medium | low",
  "type": "setup | implementation | testing | documentation",
  "depends_on": ["task_id_1", "task_id_2"],
  "estimated_time": "string"
}
```

### auracore_remember
```json
{
  "key": "string (required)",
  "value": "string (required)",
  "session_id": "string (default: 'default')",
  "ttl_minutes": "number"
}
```

### auracore_log_decision
```json
{
  "decision_type": "string (required)",
  "decision": "string (required)",
  "project_id": "string",
  "input_context": "string",
  "confidence": "number (0-1)",
  "reasoning": "string"
}
```

---

## Usage Examples

### Store a Business Rule
```
Use auracore_store_context with:
- type: "business_rule"
- name: "API Rate Limiting"
- content: "All external API calls must implement exponential backoff with max 3 retries"
- priority: "high"
```

### Track a Project
```
1. auracore_create_project: name="Auth Refactor", type="refactor"
2. auracore_create_task: title="Audit current auth code", priority="high"
3. auracore_create_task: title="Design new auth flow", depends_on=[task1_id]
4. auracore_update_task: task_id=X, status="completed"
```

### Log Important Decisions
```
auracore_log_decision with:
- decision_type: "architecture"
- decision: "Use JWT tokens instead of sessions"
- reasoning: "Stateless auth scales better for microservices"
- confidence: 0.85
```

---

## File Structure

```
auracore-mcp/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts      # MCP server entry point
│   ├── database.ts   # SQLite initialization and helpers
│   ├── tools.ts      # Tool implementations
│   └── types.ts      # TypeScript interfaces
└── dist/             # Compiled JavaScript
```

---

## Dependencies

| Package | Purpose |
|---------|--------|
| @modelcontextprotocol/sdk | MCP server framework |
| sql.js | Pure JavaScript SQLite |
| uuid | Generate unique IDs |
| zod | Schema validation |

---

## Data Location

- **Database**: `~/.auracore/auracore.db`
- **Config**: Claude Desktop config references the MCP server

---

## Integration with VPS AuraCore API

The local AuraCore MCP (Claude Desktop) and VPS AuraCore API are **independent systems**:

| Component | Location | Purpose |
|-----------|----------|--------|
| AuraCore MCP | Local (Windows/Mac) | Project/context management for Claude Desktop |
| AuraCore API | VPS | Infrastructure diagnostics with Qwen+Phi consensus |

They can optionally sync rules/context, but operate independently by default.
