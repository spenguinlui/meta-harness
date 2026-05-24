> 🌐 [繁體中文](README.md) | **English**

# meta-harness

> **A methodology for designing AI agent harnesses + the consultant wiring.**
> Prompt engineering tweaks words; harness engineering changes "the whole system around the model".
> Applies to any implementation medium — bash scripts, web apps, SaaS, hybrid products — as long as there's an AI agent inside.

---

## 1. What is this? What can it do?

`meta-harness` is an "**AI-agent systems design consultant (architect) + implementer**" that lives inside Claude Code.

You don't "run" this project — you **enter its directory and open a Claude Code session**, and it becomes an architect who knows the craft and best practices, working with you to design and build some AI agent tool (which we call a **target repo**).

```
You bring a need  →  consultant produces a design  →  you review  →  consultant writes files into your target repo  →  acceptance
```

It is **not** a framework, not a CLI tool, not a scaffold generator. It is a **conversational flow + a consultant persona with a built-in 12-axis design pattern library**.

### Three kinds of things it helps with

| What you want to do | Which mode | Output |
|---|---|---|
| **Build or redesign** the skeleton of an AI agent tool (hook or not? sub-agent or skill? how to store memory?) | `/design` | A design doc + wiring files written straight into your target repo |
| **Health-check** an existing system, using the 12 axes as a mirror to find gaps and anti-patterns | `/healthcheck` | A 12-axis health-check report |
| **Retrospect** a system that's been running a while, to see how it should evolve | `/retro` | A retrospective note + action suggestions |

### Why a "consultant" and not a "scaffold"?

The first instinct is `meta-harness new <domain>` producing a standard directory. But each of the 12 axes is a **design parameter**, not a switch, and they're coupled — there's no single combo that fits everyone. So this uses a consultant model: conversation + pattern library + design doc as the main body, with scaffolding demoted to a compiled artifact of the consultant's conclusions.

---

## 2. Install & Prerequisites

### Prerequisites

- **Claude Code CLI** installed (`claude --version` works in your terminal). This is the only hard requirement.
- A target repo you have in mind (**it need not exist yet** — you just need to articulate "what it should do").

> **No `.env`, no API key file needed.** This project itself connects to no external service and stores no secrets — its "runtime" is Claude Code itself. The only local config file is `targets.yml` below, purely for your own record of targets, **optional, not required**.

### Get the project

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
```

### (Optional) Create your target list

```bash
cp targets.yml.example targets.yml      # targets.yml is gitignored, won't be uploaded
```

`targets.yml` lets you track which target repos you have locally, their paths and status (concept / pending-audit / audited). You can pick one when opening a session, or skip it entirely and just tell the consultant the target's absolute path in conversation.

---

## 3. How to Use (steps)

### Open a session

Before running design work, **switch to the strongest model with `/model`** — design, reasoning, and methodology tasks can't afford weak thinking (a weak model tends to stack jargon walls, emit anti-patterns, and leave logic holes). An AI can't switch its own model; this is a step the designer must take.

```bash
cd ~/meta-harness
claude
```

Inside, use a **slash command as the front door** to pick a mode, or just speak plainly (the `consultant` skill auto-loads):

| Command | Plain phrasing | When |
|---|---|---|
| `/design <target absolute path>` | "I want to design / redesign ~/my-project" | Build or redesign a harness |
| `/healthcheck <target absolute path>` | "Health-check ~/my-project" | Point check an existing system, find gaps (works cold-start) |
| `/retro <target absolute path>` | "Retrospect ~/my-project" | Look back at evolution after a target has run a while |
| (no command) | "Continue last design of X" | Resume an unfinished session |

> A command is just a "discoverable front door" — once inside it's always a consultant conversation, **not a form, not a scaffold**.

### Design flow: 6 steps (`/design` runs the full flow)

```
Step 1   Requirements interview (you + consultant, 10–20 min)
         The consultant first asks you to introduce the project, then asks 5 things via button choices:
         mission/pain, current shape, anti-scope (what it shouldn't do), failure floor + lifespan, human domain familiarity
         → produces the "12-axis stakes filter table" (which axes to fully design, which are N/A)

Step 2   The architect produces the design alone (you do nothing)
         The consultant writes prescriptions/<date>-<target>.md, then pastes you the highlights

Step 3   You review, iterate to convergence
         You give plain-language feedback → consultant revises the design → shows you again (not multiple choice)

Step 4   Staged implementation
         The prescription is split into Stage 1/2/3, files written into your target repo (absolute paths)

Step 4.5 Self-verify loop (mandatory)
         For any "machine-verifiable" output (slash command / skill / pipeline),
         the consultant must headless-run ≥ 3 times + machine-score before handing it over — no eyeballing once and calling it OK

Step 5   Acceptance
         The consultant runs the auto-verifiable parts (files exist, hooks actually fire, permissions aligned);
         you do the cross-session real usage

Step 6   Flywheel retrospective (weeks later)
         After the target runs a while, look back: should repeated manual actions be distilled into a skill?
         Is the memory shape healthy? Should an exposed recurring mistake be promoted to methodology?
```

> The first time, you usually only go to Step 3 or 4; Steps 5–6 as needed. Health-check (`/healthcheck`) and retro (`/retro`) are standalone modes that don't run the full 6 steps.

### Two roles: Builder vs Human

A target repo designed by meta-harness serves two kinds of people (possibly the same person), which must be distinguished at design time:

- **Builder**: the engineer who **designs** this target repo using the meta-harness consultant persona (the you reading this README).
- **Human**: the person who runs the target's commands daily and makes decisions from the results — **not necessarily a domain expert** (e.g., an accounting system's human may be an accounting assistant, not an engineer).

Design axis 12 "Human Interface" is the interface layer designed specifically for the human (translation, granularity, feedback channel), symmetric to axis 9 "Observability" (for engineers / systems). The builder understands jargon, the human may not — that's a hard distinction at design time.

---

## 4. What files it produces / what files it needs

### Files you need to prepare

| File | Required? | Notes |
|---|---|---|
| `targets.yml` | **Optional** | Your local target list. `cp targets.yml.example targets.yml` then edit. Gitignored. |
| `.env` | **Not needed** | This project uses no `.env` and needs no API key file. Runtime = Claude Code itself. |

### Files produced during a session

These are the "traces" the consultant creates for you in a session, **all gitignored** (they contain real PII / infra IDs / owner conversations that shouldn't be uploaded; each fork's tasks don't cross-contaminate):

| Path | Content |
|---|---|
| `sessions/<date>-<topic>.md` | Notes from each requirements interview (5 answers + axis filter table) |
| `prescriptions/<date>-<target>.md` | The pre-implementation design doc / audit trail ("what to change, why") |
| `cases/` | Cases distilled from specific targets (a fork shouldn't see others' tasks) |
| `experiments/<target>-<topic>/runs/` | Raw evidence from the Step 4.5 self-verify loop (contains real target IDs) |
| `BACKLOG.md` | Your list of "rules tripped / methodology gaps" not yet digested |

> Each gitignored directory keeps a version-controlled `README.md` or structure file (`gold.md` / `run.sh` / `eval.sh` / `prompts/`), so a fork knows how the directory is used without seeing others' private content.

### Files written into "your target repo"

At Step 4, the consultant writes wiring files straight into your target repo using **absolute paths** (cwd never leaves meta-harness). What gets written is decided by the design; common ones: `.claude/hooks/*.sh`, `.claude/skills/<name>/SKILL.md`, `.claude/commands/*.md`, `.claude/settings.json`, etc.

---

## 5. Core Document Guide

To dig into the consultant's pattern library, read these:

| Document | Purpose |
|---|---|
| `docs/getting-started.md` | **Beginner entry** — run your first Phase 0 within 30 minutes |
| `.claude/skills/consultant/SKILL.md` | Consultant persona + the full 6-step flow (core) |
| `docs/design-axes.md` | **12-axis index** (design-parameter overview) |
| `docs/design-axes/<n>.md` | Each axis's deep options + anti-patterns |
| `docs/universal-care-rules.md` | The universal rules (R-1~R-11, hygiene rules the consultant enforces) |
| `docs/prescription-template.md` | Design-doc format (for review reference) |
| `docs/consultant-flow.md` | Consultant decision logic (Phase 0→1 reordering) |
| `docs/manual-template.md` | Handbook format (the deliverable docs for a target) |
| `docs/lessons.md` | Field lessons |

### The 12 design axes

> Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers / **Human Interface**

Each is a "design parameter", not a switch, and they're coupled — which is exactly why this uses a consultant model rather than a fixed template.

---

## 6. Repo Structure

```
.claude/
  hooks/                    consultant wiring hooks (cwd guard, line-count check, question self-check)
  skills/consultant/        consultant persona skill (core)
  skills/{design,healthcheck,retro,document}/  mode front doors
  commands/                 discoverable slash-command entries
  settings.json             hook registration
docs/
  getting-started.md        beginner entry
  consultant-flow.md        consultant decision logic
  design-axes.md            12-axis index
  design-axes/              per-axis depth
  universal-care-rules.md   R-1~R-11 hygiene rules
  prescription-template.md  design-doc format
  manual-template.md        handbook format
  lessons.md                field lessons
experiments/
  consolidation-loop/       reference impl of the self-verify loop (run.sh / eval.sh / prompts / gold)
targets.yml.example         target-list template (cp to targets.yml to use)
─── below is gitignored (each fork's own content, not committed) ───
targets.yml                 your local target list
sessions/                   interview notes
prescriptions/              design-doc traces
cases/                      task case library
experiments/*/runs/         self-verify raw evidence
BACKLOG.md                  undigested failures / gaps
```

---

## 7. Status

**v0.4 — Human Interface axis + multi-axis memory + flywheel retrospective**

- ✅ **12 design axes complete** (v0.4 added Human Interface — the human-facing IO boundary, symmetric to axis 9 system-facing)
- ✅ Universal rules (R-6 extended to target runtime output; R-8 no cross-layer overreach; R-9 framework vs task content; R-10 machine-verifiable outcomes self-verified first; R-11 ship-with-a-manual)
- ✅ Consultant skill locks the architect persona + the full 6-step flow
- ✅ Cwd-guard hook + R-1/R-3/R-5/R-6 enforcement hooks
- ✅ Multi-axis memory classification (content type / scope / storage form / access pattern)
- ✅ Plan-as-memory + Outcome-as-skill bidirectional flywheel
- 🔄 Cross-target validation in progress (ai-infra-management v1 live + multiple iteration rounds)

---

## License

MIT
