# Commands Discovery

### 1. Discover CI Configuration

If cache miss, search for CI/CD definitions in order of priority:

```
.github/workflows/*.yml     # GitHub Actions (primary)
.gitlab-ci.yml              # GitLab CI
.circleci/config.yml        # CircleCI
Jenkinsfile                 # Jenkins
.travis.yml                 # Travis CI
azure-pipelines.yml         # Azure DevOps
```
Git hooks:
```
.githooks/pre-commit        # Git pre-commit hook
.githooks/pre-push          # Git pre-push hook
```

### 2. Discover Task Runners

Also check for task definitions that CI might invoke:

```
Makefile / GNUmakefile      # Make targets
package.json                # npm/yarn scripts
justfile                    # Just command runner
Taskfile.yml                # Task runner
pyproject.toml              # Python (pytest, ruff, mypy)
Cargo.toml                  # Rust (cargo test, cargo clippy)
mix.exs                     # Elixir
build.gradle / pom.xml      # Java/Kotlin
```

### 3. Extract Commands from CI

Parse workflow files to identify:

- **Linting**: eslint, ruff, rubocop, golangci-lint, clippy
- **Type checking**: tsc, mypy, pyright
- **Formatting**: prettier, black, gofmt, rustfmt
- **Tests**: jest, pytest, go test, cargo test, mix test
- **Build**: npm run build, cargo build, go build, make build

Look for `run:` steps in GitHub Actions. Extract the actual shell commands.

### 4. MOST IMPORTANT: Cache Discovered Commands

After discovering commands, cache them for future runs:

```bash
# Example: cache lint commands from .github/workflows/ci.yml
$HOME/.dotfiles/ai/bin/aimeta autoland \
  --cache ".github/workflows/ci.yml" \
  "lint" \
  '["npm run lint", "eslint ."]'

# Example: cache build commands from Makefile
$HOME/.dotfiles/ai/bin/aimeta autoland \
  --cache "Makefile" \
  "build" \
  '["make build"]'
```

**Caching Strategy**:
- Cache each source file separately with its commands
- Include category (lint, test, typecheck, format, build)
- Use SHA-1 hash for invalidation
- Commands are deduplicated by `source+command+category`

**Cache Script Interface**:
```bash
$HOME/.dotfiles/ai/bin/aimeta autoland --list
$HOME/.dotfiles/ai/bin/aimeta autoland --cache <source> <category> '<commands_json>'
$HOME/.dotfiles/ai/bin/aimeta autoland --clear
```

