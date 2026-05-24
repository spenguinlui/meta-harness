> 🌐 [繁體中文](CONTRIBUTING.md) | **English**

# Extending the meta-harness Methodology

For people who **extend the consultant methodology itself** (add design axes, add rules, distill lessons).
To *use* the flow to design your own harness, see [`README.md`](./README.md); this covers **the methodology's architecture and how to change it**.

> Two-reader split (meta-harness eats its own dog food): README = people who use the consultant flow (Viewer); this file = people who modify the consultant framework (Maintainer).

## Architecture Overview

meta-harness is not a framework — it's a "**consultant persona + pattern library + conversational flow**". Three layers:

```
Identity   .claude/skills/consultant/SKILL.md   architect persona + 6-step flow (must not drift)
Knowledge  docs/design-axes/ (12 axes) + docs/universal-care-rules.md (R-1~R-11)
Front door .claude/commands/ + per-mode skills (design / healthcheck / retro / document)
```

- The 12 design axes are a **parameter space** (not a checklist), coupled to each other.
- R-1~R-11 are the cross-target hygiene floor (rules already landed as enforcement).
- `docs/lessons.md` = insights (why it's designed this way), distinct from rules: rules are mandatory, lessons are experience.

## How the Wiring Works

| Piece | What it does |
|---|---|
| `.claude/skills/consultant/` | Consultant persona + the full 6-step flow (core, shared by all modes) |
| `.claude/skills/{design,healthcheck,retro,document}/` | Four mode front doors; entering them runs the consultant conversation |
| `.claude/commands/` | Discoverable slash-command entry points |
| `.claude/hooks/` | cwd guard, CLAUDE.md line-count check (R-1), question self-check (R-5/R-6) |
| `docs/*-template.md` | prescription (design doc) + manual (handbook) formats |
| `experiments/<topic>/` | Reference implementation of the self-verify loop (R-10) |

## How to Extend

- **Add a design axis**: create `docs/design-axes/<n>-<name>.md` (decision options + couplings + anti-patterns + cases) → add a line to the `docs/design-axes.md` index. Confirm it's **orthogonal** to the existing 12 (no overlap; e.g. the 7-vs-11, 9-vs-12 boundaries).
- **Add a universal rule**: add `R-N` to `docs/universal-care-rules.md` (definition / why / rule / how-to-land). Test: **does it still hold away from this target / this person?** Only cross-target rules go into universal; target-specific ones stay in the target's own doc. The commit message must answer "why can't the source be deleted instead" (R-7).
- **Add a lesson**: hit a recurring mistake → `docs/lessons.md` (insight, not a mandatory rule). Once validated as universal enough → promote to R-N.
- **Add a mode / skill**: mirror the `document` skill — one `.claude/skills/<name>/SKILL.md` + a row in the consultant trigger table + hook it into the 6-step flow if needed.

## Design Rationale (why it's this way)

- **Consultant, not scaffold**: the 12 axes are coupled parameters; no standard template fits everyone → conversation + pattern library is the main body.
- **Layered rules** (to avoid "one file of 12 disconnected anti-patterns"): cross-flow rules (R-N) / design flow (consultant-flow) / design-doc format (template) / anti-patterns are kept separate.
- **Three governance rules**: R-7 (don't fossilize bad flows, fix root cause first), R-8 (no cross-layer overreach), R-9 (separate framework vs task content) — read before changing the methodology.

## How to Verify Changes

- **Dogfood**: run any new capability on a real target first (e.g. `/document` documented figma2code before documenting itself). Shipping without dogfooding = an unverified product (R-10).
- **Self-verify the machine-checkable**: new skill / hook behavior → headless run + machine scoring ≥ 3 times (`experiments/<topic>/`).
- **Changing a rule**: grep the root cause, confirm you're not stacking a symptom patch (R-7); confirm you're not speaking for another layer (R-8).
