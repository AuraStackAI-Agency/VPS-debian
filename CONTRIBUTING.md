# Contributing to Local LLM Automation Stack

First off, thank you for considering contributing to this project! 🎉

The following is a set of guidelines for contributing. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates.

**When submitting a bug report, please include:**
- A clear and descriptive title
- Steps to reproduce the behavior
- Expected behavior
- Actual behavior
- System information (OS, Docker version, etc.)
- Relevant logs or screenshots

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues.

**When suggesting an enhancement, please include:**
- A clear and descriptive title
- Step-by-step description of the suggested enhancement
- Why this enhancement would be useful
- Possible implementation approaches

### 🔧 Pull Requests

**Good pull requests** - patches, improvements, new features - are a fantastic help.

**Please follow these steps:**

1. **Fork the repo** and create your branch from `main`.
2. **Make your changes** with clear, descriptive commit messages.
3. **Test your changes** thoroughly.
4. **Update documentation** if needed (README, ARCHITECTURE, etc.).
5. **Submit a pull request** with a clear description of the problem and solution.

---

## Development Setup

### Prerequisites
- Docker & Docker Compose
- Git
- Node.js 18+ (for MCP development)
- Debian/Ubuntu server (for testing)

### Local Setup
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/local-llm-automation-stack.git
cd local-llm-automation-stack

# Create environment file
cp examples/env.example .env
# Edit .env with your test values

# Start the stack
docker-compose -f examples/docker-compose.example.yml up -d

# View logs
docker-compose logs -f
```

---

## Code Style

### Bash Scripts
- Use `#!/bin/bash` shebang
- Include `set -e` for error handling
- Add comments for complex logic
- Use descriptive variable names (UPPERCASE for globals)

Example:
```bash
#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/opt/backups"
RETENTION_DAYS=7

# Function to create backup
create_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "Creating backup at ${timestamp}..."
}
```

### JSON/YAML
- Use 2 spaces for indentation
- Validate syntax before committing
- Comment configuration options

### Markdown
- Use proper heading hierarchy
- Add code fences with language specification
- Keep lines under 120 characters for readability

---

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>: <subject>

<body (optional)>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add PostgreSQL backup rotation script

docs: Update MCP-GUIDE with troubleshooting section

fix: Correct UFW port configuration in hardening script
```

---

## Testing Guidelines

### Before Submitting a PR

**For Scripts:**
- Run with `bash -x` to verify logic
- Test on a clean Debian 11/12 instance
- Verify idempotency (can run multiple times safely)

**For Docker Configs:**
- Test with `docker-compose config` to validate syntax
- Ensure containers start successfully
- Verify health checks pass

**For Documentation:**
- Check for broken links
- Validate Mermaid diagrams render correctly
- Spell-check content

---

## Areas We Need Help With

### 🎯 High Priority
- [ ] Monitoring integration (Netdata/Grafana templates)
- [ ] Kubernetes deployment manifests
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Additional example N8N workflows

### 🔧 Medium Priority
- [ ] Ansible playbooks for automated deployment
- [ ] Terraform modules for cloud providers
- [ ] Multi-architecture Docker builds (ARM64)
- [ ] Performance benchmarking suite

### 📚 Documentation
- [ ] Video tutorials
- [ ] Translations (French, German, Spanish)
- [ ] Architecture decision records (ADRs)
- [ ] FAQ section

---

## Community

- Join discussions in [GitHub Discussions](https://github.com/AuraStackAI-Agency/local-llm-automation-stack/discussions)
- Report security vulnerabilities privately via email
- Follow the [Code of Conduct](#code-of-conduct)

---

## Code of Conduct

### Our Pledge
We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards
**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behavior includes:**
- Trolling, insulting/derogatory comments
- Public or private harassment
- Publishing others' private information
- Other conduct that could reasonably be considered inappropriate

### Enforcement
Project maintainers have the right to remove, edit, or reject contributions that do not align with this Code of Conduct.

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Questions?

Don't hesitate to open an issue with the `question` label or start a discussion!

Thank you for contributing! 🙏
