#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd -P)
source_root=$(cd "${FRAMEWORK_SOURCE_ROOT:-$repo}" && pwd -P)
app=$1
shift
wippy=$(command -v "${WIPPY:-wippy}")
work_root=${RUNTIME_WORK_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/wippy-framework.XXXXXX")}
mkdir -p "$work_root"
work_root=$(cd "$work_root" && pwd -P)
case "$work_root/" in "$repo/"*) echo 'Runtime files must be outside the repository' >&2; exit 1;; esac
if [ -z "${RUNTIME_WORK_DIR:-}" ]; then
    trap 'rm -r -- "$work_root"' EXIT
fi

app_root=$(cd "$source_root/$app" && pwd)
work="$work_root/${app//\//-}"
mkdir -p "$work"
source_path=$(awk '$1 == "src:" {print $2; exit}' "$app_root/wippy.lock")
source_path=$(cd "$app_root/${source_path:-.}" && pwd)
{
    printf 'directories:\n    modules: %s\n    src: %s\n' \
        "$(jq -Rn --arg value "$work/modules" '$value')" \
        "$(jq -Rn --arg value "$source_path" '$value')"
    awk '/^modules:/ {active=1} /^replacements:/ {active=0} active {print}' "$app_root/wippy.lock"
} > "$work/wippy.lock"
jq -n --arg root "$source_root" --arg work "$work" '{
    version: "1.0",
    registry: {dependency_vendor_dir: ($work + "/modules/vendor"), dependency_lock_path: ($work + "/wippy.lock")},
    workspace: {replacements: {"wippy/test": ($root + "/src/test")}}
}' > "$work/.wippy.yaml"

while IFS=$'\t' read -r component replacement; do
    replacement=$(cd "$app_root/$replacement" && pwd)
    jq --arg component "$component" --arg path "$replacement" \
        '.workspace.replacements[$component] = $path' "$work/.wippy.yaml" > "$work/config.next"
    mv "$work/config.next" "$work/.wippy.yaml"
done < <(awk '/^replacements:/ {active=1} active && $2 == "from:" {module=$3} active && $1 == "to:" {printf "%s\t%s\n", module, $2}' "$app_root/wippy.lock")

if [ "$app" = src/facade/test ]; then
    jq --arg path "$source_root/src/facade" '.workspace.replacements["wippy/facade"] = $path' \
        "$work/.wippy.yaml" > "$work/config.next"
    mv "$work/config.next" "$work/.wippy.yaml"
fi

export WIPPY_FRAMEWORK_ROOT="$repo"
export WIPPY_TEST_ARTIFACTS="$work"
cd "$work"
"$wippy" install
"$wippy" "$@"
