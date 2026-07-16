# cc-skill

A Claude Code plugin for evaluating, enhancing, and measuring SKILL.md files against 17 skill-authoring patterns.

Built on ideas from Bilgin Ibryam's ["9 Principles That Separate Useful Skills from Markdown Essays"](https://generativeprogrammer.com/p/9-principles-that-separate-useful) and Anthropic's ["Demystifying Evals for AI Agents"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents).

## What You Get

Three commands:

- **`/skill:check`** scores a SKILL.md against authoring best practices and tests whether its description triggers correctly
- **`/skill:enhance`** rewrites the skill to fill in missing patterns, preserving your original intent and voice
- **`/skill:measure`** runs the full baseline-enhance-reeval loop in a single command and produces a comparison report

## How They Relate

```
                    ┌─────────────┐
                    │ skill:check │  Read-only evaluation
                    └──────┬──────┘
                           │ identifies gaps
                           v
                    ┌───────────────┐
                    │ skill:enhance │  Rewrites weak patterns
                    └──────┬────────┘
                           │ improves skill
                           v
                    ┌───────────────┐
                    │ skill:measure │  Orchestrates the full loop
                    └──────┬────────┘
                           │ invokes
              ┌────────────┼────────────┐
              v            v            v
         /eval-run    skill:enhance   /eval-run
        (baseline)                   (enhanced)
              │                         │
              └────────┬────────────────┘
                       v
               compare-runs.sh
              (delta report)
```

`skill:check` and `skill:enhance` work standalone. `skill:measure` orchestrates the end-to-end measurement workflow by combining them with the [agent-eval-harness](https://github.com/opendatahub-io/agent-eval-harness) plugin.

## Installation

Register the `skill/` directory as a plugin in your Claude Code settings.

If you also have the [prompt plugin](https://github.com/rhuss/cc-prompt) installed, both check and enhance pick it up at runtime for deeper prompt-pattern analysis. Without it, everything works fine on its own.

## Usage

```bash
# Check a skill file
/skill:check path/to/SKILL.md

# Enhance a weak skill
/skill:enhance path/to/SKILL.md

# Full measure-enhance-measure loop (requires agent-eval-harness)
/skill:measure path/to/SKILL.md

# Standalone comparison of any two eval runs
skill/scripts/compare-runs.sh <baseline-run-dir> <enhanced-run-dir>
```

## The 17 Patterns

| Category | Patterns |
|----------|----------|
| Discovery | Activation Metadata, Exclusion Clause |
| Context Economy | Context Budget, Progressive Disclosure |
| Instruction Calibration | Control Tuning, Explain-the-Why, Template Scaffold, In-Skill Examples, Known Gotchas |
| Workflow Control | Execution Checklist, Self-Correcting Loop, Plan-Validate-Execute |
| Executable Code | Utility Bundle |
| Meta | Autonomy Calibration |
| Workflow Quality | Process over Prose, Anticipate the Excuse, Stay in Scope |

Each pattern gets one of four statuses:

| Status | Meaning |
|--------|---------|
| **strong** | Pattern meets quality criteria |
| **present** | Detectable but has quality issues |
| **absent** | Not found in the skill |
| **N/A** | Does not apply to this skill type |

## How the Checker Works

The checker reads the SKILL.md and inspects its parent directory (scripts, referenced files, sibling .md files). For each pattern, it applies detection signals and quality criteria from the knowledge file. The output includes an activation test that predicts which user requests would (and wouldn't) trigger the skill.

## How the Enhancer Works

The enhancer runs the same evaluation, then rewrites the skill to address absent and weak patterns. It prioritizes absent patterns first, then strengthens present-but-weak ones. If the skill needs splitting (Progressive Disclosure), it proposes new files for your approval before creating them. If every applicable pattern is already strong, it tells you so and leaves the skill alone.

## Measuring Skill Improvement

`/skill:measure` automates the measure-enhance-measure cycle that would otherwise require 4 manual steps across two plugins. It runs entirely within a single Claude Code session (no nested `claude -p` sessions).

### Prerequisites

You need two plugins installed:

1. **cc-skill** (this plugin) for `/skill:check`, `/skill:enhance`, and `/skill:measure`
2. **[agent-eval-harness](https://github.com/opendatahub-io/agent-eval-harness)** for `/eval-run`, `/eval-analyze`, and `/eval-dataset`

Your target skill also needs eval infrastructure set up. If you haven't done this yet, run `/eval-analyze` on the SKILL.md to generate `eval.yaml`, then `/eval-dataset` to create test cases.

### What `/skill:measure` Does

Given a SKILL.md with eval infrastructure already configured:

1. Runs `/eval-run` to capture **baseline** scores
2. Runs `/skill:enhance` to improve the skill
3. Runs `/eval-run` again to capture **enhanced** scores
4. Runs `compare-runs.sh` to compute per-judge deltas

If `/skill:enhance` reports the skill is already optimal, it skips steps 3-4 and reports the baseline scores as the skill's current quality level.

### The Comparison Script

`skill/scripts/compare-runs.sh` is a standalone utility that compares any two eval run directories. It reads `summary.yaml` from each, computes per-judge score deltas, and produces:

- A terminal table with baseline, enhanced, and delta columns
- A markdown report (`comparison.md`) saved in the enhanced run directory

You can use it independently of `/skill:measure`:

```bash
skill/scripts/compare-runs.sh eval/runs/run-1 eval/runs/run-2
```

Output:

```
Judge                       Baseline   Enhanced      Delta
-----------------------------------------------------------
enhancement_quality            3.800      4.400     +0.600  ^
frontmatter_preserved          1.000      1.000     +0.000  =
status_change_table            1.000      0.800     -0.200  v
-----------------------------------------------------------
Summary: 1 improved, 1 regressed, 1 unchanged
```

Regressions are highlighted in the markdown report with bold **REGRESSED** markers and a warning banner.

### Setting Up Eval Infrastructure

If your skill doesn't have eval infrastructure yet, set it up first (one-time per skill):

```bash
# 1. Analyze the skill and generate eval.yaml
/eval-analyze path/to/SKILL.md

# 2. Generate test cases
/eval-dataset
```

Then run `/skill:measure path/to/SKILL.md` for the full automated loop.

### The Manual Workflow (Step by Step)

If you prefer manual control over each step, or want to understand what `/skill:measure` automates:

1. **Analyze the skill** (`/eval-analyze`). Point the harness at your SKILL.md. It generates an `eval.yaml` with judges, thresholds, and dataset schema.

2. **Generate test cases** (`/eval-dataset`). The harness creates realistic test inputs based on the skill analysis.

3. **Run the baseline evaluation** (`/eval-run`). The harness executes your skill against test cases and scores the outputs. This is your "before" snapshot.

4. **Enhance the skill** (`/skill:enhance`). Run cc-skill's enhancer on the same SKILL.md.

5. **Run the evaluation again** (`/eval-run`). Same judges, same test cases, now scoring the enhanced skill.

6. **Compare results** (`compare-runs.sh`). Run the comparison script with the two run directories to see per-judge deltas.

### Choosing Judges

The eval-harness supports several judge types. For measuring skill quality, three categories are most useful:

**Structural completeness** (inline check judges). Verify that the skill's output contains expected elements: required sections, pattern coverage, file artifacts. Fast, deterministic, good for catching regressions.

**Behavioral quality** (LLM judges). Evaluate qualitative aspects: clarity, actionability, tone. Slower but capture qualities that structural checks miss.

**Improvement delta** (pairwise comparison judges). Compare outputs from two runs side by side and score which is better. Especially valuable for the measure-enhance-measure workflow because they directly measure improvement.

Start with structural completeness for fast feedback. Add behavioral quality judges for deeper assessment. Use pairwise comparison when you want to directly measure before-vs-after improvement.

### Tips

- **Already-optimal skills**: If `/skill:enhance` reports all patterns are already strong, `/skill:measure` skips re-evaluation. This confirms the skill is well-authored.

- **Scores decrease after enhancement**: Investigate which judges show lower scores and compare the before/after skill text. You may want to selectively revert parts of the enhancement.

- **Iterating**: You can repeat the cycle. Each pass typically yields smaller improvements as the skill approaches its ceiling.

## Credits

- [Bilgin Ibryam](https://www.generativeprogrammer.com/) for the 9 skill design principles that informed the pattern framework
- [Anthropic](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) for evaluation methodology guidance
- [agent-eval-harness](https://github.com/opendatahub-io/agent-eval-harness) for the evaluation infrastructure that powers `/skill:measure`
