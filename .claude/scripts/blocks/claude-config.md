## Claude Code configuration

This project's Claude Code setup comes from claude-config. What it turns on is declared
in `.claude/claude-config.json`; run `/apply-claude-config` after editing that file.
Text between `claude-config:begin` and `claude-config:end` markers is owned by the suite
and rewritten by `/apply-claude-config refresh`: write your own notes outside the
markers, or delete the markers to keep a block as your own.
