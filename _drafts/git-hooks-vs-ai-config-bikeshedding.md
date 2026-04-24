---
draft: true
title: "Git hooks, tabs vs spaces, and why I'd rather not argue about AI config"
description: The git hooks debate has the same flavour as tabs vs spaces, and deterministic tooling around AI use is worth a lot more than burning tokens (or CI minutes) on config that may or may not stay in context.
categories: [thoughts, tooling]
tags: [git, git-hooks, ai, tooling, bikeshedding, ai-assisted]
---

Every now and then a git hooks thread lights up somewhere. Should they live in the repo, should they be opt in, should they run on pre commit or pre push, should they be fast, should they block, should they be shared at all. People have strong opinions and the threads get long.

To me it has the same flavour as tabs vs spaces. It is a real question with real tradeoffs, sure, but mostly it is bikeshedding. The reason it attracts so much energy is not that the stakes are high, it is that everyone has an opinion because everyone touches it, and the surface is small enough to fit in a tweet.

## Why I still land on "yes, hooks"

With the caveat that I don't really want to argue about it either: I think deterministic tooling around how code gets produced, things like linters, formatters, type checks, test runs, and hooks that enforce any of the above, is worth more now than it was five years ago. Not less.

The reason is AI in the loop.

A lot of the current advice about "working with AI" involves stuffing configuration, preferences and rules into the model's context. Style guides, do and don't lists, "always use X, never use Y", "prefer this pattern", "follow our conventions". Pages of it.

Some of that is useful. But a lot of it is tokens spent on things the model may or may not actually keep in context, may or may not apply consistently, and may or may not still be relevant by the time it is ten tool calls deep into a task. You are paying, in tokens and in attention, for a soft guarantee.

And yes, models are getting better. They remember more, they follow instructions a bit more reliably, they stay on task for longer. But of course you also pay a proportionally better amount of money for the ones that do :) The "just put it in the prompt" answer is not free, and it gets less free the more capable the model you are relying on.

A pre commit hook that runs the formatter, on the other hand, is a hard guarantee. The code is either formatted or the commit does not land. It does not matter whether the model remembered the rule, whether the human remembered the rule, whether anyone actually read CONTRIBUTING.md. The tool decides. And it costs about the same today as it did last year.

## The CI bill nobody mentions

There is also a cost side to this that I don't see talked about enough. If your linter, formatter and unit tests only run in CI, every AI assisted commit that slips past the basics turns into a CI run. And another one after the fix. And another one after the follow up fix.

That adds up. Not just in pipeline minutes, but in the waiting time between "I pushed" and "I can see it's actually fine", which for a lot of teams is the real bottleneck. Moving the quick checks left, onto the developer's machine via a hook, means CI ends up running mostly on changes that have at least passed the cheap stuff locally. The expensive runners stay for the expensive checks (integration, e2e, builds for other platforms) instead of rejecting things a two second pre commit would have caught.

So the argument for hooks is not just "correctness". It is also, pretty directly, "don't pay your CI provider to tell you about a missing semicolon".

## A concrete, AI tool agnostic setup

I specifically don't want a setup that is tied to one AI assistant. The whole point is that the guarantee should hold regardless of who or what produced the diff, so the hooks have to live at the git level, not inside a particular tool's config.

### Wait, can hooks actually be committed?

Short answer: yes, if you don't put them in the default place.

The default `.git/hooks/` directory is inside `.git/` and is not part of your working tree, so it cannot be committed. That is the bit that trips people up and makes hooks feel unshareable.

The trick is to put the hooks in a normal, tracked directory at the root of the repo (I usually call mine `hooks/` or `.githooks/`) and then point git at it with `core.hooksPath`. That directory is just regular files, so it gets committed, reviewed, and versioned like the rest of the code. Every dev who clones gets the same hooks, and updates ship through PRs like anything else.

### The setup

```bash
# in the repo, once
mkdir -p hooks
git config core.hooksPath hooks
```

That `git config` line is per clone, so it either goes in your README under "first time setup" or in a small setup script / `justfile` / `make setup` target. It is a one liner for new developers and it is the whole ceremony.

A minimal `hooks/pre-commit`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# only look at staged files, not the whole tree
staged=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|rb|py)$' || true)
[ -z "$staged" ] && exit 0

echo "→ formatting"
# e.g. prettier, rubocop --autocorrect, ruff format, etc.
your-formatter $staged

echo "→ linting"
your-linter $staged

# re-stage anything the formatter fixed up
git add $staged
```

Commit the file, make sure it is executable (`chmod +x hooks/pre-commit`, also committed via `git update-index --chmod=+x hooks/pre-commit` if needed), and that is it. Works the same whether the commit came from you, an AI assistant, a coworker, or a script. No plugin, no npm dependency, no editor integration required.

If you want something a bit nicer with parallelism and per file selectors, [lefthook](https://github.com/evilmartians/lefthook) and the [pre-commit](https://pre-commit.com/) framework both work independently of your language stack and independently of whichever AI tool anyone is using. Pick one, commit its config, done.

The thing I would avoid is putting the rules these hooks enforce into AI specific config files and calling it a day. An `.editorconfig`, a formatter config (`.prettierrc`, `pyproject.toml`, `.rubocop.yml`), and a committed pre commit hook are all portable. A long "here is how we like our code" section in one AI tool's config file is, at best, a nudge, and only for the developers using that specific tool.

## Deterministic beats probabilistic for the boring stuff

The rule of thumb I keep coming back to: if something can be enforced by a tool, enforce it with a tool. Keep the model's context, and your budget, for the things that actually need judgement.

* Formatting? Tool.
* Import order? Tool.
* Commit message shape? Tool.
* Obvious lint violations? Tool.
* Tests must pass before push? Tool.
* Architectural tradeoffs, naming, API shape, "does this even belong here"? That is where the thinking lives, human or AI.

The more deterministic scaffolding you have around the edges, the less time you spend (in tokens, in meetings, in PR comments, in CI minutes) re arguing the same small decisions. Every rule a hook enforces is a rule you don't have to remind the model of, don't have to remind a new teammate of, and don't have to re litigate in review.

## The bikeshed part

Which is also why the hooks debate mildly frustrates me. Of course there are real versions of it, like hooks that are too slow, hooks that fight your editor, hooks that block work in ways that were never really agreed on. Those are legitimate. But a lot of the heat is the tabs vs spaces kind: strong feelings about a small surface, because the surface is small enough for everyone to have feelings about it.

Meanwhile the actually interesting question, what should be enforced by tooling vs. by convention vs. by review vs. by prompting the model, gets much less airtime. And that question matters more now, because the answer shifts a bit once a chunk of your code is being produced by something that does not reliably remember what you told it three turns ago, and charges more per token the better it gets at remembering.

My short version: lean on deterministic tooling. Git hooks are a fine place to put it, and `core.hooksPath` is what makes them shareable. Let the hook do the boring enforcement, let CI focus on the expensive checks, and argue about the shape of the guarantees a little more than about the config of the hook.
