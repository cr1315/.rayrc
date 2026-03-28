#!/usr/bin/env bash


claude.init() {
    local prompt_text=$(cat <<- 'EOF'
		Analyze this codebase and generate .claude/CLAUDE.md with:
		- project overview and structure
		- build/test commands
		- architecture patterns and key modules
		- platform-specific notes
	EOF
    )

    claude \
        -p "${prompt_text}" \
        --allowedTools "Read,Write,Glob,Bash"
}
