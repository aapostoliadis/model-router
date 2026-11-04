---
name: model-router
description: Picks the right Claude model (Haiku, Sonnet, Opus or Fable) for every task and every subtask, and routes the work to it. In Claude Code it hands each subtask to a subagent pinned to that model; in the Claude app it tells the user which model fits each step and when to switch. Use this skill at the start of every task AND on every continuation of a task ("continue", "next step", "keep going", follow-ups, feedback on a previous step), re-routing each new subtask. Covers coding, research, writing, analysis, refactors, bug hunts and planning, and any mention of model choice, cost, speed, tokens, "which model", "use a cheaper model", "use the best model" or "/model".
---

# Model router

Your job is to size the work, pick the cheapest model that will do it well, and route it there. Picking too small wastes a retry. Picking too big wastes money and time. You route per subtask, not per conversation.

## When to run

Run this skill at three moments, every time:

1. **A task starts.** Break it into subtasks (Step 0), then route the first one.
2. **A task continues.** Any message that carries on existing work ("continue", "next", "keep going", "now do the tests", feedback on the last step) triggers a fresh routing of the next subtask. Don't reuse the last pick by default.
3. **The work changes shape mid-step.** If a subtask turns out harder or easier than scored (a worker replies "ESCALATE:", or a "hard" bug turns out to be a typo), stop and re-route.

A one-line question with a one-line answer needs no routing. Answer it directly.

## Step 0: break the task into subtasks

For anything with more than one step, write the subtasks to `tasks/todo.md` with a model tag on each line:

```
- [ ] [haiku] Collect all files touching session handling
- [ ] [opus] Design the new session model
- [ ] [sonnet] Implement the design in auth/session.ts
- [ ] [haiku] Run tests and lint, report failures
```

Score each subtask on its own with Step 1. When the task continues, read `tasks/todo.md`, take the next open item, re-check its tag against what you now know, and route it. Tick items off as they pass review. In the Claude app, with no file system, keep the same list in the reply instead.

## Step 1: size the task

Score the request on six signals, 0 to 2 each. Read the request and any attached files or repo context before scoring.

| Signal | 0 | 1 | 2 |
|---|---|---|---|
| Reasoning depth | Lookup, format, rename | A few connected steps | Multi-stage reasoning, trade-offs, proofs |
| Ambiguity | Clear spec, one right answer | Some gaps to fill | Open problem, needs judgement and framing |
| Scope | One file or short text | A handful of files or a long doc | Many files, whole system, big corpus |
| Stakes | Easy to undo | Visible to others | Production, executives, regulated, money |
| Novelty | Seen-it-before pattern | Some new pieces | No known recipe, or a past model already failed |
| Autonomy | One shot | A short tool loop | Long agentic run with many tool calls |

Add the scores (0 to 12) and map:

| Score | Model | Claude Code alias | Typical work |
|---|---|---|---|
| 0 to 2 | Haiku 5.5 | `haiku` | Search, grep, file listing, formatting, renames, short summaries, classification, boilerplate, data cleanup |
| 3 to 6 | Sonnet 5.5 | `sonnet` | Most coding, bug fixes with a clear repro, tests, docs, emails, reports, moderate analysis |
| 7 to 9 | Opus 5.5 | `opus` | Architecture, multi-file refactors, vague bugs, strategy, research synthesis, exec-facing writing, UX strategy |
| 10 to 12 | Fable 5.1 | `claude-fable-5-1` | Long-horizon agentic builds, novel algorithms, system design at scale, tasks Opus already failed |

Override rules, applied after the score:

1. A single 2 on Stakes bumps the pick up one tier, all the way to Fable. An Opus-level task with production, regulatory or executive stakes goes to Fable.
2. A task that Opus already failed goes to Fable, whatever the score.
3. If the user asks for the best, strongest or most capable model ("use the best model", "money is no object", "get this right first time"), go straight to Fable.
4. Fable carries extra safety measures for biology, cybersecurity and LLM R&D work. For those topics pick Opus.
5. If the user names a model, use theirs and skip the scoring. Mention a better fit in one line if you see one.
6. Mixed tasks get split. Read references/split-patterns.md when a task has a cheap part and a hard part (for example, gather files with Haiku, then design with Opus).

## Step 2: announce the pick

Before each subtask, write one line in this shape:

> Routing step 2 of 4: **Opus 5.5** (score 8: session design, high ambiguity, production stakes).

For a single-step task, drop the step count.

Keep it to one line. No tables in the reply.

## Step 3: route

Check which environment you are in, then follow the matching path.

### In Claude Code

Delegate the task to the worker subagent for the chosen tier with the Agent (Task) tool:

| Tier | Subagent |
|---|---|
| Haiku | `haiku-worker` |
| Sonnet | `sonnet-worker` |
| Opus | `opus-worker` |
| Fable | `fable-worker` |

Pass the full task, the relevant file paths, and the acceptance criteria in the delegation prompt. The subagent starts with a clean context, so it needs everything.

If the worker subagents aren't installed, pass the model directly as the `model` parameter of the Agent call. If that isn't supported either, tell the user to run `/model <alias>` and stop.

Session-level switch: when the whole session will be one kind of work (a full day of refactoring, say), suggest `/model opus` or `/model sonnet` once, instead of delegating every message.

Stay in the main session for routing, review and talking to the user. Send the heavy lifting out.

### In the Claude app (claude.ai, desktop, mobile)

A skill can't change the model here. The user switches it in the model selector. So:

Route each subtask the same way, and flag when the next step needs a different model from the current one, so the user can switch between steps.

- If the current model matches the pick, or is one tier above it, do the task.
- If the current model is above the pick by two tiers or more, do the task and add one line at the end: the same result is available on a cheaper model next time.
- If the current model is below the pick, say so in one sentence and ask once whether to proceed or switch first. For score 10 and up, recommend switching before starting.

## Step 4: check and escalate

When the work comes back, review it against the acceptance criteria. Run tests if there are any.

- Passes: report the result and the model used.
- Fails once: retry on the same tier with a sharper prompt that names what went wrong.
- Fails twice: escalate one tier and say so in one line.
- Fails twice on Fable: stop, report what was tried, and hand the decision back to the user. Fable is the top tier available, so there is nowhere higher to go.
- Never step down a tier mid-task.

## Step 5: learn from misroutes

When a task needed escalation, or the user says a pick was wrong, add a rule to `tasks/lessons.md` in this shape:

```
- [model-router] <task type> → start on <tier>, not <tier>. Reason: <what went wrong>.
```

Read `tasks/lessons.md` at the start of a session and let those rules override the score table for matching task types.

## Reference files

- references/split-patterns.md: how to split mixed tasks across tiers, with examples
- agents/: the four worker subagents to install in `~/.claude/agents/` (see README.md)
