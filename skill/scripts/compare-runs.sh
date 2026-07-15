#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: compare-runs.sh <baseline-run-dir> <enhanced-run-dir>

Compare two eval run directories by reading summary.yaml from each,
computing per-judge score deltas, and producing:
  1. A terminal table (grouped by goal category) printed to stdout
  2. A markdown report saved to <enhanced-run-dir>/comparison.md
  3. A JSON report saved to <enhanced-run-dir>/comparison.json (best-effort)

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

# --- Helper functions ---

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

extract_category() {
  local judge="$1"
  if [[ "$judge" != *_* ]]; then
    echo "Warning: Judge '$judge' has no category prefix (no underscore found), assigning to 'other'" >&2
    echo "other"
    return
  fi
  local prefix="${judge%%_*}"
  case "$prefix" in
    outcome|process|style|efficiency) echo "$prefix" ;;
    *)
      echo "Warning: Judge '$judge' has unrecognized category prefix '$prefix', assigning to 'other'" >&2
      echo "other"
      ;;
  esac
}

category_label() {
  case "$1" in
    outcome)    echo "Outcome" ;;
    process)    echo "Process" ;;
    style)      echo "Style" ;;
    efficiency) echo "Efficiency" ;;
    other)      echo "Other" ;;
    *)          echo "$1" ;;
  esac
}

# --- Collect data ---

declare -a judge_names=()
declare -a baseline_scores=()
declare -a enhanced_scores=()
declare -a deltas=()
declare -a directions=()
declare -a judge_categories=()

improved=0
regressed=0
unchanged=0
na_count=0

while IFS= read -r judge; do
  b_score=$(get_score "$BASELINE_YAML" "$judge")
  e_score=$(get_score "$ENHANCED_YAML" "$judge")
  delta=$(compute_delta "$b_score" "$e_score")
  dir=$(direction_indicator "$delta")
  cat=$(extract_category "$judge")

  judge_names+=("$judge")
  baseline_scores+=("$b_score")
  enhanced_scores+=("$e_score")
  deltas+=("$delta")
  directions+=("$dir")
  judge_categories+=("$cat")

  case "$dir" in
    "^") improved=$((improved + 1)) ;;
    "v") regressed=$((regressed + 1)) ;;
    "=") unchanged=$((unchanged + 1)) ;;
    "-") na_count=$((na_count + 1)) ;;
  esac
done <<< "$all_judges"

total=${#judge_names[@]}

# --- Compute per-category summaries ---

KNOWN_CATEGORIES=("outcome" "process" "style" "efficiency" "other")

declare -a cat_improved=()
declare -a cat_regressed=()
declare -a cat_unchanged=()
declare -a cat_na=()
declare -a cat_direction=()
declare -a cat_has_judges=()

for cat in "${KNOWN_CATEGORIES[@]}"; do
  c_imp=0; c_reg=0; c_unch=0; c_na=0; c_has=0
  for i in $(seq 0 $((total - 1))); do
    if [[ "${judge_categories[$i]}" == "$cat" ]]; then
      c_has=1
      case "${directions[$i]}" in
        "^") c_imp=$((c_imp + 1)) ;;
        "v") c_reg=$((c_reg + 1)) ;;
        "=") c_unch=$((c_unch + 1)) ;;
        "-") c_na=$((c_na + 1)) ;;
      esac
    fi
  done
  cat_improved+=("$c_imp")
  cat_regressed+=("$c_reg")
  cat_unchanged+=("$c_unch")
  cat_na+=("$c_na")
  cat_has_judges+=("$c_has")

  if (( c_has == 0 )); then
    cat_direction+=("N/A")
  elif (( c_imp > 0 && c_reg > 0 )); then
    cat_direction+=("Mixed")
  elif (( c_imp > 0 )); then
    cat_direction+=("Improved")
  elif (( c_reg > 0 )); then
    cat_direction+=("Regressed")
  elif (( c_unch == 0 && c_na > 0 )); then
    cat_direction+=("N/A")
  else
    cat_direction+=("Unchanged")
  fi
done

# --- Max name length for formatting ---

max_name_len=5
for name in "${judge_names[@]}"; do
  if (( ${#name} > max_name_len )); then
    max_name_len=${#name}
  fi
done

# --- Terminal output (grouped by category) ---

printf "\n"

for ci in $(seq 0 $((${#KNOWN_CATEGORIES[@]} - 1))); do
  cat="${KNOWN_CATEGORIES[$ci]}"
  if (( ${cat_has_judges[$ci]} == 0 )); then
    continue
  fi

  label=$(category_label "$cat")
  printf "\n### %s\n\n" "$label"
  printf "%-${max_name_len}s  %9s  %9s  %9s  %s\n" "Judge" "Baseline" "Enhanced" "Delta" ""
  printf "%0.s-" $(seq 1 $((max_name_len + 34)))
  printf "\n"

  for i in $(seq 0 $((total - 1))); do
    if [[ "${judge_categories[$i]}" != "$cat" ]]; then
      continue
    fi
    b_fmt=$(format_score "${baseline_scores[$i]}")
    e_fmt=$(format_score "${enhanced_scores[$i]}")
    d_fmt="${deltas[$i]}"
    if [[ "$d_fmt" != "N/A" ]]; then
      d_fmt=$(printf "%+.3f" "${deltas[$i]}")
    fi
    printf "%-${max_name_len}s  %9s  %9s  %9s  %s\n" \
      "${judge_names[$i]}" "$b_fmt" "$e_fmt" "$d_fmt" "${directions[$i]}"
  done
done

printf "\n"
printf "%0.s-" $(seq 1 $((max_name_len + 34)))
printf "\n"

# Category summary line
printf "Category summary:"
cat_sep=""
for ci in $(seq 0 $((${#KNOWN_CATEGORIES[@]} - 1))); do
  if (( ${cat_has_judges[$ci]} == 0 )); then
    continue
  fi
  label=$(category_label "${KNOWN_CATEGORIES[$ci]}")
  printf "%s %s: %s" "$cat_sep" "$label" "${cat_direction[$ci]}"
  cat_sep=","
done
printf "\n"

printf "Summary: %d improved, %d regressed, %d unchanged" "$improved" "$regressed" "$unchanged"
if (( na_count > 0 )); then
  printf ", %d N/A" "$na_count"
fi
printf "\n\n"

# --- Run IDs ---

baseline_run_id=$(yq -r '.run_id // "unknown"' "$BASELINE_YAML" 2>/dev/null) || baseline_run_id="unknown"
enhanced_run_id=$(yq -r '.run_id // "unknown"' "$ENHANCED_YAML" 2>/dev/null) || enhanced_run_id="unknown"

# --- Markdown report (grouped by category) ---

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

  echo "### Category Summary"
  echo ""
  echo "| Category | Direction | Improved | Regressed | Unchanged |"
  echo "|----------|-----------|----------|-----------|-----------|"
  for ci in $(seq 0 $((${#KNOWN_CATEGORIES[@]} - 1))); do
    if (( ${cat_has_judges[$ci]} == 0 )); then
      continue
    fi
    label=$(category_label "${KNOWN_CATEGORIES[$ci]}")
    dir="${cat_direction[$ci]}"
    if [[ "$dir" == "Regressed" || "$dir" == "Mixed" ]]; then
      dir="**$dir**"
    fi
    echo "| $label | $dir | ${cat_improved[$ci]} | ${cat_regressed[$ci]} | ${cat_unchanged[$ci]} |"
  done
  echo ""

  if (( regressed > 0 )); then
    echo "> **Warning**: $regressed judge(s) regressed. Review the details below."
    echo ""
  fi

  echo "## Per-Judge Details"
  echo ""

  for ci in $(seq 0 $((${#KNOWN_CATEGORIES[@]} - 1))); do
    cat="${KNOWN_CATEGORIES[$ci]}"
    if (( ${cat_has_judges[$ci]} == 0 )); then
      continue
    fi

    label=$(category_label "$cat")
    echo "### $label"
    echo ""
    echo "| Judge | Baseline | Enhanced | Delta | Direction |"
    echo "|-------|----------|----------|-------|-----------|"

    for i in $(seq 0 $((total - 1))); do
      if [[ "${judge_categories[$i]}" != "$cat" ]]; then
        continue
      fi
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
  done

  echo "---"
  echo ""
  echo "Generated by \`compare-runs.sh\` on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"

# --- JSON output (best-effort) ---

JSON_FILE="$ENHANCED_DIR/comparison.json"

generate_json() {
  local json="{"
  json+="\"baseline_run_id\":\"$baseline_run_id\","
  json+="\"enhanced_run_id\":\"$enhanced_run_id\","
  json+="\"baseline_dir\":\"$BASELINE_DIR\","
  json+="\"enhanced_dir\":\"$ENHANCED_DIR\","

  json+="\"judges\":{"
  local first=1
  for i in $(seq 0 $((total - 1))); do
    if (( first == 0 )); then json+=","; fi
    first=0

    local b_val="${baseline_scores[$i]}"
    local e_val="${enhanced_scores[$i]}"
    local d_val="${deltas[$i]}"
    local dir_val
    if [[ "$d_val" == "N/A" ]]; then
      dir_val="na"
    else
      dir_val=$(classify_delta "$d_val")
    fi

    local b_json e_json d_json
    if [[ "$b_val" == "N/A" ]]; then b_json="null"; else b_json="$b_val"; fi
    if [[ "$e_val" == "N/A" ]]; then e_json="null"; else e_json="$e_val"; fi
    if [[ "$d_val" == "N/A" ]]; then d_json="null"; else d_json="$d_val"; fi

    json+="\"${judge_names[$i]}\":{"
    json+="\"baseline\":$b_json,"
    json+="\"enhanced\":$e_json,"
    json+="\"delta\":$d_json,"
    json+="\"direction\":\"$dir_val\","
    json+="\"category\":\"${judge_categories[$i]}\""
    json+="}"
  done
  json+="},"

  json+="\"categories\":{"
  first=1
  for ci in $(seq 0 $((${#KNOWN_CATEGORIES[@]} - 1))); do
    if (( ${cat_has_judges[$ci]} == 0 )); then
      continue
    fi
    if (( first == 0 )); then json+=","; fi
    first=0

    local cat="${KNOWN_CATEGORIES[$ci]}"

    local judges_arr="["
    local jfirst=1
    for i in $(seq 0 $((total - 1))); do
      if [[ "${judge_categories[$i]}" == "$cat" ]]; then
        if (( jfirst == 0 )); then judges_arr+=","; fi
        jfirst=0
        judges_arr+="\"${judge_names[$i]}\""
      fi
    done
    judges_arr+="]"

    local sum_delta=0
    local count_delta=0
    for i in $(seq 0 $((total - 1))); do
      if [[ "${judge_categories[$i]}" == "$cat" && "${deltas[$i]}" != "N/A" ]]; then
        sum_delta=$(awk -v s="$sum_delta" -v d="${deltas[$i]}" 'BEGIN { printf "%.6f", s + d }')
        count_delta=$((count_delta + 1))
      fi
    done
    local avg_delta
    if (( count_delta > 0 )); then
      avg_delta=$(awk -v s="$sum_delta" -v c="$count_delta" 'BEGIN { printf "%.3f", s / c }')
    else
      avg_delta="0.000"
    fi

    json+="\"$cat\":{"
    json+="\"judges\":$judges_arr,"
    json+="\"direction\":\"${cat_direction[$ci]}\","
    json+="\"improved\":${cat_improved[$ci]},"
    json+="\"regressed\":${cat_regressed[$ci]},"
    json+="\"unchanged\":${cat_unchanged[$ci]},"
    json+="\"avg_delta\":$avg_delta"
    json+="}"
  done
  json+="},"

  json+="\"summary\":{"
  json+="\"improved\":$improved,"
  json+="\"regressed\":$regressed,"
  json+="\"unchanged\":$unchanged,"
  json+="\"na\":$na_count,"
  json+="\"total\":$total"
  json+="},"

  json+="\"by_invocation_type\":{},"

  json+="\"generated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  json+="}"
  echo "$json"
}

if json_content=$(generate_json 2>/dev/null); then
  if command -v jq &>/dev/null; then
    if formatted=$(echo "$json_content" | jq '.' 2>/dev/null); then
      json_content="$formatted"
    fi
  fi
  if echo "$json_content" > "$JSON_FILE" 2>/dev/null; then
    echo "JSON report saved to: $JSON_FILE"
  else
    echo "Warning: Could not write comparison.json to $JSON_FILE" >&2
  fi
else
  echo "Warning: Failed to generate comparison.json" >&2
fi
