---
title: For agents
description: How to point Claude Code or another coding agent at Glass, and the rules it must follow.
---

This site is written to be read by people and followed by agents.

## Where an agent starts

- `/llms.txt` is the index. It lists the runbook first, then the guides.
- `/llms-full.txt` is every page in one file; `/llms-small.txt` is a trimmed version.
- The [runbook](/glass-os/agents/runbook/) is the source of truth for doing things. **Runbooks are executable; guides explain.** If they disagree, trust the runbook and tell the user.

## Prompt to give your agent

> Read the Glass `llms.txt`, then follow the runbook against my connected Fire TV Stick for "Install + one command". Run each precondition and verify command and compare the output with what the runbook expects. Stop and ask me before any step marked "Needs user", and before any write I have not approved.

## Safety rules (apply to every step)

1. One stick per session. Run `adb devices` first; if more than one device is listed, pass `-s SERIAL` on every command and ask the user which stick.
2. Never flash the bootloader, preloader, trustzone or vbmeta partitions.
3. Back up before writing anything beyond an app install or a package disable.
4. Steps marked **Root only** must not run unless the root check passes.
5. Steps marked **Coming soon** are not built. Do not improvise them.
6. Never include device serials or home-directory paths in reports back to the user or in public issues.
7. On a failed verify, run that step's rollback, then stop and ask. Do not continue to the next step.

## Step format

Every runbook step has the same shape: **Precondition** (command and expected output), **Action** (one command), **Verify** (command and expected output), **On failure** (rollback), and, where it applies, **Needs user** for physical actions or write approvals.
