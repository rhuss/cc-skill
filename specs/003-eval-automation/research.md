# Research: Measure-Enhance-Measure Automation

## R1: summary.yaml Structure

**Decision**: The comparison script parses the `judges` section of summary.yaml, which contains per-judge aggregate scores.

**Rationale**: The `judges` section is the simplest and most stable contract. Each judge has `mean` (numeric average, null for boolean judges) and `pass_rate` (fraction of passing cases, null for numeric judges). This is sufficient for delta computation without needing per-case details.

**Key structure**:
```yaml
run_id: "2026-04-15-opus-4-7"
judges:
  judge_name:
    mean: 4.2        # null for boolean judges
    pass_rate: 0.85   # null for numeric judges
run_metrics:
  cost_per_turn_usd: 0.0125
```

**Alternatives considered**: Parsing per-case results (rejected: too granular for a summary comparison), parsing run_result.json (rejected: contains execution metadata, not judge scores).

## R2: Run Directory Location

**Decision**: Run results are stored in `eval/runs/<run_id>/` by default, controlled by `$AGENT_EVAL_RUNS_DIR` environment variable.

**Rationale**: The eval-harness uses `$AGENT_EVAL_RUNS_DIR` (defaulting to `eval/runs/`) as the base directory. Run IDs are formatted as `YYYY-MM-DD-<model>` unless overridden. The skill:measure skill captures run directory paths from eval-run's conversation output (per FR-014).

**Alternatives considered**: Hardcoding `eval/runs/latest/` (rejected: no "latest" symlink exists), scanning for most recent directory (rejected: fragile, could pick wrong run).

## R3: YAML Parsing Tool

**Decision**: Use `yq` for YAML parsing in the comparison script.

**Rationale**: The user's CLAUDE.md specifies `yq` as the preferred YAML tool. It handles the summary.yaml structure well and keeps the script as a pure shell script without Python dependencies.

**Alternatives considered**: Python with PyYAML (rejected: adds runtime dependency, overkill for reading two fields per judge), jq after YAML-to-JSON conversion (rejected: extra conversion step).

## R4: Score Comparison Logic

**Decision**: Compare judges by their primary score type. For boolean judges, compare `pass_rate`. For numeric judges, compare `mean`. Delta is computed as `enhanced - baseline`.

**Rationale**: Each judge has exactly one meaningful aggregate. Boolean judges use pass_rate (0.0-1.0), numeric judges use mean. A positive delta means improvement, negative means regression. This is unambiguous and maps directly to the summary.yaml structure.

**Formatting**: Use directional indicators in the report:
- Positive delta: show with an upward indicator
- Negative delta: show with a downward indicator  
- Zero delta: show as unchanged
- Judge in only one run: show as N/A

## R5: How skill:measure Captures Run Paths

**Decision**: The skill reads eval-run's conversation output, which reports the run directory path when presenting results. The skill extracts the path from that output.

**Rationale**: eval-run reports results including the path to `report.html` and `summary.yaml`. Since skill:measure runs in the same Claude Code session, it has access to the conversation context and can extract these paths. No file system scanning needed.

**Risk**: If eval-run changes its output format, the path extraction may break. This is acceptable since both plugins are maintained by the same author and the extraction is pattern-based, not exact-match.
