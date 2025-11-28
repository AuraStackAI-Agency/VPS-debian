# MCP Integration Guide

> **Control Your Linux VPS from Claude Desktop via Model Context Protocol**

This guide walks you through setting up full remote access to your VPS infrastructure directly from Claude Desktop on Windows/macOS using the Model Context Protocol (MCP).

---

## 🎯 What is MCP?

**Model Context Protocol** is a standard that allows AI assistants (like Claude) to interact with external systems through a unified interface.

**Why it matters:**
- Give Claude "hands" to control your infrastructure
- Execute commands, query databases, restart services
- All from natural language in Claude Desktop

---

## 🏗️ Architecture Overview

```
┌──────────────────────────┐
│   Claude Desktop App     │
│   (Your Laptop)          │
│                          │
│  "Restart N8N worker 2"  │
└────────────┬─────────────┘
             │
             │ MCP Protocol
             │ (JSON-RPC)
             ▼
┌──────────────────────────┐       SSH Tunnel
│  MCP Wrapper Server      │◄─────────────────┐
│  (VPS)                   │                  │
│                          │                  │
│  • Authentication        │                  │
│  • Command Whitelisting  │                  │
│  • Sandboxed Execution   │                  │
└────────────┬─────────────┘                  │
             │                                │
             ▼                                │
┌──────────────────────────┐                  │
│   Target Services        │                  │
│  • Docker                │                  │
│  • PostgreSQL            │                  │
│  • System Commands       │                  │
└──────────────────────────┘                  │
                                              │
                                    Your SSH Key
```

---

## 🔧 Setup: Remote VPS Access

### Prerequisites

✅ SSH access to your VPS with key authentication  
✅ Claude Desktop installed (Windows/macOS)  
✅ Node.js 18+ on your VPS

---

### Step 1: Install MCP Wrapper on VPS

SSH into your VPS and run:

```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y nodejs npm

# Create MCP directory
mkdir -p /opt/mcp-wrapper
cd /opt/mcp-wrapper

# Install MCP server package
npm install @modelcontextprotocol/server-vps
```

---

### Step 2: Configure MCP Wrapper

Create `/opt/mcp-wrapper/config.json`:

```json
{
  "server": {
    "name": "vps-automation",
    "version": "1.0.0",
    "port": 3000
  },
  "security": {
    "whitelist_commands": [
      "docker ps",
      "docker logs",
      "docker restart",
      "systemctl status",
      "df -h",
      "free -m"
    ],
    "blocked_patterns": [
      "rm -rf",
      "dd if=",
      "mkfs"
    ]
  },
  "ssh": {
    "host": "YOUR_VPS_IP",
    "port": 22,
    "user": "YOUR_SSH_USER",
    "private_key_path": "/path/to/your/ssh/key"
  }
}
```

---

### Step 3: Create Systemd Service

Create `/etc/systemd/system/mcp-wrapper.service`:

```ini
[Unit]
Description=MCP Wrapper for VPS Remote Access
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mcp-wrapper
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable mcp-wrapper
sudo systemctl start mcp-wrapper
```

---

### Step 4: Configure Claude Desktop

On your Windows/macOS machine, edit:

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`  
**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

Add:

```json
{
  "mcpServers": {
    "vps-automation": {
      "command": "ssh",
      "args": [
        "-T",
        "YOUR_SSH_USER@YOUR_VPS_IP",
        "node /opt/mcp-wrapper/server.js"
      ]
    }
  }
}
```

---

### Step 5: Test the Connection

Restart Claude Desktop, then in a conversation:

```
You: Can you list the Docker containers running on my VPS?
```

Claude should now be able to execute `docker ps` remotely and return the result.

---

## 🛠️ Available Tools

Once configured, Claude has access to **7 powerful tools**:

### 1. `execute_command`
Execute whitelisted SSH commands.

**Example:**
```
You: Check disk usage on my VPS
Claude: [Executes: df -h]
```

---

### 2. `list_docker_containers`
List all running Docker containers with status.

**Example:**
```
You: Show me all running containers
Claude: 
- n8n-main-prod (Running, 3 days)
- ollama (Running, 7 days)
- postgres (Running, healthy)
```

---

### 3. `check_docker_logs`
Fetch logs from a specific container.

**Example:**
```
You: Show me the last 50 lines of n8n-main logs
Claude: [Fetches: docker logs --tail 50 n8n-main-prod]
```

---

### 4. `restart_docker_container`
Restart a specific service.

**Example:**
```
You: Restart the N8N worker 2
Claude: [Executes: docker restart n8n-worker-2-prod]
✅ Container n8n-worker-2-prod restarted successfully
```

---

### 5. `check_system_resources`
Monitor CPU, RAM, and disk usage.

**Example:**
```
You: What's the current resource usage?
Claude:
CPU: 23% (12 vCPUs)
RAM: 18.5 GB / 45 GB (41%)
Disk: 95 GB / 296 GB (34%)
```

---

### 6. `diagnose_vps`
Run a full system health check.

**Example:**
```
You: Diagnose my VPS and tell me if anything is wrong
Claude: Running full diagnostic...
✅ All Docker containers healthy
✅ PostgreSQL responding
⚠️ Disk usage at 34% (monitor if >80%)
✅ No failed systemd services
```

---

### 7. `query_postgres`
Execute read-only SQL queries on PostgreSQL.

**Example:**
```
You: How many workflows are active in N8N?
Claude: [Executes: SELECT COUNT(*) FROM workflow WHERE active = true]
Result: 4 active workflows
```

---

## 🔒 Security Best Practices

### 1. Command Whitelisting
Only allow safe, pre-approved commands:

```json
{
  "whitelist_commands": [
    "docker ps",
    "docker logs --tail",
    "docker restart",
    "systemctl status",
    "psql -c 'SELECT'"
  ]
}
```

### 2. Blocked Patterns
Explicitly block dangerous operations:

```json
{
  "blocked_patterns": [
    "rm -rf",
    "dd if=",
    "mkfs",
    "DROP DATABASE",
    "chmod 777"
  ]
}
```

### 3. SSH Key Authentication
Never use password authentication:

```bash
# Disable password auth in /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
```

### 4. Audit Logging
Log all MCP commands:

```bash
# MCP wrapper automatically logs to:
/var/log/mcp-wrapper.log
```

---

## 🚀 Real-World Use Cases

### Use Case 1: Incident Response
```
You: The website is down, diagnose and fix it.

Claude:
1. Checking Uptime Kuma... ✅ Detecting N8N webhook timeout
2. Checking N8N logs... ⚠️ Worker 2 OOM error detected
3. Restarting n8n-worker-2-prod... ✅ Restarted
4. Verifying... ✅ All workflows executing normally
```

---

### Use Case 2: Proactive Monitoring
```
You: Every morning at 9am, send me a health report of my VPS

Claude: I'll create a summary:
- ✅ All 9 containers running
- ✅ CPU avg 15% (last 24h)
- ⚠️ PostgreSQL DB size: 4.2 GB (growing 200MB/day)
- ✅ Last backup: 8 hours ago
```

---

### Use Case 3: Ad-Hoc Queries
```
You: Which N8N workflows ran in the last hour and how many succeeded?

Claude: [Queries PostgreSQL]
- PDF Extraction: 12 executions, 12 success
- Telegram Audit: 3 executions, 3 success
- MCP Task Executor: 1 execution, 1 success
```

---

## 🧪 Testing Your Setup

### Test 1: Basic Command
```
You: Run 'uptime' on my VPS
```
Expected: Claude returns system uptime.

### Test 2: Docker Interaction
```
You: List all running Docker containers
```
Expected: List of containers with status.

### Test 3: Complex Workflow
```
You: Restart the Ollama service and verify it's running
```
Expected:
1. Claude restarts container
2. Waits 10 seconds
3. Confirms service is running

---

## 🐛 Troubleshooting

### MCP Server Not Responding

**Check:**
```bash
# Is the service running?
sudo systemctl status mcp-wrapper

# Check logs
sudo journalctl -u mcp-wrapper -n 50
```

---

### SSH Connection Refused

**Check:**
```bash
# Can you SSH manually?
ssh YOUR_USER@YOUR_VPS_IP

# Is SSH key configured correctly?
ssh -vvv YOUR_USER@YOUR_VPS_IP
```

---

### Claude Can't See MCP Tools

**Check:**
1. Restart Claude Desktop
2. Verify `claude_desktop_config.json` syntax (use JSONLint)
3. Check MCP server logs on VPS

---

## 📚 Advanced Configuration

### Custom Tool: Deploy N8N Workflow

Add to MCP wrapper:

```javascript
{
  "name": "deploy_workflow",
  "description": "Deploy a new N8N workflow from JSON",
  "handler": async (workflowJson) => {
    const response = await fetch('https://n8n.your-domain.com/api/v1/workflows', {
      method: 'POST',
      headers: { 'X-N8N-API-KEY': process.env.N8N_API_KEY },
      body: JSON.stringify(workflowJson)
    });
    return await response.json();
  }
}
```

---

## 🔗 Resources

- [MCP Official Docs](https://modelcontextprotocol.io/)
- [Claude Desktop MCP Guide](https://www.anthropic.com/mcp)
- [Example MCP Servers](https://github.com/modelcontextprotocol/servers)

---

## 🎓 Next Steps

1. ✅ Set up remote MCP access
2. ⬜ Configure custom tools for your workflow
3. ⬜ Set up monitoring alerts via MCP
4. ⬜ Integrate with N8N for automation

---

**Questions?** Open an issue in the repo or start a discussion!
