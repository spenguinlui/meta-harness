> 🌐 [繁體中文](CONTRIBUTING.md) | **English**

# Extending the meta-harness method

This document is for people extending the method itself: adding a design dimension, adding a rule, recording a lesson, adding a mode or a skill.

If you just want to use this flow to design your own harness, read [`README.en.md`](./README.en.md). This one is about the architecture of the method and how to change it.

Two audiences, two documents — meta-harness follows its own rule here. The README is for people using the flow; this one is for people modifying the framework.

---

## Architecture overview

meta-harness is not a framework. It's a consultant role, a catalogue of techniques, and a conversation flow. Four layers:

```
Role layer        .claude/skills/consultant/SKILL.md   The consultant role and six-step flow.
                                                       Must not drift.
                  .claude/skills/document/SKILL.md     Produces bilingual documentation

Knowledge layer   docs/design-axes/                    The 13 design dimensions — a space of options
                  docs/universal-care-rules.md         R-1 through R-12, the baseline rules
                  docs/prescription-template.md        Design plan format, including the mapping
                                                       to software engineering practice
                  docs/manual-template.md              Documentation format
                  docs/lessons.md                      Accumulated lessons; not all become rules

Entry layer       .claude/commands/                    design / healthcheck / retro / document
                  .claude/hooks/                       working-directory guard, line-count check,
                                                       pre-question self-check (all three only warn),
                                                       plus self-verify-on-stop (the only blocker)

Verification      experiments/meta-harness-eval/       meta-harness verifying itself
                  ├── run-self-verify.sh               Single entry point; runs every test-*.sh
                  ├── test-*.sh                        The individual verification scripts
                  ├── coverage.json                    The dashboard; live numbers come from here
                  └── generate-coverage.sh             Builds coverage.json from test results
```

A few things to understand up front.

The 13 design dimensions are a space of options, not a checklist, and they affect each other.

R-1 through R-12 are the baseline that applies across projects. They're written rules; enforcement is mostly hook reminders, and only the Stop hook can actually block.

`docs/lessons.md` holds insights — the reasoning behind decisions. The difference from rules: rules are mandatory, lessons are experience.

### Dogfooding is a three-layer loop

```
atdd-task passes its own verification (own scripts; live numbers in its coverage.json)
    ↑ required by
meta-harness requires target projects to self-verify
    ↑ and requires itself to do the same
meta-harness passes its own verification (numbers in coverage.json,
                                          maintained by generate-coverage.sh)
    ↑ which is required by
this CONTRIBUTING (meta-harness's own maintainer documentation)
```

"The cobbler's children have shoes" is a verifiable engineering fact here, not a metaphor.

---

## What each piece does

| Piece | What it does |
|---|---|
| `.claude/skills/consultant/` | The consultant role and the full six-step flow. Core; loaded by every mode |
| `.claude/skills/document/` | The logic behind `/document`, producing bilingual README and CONTRIBUTING |
| `.claude/commands/{design,healthcheck,retro,document}.md` | The four entry points aimed at target projects |
| `.claude/commands/upkeep.md` | For maintaining meta-harness itself. After nobody has touched it for a while, run one round of upkeep: self-verification, recomputing the project list and coverage, checking whether backlog items have gone stale, then a health summary. Weekly is a reasonable cadence |
| `.claude/hooks/cwd-guard.sh` | At session start, checks the working directory hasn't left meta-harness. Warns only |
| `.claude/hooks/post-write-line-check.sh` | After a write, checks CLAUDE.md and hook line counts. Reminds only |
| `.claude/hooks/pre-askquestion-reminder.sh` | Before asking a question, reminds about R-5 and R-6. Reminds only |
| `.claude/hooks/self-verify-on-stop.sh` | The only hook that blocks. Runs the full verification suite at session end; exits 2 if things don't line up |
| `.claude/settings.json` | Hook registration: one blocking, three advisory |
| `docs/*-template.md` | Formats for the design plan and the documentation |
| `experiments/<topic>/` | Reference implementations, e.g. `consolidation-loop/` |
| `experiments/meta-harness-eval/` | meta-harness verifying itself; the dogfooding evidence |

---

## How to extend it

### Add a design dimension

1. Create `docs/design-axes/<n>-<name>.md` covering the options, how it interacts with other dimensions, common mistakes, and real cases.
2. Add a line to the index in `docs/design-axes.md`.
3. Bump the count in that file's title.
4. Update the count referenced in `.claude/commands/healthcheck.md`. Verification checks that these two agree.
5. Make sure it doesn't overlap an existing dimension. The boundaries between 7 and 11, and between 9 and 12, are already drawn — use them as examples.

Run `bash experiments/meta-harness-eval/run-self-verify.sh`; everything should pass.

### Add a rule

1. Add a `## R-N: <name>` section to `docs/universal-care-rules.md` covering what it is, why, the rule itself, and how it's enforced.
2. The test is: does this still hold in a different project, for a different person? Only rules that travel become general rules. Project-specific ones stay in that project's own documentation.
3. The commit message must answer "why can't the root cause just be removed?" That's the R-7 discipline: don't cement bad workflows, fix the root cause first.
4. Run verification. `test-universal-care-rules-schema.sh` checks the numbering is contiguous and every rule has content.

### Record a lesson

When you hit a recurring mistake, write it into `docs/lessons.md`. That's an insight, not a mandatory rule.

Once it's been validated enough times to look general, promote it to a rule.

### Add a mode or skill

Follow the shape of the `document` skill:

1. Create `.claude/skills/<name>/SKILL.md`; `name` and `description` in the frontmatter are required.
2. Add a row to the trigger table in the consultant skill.
3. Hook it into the six-step flow if it belongs there.
4. Add a matching command at `.claude/commands/<name>.md`.
5. Verification will check frontmatter and references via `test-skill-spec-format.sh` and `test-slash-command-flow-integrity.sh`.

### Change the design plan or documentation format

Edit `docs/prescription-template.md` or `docs/manual-template.md` directly.

Run verification; `test-prescription-template-structure.sh` checks the structure is intact (Header, Part A through F, and the usage rules section).

---

## Why it's built this way

**Why a consultant rather than a generator.** The 13 dimensions are coupled parameters. No template fits everyone, so the body of the work is conversation plus a catalogue of techniques.

**Why rules live in separate layers.** This avoids ending up with a single document holding 13 disconnected "don't do this" entries. General rules, the design flow, the plan format, and common mistakes each live somewhere different.

**Why R-10 became an automatic gate.** R-10 says anything a machine can verify must be verified before delivery. It used to be just a rule. Now it's three files — the Stop hook, coverage.json, and run-self-verify.sh — that make "no commit without verification" an operating-system-level fact rather than something a person has to remember.

**Why files written into a target project must stand on their own.** A target project is an independent repo, and its readers don't have meta-harness.

That rule (R-12) doesn't apply to meta-harness itself, though. Design plans, dimensions, and rule numbers are meta-harness's own shared vocabulary, and they belong here.

### Four rules to read before changing the method

- **R-7**: don't cement bad workflows; find the root cause before fixing. Stacking rules to cover symptoms ends in a pile of rules.
- **R-8**: don't overstep between layers. Method-level rules don't belong in project-specific documents.
- **R-9**: framework is framework, task content is task content. meta-harness touches the framework, not a target project's business logic.
- **R-12**: files written into a target project must stand on their own. This doesn't apply to meta-harness itself, but you need to understand its purpose before changing R-12 or the `/document` skill.

---

## How to verify your changes

### Run the verification suite

Run `bash experiments/meta-harness-eval/run-self-verify.sh`. Everything must pass.

Any failure means something is out of sync. The Stop hook will block the session from ending until it's fixed.

Here's roughly what the scripts cover. The full list and live numbers are in `coverage.json`; this table is a subset:

| Script | What it covers |
|---|---|
| `test-cross-references.sh` | Rule and dimension references in design plans actually exist |
| `test-prescription-format.sh` | The structure of each design plan |
| `test-prescription-template-structure.sh` | The structure of the plan format itself |
| `test-target-coverage.sh` | Progress across targets.yml and each project's coverage.json |
| `test-design-axes-doc-completeness.sh` | All 13 dimension documents are structurally complete |
| `test-healthcheck-axis-consistency.sh` | The count referenced in healthcheck matches reality |
| `test-skill-spec-format.sh` | SKILL.md frontmatter |
| `test-universal-care-rules-schema.sh` | Rule numbering is contiguous and every rule has content |
| `test-self-verify-stop-hook-behavior.sh` | The Stop hook in three situations: no runner, passing, failing |
| `test-run-self-verify-runner-integrity.sh` | The entry script in three states |
| `test-slash-command-flow-integrity.sh` | Command frontmatter, and that referenced files exist |
| `test-consultant-skill-structure.sh` | The consultant's core vocabulary is intact |
| `test-coverage-json-schema.sh` | coverage.json format is consistent across projects |

Add new configuration, add a `test-*.sh` to cover it. Pick one of the four verification approaches (details in the dimension 13 document):

- **A. Check that configuration agrees with itself**, when one setting is spread across files.
- **B. Trigger it and see if anything happens**, for hooks and middleware.
- **C. Score the output**, for content an agent produces.
- **D. Compare before and after**, for side effects.

### Use any new capability yourself first

Any new skill, command, or format has to be run against a real project first.

`/document` was tried on figma2code before it was used to write these docs. Self-verification was built into meta-harness itself before being pushed to atdd-task.

Shipping without using it yourself means shipping something unverified — exactly what R-10 exists to prevent.

### Checks when changing rules or adding dimensions

- **Grep for the root cause.** Don't just stack something on top to cover a symptom (R-7).
- **Confirm it doesn't overlap.** The 7/11 and 9/12 boundaries are already drawn. Dimension 13 and R-10 split as "metric" versus "discipline".
- **Try it across projects.** Before promoting something to a general rule, validate it on at least two real projects. Otherwise it goes in `docs/lessons.md`.
- **Answer R-7 in the commit message.** Before committing, answer "why can't the root cause be removed instead?"

### After changing a format

Run verification and confirm `test-prescription-template-structure.sh` still passes.

If you changed structure outside Part A through F — adding a Part G, say — update that test's expectations too.

---

## Relationship with external projects

A target project designed by meta-harness is an independent repo. It should stand on its own and not need meta-harness to run.

That's what R-12 governs: files written into a target project must not leak meta-harness's internal identity — no mentions of design plans, dimensions, or rule numbers in the target's README.

The relationship is one-directional. The target project shouldn't know about meta-harness; meta-harness knows about and tracks its target projects, via `targets.yml` and `test-target-coverage.sh`.

Per-project verification progress changes over time, so it isn't copied here. To see the current state, run:

```bash
bash experiments/meta-harness-eval/test-target-coverage.sh
```

To bring self-verification to a new project:

1. Create `experiments/<project>-eval/run-self-verify.sh` in that project; the portable version from meta-harness can be reused.
2. Add `.claude/hooks/self-verify-on-stop.sh` and register it under `Stop` in `settings.json`.
3. Write a `test-*.sh` for each piece of configuration, picking one of the four approaches.
4. Run `generate-coverage.sh` to produce `coverage.json`, and fill in the inventory of items by hand.
5. In meta-harness's `targets.yml`, add `eval_dir` to that project's entry if its directory isn't named `<project>-eval`.
6. Run `test-target-coverage.sh`; it should pick up the new progress.
