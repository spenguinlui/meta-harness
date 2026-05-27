> 🌐 [繁體中文](README.md) | **English**

# meta-harness

> **A methodology + consultant wiring for designing AI agent harnesses.**
> Prompt engineering tweaks words; harness engineering changes "the whole system around the model."
> Works on any implementation medium — bash scripts, web apps, SaaS, hybrid products — as long as there's an AI agent inside.

---

## 1. What it is / What it does

`meta-harness` is an **AI agent system design consultant (architect) + builder** that lives inside Claude Code.

You don't "run" this project — you **cd into its directory and open a Claude Code session**, and it becomes an architect who knows the craft and best practices, walking you through designing and building a specific AI agent tool (hereafter **target repo** = the project you're designing).

```
You state need  →  Consultant produces blueprint  →  You review  →  Consultant lands files into your target repo  →  Acceptance
```

It is **not** a framework / CLI tool / scaffold generator. It is a **conversational flow + a consultant identity with a built-in 13-design-axis pattern library**.

### Four things it helps with

| Goal | Mode | Output |
|---|---|---|
| **Design or redesign** the skeleton of an AI agent tool (hook or not? sub-agent or skill? where does memory live?) | `/design` | A prescription + wiring files written directly into your target repo |
| **Health-check** an existing system, find gaps & anti-patterns using the 13 axes as a mirror | `/healthcheck` | A 13-axis assessment report |
| **Retrospect** on a system that's been running, see how it should evolve | `/retro` | Retrospective summary + action items |
| **Produce target-facing docs** (README + CONTRIBUTING, bilingual) | `/document` | Viewer manual (for daily users) + maintainer doc (for future contributors) |

### Why "consultant" and not "scaffold"

Each of the 13 design axes is a **design parameter** (not a switch), and they couple with each other — there's no one-size-fits-all standard configuration. So this is **conversation + pattern library + blueprint as the body**; scaffolding is demoted to the compiled output of consultant decisions.

---

## 2. Quickstart

### Prerequisites

- **Claude Code CLI** installed (`claude --version` works). The only hard requirement.
- A target repo you want to design in mind (**doesn't need to exist yet** — just describable).

> **No `.env`, no API key file required.** This project connects to no external service and stores no secret — its "runtime" is Claude Code itself.

### Get + enter

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
claude
```

After session start **switch to the strongest model with `/model`** — design / reasoning / methodology tasks can't tolerate a weak model (weak models pile up jargon walls, give anti-patterns, leave logic holes). The AI cannot switch its own model; the designer must do it.

Inside, use a **slash command as a discoverable entry**, or just speak in plain language (the consultant identity auto-loads):

```
/design ~/my-project              # Design or redesign a harness
/healthcheck ~/my-project         # Spot-check an existing system
/retro ~/my-project               # Retrospective after some runtime
/document ~/my-project            # Produce external docs
(no command, plain speech)        # Resume a previous session
```

First run usually takes 10–20 minutes to finish the interview and see the first prescription. Full new-user guide: [`docs/getting-started.md`](docs/getting-started.md).

---

## 3. Access & configuration

| File | Required | Purpose |
|---|---|---|
| `targets.yml` | Optional | Your local target repo list. `cp targets.yml.example targets.yml` then edit. Gitignored. |
| `.env` | **Not needed** | Not used by this project, no API key file. |

`targets.yml` lets you record your local target list (path, status `concept`/`pending-audit`/`audited`, optional `eval_dir` to override axis-13 default path). You can pick one when starting a session, or skip it entirely and give an absolute path in conversation.

---

## 4. How to use / Common tasks

You'll enter one of five modes. Each is a **conversational front door** — not a form, not a scaffold; inside it's always a dialogue with the consultant.

| Mode | Command | Plain phrasing | When |
|---|---|---|---|
| **Design** | `/design <target>` | "Design / redesign ~/X" | New or rebuild a harness |
| **Healthcheck** | `/healthcheck <target>` | "Health-check ~/X" | Spot-check existing system (cold-start ok) |
| **Retro** | `/retro <target>` | "Retro ~/X" | After target has been running for a while |
| **Document** | `/document <target>` | "Write docs / produce README" | Docs outdated, handing off to others |
| **Resume** | (no command) | "Continue X's design" | Pick up a previous session |

### Design flow — 6 steps (`/design` runs the full flow)

```
Step 1   Needs interview (10–20 min; button-choice + open questions)
Step 2   Architect drafts the prescription alone (you don't do anything)
Step 3   You review, iterate back-and-forth (plain text feedback, not choices)
Step 4   Phased landing (split into Stage 1/2/3, write into your target repo)
Step 4.5 Self-verify loop (mandatory) — machine-verifiable outputs must run headless ≥ 3 times with machine scoring before delivery
Step 5   Acceptance (consultant runs the auto-verifiable, you try across sessions)
Step 6   Flywheel retrospective (weeks later)
```

First-time users usually reach Step 3 or 4; Step 5–6 as needed. `/healthcheck` and `/retro` are short independent modes, not the full 6 steps.

### Builder vs Human (a hard distinction)

A target repo designed by meta-harness serves two roles:

- **Builder**: the engineer who **designs** the target repo using meta-harness's consultant identity (the person reading this README).
- **Human**: the person who runs target commands and reads results daily — **not necessarily a domain expert** (e.g., an accounting tool's human may be an accounting assistant, not an engineer).

Design axis 12 "Human Interface" is the layer specifically for humans (translation / granularity / feedback channels), symmetric to axis 9 "Observability" (for engineers / systems).

---

## 5. Workflow loop (human vs AI division of labor)

```
┌─────────────────────────────────────────────────────────┐
│                  You (Builder)                           │
│    State needs / review prescription / try across sessions │
└──────────────────┬──────────────────────────────────────┘
                   │ /design ~/my-target
                   ▼
┌─────────────────────────────────────────────────────────┐
│       meta-harness Consultant (Claude Code session)      │
├─────────────────────────────────────────────────────────┤
│  Step 1  Interview 5 things (AskUserQuestion UI)         │
│  Step 2  Draft prescription alone (you don't move)       │
│  Step 3  You feed back → revise blueprint → show         │◀───┐
│  Step 4  Phased landing: write files into target         │    │ Conversational
│  Step 4.5 Self-verify loop (headless ≥ 3 + scoring)     │    │ convergence
│  Step 5  Acceptance (auto-verify + you try)              │ ───┘
│  Step 6  Flywheel retrospective (weeks later)            │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│        Your target repo (the landed AI tool)             │
│  Stop hook + run-self-verify.sh                         │ ◀── Axis 13 physical discipline
│  drift → exit 2 blocks session end                       │
│  coverage.json continuously tracks coverage              │
└─────────────────────────────────────────────────────────┘
```

**When you hand off to AI**: Step 2 (consultant drafts blueprint alone), Step 4 (phased landing writes files), Step 4.5 (self-verify loop), the machine-verifiable parts of Step 5.

**When you take back control for acceptance**: Step 1 (state needs), Step 3 (review blueprint), Step 5's "across-session trial use", Step 6 (flywheel retrospective).

**Automatic gates**: Step 4.5 (headless self-verify ≥ 3 times passing before proceeding) + axis 13 Stop hook (drift blocks session end). These are **physical gates** — the execution layer of R-10 "machine-verifiable outcomes must self-verify before delivery", not bypassable.

---

## 6. Available commands / skills

### Slash commands (front doors, 4)

| Command | Purpose |
|---|---|
| `/design <target>` | New or rebuild a harness, full 6-step flow |
| `/healthcheck <target>` | Spot-check via 13 axes, produce report |
| `/retro <target>` | Flywheel retrospective after runtime |
| `/document <target>` | Produce bilingual README + CONTRIBUTING |

### Skills (consultant core, 2)

| Skill | Purpose |
|---|---|
| `consultant` | Consultant identity definition + full 6-step flow (loads on any command entry) |
| `document` | Extract from prescription + repo state, produce viewer manual + maintainer doc |

### Core docs (when builders want to go deep)

| Doc | Purpose |
|---|---|
| [`docs/getting-started.md`](docs/getting-started.md) | **New-user entry** — first interview in 30 minutes |
| [`.claude/skills/consultant/SKILL.md`](.claude/skills/consultant/SKILL.md) | Consultant identity definition + 6-step details |
| [`docs/design-axes.md`](docs/design-axes.md) | **13-axis index** (design parameter overview) |
| [`docs/design-axes/<n>-<name>.md`](docs/design-axes/) | Per-axis depth + anti-patterns + cases |
| [`docs/universal-care-rules.md`](docs/universal-care-rules.md) | R-1~R-12 (consultant's built-in mandatory hygiene rules) |
| [`docs/prescription-template.md`](docs/prescription-template.md) | Blueprint format (for review comparison) |
| [`docs/manual-template.md`](docs/manual-template.md) | Manual format |
| [`docs/consultant-flow.md`](docs/consultant-flow.md) | Consultant decision logic |
| [`docs/lessons.md`](docs/lessons.md) | Field lessons |

### 13 design axes (one-liner)

Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers / Human Interface / **Self-Verify Coverage**

Each is a **design parameter** (not a switch), coupled with the others — this is exactly why we use consultant mode rather than a fixed template.

---

## 7. What it produces + How to verify it's right

### Session-time artifacts (meta-harness local trail, **all gitignored**)

| Path | Content |
|---|---|
| `sessions/<date>-<topic>.md` | Interview notes (5 answers + axis filter table) |
| `prescriptions/<date>-<target>.md` | Consultant's pre-action blueprint / audit trail |
| `cases/` | Distilled cases per target (forks should not see others' tasks) |
| `experiments/<target>-<topic>/runs/` | Step 4.5 self-verify raw evidence (contains real target IDs) |
| `BACKLOG.md` | Your own list of "rule/methodology gaps encountered" |

Each gitignored directory keeps a tracked `README.md` or structure file so forks know how to use it without seeing private content.

### Files written into your target repo (Step 4 landing)

Consultant writes wiring files into your target repo via **absolute path** (cwd stays in meta-harness). What it writes is blueprint-driven; common ones: `.claude/hooks/*.sh`, `.claude/skills/<name>/SKILL.md`, `.claude/commands/*.md`, `.claude/settings.json`, `experiments/<target>-eval/test-*.sh`, etc.

### How to verify it's right (axis 13: self-verify coverage / R-10 physical layer)

Every target repo (meta-harness itself included) lands a three-piece kit:

- `experiments/<target>-eval/run-self-verify.sh` — single entry point, runs all `test-*.sh`
- `experiments/<target>-eval/test-*.sh` — wiring-specific scorers (written per the 4 Patterns)
- `experiments/<target>-eval/coverage.json` — data dashboard (scorers / check totals / mechanism coverage)
- `.claude/hooks/self-verify-on-stop.sh` + settings.json Stop registration — drift physically blocks session end

**Four Pattern classification** (every `test-*.sh` must belong to one):

- **A. Single source of truth + drift detection** (config / wiring cross-file consistency)
- **B. Trigger + assert** (does the hook / middleware get triggered correctly)
- **C. Scorer + METRICS line** (behavioral quality / agent output)
- **D. Snapshot + diff** (are side effects correct)

Landing reference numbers:

| Target | Scorers | Checks | Coverage |
|---|---|---|---|
| meta-harness itself | 13 | 216 | **100% (15/15)** |
| atdd-task | 7 | 58 | 47% (7/15) |

See [`docs/design-axes/13-self-verify-coverage.md`](docs/design-axes/13-self-verify-coverage.md).

---

## 8. Boundaries: What it won't do + Known limits

### Won't do

- **Not a scaffold generator**: there's no `meta-harness new <type>` to give you a standard directory. Rationale in §1 "Why consultant".
- **Won't write your target's business logic**: consultant works on framework (hook / skill / command / settings / self-verify wiring), not task content (business rules, domain knowledge inside agent prompts). Per rule R-9.
- **No cross-layer overreach**: framework doesn't speak for task content (R-9); method-level rules don't get written into target-specific docs (R-8).
- **Won't bypass self-verify discipline**: machine-verifiable outputs must run headless ≥ 3 times first (Step 4.5, R-10). Stop hook physically blocks "no self-verify, no commit" (axis 13).
- **No external services**: no API key, no telemetry, no remote sync. Runtime is Claude Code itself.

### Known limits

- **Depends on Claude Code environment**: doesn't run in ChatGPT / Cursor / other IDEs (consultant identity uses Claude Code's skill and slash command mechanics).
- **Best used with the builder present**: design flow relies on dialogue; can't run autonomously without a builder (flywheel retrospective is a partial exception).
- **LLM-output quality self-verify still leans structural**: Pattern A/B/D well landed; Pattern C (LLM-judge of agent output quality) standard infrastructure still evolving.
- **Session quota**: spawning many `claude -p` subprocesses (e.g., agent×model eval matrix) will hit the Claude Code subscription's session ceiling; to avoid, set `ANTHROPIC_API_KEY` to use API billing instead.

---

## 9. What to do when things go wrong

### Common situations

| Symptom | Handling |
|---|---|
| Stop hook keeps blocking session end / prints "⛔ self-verify failed" | Run `bash experiments/meta-harness-eval/run-self-verify.sh` to see which scorer drifted. R-10 isn't punishment, it's a reminder: drift is real, fix first. |
| Consultant rambles / starts lecturing concepts instead of producing a blueprint | Snap it back to architect mode: "You're an architect, not a textbook reciter; give me the mechanism." The consultant skill has identity-drift defenses, but builder self-check is another layer. |
| Unsure whether to elevate an axis / R-N | See `docs/consultant-flow.md` decision logic, or ask in session "Should this be elevated to universal? Does it hold across targets?" |
| After landing, wiring doesn't match prescription | Run `experiments/meta-harness-eval/test-cross-references.sh` — auto-detects R-N / axis-N drift. Or manual grep. |
| Claude session hits quota limit | See the message for reset time; long-term fix is setting `ANTHROPIC_API_KEY` to switch to API billing (separate quota pool). |

### Lessons learned (growing list)

`docs/lessons.md` accumulates field lessons (each with "why it bit, how to prevent next time").

### Can't find an answer?

Go to [Issues](https://github.com/spenguinlui/meta-harness/issues) or open a PR; you can also tell the consultant in-session "I think there's a methodology gap here" — it'll help you decide whether to elevate to R-N or place in `docs/lessons.md`.

---

## 10. Who maintains / How to report

- **Maintainer**: [@spenguinlui](https://github.com/spenguinlui) (the primary builder of this methodology).
- **Report issues / suggestions**: open a [GitHub Issue](https://github.com/spenguinlui/meta-harness/issues); attach the **concrete situation hit** (which session, which prescription, which axis/rule got stuck) — more useful than abstract suggestions.
- **Want to extend the methodology itself** (add an axis / rule / skill): read [`CONTRIBUTING.md`](CONTRIBUTING.md) first — it covers the discipline for "extending meta-harness itself."
- **Want to share your prescription / blueprint**: PRs to `cases/` welcome (but remember `prescriptions/` is gitignored and contains target-private content; for sharing, write a distilled version).

---

## 11. Glossary

meta-harness internal coinages. Even peers should glance through:

| Term | Plain meaning |
|---|---|
| **target repo (target)** | The AI agent tool's repo you're designing — NOT meta-harness itself. |
| **builder** | The engineer who **designs** the target using meta-harness's consultant identity. The person reading this README. |
| **human** | The person who **uses** the target daily. May or may not be the same person as the builder (e.g., accounting assistant vs system engineer). |
| **viewer** | Manual-template term, near-equivalent to human — the manual's audience. |
| **consultant identity** | The role the Claude Code session adopts inside meta-harness after loading the `consultant` skill. Architect persona, non-drifting. |
| **prescription (blueprint)** | The pre-action blueprint doc the consultant writes (lands at `prescriptions/<date>-<target>.md`). For the architect's eyes. |
| **manual** | What `/document` produces for the target's outward-facing README + CONTRIBUTING. For viewer / maintainer eyes. |
| **design axis / axis N** | The 13 design parameters (Tool / Context / Memory / ...). Each is a parameter space, not a switch. |
| **R-N (universal-care-rules)** | 12 cross-target hygiene rules (R-1 CLAUDE.md ≤ 50 lines, R-10 self-verify discipline, R-12 self-containment, etc.). |
| **wiring** | The whole connection of hook / skill / command / settings etc. wired into behavior. |
| **mechanism** | In consultant context = the concrete approach of a wiring (not a file, a behavior). |
| **anti-scope** | The explicit "don't do" list. Mandatory in Step 1 interview. |
| **flywheel (retrospective)** | Retrospect after target has been running — 4 checks: outcome→skill distillation, signal accumulation feedback, memory shape, methodology gap. |
| **dog food** | Using your own methodology on yourself (e.g., meta-harness using its own axis 13 to self-verify). |
| **headless (self-verify)** | `claude -p` non-interactive mode, run ≥ 3 times + machine scoring, mandatory in Step 4.5. |
| **drift** | Wiring inconsistent with blueprint / source of truth. The detection target of axis 13 self-verify. |

Industry terms (hook / skill / slash command / CLI / DDD / TDD / Pattern, etc.) are not listed here — peer audience assumed.

---

## Repo structure

```
.claude/
  hooks/                    Consultant's own hooks (cwd guard, CLAUDE.md line check, question self-audit, self-verify-on-stop)
  skills/consultant/        Consultant identity skill (core, loads on any command entry)
  skills/document/          /document skill
  commands/                 design / healthcheck / retro three front doors (document triggered by commands, main logic in skill)
  settings.json             Hook registration (including axis 13 Stop hook)
docs/
  getting-started.md        New-user entry
  consultant-flow.md        Consultant decision logic
  design-axes.md            13-axis index
  design-axes/              Per-axis depth (including 13-self-verify-coverage.md)
  universal-care-rules.md   R-1~R-12 hygiene rules
  prescription-template.md  Blueprint format (includes "software engineering discipline mapping": Strategy/Specification/Middleware/...)
  manual-template.md        Manual format
  lessons.md                Field lessons
experiments/
  meta-harness-eval/        meta-harness's own axis 13 landing (runner / 13 scorers / coverage.json)
  consolidation-loop/       Reference implementation of self-verify loop
targets.yml.example         Target list template (cp to targets.yml to use)
─── Below gitignored (per-fork private content, not in git) ───
targets.yml                 Your local target list
sessions/                   Interview notes
prescriptions/              Blueprint trail
cases/                      Per-task case library
experiments/*/runs/         Self-verify raw evidence
BACKLOG.md                  Undigested failures / gaps list
```

---

## Status

**v0.5 — Axis 13 self-verify coverage + software engineering methodology mapping**

- ✅ **13 design axes complete** (v0.5 adds "Self-Verify Coverage" — R-10 elevated from discipline to a quantifiable KPI + physical gate)
- ✅ universal rules R-1~R-12 (R-11 bilingual manual, R-12 target self-containment)
- ✅ Consultant skill locks architect identity + 6-step flow
- ✅ `/document` skill (bilingual README + CONTRIBUTING auto-produced)
- ✅ Memory multi-axis taxonomy + Plan-as-memory + Outcome-as-skill bidirectional flywheel
- ✅ meta-harness self-landing of axis 13: 13 scorers / 216 checks / **100% coverage (15/15)**
- ✅ atdd-task first external target landing axis 13: 7 scorers / 58 checks / 47% coverage (7/15)
- 🔄 Cross-target rollout in progress (ai-infra-management / figma2code / self-profile / google_sheet_builder pending)

---

## License

MIT
