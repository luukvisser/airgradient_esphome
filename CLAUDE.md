# CLAUDE.md — Tooling guide for AI coding agents

For repository architecture, directory layout, local dev setup, and ESPHome commands see
**README.md**. For YAML conventions, naming rules, package authoring, commit format, and
PR checklist see **CONTRIBUTING.md**. This file covers only the code quality tooling
added on top of those.

---

## Code quality tooling

This repository uses [pre-commit](https://pre-commit.com/) with four hook sets:

| Hook                         | Tool             | File types      |
| ---------------------------- | ---------------- | --------------- |
| `trailing-whitespace`        | pre-commit-hooks | all             |
| `end-of-file-fixer`          | pre-commit-hooks | all             |
| `check-yaml --unsafe`        | pre-commit-hooks | `.yaml`, `.yml` |
| `check-merge-conflict`       | pre-commit-hooks | all             |
| `check-added-large-files`    | pre-commit-hooks | all             |
| `mixed-line-ending --fix=lf` | pre-commit-hooks | all             |
| `yamlfmt`                    | google/yamlfmt   | `.yaml`, `.yml` |
| `prettier`                   | mirrors-prettier | `.md`           |
| `ruff` (lint + fix)          | astral-sh/ruff   | `.py`           |
| `ruff-format`                | astral-sh/ruff   | `.py`           |

### Why yamlfmt instead of Prettier for YAML

ESPHome configurations use YAML custom tags (`!include`, `!lambda`, `!extend`,
`!secret`) that are not part of the YAML specification. Prettier's YAML parser raises a
parse error on these tags. `yamlfmt` (Google) uses Go's `yaml.v3` library, which
round-trips custom tags without modification — making it the correct formatter for this
project.

Prettier is kept for Markdown only, where it handles prose wrapping cleanly.

### ESPHome custom tags quick reference

| Tag        | Purpose                                       | Example                               |
| ---------- | --------------------------------------------- | ------------------------------------- |
| `!include` | Import another YAML file as a value           | `board: !include packages/board.yaml` |
| `!secret`  | Read a value from `secrets.yaml`              | `password: !secret wifi_password`     |
| `!lambda`  | Inline C++ expression                         | `value: !lambda 'return x * 2;'`      |
| `!extend`  | Extend a component defined in another package | `id: !extend sensor_id`               |

These tags are preserved verbatim by yamlfmt and validated by `check-yaml --unsafe`
(PyYAML FullLoader). Do not treat them as errors.

---

## Setup

```bash
uv tool install pre-commit
pre-commit install
```

---

## Running formatters

```bash
# Run all hooks on every file (what CI runs)
uvx pre-commit run --all-files

# Run a single hook
uvx pre-commit run yamlfmt --all-files
uvx pre-commit run prettier --all-files
uvx pre-commit run ruff --all-files

# Update all hooks to their latest pinned versions
uvx pre-commit autoupdate
```

---

## Before committing

1. Run `uvx pre-commit run --all-files` — hooks auto-fix what they can (trailing
   whitespace, EOF newlines, yamlfmt, ruff). Re-stage any auto-fixed files.
2. Confirm `check-yaml` passes on all YAML files (it validates ESPHome custom tags via
   PyYAML's FullLoader).
3. Commit with a Conventional Commits message (see CONTRIBUTING.md).
