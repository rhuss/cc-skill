# cc-skill

A Claude Code plugin that checks SKILL.md files against 14 skill-authoring patterns and rewrites weak ones to be stronger.

## What You Get

Two commands:

- **`/skill:check`** scores a SKILL.md against authoring best practices and tests whether its description triggers correctly
- **`/skill:enhance`** rewrites the skill to fill in missing patterns, preserving your original intent and voice

## Installation

Register the `skill/` directory as a plugin in your Claude Code settings. That's it.

If you also have the [prompt plugin](https://github.com/anthropics/cc-prompt) installed, both commands pick it up at runtime for deeper prompt-pattern analysis. Without it, everything works fine on its own.

## Usage

```bash
# Check a skill file
/skill:check path/to/SKILL.md

# Enhance a weak skill
/skill:enhance path/to/SKILL.md

# Check from conversation context (after reading a SKILL.md)
/skill:check
```

## The 14 Patterns

| Category | Patterns |
|----------|----------|
| Discovery | Activation Metadata, Exclusion Clause |
| Context Economy | Context Budget, Progressive Disclosure |
| Instruction Calibration | Control Tuning, Explain-the-Why, Template Scaffold, In-Skill Examples, Known Gotchas |
| Workflow Control | Execution Checklist, Self-Correcting Loop, Plan-Validate-Execute |
| Executable Code | Utility Bundle |
| Meta | Autonomy Calibration |

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

You can combine cc-skill with the [agent-eval-harness](https://github.com/anthropics/agent-eval-harness) plugin to measure how much `/skill:enhance` actually improves a skill. The workflow is: measure the skill's quality, enhance it, then measure again to see what changed.

**Prerequisites**: You need both plugins installed in your Claude Code environment. Register cc-skill's `skill/` directory and the agent-eval-harness's plugin directory in your settings. You also need at least one SKILL.md file you want to evaluate and improve.

### The Workflow

The measure-enhance-measure cycle has 6 steps. Steps 1-3 and 5 come from the agent-eval-harness plugin. Step 4 comes from cc-skill.

1. **Analyze the skill** (`/eval-analyze`). Point the harness at your SKILL.md. It examines the skill's structure, sub-skills, and test cases, then generates an `eval.yaml` configuration with judges, thresholds, and dataset schema.

2. **Generate test cases** (`/eval-dataset`). The harness creates realistic test inputs based on the skill analysis. These are the prompts your skill will be evaluated against. Review them to make sure they cover the scenarios you care about.

3. **Run the baseline evaluation** (`/eval-run`). The harness executes your skill against the test cases and scores the outputs with the configured judges. This produces your baseline scores, the "before" snapshot.

4. **Enhance the skill** (`/skill:enhance`). Run cc-skill's enhancer on the same SKILL.md. It evaluates the 14 patterns, rewrites absent and weak ones, and produces an improved version of the skill.

5. **Run the evaluation again** (`/eval-run`). Run the same eval configuration against the enhanced skill. This produces your "after" scores using the same judges and test cases.

6. **Compare results**. Look at the score differences between the baseline run (step 3) and the enhanced run (step 5). The delta tells you exactly how much the enhancement improved your skill's quality, broken down by judge.

### Walkthrough

Here is the full workflow applied to a hypothetical skill. Imagine you have a `code-review` skill that provides code review guidance. It works, but the checker reports several weak or absent patterns.

**Step 1: Analyze the skill**

```
/eval-analyze path/to/code-review/SKILL.md
```

The harness reads the skill and produces an `eval.yaml` with judges configured for the skill type. You see output like:

```
Analyzed: code-review skill
Generated: eval.yaml
  - 3 judges configured (structural, behavioral, actionability)
  - 5 test case schema fields defined
  - Threshold: 0.7 average across judges
```

**Step 2: Generate test cases**

```
/eval-dataset
```

The harness creates test inputs based on the skill analysis:

```
Generated 8 test cases:
  1. "Review this Python function for error handling issues"
  2. "Check this React component for accessibility problems"
  3. "Analyze this SQL query for performance concerns"
  ...
```

**Step 3: Run baseline evaluation**

```
/eval-run
```

The harness runs the skill against all test cases and scores the outputs:

```
Baseline results:
  structural_completeness:  0.55  (missing sections in 4/8 outputs)
  behavioral_quality:       0.62  (guidance unclear in 3/8 outputs)
  output_actionability:     0.48  (no concrete suggestions in 5/8 outputs)
  ──────────────────────────────
  Average:                  0.55
```

**Step 4: Enhance the skill**

```
/skill:enhance path/to/code-review/SKILL.md
```

The enhancer evaluates the 14 patterns and rewrites the skill:

```
Evaluation complete. 5 of 14 patterns need work.

Patterns improved:
  - Execution Checklist:    absent → strong (added step-by-step review flow)
  - Template Scaffold:      absent → strong (added output template)
  - Known Gotchas:          absent → strong (added common review pitfalls)
  - Control Tuning:         present → strong (sharpened tone directives)
  - In-Skill Examples:      present → strong (added before/after examples)

Enhanced skill written to: path/to/code-review/SKILL.md
```

**Step 5: Re-run evaluation**

```
/eval-run
```

Same judges, same test cases, now scoring the enhanced skill:

```
Enhanced results:
  structural_completeness:  0.88  (+0.33)
  behavioral_quality:       0.79  (+0.17)
  output_actionability:     0.82  (+0.34)
  ──────────────────────────────
  Average:                  0.83  (+0.28)
```

**Step 6: Compare**

The before/after comparison shows the enhancement impact:

```
Judge                      Before   After   Delta
─────────────────────────  ──────   ─────   ─────
structural_completeness     0.55    0.88   +0.33
behavioral_quality          0.62    0.79   +0.17
output_actionability        0.48    0.82   +0.34
─────────────────────────  ──────   ─────   ─────
Average                     0.55    0.83   +0.28
```

The skill improved from 0.55 to 0.83 average across all judges. The biggest gains came from structural completeness and output actionability, which makes sense since the enhancer added an execution checklist and output template (both directly improve structure and actionability).

### Choosing Judges

The eval-harness supports several judge types. For measuring skill quality, three categories are most useful:

**Structural completeness** (inline check judges). These verify that the skill's output contains expected elements: required sections, pattern coverage, file artifacts. They answer "did the skill produce everything it should?" Inline checks are fast, deterministic, and good for catching regressions. Use them to verify that the enhanced skill still produces all required output sections.

**Behavioral quality** (LLM judges). These evaluate qualitative aspects of the skill's output: clarity, actionability, tone, and whether the guidance is genuinely useful. They answer "is the output good?" LLM judges are slower but capture qualities that structural checks miss. Use them to verify that the enhancement made the skill's guidance clearer, not just longer.

**Improvement delta** (pairwise comparison judges). These compare outputs from two different runs side by side and score which is better. They answer "did the skill get better?" Pairwise judges are especially valuable for the measure-enhance-measure workflow because they directly measure the improvement rather than scoring each version independently.

When setting up `/eval-analyze`, you do not need to configure all three categories. Start with structural completeness for fast feedback, add behavioral quality judges for deeper assessment, and use pairwise comparison when you want to directly measure before-vs-after improvement.

### Tips

- **Already-optimal skills**: If `/skill:enhance` reports that all applicable patterns are already strong, the re-evaluation in step 5 will produce scores identical (or very close) to the baseline. This confirms the skill is already well-authored rather than indicating a problem with the workflow.

- **Scores decrease after enhancement**: This can happen if the enhancement changed the skill's behavior in unexpected ways. Investigate which judges show lower scores and compare the before/after skill text to understand what shifted. You may want to selectively revert parts of the enhancement or run `/skill:enhance` again with more specific guidance.

- **Iterating**: You can repeat the cycle. After the first enhancement, run `/skill:check` to see if any patterns are still weak, enhance again, and re-evaluate. Each pass typically yields smaller improvements as the skill approaches its ceiling.
