---
draft: true
title: "AI at the team level reminds me of the Spotify model days"
description: The push to move AI from individuals to the whole organization feels a lot like the Spotify model era, and probably runs into the same problem.
categories: [thoughts, engineering-culture]
tags: [ai, organization, culture, spotify-model, ai-assisted]
---

Every now and then I read a sentence somewhere that gives me a little bit of déjà vu. Lately it was something along the lines of:

> moving AI from a tool in individual hands to infrastructure the whole organization leans on

I am not against the direction, to be clear. That is probably where the real value is. What got my attention is more the shape of the sentence, the confident way it describes a shift as if the shift itself is the hard part.

It reminded me of something companies went through roughly ten years ago. The Spotify model era.

## The Spotify thing

Somewhere around the mid 2010s, a lot of mid sized tech companies suddenly announced they were moving to squads, tribes, chapters and guilds. There were diagrams everywhere, leadership decks got relabeled, teams got renamed, and there were plenty of kick off meetings.

A couple of years later most of those efforts had quietly faded, and even Spotify themselves have said at some point that the picture people were copying was never really the point. What looked like a structure you could adopt was actually the trace left by a particular culture, at a particular size, with particular people.

The structure is the easy part to announce. The culture underneath is the hard part, and that part doesn't just happen because someone at the top says it will.

## Same problem, different decade

The things implied by "AI as organizational infrastructure", like shared context that is actually written down and trusted, some kind of norm for how AI assisted work gets reviewed and pushed back on, teams that don't fall apart when anyone can generate a plausible looking proposal in thirty seconds, a willingness to let the tool actually change the work instead of just speeding up the current work, all of those are cultural things.

And cultural things grow, or they don't. You can encourage them, make room for them, try to live them yourself, but you can't really announce them into existence and you can't put them on a roadmap for Q3.

That is the analogy, I guess. Not really "AI is the new Spotify model", more that both are moments where an organization tries (or is about to try) to decree a cultural change from above and then finds out that the announcement was the easy part.

The Spotify era is useful because we already know how it played out. The companies that actually got something real out of it were not the ones that adopted the vocabulary the fastest. They were the ones where something in the culture was already moving in that direction anyway, and the new names just gave it a shape.

## What teams actually ship when they try this

To be fair, there are concrete things a team can build when they want to go "organization level" with AI, and some of them are genuinely useful. I just think it is worth being clear about which part of the problem they solve and which part they don't.

A few examples I see come up:

* A committed, tool agnostic context file at the root of the repo. The `AGENTS.md` convention is the most portable one at the moment, and Claude Code, Cursor, Aider and friends either read it directly or can be pointed at it. It is a plain markdown file, reviewed in PRs like any other code.
* A small shared evals suite, so that whatever the team builds on top of an LLM can be regression tested instead of re vibed every time the model version changes.
* A shared "skills provider" MCP server, exposing the team's curated playbooks (how we onboard a service, how we write a migration, how we triage an incident, how we cut a release) over MCP, so any MCP capable assistant can list and invoke them.

The last one is the one I find most interesting in the context of this post, because it is very easy to get running and very easy to mistake for the actual goal.

A minimal version with [FastMCP](https://github.com/jlowin/fastmcp) looks roughly like this:

```python
from pathlib import Path
from fastmcp import FastMCP

SKILLS_DIR = Path(__file__).parent / "skills"
mcp = FastMCP("skills-provider")

@mcp.tool()
def list_skills() -> list[str]:
    """Return the names of all available team skills."""
    return sorted(p.stem for p in SKILLS_DIR.glob("*.md"))

@mcp.tool()
def get_skill(name: str) -> str:
    """Return the markdown body of a named skill."""
    path = SKILLS_DIR / f"{name}.md"
    if not path.exists():
        raise ValueError(f"unknown skill: {name}")
    return path.read_text()

if __name__ == "__main__":
    mcp.run()
```

Point it at a committed `skills/` directory in the team repo and you are done. Skills get reviewed in PRs like any other code, every assistant that speaks MCP sees the same set, and nobody has to re explain "how we do X" in every new chat session.

And yet. The server is the easy part. It ships in an afternoon. What it does not ship is:

* a team culture where people actually take the ten minutes to write a skill down after solving something non trivial,
* a review habit where skills get updated when they go stale, instead of quietly rotting,
* a default reflex to reach for `list_skills()` before reinventing the wheel from memory.

Those are the things that decide whether the whole setup is a genuine organizational capability or just another internal tool that nobody opens. The repo can have the artifact. The culture decides whether it matters.

That is sort of the whole point of this post. The tool shaped things are shippable and reviewable and they look good in a demo. The cultural things around them are slower, messier, and don't fit on a roadmap slide. And it is pretty much always the second group that does the actual work.

## Closing

My guess, and it is only a guess, is that AI at the team and organizational level will go about the same way as the Spotify model did. Some places will get there because the culture was already quietly ready. Others will print the slides, do the town hall, spin up the MCP server, and then a year later wonder why not much really changed.

Both times, the thing doing the actual work is not the framing. It is whatever was already happening underneath.
