# .claude/skills/claudemd/SKILL.md
## Generate CLAUDE.md
1. Analyze the full repo structure using Glob and Read
2. Identify: language, build system, test commands, deploy process
3. Write CLAUDE.md with sections: ## Overview, ## Build & Test Commands, ## Architecture, ## Conventions
4. If Python with poetry, prefix all commands with `poetry run`
5. If Terraform, document provider versions, backend config, and module structure
6. Ask user to review before finalizing

# Then run with: /claudemd
