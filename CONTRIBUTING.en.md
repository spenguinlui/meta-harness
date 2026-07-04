> 🌐 [繁體中文](CONTRIBUTING.md) | **English**

# Extending the meta-harness Methodology

For people **extending the consultant methodology itself** (adding design axes, rules, lessons, skills).
If you want to **use** this flow to design your own harness, see [`README.en.md`](./README.en.md); this doc covers **the methodology's architecture and how to evolve it**.

> Two-reader split (meta-harness eats its own dogfood): README = users of the consultant flow (Viewer); this doc = those modifying the consultant framework (Maintainer).

---

## Architecture overview

meta-harness is not a framework; it's "**consultant identity + pattern library + conversational flow**". Three layers:

```
Identity layer  .claude/skills/consultant/SKILL.md     Architect persona + 6-step flow (non-drifting)
                .claude/skills/document/SKILL.md       /document mode (bilingual manual production)

Knowledge layer docs/design-axes/ (13 axes)            Design parameter space (including axis 13 Self-Verify Coverage)
                docs/universal-care-rules.md (R-1~R-12) Hygiene rule floor
                docs/prescription-template.md          Blueprint format (includes "software engineering discipline mapping" section)
                docs/manual-template.md                Manual format
                docs/lessons.md                        Insights accumulated (not necessarily elevated to R-N)

Front-door     .claude/commands/                       design / healthcheck / retro / document four slash commands
                .claude/hooks/                          cwd guard + line/question reminders (3 advisory) + self-verify-on-stop (1 blocking)

Self-verify    experiments/meta-harness-eval/          meta-harness's own axis 13 landing
                ├── run-self-verify.sh                  Single entry point (13 scorers / 216 checks)
                ├── test-*.sh                           Pattern A/B scorers
                ├── coverage.json                       KPI dashboard (100% coverage)
                └── generate-coverage.sh                Generates coverage.json from test results
```

- **13 design axes** = design **parameter space** (not a checklist), coupled to each other.
- **R-1~R-12** = cross-target hygiene floor (written rules; landing is mostly hook reminders — only the Stop hook can block).
- **`docs/lessons.md`** = insights (the why), distinct from rules: rules are mandatory, lessons are experience.

### Dog food three-layer closed loop (meta-harness proves its own methodology)

```
atdd-task passes its own self-verify (7 scorers / 58 checks)
    ↑ Required by
meta-harness (requires targets to self-verify)
    ↑ Requires itself too
meta-harness passes its own self-verify (13 scorers / 216 checks / 100% coverage)
    ↑ Requires prescription structure
This CONTRIBUTING (meta-harness's maintainer doc to itself)
```

"The shoemaker's child has shoes" is a **verifiable engineering fact** here, not a metaphor.

---

## How wiring works

| Component | Purpose |
|---|---|
| `.claude/skills/consultant/` | Consultant identity + complete 6-step flow (core; loads on any mode entry) |
| `.claude/skills/document/` | `/document` mode logic (bilingual README + CONTRIBUTING auto-production) |
| `.claude/commands/{design,healthcheck,retro,document}.md` | Four front-door slash commands |
| `.claude/hooks/cwd-guard.sh` | SessionStart: guards cwd from leaving meta-harness (**advisory**, prints a warning, does not block) |
| `.claude/hooks/post-write-line-check.sh` | PostToolUse(Write/Edit): reminds when R-1 (CLAUDE.md line count) / R-3 (hook line count) exceed the threshold (**advisory**, no block) |
| `.claude/hooks/pre-askquestion-reminder.sh` | PreToolUse(AskUserQuestion): R-5 (questions anchor artifacts) / R-6 (no unexplained jargon) self-audit reminder (**advisory**, no block) |
| `.claude/hooks/self-verify-on-stop.sh` | Stop: **the only blocking hook** — runs full self-verify at session end; drift exit 2 blocks (axis 13 physical gate) |
| `.claude/settings.json` | Hook registration (SessionStart / PreToolUse / PostToolUse / Stop) — **1 blocking (Stop) + 3 advisory (remind but don't block)** |
| `docs/*-template.md` | Prescription (blueprint) + manual format |
| `experiments/<topic>/` | Reference implementation (e.g., `consolidation-loop/`) |
| `experiments/meta-harness-eval/` | **meta-harness's own axis 13 landing** — dog food evidence |

---

## How to extend

### Add a design axis

1. Create `docs/design-axes/<n>-<name>.md` (decision options + couplings + anti-patterns + cases)
2. Add a line to the `docs/design-axes.md` index
3. Bump the `# Harness <N> design axes (index)` title number
4. Update `.claude/commands/healthcheck.md` axis count references (self-verify will catch drift)
5. **Orthogonality check**: don't overlap with the existing 13 axes (e.g., 7 vs 11, 9 vs 12 boundaries are already drawn)

Run `bash experiments/meta-harness-eval/run-self-verify.sh` → should be all green (`test-healthcheck-axis-consistency` catches axis count alignment).

### Add a universal rule (R-N)

1. Add a `## R-N：<name>` section in `docs/universal-care-rules.md` (definition / why / rule / landing)
2. **Criterion**: **Does it still hold leaving this target / this person**? Only cross-target qualifies as universal; target-specific stays in the target's own doc.
3. Commit message must answer "**why can't we delete the source**" (R-7 discipline — don't ossify bad flow, fix root cause)
4. Run self-verify → `test-universal-care-rules-schema.sh` checks R-N numbering continuity + content completeness

### Add a lesson

Hit a recurring failure → write in `docs/lessons.md` (insight, **not a mandatory rule**). Once validated to be universal across enough cases → elevate to R-N.

### Add a mode / skill

Follow `document` skill as template:

1. Create `.claude/skills/<name>/SKILL.md` (frontmatter `name:` + `description:` required)
2. Add a row to the consultant skill's trigger table
3. Hook into the 6-step flow if needed (e.g., Step 5.5 / Step 6)
4. Add the matching slash command in `.claude/commands/<name>.md` (front door)
5. Self-verify will catch frontmatter / reference alignment via `test-skill-spec-format.sh` + `test-slash-command-flow-integrity.sh`

### Modify prescription / manual template

Edit `docs/prescription-template.md` or `docs/manual-template.md` directly. Run self-verify → `test-prescription-template-structure.sh` checks structure (Header + Part A-F + the "modal-use guidelines" all still present).

---

## Design rationale (why this way)

- **Consultant, not scaffold**: 13 axes are coupled parameters; no standard template fits all → conversation + pattern library as the body.
- **Layered rules** (avoid "a single doc with 13 disconnected anti-patterns"): cross-flow universals (R-N) / design flow (consultant-flow) / blueprint format (template) / anti-patterns kept separate.
- **R-10 physicalized (axis 13)**: R-10 "machine-verifiable outcomes must self-verify before delivery" was originally a discipline, now elevated to a **physical gate** — Stop hook + coverage.json + run-self-verify.sh kit. So "no self-verify no commit" becomes an OS-level fact, not relying on human memory.
- **R-12 self-containment** (target landing files don't leak meta-harness identity): targets are independent repos; their readers don't have meta-harness. But **R-12 doesn't apply to meta-harness itself** — prescription / design axis / R-N are meta-harness's ubiquitous language; they should be spoken here.

### Four governance rules (must read before modifying methodology)

- **R-7**: Don't ossify bad flow; fix root cause first (piling on patches = rule bloat trap)
- **R-8**: No cross-layer overreach (method-level rules don't go into target-specific docs)
- **R-9**: Framework vs task content split (meta-harness touches framework, not target business logic)
- **R-12**: Target landing files self-contained (**doesn't apply to meta-harness itself**, but understand its purpose when modifying R-12 / `/document` skill)

---

## How to verify changes

### Axis 13 self-verify (OS-level gate)

Run `bash experiments/meta-harness-eval/run-self-verify.sh` → **must be 13/13 all green**.

Any scorer red = drift. Stop hook will block session end (unless drift is fixed).

The 13 scorers' covered mechanisms:

| Scorer | Covers |
|---|---|
| `test-cross-references.sh` | Prescription R-N / axis-N reference integrity |
| `test-prescription-format.sh` | Prescriptions structure (Part A-F + frontmatter) |
| `test-prescription-template-structure.sh` | Template's own structure |
| `test-target-coverage.sh` | targets.yml ↔ target coverage.json landing progress |
| `test-design-axes-doc-completeness.sh` | 13 design axes doc structure complete |
| `test-healthcheck-axis-consistency.sh` | healthcheck axis count refs ↔ actual |
| `test-skill-spec-format.sh` | SKILL.md frontmatter |
| `test-universal-care-rules-schema.sh` | R-N numbering continuity + content existence |
| `test-self-verify-stop-hook-behavior.sh` | Stop hook three behaviors (no runner / green / red) |
| `test-run-self-verify-runner-integrity.sh` | Runner three states (no test / all green / red) |
| `test-slash-command-flow-integrity.sh` | Slash command frontmatter + ref file existence |
| `test-consultant-skill-structure.sh` | Consultant core vocab completeness |
| `test-coverage-json-schema.sh` | Cross-target coverage.json schema consistency |

New wiring → new `test-*.sh` to cover it. **Pick one of the four Patterns** (see axis 13 doc):

- **A. Single source of truth + drift detection** (config / wiring cross-file consistency)
- **B. Trigger + assert** (does the hook / middleware receive the correct trigger)
- **C. Scorer + METRICS line** (behavioral quality / agent output)
- **D. Snapshot + diff** (are side effects correct)

### Dogfood (any new capability runs live first)

Any new skill / command / template must run on a real target once (e.g., `/document` wrote figma2code before writing itself; axis 13 landed in meta-harness before rolling to atdd-task). **No dogfood = unverified delivery (R-10 anti-pattern)**.

### Hygiene checks when changing rules / adding axes

- **grep root cause**: don't just patch symptoms (R-7).
- **Orthogonality confirmation**: don't overlap with existing axes / R-N (e.g., 7 vs 11, 9 vs 12 boundaries drawn; axis 13 vs R-10 is "KPI vs discipline" layering).
- **Cross-target trial**: before elevating to universal, verify the rule holds in ≥ 2 real targets (otherwise put it in `docs/lessons.md`).
- **commit message R-7**: before commit, self-answer "why can't we delete the source, only add a rule".

### After modifying prescription / template

Run self-verify; `test-prescription-template-structure.sh` should stay green. If you change structure outside Part A-F (e.g., adding Part G), update that test's expectations too.

---

## Relationship with external targets

Targets designed by meta-harness are **independent repos** — they should self-contain, not require meta-harness to run. R-12 specifies "target landing files don't leak meta-harness identity" (don't reference `prescription / design axis / R-N` jargon in the target README).

But **this relationship is one-way**: targets don't know meta-harness; meta-harness knows and tracks targets (via `targets.yml` + `test-target-coverage.sh`).

Cross-target dog-food progress is continuously monitored by `experiments/meta-harness-eval/test-target-coverage.sh`:

| Target | Axis 13 landing |
|---|---|
| meta-harness itself | ✅ 100% (15/15) |
| atdd-task | ✅ 47% (7/15) |
| ai-infra-management | ⏳ Pending |
| figma2code | ⏳ Pending |
| self-profile | ⏳ Pending |
| google_sheet_builder | ⏳ Pending |

Process for landing axis 13 in a new target:

1. Create `experiments/<target>-eval/run-self-verify.sh` in the target (reuse meta-harness's portable version)
2. Add `.claude/hooks/self-verify-on-stop.sh` + `settings.json` Stop registration
3. Write `test-*.sh` for each of the target's wirings (per the four Patterns)
4. Run `generate-coverage.sh` to produce `coverage.json`; the builder fills in `mechanisms_inventory` manually
5. In meta-harness's `targets.yml` entry for that target, add `eval_dir` (if the directory isn't `<target>-eval`)
6. Run `meta-harness/experiments/meta-harness-eval/test-target-coverage.sh` to confirm landing detected
