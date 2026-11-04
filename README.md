# Model router: setup

## Claude app (claude.ai, desktop, mobile)

Upload the .skill file in Settings > Capabilities > Skills, or use the Save skill button on the file card. Replace the older version if you installed one. In the app the skill recommends a model for each step and tells you when to switch. It can't flip the model selector for you, and the app has no hooks, so routing there relies on the skill description and your saved preferences.

## Claude Code

1. Copy the skill folder to `~/.claude/skills/model-router/`.
2. Copy the four files in `agents/` to `~/.claude/agents/` so every project can use them.
3. Make routing run on every message. Copy `hooks/route-reminder.sh` to `~/.claude/hooks/` and add this to `~/.claude/settings.json` (merge with any `hooks` block you already have):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/route-reminder.sh" }
        ]
      }
    ]
  }
}
```

The hook fires each time you send a prompt, including "continue" and follow-ups, so every new subtask gets routed.

4. As a backup, add this line to `~/.claude/CLAUDE.md`:

```
At the start of every task and on every continuation, use the model-router skill to route the next subtask to the right worker subagent.
```

5. Run `/agents` and check that haiku-worker, sonnet-worker, opus-worker and fable-worker show up. Run `/hooks` and check the UserPromptSubmit hook is listed.

If `claude-fable-5-1` isn't available on your plan, change the `model:` line in `fable-worker.md` to `opus`.

## Cost note

If `CLAUDE_CODE_SUBAGENT_MODEL` is set in your shell, it overrides the `model:` field in every worker and the routing stops working. Unset it, or set it to `inherit`.
