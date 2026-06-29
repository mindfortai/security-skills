---
name: supply-chain-review
description: Reviews dependencies, CI/CD, build scripts, release workflows, containers, and repository security settings for supply-chain and deployment risk. Use when testing software composition, vulnerable components, or build and release security posture.
allowed-tools: Read Grep Glob Bash WebSearch WebFetch
---

# Supply Chain Review

Use this skill when reviewing what software the product contains and how code becomes a running product: SBOMs, direct dependencies, transitive dependencies, vendored code, container layers, build tools, CI workflows, secrets, artifacts, releases, and deployment permissions.

The goal is to find realistic paths where a vulnerable component, compromised dependency, over-privileged workflow, leaked secret, unsafe build step, or untrusted artifact could affect production, customers, source code, or release integrity.

## Operating Principles

- Review the actual path from pull request to build to deploy.
- Build the best SBOM/software composition inventory the local repo allows before judging dependency risk.
- Recursively inspect direct and transitive dependency versions. Lockfiles, generated SBOMs, package-manager graphs, container manifests, vendored code, and build plugins are all in scope.
- Use web search and vulnerability databases for current CVE/advisory research when local tooling cannot answer package-version exposure.
- Treat CI tokens, package install scripts, deploy keys, cloud credentials, artifact signing, and release automation as high-value assets.
- Distinguish theoretical supply-chain hygiene from reachable component, build, or release risk.
- Treat CVE matches as leads, not final findings. Validate affected version ranges, reachable runtime/build context, fixed versions, exploitability notes, and whether the vulnerable code path is actually present.
- Do not run dependency installation, destructive release commands, or production deployment commands unless explicitly approved.
- Use security-tool findings as evidence, not as final judgment.

## Discovery

Inspect, when present:

- GitHub Actions, GitLab CI, CircleCI, Buildkite, Jenkins, Railway, Fly, Vercel, Netlify, Render, Heroku, or custom deploy scripts.
- `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `bun.lockb`, `requirements.txt`, `requirements.lock`, `poetry.lock`, `Pipfile.lock`, `uv.lock`, `pyproject.toml`, `go.mod`, `go.sum`, `Cargo.toml`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`, `mix.lock`, `pom.xml`, `gradle.lockfile`, `build.gradle`, `packages.lock.json`, `Package.resolved`, `conan.lock`, `vcpkg.json`, `Dockerfile`, `docker-compose.yml`.
- Existing SBOMs or vulnerability artifacts: CycloneDX JSON/XML, SPDX JSON/tag-value, Syft output, Trivy/Grype reports, Dependabot/Renovate reports, SARIF, VEX, CSAF, vendor advisories, and container scan output.
- Release scripts, publish scripts, migration scripts, generated code, vendored binaries, and build tooling.
- Terraform, Kubernetes, Helm, Docker Compose, serverless config, cloud IAM, secrets references, and environment examples.
- Dependabot, Renovate, CodeQL, secret scanning, branch protection, required checks, artifact attestation, and vulnerability scan configs.

Useful commands when available:

```sh
rg --files
rg -n "GITHUB_TOKEN|permissions:|secrets\\.|pull_request_target|workflow_run|id-token|OIDC|deploy|publish|release|docker|artifact|provenance|attest"
rg -n "postinstall|preinstall|curl|wget|bash|sh -c|eval|npm publish|twine upload|docker push"
rg -n "cyclonedx|spdx|sbom|syft|grype|trivy|osv|dependabot|renovate|audit|vulnerability|cve|vex|csaf"
```

Useful SBOM and dependency graph commands when already available in the repo or local environment:

```sh
syft . -o cyclonedx-json
trivy fs --format cyclonedx .
cyclonedx-npm --output-format JSON
npm ls --all --json
pnpm list --recursive --depth Infinity --json
yarn info --name-only
pip inspect
uv pip list
poetry show --tree
go list -m -json all
cargo tree --edges normal,build
bundle list
composer show --tree
mvn dependency:tree
gradle dependencies
dotnet list package --include-transitive
swift package show-dependencies --format json
```

Do not install SBOM tooling just to complete the review unless the user approves dependency installation. If tools are missing, reconstruct the SBOM from lockfiles and package manifests as far as possible and record coverage limits.

If authenticated and authorized, read-only GitHub checks can include:

```sh
gh repo view --json nameWithOwner,isPrivate,defaultBranchRef,url
gh api repos/{owner}/{repo}/dependabot/alerts --paginate
gh api repos/{owner}/{repo}/code-scanning/alerts --paginate
gh api repos/{owner}/{repo}/secret-scanning/alerts --paginate
```

If these are unavailable, record that as a limitation rather than a clean result.

## Review Areas

### SBOM And Software Composition Analysis

Build a component inventory before reporting dependency findings.

For each ecosystem in scope, identify:

- Primary component: application, service, package, container image, or deployable artifact.
- Direct dependencies and transitive dependencies with exact versions.
- Package ecosystem and package URL when possible: npm, PyPI, Go, Cargo, Maven, NuGet, RubyGems, Composer, SwiftPM, Hex, Debian, Alpine, RPM, GitHub Actions, Docker image, vendored binary, or source archive.
- Dependency depth: direct, transitive, build-time, runtime, dev/test-only, optional, peer, plugin, action, image layer, vendored, generated, or unknown.
- Lockfile source and confidence: exact lockfile, package-manager graph, generated SBOM, container scanner, manifest-only inference, or unknown.
- Integrity data when available: hashes, checksums, resolved URLs, registry source, signatures, attestations, and provenance.
- Unknowns: missing lockfiles, unresolved version ranges, private registries, vendored blobs, generated artifacts, binary downloads, container base-image ancestry, and dependency groups not represented by tooling.

Prefer CycloneDX or SPDX when an SBOM artifact can be generated safely. If an SBOM artifact cannot be generated, produce a best-effort component inventory from manifests and lockfiles.

### Recursive CVE And Advisory Research

For each exact component version that is production runtime, build-critical, security-sensitive, or reachable through a deployable artifact:

- Query local advisory tooling first when available: Dependabot, Renovate, package manager audit, `osv-scanner`, `trivy`, `grype`, `npm audit`, `pip-audit`, `cargo audit`, `bundler-audit`, `govulncheck`, `dotnet list package --vulnerable`, `mvn org.owasp:dependency-check`, or similar.
- Use web search and public vulnerability sources to research exact package/version exposure when local tooling is missing, stale, incomplete, or disagrees.
- Prefer primary/current sources: OSV, GitHub Security Advisories, NVD, CISA KEV, vendor advisories, distro security trackers, package registry advisories, language-ecosystem advisories, and maintainer release notes.
- Search recursively: if a vulnerable package appears as a transitive dependency, trace which direct dependency introduces it, whether the vulnerable version is actually selected by the lockfile, and which upgrade or override path removes it.
- Check affected version ranges, fixed versions, vulnerable functions/modules, exploitability, known exploitation, EPSS/CVSS only as supporting evidence, and whether the package is present in runtime, build, test, or unused optional scope.
- Deduplicate by vulnerable component plus reachable path. Do not create separate rows for every advisory alias when they describe the same underlying vulnerability.
- Treat unresolved version ranges, private packages, vendored binaries, and container base layers as `needs_validation` when exact CVE matching cannot be completed.

Do not report a CVE solely because a package name appears in the repo. Confirm exact version, vulnerable range, dependency path, and reachable context.

### Workflow Permissions

Look for:

- Broad `contents: write`, `actions: write`, `packages: write`, `id-token: write`, or default write permissions.
- `pull_request_target` or `workflow_run` paths that run untrusted code with privileged tokens.
- Missing branch protection or required checks for release branches.
- Jobs that deploy from unreviewed branches, forks, or untrusted artifacts.

### Secrets And Credentials

Look for:

- Secrets printed to logs, passed to untrusted scripts, exposed to pull requests, embedded in examples/tests, or stored in repo files.
- Long-lived cloud keys where OIDC or scoped deploy tokens should be used.
- Shared production credentials used in build, test, and deploy contexts.

For deep cryptography and secrets review (password hashing, encryption modes, JWT verification, webhook signatures, TLS configuration, key management, and crypto agility), see the `code-review` skill.

### Dependencies

Look for:

- Unpinned or loosely pinned dependencies in security-sensitive services.
- Lockfile drift or missing lockfiles.
- Install scripts in dependency paths.
- Known vulnerable dependencies that are reachable in runtime or build.
- Development-only vulnerabilities incorrectly treated as production risk, and production vulnerabilities incorrectly dismissed as dev-only.
- Transitive dependencies with high/critical CVEs hidden behind broad version ranges, private registries, optional dependency groups, plugins, or container base images.
- Dependency confusion risk from mixed public/private package names, unscoped internal packages, custom registry fallback, or lockfiles resolving to unexpected registries.
- Typosquatting, abandoned packages, suspicious maintainers, unexpected postinstall behavior, unsigned binaries, or packages fetched from Git URLs, tarballs, raw URLs, or mutable branches.
- Duplicated dependency versions where an old vulnerable transitive version remains even after a top-level package appears patched.

### Build And Release Integrity

Look for:

- Build scripts that fetch and execute remote code.
- Unsigned or unverified artifacts.
- Generated code or vendored binaries without provenance.
- Release automation that can be triggered by low-trust actors.
- Publish steps that reuse broad personal tokens.

### Containers And Runtime Images

Look for:

- Root containers, broad capabilities, writable filesystems, missing health checks, secret-bearing layers, unpinned base images, and build args leaking secrets.
- Vulnerability scan results and whether critical findings are in runtime layers.
- Base-image lineage, OS package versions, language runtime versions, package manager cache contents, copied vendored binaries, and multi-stage build artifacts that carry vulnerable components into the final image.

### Infrastructure And Deployment

Look for:

- Over-broad IAM, public storage, exposed admin ports, weak network segmentation, missing TLS, unsafe CORS, public debug endpoints, and environment drift.
- Whether staging and production are separated enough to prevent accidental exposure.

## Finding Standard

A finding must answer:

- What build, release, dependency, SBOM component, transitive path, container layer, or deployment path is affected?
- What attacker or failure scenario is realistic?
- What credential, artifact, environment, or customer impact is at risk?
- What existing control is missing, weak, or bypassable?
- What evidence proves reachability or material risk?
- For CVE/component findings: what exact component name, ecosystem, version, dependency path, advisory ID/CVE, affected range, fixed version, and runtime/build scope apply?
- What minimal change reduces the risk?
- What check should enforce the fix going forward?

## Validation

- Run local build, lint, workflow simulation, dependency-audit, container, or IaC checks when the commands are clear, safe, and do not publish artifacts or deploy.
- Generate or parse an SBOM when safe. If a full SBOM cannot be generated, produce a best-effort inventory from lockfiles and manifests and state confidence.
- Use web search tooling to validate exact package/version CVEs when local advisory tools are missing, stale, or incomplete. Cite the source in `evidence` or `scope_notes`.
- Use temporary stubs only to isolate unavailable registries, cloud credentials, scanners, or external services. Do not stub the CI permission, release gate, dependency behavior, or infrastructure setting being reviewed.
- Clean up scratch manifests, temporary config, mock registries, generated artifacts, local scan outputs, and throwaway scripts before final output unless the user asked to keep them.
- When subagents are available, ask an independent subagent to challenge high-impact findings for whether the path can affect source, secrets, artifacts, deployments, or production.

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `category` values such as `sbom`, `sca-cve`, `transitive-dependency`, `workflow-permissions`, `secrets`, `dependencies`, `dependency-confusion`, `release`, `containers`, `base-image`, `infrastructure`, `repository-settings`, `artifact-integrity`, `iam`, or `tooling`.

Example row:

```csv
F-001,high,high,confirmed,workflow-permissions,pull_request_target runs untrusted install with write token,.github/workflows/test.yml:14,CI test workflow,external contributor,The workflow checks out pull request code and runs package install under pull_request_target with write permissions,A malicious PR can execute code with repository token privileges,Workflow uses pull_request_target contents:write and runs npm install from PR-controlled package scripts,Use pull_request with read-only permissions or checkout base before privileged operations,Add CI policy check preventing pull_request_target jobs from running untrusted code,Dependabot unavailable; reviewed GitHub Actions only
F-002,high,medium,confirmed,sca-cve,Runtime image includes vulnerable transitive package,poetry.lock:412,api container runtime dependency chain,remote unauthenticated user,package-a pulls package-b 1.2.3 which is in the affected range for CVE-YYYY-NNNN,Reachable request parsing path can trigger the vulnerable code in production,Lockfile selects package-b 1.2.3 via package-a and OSV/GitHub advisory list fixed version 1.2.4,Upgrade package-a or override package-b to 1.2.4+ and rebuild the image,Add dependency audit gate plus smoke test for the request parsing path,SBOM reconstructed from poetry.lock; advisory checked with OSV and vendor release notes
```

If no confirmed issues are found, still emit the header and one `no_confirmed_findings` informational row. Put tooling status, coverage, and residual risk after the CSV unless the user asks for CSV only.

After the findings CSV, include an SBOM summary unless the user asks for CSV only:

```text
SBOM Summary
- Format generated or reconstructed: CycloneDX | SPDX | lockfile-derived | mixed | not available
- Ecosystems reviewed: ...
- Components inventoried: direct=..., transitive=..., container/os=..., vendored=..., unknown=...
- Vulnerability sources checked: OSV, GitHub Advisories, NVD, CISA KEV, vendor advisories, package-manager audit, scanner output, ...
- Unresolved composition gaps: ...
```

When the user asks for the SBOM itself, output a second CSV component inventory:

```csv
component_id,ecosystem,name,version,package_url,dependency_depth,scope,dependency_path,source_file,integrity,licenses,vulnerability_status,notes
```
