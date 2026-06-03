// Area 5 microsprint dispatch template (MS4-MS8 reusable).
//
// Encodes the three harness rules from feedback_spec_baseline_and_workflow_halt.md
// as EXECUTABLE CODE, not advisory text:
//
// Rule 1 (spec baseline preflight): Phase 0 reads the spec/plan/ADRs cited by
//   args and verifies every cited /tmp/spoke-*.png file exists and is > 0 bytes.
//   If any baseline is missing/empty, the workflow HALTS before Phase 1.
//
// Rule 2 (workflow phase halt gate): every phase returns `shouldHaltForEduardo`
//   in its structured output. The controller code below checks this BEFORE
//   dispatching the next phase. No `if` branch can be silently omitted — the
//   helper `dispatchOrHalt` makes it mechanical.
//
// Rule 3 (1st-time architectural surprise): the implementer prompt is built
//   with an explicit clause "if your spoke baseline contradicts the spec/plan
//   in a structural way (widget shape, navigation model, state model) you MUST
//   return BLOCKED_SPEC_OUTDATED status and stop — do NOT implement either
//   version." This makes the implementer a halt source too.
//
// Invocation: Workflow({scriptPath: '.claude/workflows/area5-microsprint.js', args: {
//   msNumber: 4,                                  // microsprint number (4, 5, 6, 8)
//   msTitle: 'Time sub-pickers (numpad)',         // human-readable
//   baseCommitSha: 'a00a0a6',                     // HEAD before this MS starts
//   spokeBaselineFiles: [                          // PNGs cited by spec/plan/ADRs
//     '/tmp/spoke-a5-inspection/step2-time-iniciar.png',
//     '/tmp/spoke-a5-inspection/step4-typed-1030.png',
//   ],
//   specRelPath: 'docs/superpowers/specs/2026-06-02-area5-route-details.md',
//   planRelPath: 'docs/superpowers/plans/2026-06-02-area5-route-details.md',
//   relevantAdrRelPaths: ['docs/decisions/0042-time-picker-numpad-spoke-fidelity.md'],
//   widgetUnderInspection: 'time picker — Início and Término sub-pickers',
//   filesToTouch: [                                // expected diff scope
//     'apps/mobile/lib/features/route_config/presentation/widgets/time_picker_sheet.dart',
//     'apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart',
//     'apps/mobile/test/features/route_config/presentation/widgets/time_picker_sheet_test.dart',
//     'apps/mobile/test/features/route_config/presentation/pages/route_details_page_test.dart',
//   ],
//   minTestsExpected: 213,                         // baseline + delta
// }})

export const meta = {
  name: 'area5-microsprint',
  description: 'Reusable MS4-MS8 dispatch with executable halt gates and spec-baseline preflight',
  phases: [
    { title: 'Preflight' },
    { title: 'Spoke Baseline' },
    { title: 'Library Research' },
    { title: 'Implement' },
    { title: 'Reviews' },
  ],
}

// ---------------------------------------------------------------------------
// Shared output schemas — every phase carries shouldHaltForEduardo + haltReason
// so the controller can mechanically check before fanning out next phase.
// ---------------------------------------------------------------------------

const HALT_FIELDS = {
  shouldHaltForEduardo: { type: 'boolean' },
  haltReason: { type: 'string', description: 'Required if shouldHaltForEduardo is true' },
}

const PREFLIGHT_SCHEMA = {
  type: 'object',
  required: ['shouldHaltForEduardo', 'baselineCheckResults', 'docCheckResults'],
  properties: {
    ...HALT_FIELDS,
    baselineCheckResults: {
      type: 'array',
      items: {
        type: 'object',
        required: ['path', 'exists', 'sizeBytes'],
        properties: {
          path: { type: 'string' },
          exists: { type: 'boolean' },
          sizeBytes: { type: 'number' },
        },
      },
    },
    docCheckResults: {
      type: 'array',
      items: {
        type: 'object',
        required: ['path', 'exists', 'hasInferredMarker'],
        properties: {
          path: { type: 'string' },
          exists: { type: 'boolean' },
          hasInferredMarker: { type: 'boolean', description: 'True if file contains literal [INFERRED — VERIFY BEFORE LOCK]' },
        },
      },
    },
    notes: { type: 'string' },
  },
}

const BASELINE_SCHEMA = {
  type: 'object',
  required: ['shouldHaltForEduardo', 'screenshotsCaptured', 'widgetStructure', 'divergencesVsSpec'],
  properties: {
    ...HALT_FIELDS,
    inspectionPath: { type: 'string', enum: ['maestro_mcp', 'adb_uiautomator', 'mixed'] },
    screenshotsCaptured: { type: 'array', items: { type: 'string' } },
    widgetStructure: {
      type: 'object',
      required: ['summary'],
      properties: {
        summary: { type: 'string', description: 'One paragraph describing what Spoke actually renders' },
        topbar: { type: 'string' },
        body: { type: 'string' },
        confirmAction: { type: 'string' },
        cancelAction: { type: 'string' },
        differences: { type: 'string', description: 'How sub-variants of the widget differ (e.g. Iniciar vs Termino)' },
      },
    },
    divergencesVsSpec: {
      type: 'array',
      items: {
        type: 'object',
        required: ['kind', 'spokeReality', 'specSays', 'severity'],
        properties: {
          kind: { type: 'string', enum: ['structural', 'label', 'count', 'icon', 'order', 'microcopy', 'flow', 'state'] },
          spokeReality: { type: 'string' },
          specSays: { type: 'string', description: 'What spec/plan currently claims about this aspect' },
          severity: { type: 'string', enum: ['architectural-surprise', 'must-fix', 'should-fix', 'nit'] },
          fixDescription: { type: 'string' },
        },
      },
    },
    notes: { type: 'string' },
  },
}

const RESEARCH_SCHEMA = {
  type: 'object',
  required: ['shouldHaltForEduardo', 'recommendations'],
  properties: {
    ...HALT_FIELDS,
    recommendations: {
      type: 'array',
      items: {
        type: 'object',
        required: ['topic', 'recommendation', 'source'],
        properties: {
          topic: { type: 'string' },
          recommendation: { type: 'string' },
          source: { type: 'string' },
        },
      },
    },
    risksDiscovered: { type: 'array', items: { type: 'string' } },
  },
}

const IMPLEMENT_SCHEMA = {
  type: 'object',
  required: ['status', 'commitsMade', 'filesChanged', 'testCounts', 'analyzeStatus'],
  properties: {
    status: { type: 'string', enum: ['DONE', 'DONE_WITH_CONCERNS', 'BLOCKED_SPEC_OUTDATED', 'BLOCKED_OTHER', 'NEEDS_CONTEXT'] },
    blockReason: { type: 'string', description: 'Required if status starts with BLOCKED_*' },
    commitsMade: { type: 'array', items: { type: 'string' } },
    filesChanged: { type: 'array', items: { type: 'string' } },
    testCounts: { type: 'string' },
    analyzeStatus: { type: 'string' },
    divergencesAddressed: { type: 'array', items: { type: 'string' } },
    techDebtIntroduced: { type: 'array', items: { type: 'string' }, description: 'Empty if zero debt — non-empty list triggers automatic review failure' },
    concerns: { type: 'array', items: { type: 'string' } },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  required: ['verdict', 'mustFix', 'shouldFix', 'nits'],
  properties: {
    verdict: { type: 'string', enum: ['compliant', 'issues_found', 'approved', 'changes_requested'] },
    mustFix: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'fileRef', 'detail'],
        properties: {
          title: { type: 'string' },
          fileRef: { type: 'string' },
          detail: { type: 'string' },
        },
      },
    },
    shouldFix: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'fileRef', 'detail'],
        properties: {
          title: { type: 'string' },
          fileRef: { type: 'string' },
          detail: { type: 'string' },
        },
      },
    },
    nits: { type: 'array', items: { type: 'string' } },
    strengths: { type: 'array', items: { type: 'string' } },
    confidenceNote: { type: 'string' },
  },
}

// ---------------------------------------------------------------------------
// args parsing + validation
//
// IMPORTANT: empirically (see workflow w1lt9y2qo probe 2026-06-03), the
// Workflow runtime delivers `args` as a STRING (the JSON-stringified value
// passed in the tool call), NOT as the actual JS object the tool docs imply.
// We parse defensively to support both shapes — string AND object — so the
// template works regardless of any future runtime change.
// ---------------------------------------------------------------------------

let cfg
if (typeof args === 'string') {
  try {
    cfg = JSON.parse(args)
  } catch (e) {
    throw new Error(`area5-microsprint: args is a string but not valid JSON. Got: ${args.slice(0, 200)}`)
  }
} else if (args != null && typeof args === 'object') {
  cfg = args
} else {
  throw new Error('area5-microsprint: args is missing. Pass via Workflow({args: {...}}).')
}

const REQUIRED_ARGS = [
  'msNumber', 'msTitle', 'baseCommitSha', 'spokeBaselineFiles',
  'specRelPath', 'planRelPath', 'widgetUnderInspection', 'filesToTouch',
  'minTestsExpected',
]
for (const k of REQUIRED_ARGS) {
  if (cfg[k] == null) {
    throw new Error(`area5-microsprint: missing required arg '${k}'. Pass via Workflow({args: {...}}).`)
  }
}
if (!Array.isArray(cfg.spokeBaselineFiles) || cfg.spokeBaselineFiles.length === 0) {
  throw new Error('area5-microsprint: spokeBaselineFiles must be a non-empty array of /tmp/*.png paths')
}
if (!Array.isArray(cfg.filesToTouch) || cfg.filesToTouch.length === 0) {
  throw new Error('area5-microsprint: filesToTouch must be a non-empty array')
}

const REPO_ROOT = '/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro'

// ---------------------------------------------------------------------------
// Rule 2 halt-gate helper — wraps every phase dispatch.
// If the phase returns shouldHaltForEduardo=true, the workflow returns a
// structured "halted" result and the controller MUST surface to Eduardo.
// ---------------------------------------------------------------------------

function buildHaltedResult(phaseLabel, partial, reason) {
  return {
    halted: true,
    atPhase: phaseLabel,
    haltReason: reason || partial.haltReason || 'unspecified',
    partial,
    msNumber: cfg.msNumber,
    msTitle: cfg.msTitle,
    baseCommitSha: cfg.baseCommitSha,
  }
}

// ===========================================================================
// PHASE 0 — Preflight: verify spec baseline PNGs and docs exist + non-empty
// ===========================================================================

phase('Preflight')

const preflight = await agent(
  `You are running Phase 0 preflight for MS${cfg.msNumber} (${cfg.msTitle}).

Repo: ${REPO_ROOT}
Base commit (HEAD before this MS): ${cfg.baseCommitSha}

## Your ONLY job — verify upstream artifacts before any agent does real work

This phase enforces Rule 1 of memory \`feedback_spec_baseline_and_workflow_halt\` — every spec/plan/ADR cited baseline PNG must exist on disk AND be non-zero bytes. If ANY baseline is missing or empty, the workflow MUST halt before Phase 1.

### Step 1 — Baseline PNG check

For each path in the list below, run \`ls -la <path>\` and \`stat -c %s <path>\` (or equivalent on macOS: \`stat -f %z <path>\`). Record:

- \`path\`: the literal path
- \`exists\`: true if file is present
- \`sizeBytes\`: the file size in bytes (0 if empty or missing)

Baselines to check:
${cfg.spokeBaselineFiles.map((p) => `  - ${p}`).join('\n')}

### Step 2 — Spec/plan/ADR \`[INFERRED — VERIFY BEFORE LOCK]\` scan

For each doc path below, read the file and search for the literal string \`[INFERRED — VERIFY BEFORE LOCK]\` (case-sensitive). Record:

- \`path\`: literal path
- \`exists\`: true if file is present
- \`hasInferredMarker\`: true if the file contains the literal marker

Docs to check:
  - ${cfg.specRelPath}
  - ${cfg.planRelPath}
${(cfg.relevantAdrRelPaths || []).map((p) => `  - ${p}`).join('\n')}

### Step 3 — Decide halt

Set \`shouldHaltForEduardo: true\` and provide \`haltReason\` if ANY of:
- Any baseline file has \`sizeBytes < 100\` (anything under 100 bytes is too small to be a real screenshot).
- Any baseline file does not exist.
- Any spec/plan/ADR contains the \`[INFERRED]\` marker (those decisions need live verification before any code is written).
- Any spec/plan/ADR file does not exist.

Otherwise: \`shouldHaltForEduardo: false\`.

### Return per schema. ONE StructuredOutput call only.`,
  { schema: PREFLIGHT_SCHEMA, label: 'preflight', phase: 'Preflight' }
)

if (preflight.shouldHaltForEduardo) {
  return buildHaltedResult('Preflight', preflight, preflight.haltReason)
}

// Defensive secondary check — if the agent set shouldHalt=false but any
// baseline is empty, halt anyway. Trust but verify (Rule 2 mechanical).
for (const b of preflight.baselineCheckResults) {
  if (!b.exists || b.sizeBytes < 100) {
    return buildHaltedResult(
      'Preflight',
      preflight,
      `Baseline ${b.path} is missing or empty (${b.sizeBytes} bytes). Agent said no halt but defensive check overrides.`,
    )
  }
}
for (const d of preflight.docCheckResults) {
  if (d.hasInferredMarker) {
    return buildHaltedResult(
      'Preflight',
      preflight,
      `Doc ${d.path} contains [INFERRED — VERIFY BEFORE LOCK] marker. Spec must be locked before MS dispatch.`,
    )
  }
}

// ===========================================================================
// PHASE 1 — Spoke baseline (live re-inspection of the specific widget)
// ===========================================================================

phase('Spoke Baseline')

const baseline = await agent(
  `LIVE Spoke baseline re-inspection for MS${cfg.msNumber}: ${cfg.widgetUnderInspection}.

Device: Samsung M54 \`RQCW401G33T\` (confirmed connected at MS start; if \`mcp__maestro__list_devices\` returns empty, halt).

## Eduardo's directive (memory)

- Spoke is canonical for behavior/UX (\`feedback_spoke_parity_zero_debt_per_ms\`).
- 1st-time architectural surprise = immediate escalation, not "implement and flag later" (\`feedback_spec_baseline_and_workflow_halt\` Rule 3).

## What to do

Navigate Spoke on M54 to the screen containing \`${cfg.widgetUnderInspection}\`. Capture XML + PNG of every state the widget can be in (empty, mid-interaction, confirmed, dismissed).

**Prefer Maestro MCP.** Fallback to \`adb shell uiautomator dump\` + \`adb exec-out screencap -p\`. Save screenshots to \`/tmp/spoke-a5-inspection/ms${cfg.msNumber}-*.png\`.

## What to compare against

The pre-existing spec (\`${cfg.specRelPath}\`) and plan (\`${cfg.planRelPath}\`) make claims about \`${cfg.widgetUnderInspection}\`. Read those documents and the relevant ADRs (${(cfg.relevantAdrRelPaths || []).join(', ') || 'none specified'}), then list every divergence between what Spoke actually renders and what spec/plan/ADRs currently claim.

For each divergence, classify \`severity\`:

- **\`architectural-surprise\`**: structural mismatch where the widget SHAPE, navigation MODEL, state MODEL, or persistence MODEL in spec/plan does NOT match Spoke. Examples: spec says wheel, Spoke is numpad. Spec says full-screen route, Spoke is bottom sheet. Spec says 3 routes, Spoke has 1 screen with 3 modes. THIS LEVEL OF MISMATCH means the spec is wrong about the foundational architecture and MUST be revised BEFORE implementer dispatch.
- **\`must-fix\`**: divergence in label/count/icon/order that affects user-visible behavior but does NOT change the architecture.
- **\`should-fix\`**: divergence in microcopy or spacing.
- **\`nit\`**: cosmetic.

## Halt condition (Rule 3 — first-time architectural surprise)

Set \`shouldHaltForEduardo: true\` and provide \`haltReason\` if you find at least one \`architectural-surprise\` divergence. Do NOT continue to library research if the spec's foundational architecture is wrong — that's exactly the MS4 wheel_picker failure mode (Phase 2 researched the wrong widget because Phase 1 surprise was ignored).

Otherwise: \`shouldHaltForEduardo: false\`.

## Apply Compose icon lessons (mandatory)

- \`lesson_uiautomator_blindspot_compose_imagevectors\` — XML hierarchy does NOT expose Compose Icon composables. Cite SCREENSHOT PIXELS for any icon presence/absence claim.
- \`lesson_visual_screenshot_overrides_xml_inference_in_compose_apps\` — re-dispatch reports that lack screenshot evidence.

Return per schema.`,
  { schema: BASELINE_SCHEMA, label: 'spoke-baseline', phase: 'Spoke Baseline', agentType: 'spoke-parity-checker' }
)

if (baseline.shouldHaltForEduardo) {
  return buildHaltedResult('Spoke Baseline', baseline, baseline.haltReason)
}

// Defensive: even if agent said no halt, if any divergence is architectural-surprise, halt.
const archSurprises = baseline.divergencesVsSpec.filter((d) => d.severity === 'architectural-surprise')
if (archSurprises.length > 0) {
  return buildHaltedResult(
    'Spoke Baseline',
    baseline,
    `${archSurprises.length} architectural-surprise divergence(s) detected: ${archSurprises.map((d) => d.kind).join(', ')}. Spec must be revised before implementer dispatch.`,
  )
}

// ===========================================================================
// PHASE 2 — Library research (only if baseline matched spec architecturally)
// ===========================================================================

phase('Library Research')

const research = await agent(
  `Research Flutter 3.44 + Riverpod 3 best practices for MS${cfg.msNumber} (${cfg.msTitle}).

## Spoke baseline (just captured, frozen)

\`\`\`
${JSON.stringify(baseline.widgetStructure, null, 2)}
\`\`\`

Divergences cataloged (none architectural — already verified by Phase 1 halt check):
${baseline.divergencesVsSpec.map((d, i) => `${i + 1}. [${d.severity}] ${d.kind}: ${d.spokeReality}`).join('\n')}

## Research order (Rule 1 of feedback_harness_validation_and_escalation)

1. **Dart MCP** (\`mcp__dart__hover\`, \`mcp__dart__analyze_files\`, \`mcp__dart__pub_dev_search\`) for any installed package.
2. **Context7** (\`mcp__claude_ai_Context7__resolve-library-id\` + \`mcp__claude_ai_Context7__query-docs\`) for external libraries.
3. **WebSearch** only when Context7 misses.

For each topic relevant to building \`${cfg.widgetUnderInspection}\`:
- What's the current Flutter 3.44 / Material 3 idiom?
- Are there gesture / state / lifecycle risks?
- Citation source URL or package id.

## Halt conditions (Rule 2)

Set \`shouldHaltForEduardo: true\` if you discover during research:
- A library API behaves contrary to the spec's assumption AND no workaround is obvious.
- Multiple equally-valid implementation paths exist and the choice has architectural implications for MS${cfg.msNumber + 1}+.
- Risk that violates an existing memory rule (e.g. introduces a sync API where async is required).

Otherwise \`shouldHaltForEduardo: false\`. List \`risksDiscovered\` even if no halt — they inform implementer.

Return per schema.`,
  { schema: RESEARCH_SCHEMA, label: 'library-research', phase: 'Library Research' }
)

if (research.shouldHaltForEduardo) {
  return buildHaltedResult('Library Research', research, research.haltReason)
}

// ===========================================================================
// PHASE 3 — Implement (TDD, with explicit "contradict spec if baseline says so" clause)
// ===========================================================================

phase('Implement')

const impl = await agent(
  `Implement MS${cfg.msNumber} (${cfg.msTitle}) per the spec/plan AND the live Spoke baseline below.

Repo: ${REPO_ROOT}
Branch HEAD before this MS: ${cfg.baseCommitSha}

## Eduardo's directives (memory — non-negotiable)

1. **Spoke is canonical for behavior/UX.** If the spec/plan/ADRs contradict the live Spoke baseline below in a STRUCTURAL way (widget shape, navigation model, state model, persistence model), STOP. Return \`status: 'BLOCKED_SPEC_OUTDATED'\` with \`blockReason\` describing the mismatch. DO NOT implement either version. The controller will escalate to Eduardo.
2. **Zero tech debt.** No \`// TODO\`, \`// FIXME\`, \`// MS\` markers. No commented-out code. No "defer to MS9". If a divergence flagged below requires structural rework, escalate via BLOCKED_OTHER — don't half-fix.
3. **TDD red→green per change.** Test first asserting Spoke string/structure, fails → implement → passes → commit.
4. **Surgical scope.** Touch ONLY files in the allowed list below. \`git diff ${cfg.baseCommitSha} HEAD --stat\` must show only these files at the end.
5. **Spoke baseline is the contract.** Every divergence in the punch list below must be addressed in code AND a paired widget test that asserts the Spoke shape (not the old spec wording).

## Spoke baseline (frozen — DO NOT re-inspect)

\`\`\`
${JSON.stringify(baseline.widgetStructure, null, 2)}
\`\`\`

Baseline screenshots already captured: ${JSON.stringify(baseline.screenshotsCaptured)}.

## Divergences punch list

${baseline.divergencesVsSpec.map((d, i) => `${i + 1}. [${d.severity}] ${d.kind}: Spoke=${d.spokeReality} / Spec=${d.specSays} / Fix=${d.fixDescription || '(infer from baseline)'}`).join('\n')}

## Library research findings

${research.recommendations.map((r) => `- **${r.topic}**: ${r.recommendation} _(source: ${r.source})_`).join('\n')}

Risks to mitigate: ${JSON.stringify(research.risksDiscovered || [])}

## Allowed scope — touch ONLY these files

${cfg.filesToTouch.map((f) => `- ${f}`).join('\n')}

Any drive-by edit outside this list is a fail; the reviewer will reject. \`git diff ${cfg.baseCommitSha} HEAD --stat\` is your scope check before declaring done.

## Acceptance gates (Rule 3 of feedback_escalate_recurring_and_gate_check)

Before declaring DONE, mechanically verify:
- [ ] \`cd apps/mobile && flutter test\` returns "All tests passed!" with count >= ${cfg.minTestsExpected}.
- [ ] \`cd apps/mobile && flutter analyze\` (over touched scope) returns "No issues found!".
- [ ] \`git diff ${cfg.baseCommitSha} HEAD --stat\` shows ONLY files from the allowed list.
- [ ] \`git grep -nE 'TODO|FIXME|XXX|// MS|wires MS' apps/mobile/lib/\` returns nothing inside the diff.

If any gate fails, return \`status: 'DONE_WITH_CONCERNS'\` with the specific gate failure in \`concerns\`. Do NOT claim DONE with unmet gates.

\`techDebtIntroduced\` MUST be an empty array. Non-empty triggers automatic review failure.

Commit per Conventional Commits + valid scope. NO \`.g.dart\` committed (ADR-0005).

Return per schema.`,
  { schema: IMPLEMENT_SCHEMA, label: 'implement', phase: 'Implement' }
)

// Halt on BLOCKED status
if (impl.status === 'BLOCKED_SPEC_OUTDATED') {
  return buildHaltedResult(
    'Implement',
    impl,
    `Implementer detected spec/baseline mismatch and refused to ship either version. blockReason: ${impl.blockReason}`,
  )
}
if (impl.status === 'BLOCKED_OTHER' || impl.status === 'NEEDS_CONTEXT') {
  return buildHaltedResult(
    'Implement',
    impl,
    `Implementer blocked. status=${impl.status}, blockReason: ${impl.blockReason || '(none)'}`,
  )
}

// Defensive: techDebtIntroduced must be empty
if (Array.isArray(impl.techDebtIntroduced) && impl.techDebtIntroduced.length > 0) {
  return buildHaltedResult(
    'Implement',
    impl,
    `Implementer self-reported ${impl.techDebtIntroduced.length} tech debt items. Zero debt rule violated: ${impl.techDebtIntroduced.join('; ')}`,
  )
}

// ===========================================================================
// PHASE 4 — Reviews (spec parity + code quality, parallel)
// ===========================================================================

phase('Reviews')

const [specReview, qualityReview] = await parallel([
  () => agent(
    `Review Spoke parity compliance for MS${cfg.msNumber} implementation.

**DO NOT trust the implementer report.** Read code + Spoke baseline independently.

Branch HEAD after MS commits: read \`git log --oneline ${cfg.baseCommitSha}..HEAD\`.

## Spoke baseline (frozen — already captured by Phase 1)

\`\`\`
${JSON.stringify(baseline.widgetStructure, null, 2)}
\`\`\`

Screenshots: ${JSON.stringify(baseline.screenshotsCaptured)}.

## Divergences punch list implementer was asked to address

${baseline.divergencesVsSpec.map((d, i) => `${i + 1}. [${d.severity}] ${d.kind}: Spoke=${d.spokeReality} / Fix=${d.fixDescription || '(infer)'}`).join('\n')}

## Implementer claims

${JSON.stringify(impl, null, 2)}

## Checks (cite file:line for each)

For each divergence: verify code change + paired test assertion locking Spoke shape.

Mechanical gates:
- \`cd apps/mobile && flutter test\` count >= ${cfg.minTestsExpected}.
- \`cd apps/mobile && flutter analyze\` over implementer's touched scope: clean.
- \`git diff ${cfg.baseCommitSha} HEAD --stat\` shows ONLY: ${cfg.filesToTouch.join(', ')}.
- \`git grep -nE 'TODO|FIXME|XXX|// MS|wires MS' apps/mobile/lib/\` empty in the diff.

Report per schema.`,
    { schema: REVIEW_SCHEMA, label: 'parity-spec-review', phase: 'Reviews' },
  ),
  () => agent(
    `Review code quality for MS${cfg.msNumber} implementation.

Implementer report: ${JSON.stringify(impl, null, 2)}

Research recommendations applied: ${research.recommendations.map((r) => r.topic).join(', ')}.

## Quality dimensions

A. Material 3 / Flutter 3.44 idioms — research recommendations actually applied.
B. Test quality — tests assert BEHAVIOR (tap, callback, state) not just rendering. No tautological asserts.
C. Surgical scope — \`git diff ${cfg.baseCommitSha} HEAD --stat\` matches allowed list.
D. Zero tech debt — no TODO/FIXME/// MS markers in diff.
E. Riverpod 3 — ref.watch reactive, ref.read callback. ConsumerStatefulWidget when local state. Family + autoDispose where scoping needs.
F. Naming — class/method names self-describing. No abbreviations.
G. Theme tokens — AppColors/AppRadii references, no hardcoded hex.
H. Semantics identifiers — every interactive element has stable identifier for Maestro.
I. Commit hygiene — Conventional Commits + valid scope, WHY body, atomic.
J. No .g.dart committed (ADR-0005).

Report per schema.`,
    { schema: REVIEW_SCHEMA, label: 'quality-review', phase: 'Reviews' },
  ),
])

// Final structured return — controller surfaces to Eduardo
return {
  halted: false,
  msNumber: cfg.msNumber,
  msTitle: cfg.msTitle,
  baseCommitSha: cfg.baseCommitSha,
  preflight,
  baseline,
  research,
  impl,
  specReview,
  qualityReview,
}
