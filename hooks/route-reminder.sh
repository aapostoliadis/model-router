#!/bin/sh
# Runs on every prompt you send in Claude Code. Its output is added to Claude's context.
echo "Model router: before working on this message, use the model-router skill. If this starts a task, break it into subtasks in tasks/todo.md with a model tag on each. If it continues a task, take the next open subtask, re-score it, and delegate it to the matching worker subagent (haiku-worker, sonnet-worker, opus-worker or fable-worker). Skip routing for one-line questions."
