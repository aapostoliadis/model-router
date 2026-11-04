# Split patterns

Many real tasks mix cheap and expensive work. Splitting them saves cost and keeps the expensive model's context clean. Split only when the cheap part is big enough to matter (more than a few file reads or a long document). For small tasks, one model is simpler.

## Gather, then think

Haiku collects, a bigger model decides.

Example: "Review our auth module and propose a new session design."
Haiku-worker lists the auth files, extracts function signatures and current session handling into a short brief. Opus-worker reads the brief plus the two or three files that matter and writes the design.

## Draft, then polish

Sonnet does the bulk, Opus does the part that carries the stakes.

Example: "Write a 12-page discovery report and an exec summary for the steering group."
Sonnet-worker drafts the body from the research notes. Opus-worker writes the exec summary and checks the recommendations hold up.

## Plan, then build

Opus or Fable plans, Sonnet builds, Haiku checks.

Example: "Migrate the reporting service from REST to an event queue."
Opus-worker writes the plan with steps and acceptance tests into tasks/todo.md. Sonnet-worker implements step by step. Haiku-worker runs the test suite and lint and reports failures.

## Fan out, then merge

Same small job across many inputs.

Example: "Summarise these 40 interview transcripts and find the themes."
Haiku-worker summarises each transcript in parallel to a fixed template. Opus-worker merges the summaries and builds the themes.

## Hand-off rules

Each worker gets the full context it needs in its prompt, since subagents don't see the main conversation. Pass outputs between workers as files or short briefs, never as "see above". The main session owns the final review.
