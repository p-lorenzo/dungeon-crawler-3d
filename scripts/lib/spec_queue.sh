#!/bin/bash
#
# Ralph Wiggum Spec Queue Helpers
#
# Lightweight helpers for the root-level numbered specs.
#
# Spec status convention:
#   A spec is COMPLETE if it contains one of these lines (at the start of a line):
#     Status: COMPLETE
#     **Status**: COMPLETE
#     ## Status: COMPLETE
#
#   Any other status (Draft, TODO, In Progress, or missing) means INCOMPLETE.
#
# Spec priority:
#   Lower number = higher priority. Files are sorted lexicographically,
#   so 001-foo.md is picked before 100-bar.md.
#

get_root_specs() {
    local specs_dir="${1:-specs}"

    if [ ! -d "$specs_dir" ]; then
        return 0
    fi

    find "$specs_dir" -maxdepth 1 -type f -name "*.md" | sort
}

is_root_spec_complete() {
    local spec_file="$1"

    [ -f "$spec_file" ] || return 1
    grep -Eq '^(#{1,3} )?(\*\*)?Status(\*\*)?:[[:space:]]+COMPLETE' "$spec_file"
}

get_incomplete_root_specs() {
    local specs_dir="${1:-specs}"
    local tmpfile
    tmpfile=$(mktemp)

    get_root_specs "$specs_dir" > "$tmpfile"

    while IFS= read -r spec_file; do
        [ -n "$spec_file" ] || continue
        if ! is_root_spec_complete "$spec_file"; then
            printf '%s\n' "$spec_file"
        fi
    done < "$tmpfile"

    rm -f "$tmpfile"
}

count_root_specs() {
    local specs_dir="${1:-specs}"
    local tmpfile
    tmpfile=$(mktemp)

    get_root_specs "$specs_dir" > "$tmpfile"
    local count
    count=$(wc -l < "$tmpfile" | tr -d ' ')
    rm -f "$tmpfile"

    printf '%d\n' "$count"
}

count_incomplete_root_specs() {
    local specs_dir="${1:-specs}"
    local tmpfile
    tmpfile=$(mktemp)

    get_incomplete_root_specs "$specs_dir" > "$tmpfile"
    local count
    count=$(wc -l < "$tmpfile" | tr -d ' ')
    rm -f "$tmpfile"

    printf '%d\n' "$count"
}

get_first_incomplete_root_spec() {
    local specs_dir="${1:-specs}"
    local tmpfile
    tmpfile=$(mktemp)

    get_incomplete_root_specs "$specs_dir" > "$tmpfile"
    local first
    first=$(head -n 1 "$tmpfile")
    rm -f "$tmpfile"

    printf '%s\n' "$first"
}
