#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Install Agent Skills from this repository.

Usage:
  ./scripts/install.sh [options]

Options:
  --platform claude|agents|cursor
                         Install to Claude, open Agent Skills, or Cursor paths. Default: claude
  --scope user|project   Install for the current user or current project. Default: user
  --source DIR           Directory containing skill directories. Default: ./skills
  --dest DIR             Explicit destination directory. Overrides --scope
  --skill NAME           Install only one skill directory
  --force                Replace existing installed skill directories
  --dry-run              Print actions without writing files
  --list                 List installable skills and exit
  -h, --help             Show this help
USAGE
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

script_dir=""
repo_dir=""
source_dir=""
if [ -n "${0:-}" ] && [ -f "$0" ]; then
  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
  source_dir="$repo_dir/skills"
fi

platform=""
scope="user"
dest_dir=""
skill_name=""
force="false"
dry_run="false"
list_only="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform)
      [ "$#" -ge 2 ] || die "--platform requires a value"
      platform="$2"
      shift 2
      ;;
    --scope)
      [ "$#" -ge 2 ] || die "--scope requires a value"
      scope="$2"
      shift 2
      ;;
    --source)
      [ "$#" -ge 2 ] || die "--source requires a value"
      source_dir="$2"
      shift 2
      ;;
    --dest)
      [ "$#" -ge 2 ] || die "--dest requires a value"
      dest_dir="$2"
      shift 2
      ;;
    --skill)
      [ "$#" -ge 2 ] || die "--skill requires a value"
      skill_name="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    --list)
      list_only="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

case "$scope" in
  user|project) ;;
  *) die "--scope must be user or project" ;;
esac

if [ -z "$platform" ]; then
  if [ -e /dev/tty ] && [ -r /dev/tty ]; then
    printf '\nWhich platform are you using?\n'
    printf '  1) Claude Code (default)\n'
    printf '  2) Codex / Agent Skills\n'
    printf '  3) Cursor\n'
    printf 'Enter choice [1]: '
    choice=""
    { read choice < /dev/tty; } 2>/dev/null || true
    case "$choice" in
      ""|1) platform="claude" ;;
      2) platform="agents" ;;
      3) platform="cursor" ;;
      *) die "invalid choice: $choice" ;;
    esac
    printf '\n'
  else
    platform="claude"
  fi
fi

case "$platform" in
  claude|agents|cursor) ;;
  *) die "--platform must be claude, agents, or cursor" ;;
esac

if [ -z "$dest_dir" ]; then
  if [ "$scope" = "user" ]; then
    [ -n "${HOME:-}" ] || die "HOME is not set"
    if [ "$platform" = "cursor" ]; then
      dest_dir="$HOME/.cursor/skills-cursor"
    elif [ "$platform" = "claude" ]; then
      dest_dir="$HOME/.claude/skills"
    else
      dest_dir="$HOME/.agents/skills"
    fi
  else
    if [ "$platform" = "cursor" ]; then
      dest_dir="$(pwd)/.cursor/skills"
    elif [ "$platform" = "claude" ]; then
      dest_dir="$(pwd)/.claude/skills"
    else
      dest_dir="$(pwd)/.agents/skills"
    fi
  fi
fi

TMP_DIR=""
cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR}" ]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT INT TERM

if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
  if command -v mktemp >/dev/null 2>&1; then
    TMP_DIR=$(mktemp -d -t security-skills-install.XXXXXX)
  else
    TMP_DIR="/tmp/security-skills-install.$$-$(date +%s)"
    mkdir "$TMP_DIR" 2>/dev/null || die "failed to create secure temp directory"
    chmod 700 "$TMP_DIR"
  fi

  printf 'Skills directory not found locally. Bootstrapping from GitHub...\n'

  if command -v git >/dev/null 2>&1; then
    printf 'Cloning security-skills repository...\n'
    git clone --depth 1 https://github.com/mindfortai/security-skills.git "$TMP_DIR/repo" >/dev/null 2>&1 || die "failed to clone repository"
    source_dir="$TMP_DIR/repo/skills"
  elif command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    printf 'Downloading security-skills archive...\n'
    curl -sSL https://github.com/mindfortai/security-skills/tarball/main -o "$TMP_DIR/archive.tar.gz" || die "failed to download archive"
    mkdir -p "$TMP_DIR/repo"
    tar -xzf "$TMP_DIR/archive.tar.gz" -C "$TMP_DIR/repo" --strip-components=1 || die "failed to extract archive"
    source_dir="$TMP_DIR/repo/skills"
  elif command -v wget >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    printf 'Downloading security-skills archive...\n'
    wget -qO "$TMP_DIR/archive.tar.gz" https://github.com/mindfortai/security-skills/tarball/main || die "failed to download archive"
    mkdir -p "$TMP_DIR/repo"
    tar -xzf "$TMP_DIR/archive.tar.gz" -C "$TMP_DIR/repo" --strip-components=1 || die "failed to extract archive"
    source_dir="$TMP_DIR/repo/skills"
  else
    die "git, curl, or wget is required to bootstrap installation"
  fi
fi

[ -d "$source_dir" ] || die "source directory does not exist: $source_dir"

is_valid_skill_name() {
  case "$1" in
    ""|-*|*-|*--*|*/*|*\\*|*[!abcdefghijklmnopqrstuvwxyz0123456789-]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

validate_skill() {
  skill_dir="$1"
  skill="$(basename -- "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  is_valid_skill_name "$skill" || die "invalid skill directory name: $skill"
  [ -f "$skill_file" ] || die "missing SKILL.md in $skill_dir"

  first_line=$(sed -n '1p' "$skill_file")
  [ "$first_line" = "---" ] || die "$skill/SKILL.md must start with YAML frontmatter"

  metadata_name=$(sed -n '2,80s/^name:[[:space:]]*//p' "$skill_file" | sed -n '1p')
  [ "$metadata_name" = "$skill" ] || die "$skill/SKILL.md frontmatter name must match its directory"

  description=$(sed -n '2,80s/^description:[[:space:]]*//p' "$skill_file" | sed -n '1p')
  [ -n "$description" ] || die "$skill/SKILL.md frontmatter must include a non-empty description"
  [ "${#description}" -le 1024 ] || die "$skill/SKILL.md description must be 1024 characters or fewer"
}

print_skills() {
  found="false"
  for skill_dir in "$source_dir"/*; do
    [ -d "$skill_dir" ] || continue
    validate_skill "$skill_dir"
    printf '%s\n' "$(basename -- "$skill_dir")"
    found="true"
  done
  [ "$found" = "true" ] || die "no skills found in $source_dir"
}

if [ "$list_only" = "true" ]; then
  print_skills
  exit 0
fi

install_skill() {
  skill_dir="$1"
  skill="$(basename -- "$skill_dir")"
  target="$dest_dir/$skill"

  validate_skill "$skill_dir"

  if [ -e "$target" ] && [ "$force" != "true" ]; then
    die "$target already exists; rerun with --force to replace it"
  fi

  if [ "$dry_run" = "true" ]; then
    if [ -e "$target" ]; then
      printf 'would replace %s -> %s\n' "$skill_dir" "$target"
    else
      printf 'would install %s -> %s\n' "$skill_dir" "$target"
    fi
    return
  fi

  mkdir -p "$dest_dir"

  if [ -e "$target" ]; then
    [ -L "$target" ] && die "refusing to install over a symlink: $target"
    rm -rf "$target"
  fi

  [ -L "$target" ] && die "refusing to install over a symlink: $target"
  cp -R "$skill_dir" "$target"
  printf 'installed %s -> %s\n' "$skill" "$target"
}

if [ -n "$skill_name" ]; then
  is_valid_skill_name "$skill_name" || die "invalid skill name: $skill_name"
  [ -d "$source_dir/$skill_name" ] || die "skill not found: $skill_name"
  install_skill "$source_dir/$skill_name"
else
  found="false"
  for skill_dir in "$source_dir"/*; do
    [ -d "$skill_dir" ] || continue
    install_skill "$skill_dir"
    found="true"
  done
  [ "$found" = "true" ] || die "no skills found in $source_dir"
fi
