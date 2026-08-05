> 🌐 [繁體中文](README.md) | **English**

# meta-harness

A method for designing AI agent harnesses, plus a consultant that will build the design for you.

A harness is everything around the model: which tools it gets, how context is packed, where memory lives, when it should stop and ask a person. Editing a prompt tweaks wording. Designing a harness changes the whole system. It doesn't matter what you build with — bash scripts, a web app, SaaS, a hybrid product — if there's an AI agent inside, this applies.

---

## 1. What this is

meta-harness is a consultant that lives inside Claude Code. It helps you design AI agent systems, and it also does the implementation.

You don't "run" this project. You cd into its directory, open a Claude Code session, and it becomes a designer who knows the craft and the common traps. It walks you through designing and building a specific AI agent tool. Throughout these docs, that tool is called the target project.

The shape of it: you describe what you need, the consultant produces a design plan, you read it and give feedback, the consultant writes the files into your target project, and then you accept the result.

It is not a framework, not a CLI tool, and not a scaffold generator. It's a conversation flow plus a built-in catalogue of design techniques.

### Four things it does

**Design a new tool, or redesign an existing one.** Should this use a hook? A sub-agent or a skill? Where does memory live? Use `/design`. You get a design plan, plus configuration files written straight into your target project.

**Health-check an existing system.** Hold up the 13 design dimensions as a mirror and find what's missing or wrong. Use `/healthcheck`. You get an assessment report.

**Look back at a system that's been running.** Figure out what to adjust next. Use `/retro`. You get a summary and a list of actions.

**Produce user-facing docs.** README plus CONTRIBUTING, in both English and Chinese. Use `/document`. You get two documents: one for the people who use the tool daily, one for whoever maintains it later.

### Why a consultant instead of a generator

Each of the 13 design dimensions is a parameter with many possible values, not an on-off switch. They also affect each other: what you pick for one constrains what makes sense for another. No single combination fits everyone.

So the core of this project is the conversation, the catalogue of techniques, and the design plan. Generating files is demoted to a side effect — it's what comes out after the discussion, not the way in.

---

## 2. Quick start

You need:

- Claude Code CLI installed (`claude --version` works). That's the only hard requirement.
- A target project in mind. It doesn't have to exist yet; being able to describe what you want is enough.

No `.env`, no API key file. This project connects to no external service and stores no secrets. Its runtime is Claude Code itself.

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
claude
```

Once the session is open, the first thing to do is switch to the strongest model with `/model`. Design and reasoning work is sensitive to model quality — a weaker model tends to pile up jargon, suggest bad patterns, and leave logic holes. The AI can't switch its own model, so this step is on you.

After that, use a command, or just say what you want in plain language (the consultant role loads automatically):

```
/design ~/my-project              # Design something new, or redesign what exists
/healthcheck ~/my-project         # Check over an existing system
/retro ~/my-project               # Look back after it's been running a while
/document ~/my-project            # Produce user-facing docs
(no command, just talk)           # Pick up where the last session left off
```

A first run usually takes 10 to 20 minutes to finish the interview and produce a first design plan. For a fuller walkthrough, read [`docs/getting-started.md`](docs/getting-started.md).

---

## 3. Configuration

There's one optional config file: `targets.yml`. It records which target projects you have locally — their paths, their current status (concept, pending audit, audited), and an optional `eval_dir` to override the default location of the self-verification directory.

```bash
cp targets.yml.example targets.yml
```

It's already in `.gitignore`. You can pick a project from this list when you start a session, or skip it entirely and just give an absolute path in conversation.

You don't need a `.env`. This project uses no API key files.

---

## 4. How to use it

You'll enter one of five modes. Each one is just an entry point — once you're in, it's a conversation with the consultant, not a form to fill out.

| Mode | Command | In plain words | When to use it |
|---|---|---|---|
| Design | `/design <project>` | "Design or redesign ~/X" | Starting fresh, or rebuilding |
| Health check | `/healthcheck <project>` | "Check over ~/X" | Reviewing an existing system, finding gaps (works even before it's running) |
| Retro | `/retro <project>` | "Look back at ~/X" | After the project has been running a while |
| Docs | `/document <project>` | "Write the docs" | Docs are stale, or you're handing it to someone else |
| Resume | (no command) | "Continue designing X" | Picking up an unfinished session |

### The six steps of the design flow

`/design` runs the whole thing:

1. **Interview.** 10 to 20 minutes, a mix of multiple choice and open questions.
2. **The consultant writes the design plan alone.** You do nothing during this part.
3. **You read it, give feedback, and iterate until it's settled.** This part is free-form text, not multiple choice.
4. **Implementation in stages.** Split into a first, second, and third stage, writing files into your target project as it goes.
5. **Self-verification (required).** Anything a machine can verify gets run headless at least three times and scored before it's handed to you. This is numbered 4.5 because it's part of implementation.
6. **Acceptance.** The consultant runs what can be checked automatically; you open a fresh session and actually try it.
7. **Look back later.** A few weeks on, revisit and see what should change.

A first-time run usually gets to step three or four; the rest is as needed. `/healthcheck` and `/retro` are short standalone flows that don't go through these six steps.

### Two kinds of people: designers and users

A target project built with meta-harness serves two audiences, and you have to keep them apart while designing.

**The designer** is the engineer using meta-harness to build the target project — the person reading this README.

**The user** is whoever runs the target project daily and makes decisions from its output. They may not be technical in this domain at all. An accounting system's user might be an accounting assistant, not an engineer.

Design dimension 12, "the human interface", is the layer built specifically for that user: how terminology gets translated, how much detail to show, how their feedback gets back to you. It's the mirror image of dimension 9, "observability", which is the output meant for engineers and systems.

---

## 5. Who does what

```
┌────────────────────────────────────────────────────┐
│                    You (the designer)               │
│  state needs / read the plan / try it in a session  │
└──────────────────┬─────────────────────────────────┘
                   │ /design ~/my-target
                   ▼
┌────────────────────────────────────────────────────┐
│      meta-harness consultant (Claude Code session)  │
├────────────────────────────────────────────────────┤
│  1   Interview: five questions (button UI)          │
│  2   Consultant writes the plan alone               │
│  3   You give feedback → plan revised → repeat      │◀───┐
│  4   Files written into your project (abs. paths)   │    │
│  4.5 Self-verification (headless ≥ 3 runs + score)  │    │ discussion
│  5   Acceptance (consultant runs what it can,       │ ───┘
│      you try it in a fresh session)                 │
│  6   Look back a few weeks later                    │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│         Your target project (the AI tool built)     │
│  Stop hook + run-self-verify.sh                    │
│  Config out of sync with the plan → exit 2 blocks   │
│  coverage.json tracks verification coverage         │
└────────────────────────────────────────────────────┘
```

The AI handles step 2 (writing the plan), step 4 (implementation), step 4.5 (self-verification), and the machine-checkable part of step 5.

You handle step 1 (stating needs), step 3 (reading the plan), the hands-on part of step 5, and step 6.

Two gates run automatically. Step 4.5 requires self-verification to pass at least three times before moving on. And a Stop hook runs verification whenever architecture files have changed, blocking the session from ending if the configuration no longer matches the plan. Both are the enforcement layer for rule R-10 — "anything a machine can verify must be verified before delivery" — and they can't be bypassed. Sessions that were pure consultation or pure reading don't get penalized with a full run; a file fingerprint decides. Set `META_HARNESS_VERIFY=always` to force verification every time.

---

## 6. Commands and skills

Four command entry points:

| Command | What it does |
|---|---|
| `/design <project>` | Design or redesign, running the full six steps |
| `/healthcheck <project>` | Check the project against the 13 design dimensions, produce a report |
| `/retro <project>` | Look back after it's been running |
| `/document <project>` | Produce bilingual README and CONTRIBUTING |

Two skills. `consultant` defines the consultant role and the full six-step flow; it loads no matter which command you came in through. `document` pulls content from the design plan and the current state of the project to produce the docs.

If you want to go deeper, these are the core documents:

| Document | What's in it |
|---|---|
| [`docs/getting-started.md`](docs/getting-started.md) | New-user entry point; first interview in 30 minutes |
| [`.claude/skills/consultant/SKILL.md`](.claude/skills/consultant/SKILL.md) | The consultant role and the six-step flow in detail |
| [`docs/design-axes.md`](docs/design-axes.md) | Index of the 13 design dimensions |
| [`docs/design-axes/<n>-<name>.md`](docs/design-axes/) | Each dimension: the options, the common mistakes, real cases |
| [`docs/universal-care-rules.md`](docs/universal-care-rules.md) | R-1 through R-12, the baseline rules the consultant always follows |
| [`docs/prescription-template.md`](docs/prescription-template.md) | The format of a design plan, useful when reviewing one |
| [`docs/manual-template.md`](docs/manual-template.md) | The format of user documentation |
| [`docs/consultant-flow.md`](docs/consultant-flow.md) | How the consultant makes its judgment calls |
| [`docs/lessons.md`](docs/lessons.md) | Mistakes made along the way |

### The 13 design dimensions

Tool execution, context management, memory, planning, the execution loop, permissions and safety, hooks, evaluation, observability, multi-agent coordination, triggers and scheduling, the human interface, and self-verification coverage.

Every one of them is a parameter with many options, and they affect each other. That's exactly why this is a conversational consultant and not a fixed template.

---

## 7. What comes out, and how you know it's right

### What stays local in meta-harness during a session

All of this is in `.gitignore`:

- `sessions/<date>-<topic>.md` — interview notes, with the five answers and the dimension shortlist.
- `prescriptions/<date>-<project>.md` — the design plan the consultant writes before touching anything. Also the audit trail.
- `cases/` — cases distilled from specific projects. Someone who forks this shouldn't see your work.
- `experiments/<project>-<topic>/runs/` — raw evidence from the step 4.5 verification runs, including real identifiers.
- `BACKLOG.md` — your own list of "there's a gap in the rules or the method here".

Each ignored directory keeps a committed `README.md` or structure file, so people who fork the repo know what the directory is for without seeing anyone's private content.

### What gets written into your target project

During step 4, the consultant uses absolute paths to write files directly into your target project; the working directory never leaves meta-harness. What gets written is decided by the design plan. Common ones: `.claude/hooks/*.sh`, `.claude/skills/<name>/SKILL.md`, `.claude/commands/*.md`, `.claude/settings.json`, and `experiments/<project>-eval/test-*.sh`.

### How you know it worked

This is what design dimension 13 is about, and it's how rule R-10 gets enforced. After implementation, every target project — including meta-harness itself — ends up with:

- `experiments/<project>-eval/run-self-verify.sh` — a single entry point that runs every `test-*.sh`.
- `experiments/<project>-eval/test-*.sh` — a verification script per piece of configuration.
- `experiments/<project>-eval/coverage.json` — the dashboard: how many scripts, how many checks, what coverage.
- `.claude/hooks/self-verify-on-stop.sh` plus the Stop registration in settings.json — verify when architecture changed, block the session from ending when things don't line up.

Every `test-*.sh` belongs to one of four verification approaches:

- **A. Check that configuration agrees with itself.** When one setting is spread across several files, check they haven't drifted apart.
- **B. Trigger it and see if anything happens.** Whether hooks and middleware actually fire.
- **C. Score the output.** For content an agent produces.
- **D. Compare before and after.** For side effects.

Live numbers — how many scripts, how many checks, what percentage — always come from [`experiments/meta-harness-eval/coverage.json`](experiments/meta-harness-eval/coverage.json), which `generate-coverage.sh` maintains. Nothing is copied by hand here, because hand-copied numbers always go stale.

meta-harness verifies itself the same way: it runs a full set of verification scripts, and the denominator for coverage is derived by scanning hooks, commands, skills, bin, and templates. A human can only exclude something with a stated reason, and anything not covered is listed explicitly in `coverage.json`. atdd-task was the first external project to do the same, with its own scripts and its own `coverage.json`.

One thing worth being clear about: the coverage number reported today covers structure and behavior — approaches A and B above. The denominator is machine-derived so it can't be inflated. Semantic coverage — approach C, using an LLM as a judge to assess content quality — isn't fully built yet and is on the roadmap. Right now the consultant skill's output quality is approximated by a structural check (`test-consultant-skill-structure.sh`), which is not real semantic verification.

Details in [`docs/design-axes/13-self-verify-coverage.md`](docs/design-axes/13-self-verify-coverage.md).

---

## 8. What it doesn't do, and known limits

What it doesn't do:

- **It doesn't generate directory scaffolding.** There's no `meta-harness new <type>`. The reasoning is in section 1.
- **It doesn't write your business logic.** The consultant touches the framework layer — hooks, skills, commands, settings, verification scripts. It doesn't touch your task content: business rules, domain knowledge inside agent prompts. That's rule R-9.
- **It doesn't overstep between layers.** The framework layer doesn't take positions on task content (also R-9), and method-level rules don't get written into project-specific documents (R-8).
- **It doesn't skip verification.** Anything a machine can verify must be run headless at least three times before delivery (step 4.5, R-10). The Stop hook blocks "commit without verifying".
- **It doesn't connect to anything external.** No API keys, no telemetry, no remote sync. The runtime is Claude Code itself.

Known limits:

- **It's tied to Claude Code.** It won't run in ChatGPT, Cursor, or other IDEs, because the consultant role is implemented with Claude Code's skill and command mechanisms.
- **It needs a person present.** The design flow is a conversation; without a designer in the room it can't run on its own. The periodic retrospective is a partial exception.
- **Verifying LLM output quality is still mostly structural.** Approaches A, B, and D are built. Approach C — using an LLM as a judge for agent output quality — is still evolving.
- **You can hit session limits.** Running many `claude -p` subprocesses (for example an evaluation matrix across agents and models) will hit the Claude Code subscription's session cap. To avoid that, set `ANTHROPIC_API_KEY` and bill through the API instead.

---

## 9. When something goes wrong

**The Stop hook keeps blocking the session and printing verification failures.**
Run `bash experiments/meta-harness-eval/run-self-verify.sh` to see which script is failing. This isn't a punishment; it's a signal that something really is out of sync. Fix it first.

**The consultant starts explaining concepts instead of producing a design.**
Pull it back: "You're the designer, not a textbook. Give me the concrete approach." The consultant skill has a guard against drifting out of role, but you watching is another layer.

**You're not sure whether some rule or dimension should be promoted to a general rule.**
Read the decision logic in `docs/consultant-flow.md`, or just ask in the session: "Should this become a general rule? Does it still hold in a different project?"

**After implementation the configuration doesn't match the design plan.**
Run `experiments/meta-harness-eval/test-cross-references.sh` — it catches mismatched rule and dimension references automatically. You can also grep by hand.

**You hit the Claude session limit.**
Check the reset time in the message. The long-term fix is to set `ANTHROPIC_API_KEY` and bill through the API, which is a separate quota.

Mistakes made along the way accumulate in `docs/lessons.md`, each with why it happened and how to avoid it.

Still stuck? Open an [issue](https://github.com/spenguinlui/meta-harness/issues) or a PR. You're also welcome to tell the consultant mid-session "I think there's a gap in this method" — it will help you judge whether it should become a general rule or go into `docs/lessons.md`.

---

## 10. Maintenance and reporting

Maintained by [@spenguinlui](https://github.com/spenguinlui).

To report a problem or suggest something, open a [GitHub issue](https://github.com/spenguinlui/meta-harness/issues). Include the specific situation you hit — which session, which design plan, which rule or dimension you got stuck on. That's far more useful than an abstract suggestion.

To extend the method itself (add a dimension, a rule, a skill), read [`CONTRIBUTING.md`](CONTRIBUTING.md) first. That's where the discipline for changing meta-harness itself is written down.

To share a design plan, PRs adding to `cases/` are welcome. Note that `prescriptions/` itself is gitignored and contains private project content, so sharing means writing a trimmed version separately.

---

## 11. Glossary

These are meta-harness's own terms, easy to confuse on first contact:

| Term | What it means |
|---|---|
| Target project | The repo for the AI agent tool you're designing — not meta-harness itself. Called "target repo" in the source and commands. |
| Designer | The engineer using meta-harness to design the target project. That's you, reading this. Called "builder" in the source. |
| User | The person who actually uses the target project day to day. May or may not be the same person as the designer — think accounting assistant versus systems engineer. Called "human" or "viewer" in the source. |
| Consultant role | The role a Claude Code session takes on after loading the `consultant` skill. |
| Design plan | The design document the consultant writes before touching anything, stored at `prescriptions/<date>-<project>.md`. Called "prescription" in the source and commands. |
| Manual | The user-facing README and CONTRIBUTING that `/document` produces for the target project. |
| Design dimension | The 13 design parameters (tool execution, context, memory, and so on). Each is a space of options, not a switch. Called "design axis" / 設計軸 in the source and commands. |
| R-N | The 12 general rules that apply across projects. R-1 is "CLAUDE.md stays under 50 lines", R-10 is "verify before delivery", R-12 is "files written into a target project must stand on their own". |
| Wiring | How hooks, skills, commands, and settings connect into a behavior. |
| Mechanism | The concrete way one piece of wiring is implemented. It's a behavior, not a file. |
| Anti-scope | An explicit list of what the tool should not do. Always asked in the first interview. |
| Retrospective | Revisiting a project after it's been running, checking four things: which outcomes should become skills, what the accumulated signals show, whether memory has the right shape, and whether the method itself has gaps. Called the "flywheel" in the source. |
| Dogfooding | meta-harness verifying itself with its own verification method. |
| Headless verification | Running `claude -p` at least three times plus machine scoring — the requirement in step 4.5. |
| Drift | Configuration that no longer matches the design plan or the source of truth. This is what self-verification looks for. |

Industry-standard terms (hook, skill, slash command, CLI, DDD, TDD) aren't listed here; readers are assumed to know them.

---

## Repo structure

```
.claude/
  hooks/                    The consultant's own hooks: working-directory guard,
                            CLAUDE.md line count, pre-question self-check. Only
                            self-verify-on-stop actually blocks a session.
  skills/consultant/        The consultant role. Core; loaded by every command.
  skills/document/          The skill behind /document
  commands/                 design / healthcheck / retro / document — four entry points
                            (document is a thin shell; the logic lives in the skill)
  settings.json             Hook registration, including the Stop hook for verification
docs/
  getting-started.md        New-user entry point
  consultant-flow.md        How the consultant makes judgment calls
  design-axes.md            Index of the 13 design dimensions
  design-axes/              Each dimension in depth
  universal-care-rules.md   R-1 through R-12
  prescription-template.md  The format of a design plan
  manual-template.md        The format of user documentation
  lessons.md                Mistakes made along the way
experiments/
  meta-harness-eval/        meta-harness verifying itself (entry script, checks, coverage.json)
  consolidation-loop/       Reference implementation of the verification flow
targets.yml.example         Template for the project list (copy to targets.yml)
─── everything below is gitignored: each fork's own content ───
targets.yml                 Your local list of target projects
sessions/                   Interview notes
prescriptions/              Design plans
cases/                      Case library
experiments/*/runs/         Raw verification evidence
BACKLOG.md                  Unresolved failures and gaps
```

---

## Where things stand

**v0.5: self-verification coverage, plus a mapping to software engineering practice.**

Done:

- All 13 design dimensions. v0.5 added the thirteenth, self-verification coverage, turning R-10 from a rule into a measurable metric with an automatic gate.
- All 12 general rules, R-1 through R-12. R-11 is bilingual documentation; R-12 is that files written into a target project must stand on their own.
- The consultant skill holds the role steady, and the six-step flow is complete.
- `/document` produces bilingual README and CONTRIBUTING automatically.
- Memory is classified along several dimensions, with two feedback loops: plans becoming memory, and outcomes becoming skills.
- meta-harness verifies itself with its own scripts, with a machine-derived denominator. Live numbers in `coverage.json`.
- atdd-task was the first external project to do the same, with its own scripts and coverage.json.

In progress: rolling this out to other projects. For where each project actually stands, run `bash experiments/meta-harness-eval/test-target-coverage.sh` — that's the live number, not copied here.

---

## License

MIT
