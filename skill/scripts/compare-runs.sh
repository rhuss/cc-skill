#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: compare-runs.sh <baseline-run-dir> <enhanced-run-dir>

Compare two eval run directories by reading summary.yaml from each,
computing per-judge score deltas, and producing:
  1. A terminal table printed to stdout
  2. A markdown report saved to <enhanced-run-dir>/comparison.md

Both directories must contain a summary.yaml file with a judges section.

Exit codes:
  0  Success
  1  Missing arguments or invalid directories
  2  Missing summary.yaml in one or both directories
  3  yq not found
EOF
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

BASELINE_DIR="$1"
ENHANCED_DIR="$2"

if ! command -v yq &>/dev/null; then
  echo "Error: yq is required but not found. Install it: https://github.com/mikefarah/yq" >&2
  exit 3
fi

if [[ ! -d "$BASELINE_DIR" ]]; then
  echo "Error: Baseline directory does not exist: $BASELINE_DIR" >&2
  exit 1
fi

if [[ ! -d "$ENHANCED_DIR" ]]; then
  echo "Error: Enhanced directory does not exist: $ENHANCED_DIR" >&2
  exit 1
fi

BASELINE_YAML="$BASELINE_DIR/summary.yaml"
ENHANCED_YAML="$ENHANCED_DIR/summary.yaml"

if [[ ! -f "$BASELINE_YAML" ]]; then
  echo "Error: No summary.yaml found in baseline directory: $BASELINE_DIR" >&2
  exit 2
fi

if [[ ! -f "$ENHANCED_YAML" ]]; then
  echo "Error: No summary.yaml found in enhanced directory: $ENHANCED_DIR" >&2
  exit 2
fi

if ! baseline_judges=$(yq -r '.judges | keys | .[]' "$BASELINE_YAML" 2>/dev/null); then
  echo "Error: Failed to parse summary.yaml in baseline directory: $BASELINE_DIR (invalid YAML or missing judges section)" >&2
  exit 2
fi
if ! enhanced_judges=$(yq -r '.judges | keys | .[]' "$ENHANCED_YAML" 2>/dev/null); then
  echo "Error: Failed to parse summary.yaml in enhanced directory: $ENHANCED_DIR (invalid YAML or missing judges section)" >&2
  exit 2
fi

all_judges=$(printf '%s\n%s\n' "$baseline_judges" "$enhanced_judges" | sort -u | grep -v '^$' || true)

if [[ -z "$all_judges" ]]; then
  echo "Error: No judges found in either summary.yaml" >&2
  exit 2
fi

get_score() {
  local yaml_file="$1"
  local judge="$2"

  local has_judge
  has_judge=$(yq -r ".judges.\"$judge\" // \"missing\"" "$yaml_file")
  if [[ "$has_judge" == "missing" || "$has_judge" == "null" ]]; then
    echo "N/A"
    return
  fi

  local pass_rate
  pass_rate=$(yq -r ".judges.\"$judge\".pass_rate // \"null\"" "$yaml_file")
  if [[ "$pass_rate" != "null" ]] && is_numeric "$pass_rate"; then
    echo "$pass_rate"
    return
  fi

  local mean
  mean=$(yq -r ".judges.\"$judge\".mean // \"null\"" "$yaml_file")
  if [[ "$mean" != "null" ]] && is_numeric "$mean"; then
    echo "$mean"
    return
  fi

  echo "N/A"
}

is_numeric() {
  [[ "$1" =~ ^-?[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?$ ]]
}

format_score() {
  local score="$1"
  if [[ "$score" == "N/A" ]]; then
    echo "N/A"
    return
  fi
  if ! is_numeric "$score"; then
    echo "N/A"
    return
  fi
  printf "%.3f" "$score"
}

compute_delta() {
  local baseline="$1"
  local enhanced="$2"

  if [[ "$baseline" == "N/A" || "$enhanced" == "N/A" ]]; then
    echo "N/A"
    return
  fi

  awk -v e="$enhanced" -v b="$baseline" 'BEGIN { printf "%.3f", e - b }'
}

classify_delta() {
  local delta="$1"
  awk -v d="$delta" 'BEGIN { if (d > 0.0005) print "up"; else if (d < -0.0005) print "down"; else print "same" }'
}

direction_indicator() {
  local delta="$1"
  if [[ "$delta" == "N/A" ]]; then
    echo "-"
    return
  fi

  local cmp
  cmp=$(classify_delta "$delta")
  case "$cmp" in
    up)   echo "^" ;;
    down) echo "v" ;;
    same) echo "=" ;;
    *)    echo "-" ;;
  esac
}

direction_indicator_md() {
  local delta="$1"
  if [[ "$delta" == "N/A" ]]; then
    echo "-"
    return
  fi

  local cmp
  cmp=$(classify_delta "$delta")
  case "$cmp" in
    up)   echo "Improved" ;;
    down) echo "**REGRESSED**" ;;
    same) echo "Unchanged" ;;
    *)    echo "-" ;;
  esac
}

declare -a judge_names=()
declare -a baseline_scores=()
declare -a enhanced_scores=()
declare -a deltas=()
declare -a directions=()

improved=0
regressed=0
unchanged=0
na_count=0

while IFS= read -r judge; do
  b_score=$(get_score "$BASELINE_YAML" "$judge")
  e_score=$(get_score "$ENHANCED_YAML" "$judge")
  delta=$(compute_delta "$b_score" "$e_score")
  dir=$(direction_indicator "$delta")

  judge_names+=("$judge")
  baseline_scores+=("$b_score")
  enhanced_scores+=("$e_score")
  deltas+=("$delta")
  directions+=("$dir")

  case "$dir" in
    "^") improved=$((improved + 1)) ;;
    "v") regressed=$((regressed + 1)) ;;
    "=") unchanged=$((unchanged + 1)) ;;
    "-") na_count=$((na_count + 1)) ;;
  esac
done <<< "$all_judges"

total=${#judge_names[@]}

max_name_len=5
for name in "${judge_names[@]}"; do
  if (( ${#name} > max_name_len )); then
    max_name_len=${#name}
  fi
done

printf "\n"
printf "%-${max_name_len}s  %9s  %9s  %9s  %s\n" "Judge" "Baseline" "Enhanced" "Delta" ""
printf "%0.s-" $(seq 1 $((max_name_len + 34)))
printf "\n"

for i in $(seq 0 $((total - 1))); do
  b_fmt=$(format_score "${baseline_scores[$i]}")
  e_fmt=$(format_score "${enhanced_scores[$i]}")
  d_fmt="${deltas[$i]}"
  if [[ "$d_fmt" != "N/A" ]]; then
    d_fmt=$(printf "%+.3f" "${deltas[$i]}")
  fi

  printf "%-${max_name_len}s  %9s  %9s  %9s  %s\n" \
    "${judge_names[$i]}" "$b_fmt" "$e_fmt" "$d_fmt" "${directions[$i]}"
done

printf "%0.s-" $(seq 1 $((max_name_len + 34)))
printf "\n"
printf "Summary: %d improved, %d regressed, %d unchanged" "$improved" "$regressed" "$unchanged"
if (( na_count > 0 )); then
  printf ", %d N/A" "$na_count"
fi
printf "\n\n"

baseline_run_id=$(yq -r '.run_id // "unknown"' "$BASELINE_YAML" 2>/dev/null) || baseline_run_id="unknown"
enhanced_run_id=$(yq -r '.run_id // "unknown"' "$ENHANCED_YAML" 2>/dev/null) || enhanced_run_id="unknown"

REPORT_FILE="$ENHANCED_DIR/comparison.md"

{
  echo "# Eval Run Comparison"
  echo ""
  echo "| | Run ID | Directory |"
  echo "|---|--------|-----------|"
  echo "| Baseline | $baseline_run_id | \`$BASELINE_DIR\` |"
  echo "| Enhanced | $enhanced_run_id | \`$ENHANCED_DIR\` |"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Improved | $improved |"
  echo "| Regressed | $regressed |"
  echo "| Unchanged | $unchanged |"
  if (( na_count > 0 )); then
    echo "| N/A (judge in one run only) | $na_count |"
  fi
  echo "| **Total judges** | **$total** |"
  echo ""

  if (( regressed > 0 )); then
    echo "> **Warning**: $regressed judge(s) regressed. Review the details below."
    echo ""
  fi

  echo "## Per-Judge Details"
  echo ""
  echo "| Judge | Baseline | Enhanced | Delta | Direction |"
  echo "|-------|----------|----------|-------|-----------|"

  for i in $(seq 0 $((total - 1))); do
    b_fmt=$(format_score "${baseline_scores[$i]}")
    e_fmt=$(format_score "${enhanced_scores[$i]}")
    d_fmt="${deltas[$i]}"
    if [[ "$d_fmt" != "N/A" ]]; then
      d_fmt=$(printf "%+.3f" "${deltas[$i]}")
    fi
    dir_md=$(direction_indicator_md "${deltas[$i]}")

    echo "| ${judge_names[$i]} | $b_fmt | $e_fmt | $d_fmt | $dir_md |"
  done

  echo ""
  echo "---"
  echo ""
  echo "Generated by \`compare-runs.sh\` on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
