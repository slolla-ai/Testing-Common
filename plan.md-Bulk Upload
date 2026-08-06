# Implementation Plan: DMS Bulk Device Commands & Firmware Queuing at Scale

**Branch**: `FS-1865-dms-bulk-command-queuing` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/FS-1865-dms-bulk-command-queuing/spec.md`

## Summary

Let a DMS user (tech-support / firmware engineer) submit one large bulk job — a device command or a
firmware (FOTA) update — beyond today's practical per-request size, up to a configurable ceiling
(default 10,000). The platform accepts the submission immediately with a job reference, validates the
targeted devices asynchronously, then drains the job through **self-advancing batches**: the next batch
releases only after the current batch reaches a configured **terminal-outcome** completion threshold (or
a per-batch max-wait elapses). Progress and per-device outcomes are visible in the existing DMS
command/firmware history views, a persisted in-app notification announces completion (surviving logout),
and the submitter can cancel an in-flight job.

**Technical approach (grounded in the real repos, Principle VI).** The orchestration is built by
**extending the patterns that already exist in `device-management-service`**, not by introducing a new
async platform:

- **Batch advance = a new, SEPARATE scheduled poller** (`BulkJobBatchPoller`, ≤30 s) — modeled on the
  existing `NggCommandStatusPoller` but deliberately **not** merged into it or `MessageExportPoller`
  (research R11: those are NGG/DDP- and export-specific at the wrong cadence; a separate
  single-responsibility poller keeps the existing ACK listeners and NGG poller untouched). It reads
  active bulk jobs, computes each active batch's terminal-outcome ratio from the per-device rows the
  existing mechanisms already maintain (it does **not** duplicate NGG status polling), and releases the
  next batch via the **existing** `CommandService.sendCommand()` path when the threshold is met or the
  max-wait elapses. *Coordination caveat*: for NGG commands, device-terminal freshness is bounded by the
  existing 5-min NGG poller, so tune that separately if NGG batch throughput must be tighter.
- **Job/batch/outcome state = a new, thin generic orchestration layer** (`bulk_job` / `bulk_job_batch`
  Flyway tables in the `dms` schema) shared by bulk **command and firmware** jobs via a `job_type`
  discriminator (export-extensible), sitting **on top of** the existing domain tables — **not** a merge
  of `message_export_job` / `dat_sent_command(s)` / `firmware_update_detail(s)`, which stay unchanged
  (research R10; they have irreconcilable status vocabularies and aggregation patterns). Per-device
  terminal outcomes are rolled up from the **job-type-appropriate** table (I3): `dat_sent_command_devices`
  for COMMAND jobs (terminal `COMPLETED/FAILED/CANCELLED/EXPIRED`, first-outcome-wins guard), and
  `device_firmware_update_progress` for FIRMWARE jobs (the command-device row only reflects the
  firmware-ready ACK, not transfer completion) — correlated via the **V20** `sentcommanddevicekey` FK.
- **Completion notification = the existing `MessageExportJob` + notification-bell precedent** (a
  persisted job row the UI polls), extended to bulk jobs.
- **Submission = unchanged entry path** (R12/R13): the web app submits the **same** `/commands/send` /
  `/v1/firmwareupdate` endpoints with the same payload (no client-side endpoint branching); the **only**
  frontend change is skipping the client-side asset-validation loop for bulk-criteria requests (R15).
  The backend persists **every** request as a `bulk_job` in `PENDING`, then releases a below-threshold
  job's single batch **immediately in-request** and hands an above-threshold job to the scheduler — one
  uniform submit path. Payload verified within the API Gateway 10 MB cap at the 10k ceiling.
- **Single sent-command per submission** (R16, Option C): each bulk job is **one** `DatSentCommand` with
  all device rows created up front; the poller dispatches them **in chunks** (`PENDING → QUEUED`), so a
  submission is **naturally one history row** keyed by the existing `:sentCommandKey` — this **removes**
  the job-aware-regroup + `bulkJobKey` drilldown re-key. Device lifecycle: `INVALID` (pre-dispatch) |
  `PENDING` (validated pool) → `QUEUED` (dispatched) → terminal. **Cost**: refactor `sendCommand` /
  `createFirmwareUpdateDetail` to **decouple create-from-dispatch**, and update the existing
  status-dependent queries (NGG poller `PENDING→QUEUED`, cancellable query, group-status CASE) since
  `PENDING` is repurposed (research R16).
- **UI = no net-new components** (R14): bulk and small jobs surface in the existing command/firmware
  **history** views via their existing status columns, moving `PENDING → QUEUED → … → terminal` (one row
  per submission, drilldown works as-is). Follow-ups: `QUEUED`/`INVALID` status→label display mapping
  (affects all commands, not just bulk), and a **60 s auto-refresh timer** on the in-flight history view
  for FR-011 (matches the notification-bell cadence). Reuses `px-*` / Material + the notification bell
  (Principle VIII).

Consequently **`dms-infrastructure` change is minimal** (queue capacity/config and, if required, DLQ
tuning — no new Lambda/Step Functions/EventBridge orchestration), keeping this a targeted hardening
rather than a re-architecture.

> **Spec-vs-reality flag carried from spec review (Principle VI).** The spec's premise that "today's
> per-request cap is 2000" is **not enforced anywhere in the verified request path**: neither the
> backend request models (`SendCommandRequest.mcuIds`, `FirmwareUpdateDetailCreateRequest.deviceSensorList`
> have no max-size constraint) nor the web UI impose a 2000 cap. 2000 appears only as an unrelated
> *status-poller* batch size (`ngg.command.poller.batch-size=100`) and a client-side *validation* chunk
> of 150. This plan therefore treats the feature as **introducing** a configurable ceiling + bounded
> async batching (not "raising an existing 2000 cap"), and uses 2000 as an independently-chosen default
> batch size rather than "reuse of today's cap." **This premise must be confirmed by engineering** (see
> research.md R1); if a cap exists at an unsearched layer (BFF/API gateway), the framing is restored.

## Technical Context

**Language/Version**:
- `device-management-service`: Java 17 / Spring Boot (layered controller→service→repository), Gradle.
- `dms-web-app`: TypeScript (strict) / Angular 14.x, Karma+Jasmine.
- `dms-infrastructure`: TypeScript ~5.9 / AWS CDK v2 (2.215.0), Node 20, Jest + cfn-nag.

**Primary Dependencies**: Spring Data JPA + Flyway (forward-only, `dms` schema); Spring Cloud AWS SQS
listeners; WebClient (DDP/NGG); Redis (Lettuce, transient status cache); OpenTelemetry Java agent.
Angular Material + `px-*` shared component library. AWS CDK (`aws-cdk-lib`).

**Storage**:
- PostgreSQL Aurora 14.3 (`dms` schema, read/write split) — **primary store** for bulk-job state and
  per-device outcomes.
- MongoDB Atlas — device telemetry/archive only (not used by this feature).
- Redis ElastiCache — transient SQS-status cache (reused as-is; not the job store).
- S3 — firmware artifacts (already referenced by firmware flow).

**Testing**: JUnit 5 + Mockito (unit), `@integration`-tagged integration tests, **idempotency tests
mandatory** (DMS constitution V); Karma/Jasmine specs for new Angular components; Jest stack assertions
+ cfn-nag for any infra change.

**Target Platform**: ECS Fargate (device-management-service), CloudFront/S3 SPA (dms-web-app), AWS
(us-west-2) provisioned by dms-infrastructure.

**Project Type**: Cross-repo web feature (backend + Angular frontend + IaC).

**Performance Goals**:
- Submission acknowledged within **5 s** regardless of job size (SC-002) — achieved by immediate
  accept + async validation.
- Bounded completion: every job reaches a terminal state within a predictable time given size ×
  batch-size × per-batch max-wait (SC-006).
- Live-progress refresh latency: **60 s** for active jobs (research R7/R14 — a history auto-refresh
  timer matching the existing notification-bell cadence).

**Constraints**: Forward-only Flyway migrations; command/ACK handling MUST stay idempotent under
duplicate SQS delivery; OTEL trace context (W3C `traceparent`) MUST propagate across HTTP and SQS hops;
no secrets in code/logs; Angular strict typing + bundle budgets; infra IaC-only with least-privilege IAM
and env parity across dev/qa/perf/prod.

**Scale/Scope**: Up to ~tens of lessee... (N/A — DMS) → up to a configurable **10,000 devices/job**;
default batch size **2000** (commands and firmware); job volume low (internal staff users). Batch-size
and threshold are per-type configurable.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

This is the **central SDD constitution** (process) check; each service change also complies with its
own repo constitution (Principle IV).

- **I. Specs Before Code** — ✅ spec exists, clarified (4 sessions), checklist 16/16. This plan precedes
  any service code. *Note: spec Status is still `Draft`; four review items (R1 2000-premise, US1/US4
  priority, invalid-reporting-as-new-behavior, progress latency) are surfaced here and should be
  reconciled into the spec before `/speckit-ratify` — they do not block planning but must not be lost.*
- **II. One Feature, One Folder, One Branch** — ✅ `specs/FS-1865-dms-bulk-command-queuing/`, branch ==
  folder, Epic `FS-1865` in `feature.json`.
- **III. Cross-Repo Traceability** — ✅ three impacted repos verified against real code
  (`device-management-service`, `dms-web-app`, `dms-infrastructure`); identical branch name in each.
  Cross-Repo table present in spec. `dms-infrastructure` confirmed **in scope but minimal** (see
  research R3); it stays in the table (may resolve to config-only).
- **IV. Respect Each Service's Constitution** — ✅ verified: DMS (layered arch, forward-only Flyway,
  idempotency + tests, OTEL propagation), dms-web-app (modular Angular, strict TS, RBAC guards, reuse
  `px-*`), dms-infrastructure (IaC-only, env parity, least-privilege IAM, synth/cfn-nag gate). No
  requirement in this plan violates any of them.
- **V. Implementation-Agnostic Spec** — ✅ spec stays behavioral; implementation choices live here.
- **VI. Ground Plans in Real Repos** — ✅ all endpoints, entities, queues, schedulers, and UI components
  cited below were read in the actual repos. The one unverifiable premise (2000 cap) is **flagged, not
  invented** (R1).
- **VIII. Reuse Existing UI Components** — ✅ the plan reuses `dms-web-app`'s command-history /
  firmware-history views, cancel-confirmation popups, notification bell, `px-table`, Material progress
  bar/expansion panels. Net-new UI is limited to what existing screens cannot express (large-scale
  per-device drilldown filtering, live batch-progress panel) and is justified in research R6.

**Result: PASS** — no gate violations; no Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/FS-1865-dms-bulk-command-queuing/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions (R1..R9)
├── data-model.md        # Phase 1 — entities + Flyway migration outline
├── quickstart.md        # Phase 1 — end-to-end validation guide
├── contracts/           # Phase 1 — bulk-job API + notification + config contracts
└── tasks.md             # Phase 2 — /speckit-tasks (NOT created here)
```

### Source Code (per impacted repo)

```text
device-management-service/            # Java / Spring — orchestration + persistence + APIs
├── src/main/java/.../controller/     # + BulkJobController (submit/status/cancel/detail)
├── src/main/java/.../service/        # + BulkJobService, BulkJobBatchAdvancer (uses CommandService)
├── src/main/java/.../scheduler/      # + BulkJobBatchPoller (@Scheduled, mirrors NggCommandStatusPoller)
├── src/main/java/.../postgres/entity # + BulkJobEntity, BulkJobBatchEntity (join dat_sent_command_devices)
├── src/main/resources/db/migration/  # + Vnn__bulk_job.sql (forward-only)
└── src/test/java/...                 # unit + @integration + idempotency tests

dms-web-app/                          # Angular — reuse-first UI
├── src/app/pages/commands/           # extend command-history + details (bulk entries, live progress)
├── src/app/pages/firmware/           # extend firmware-history symmetrically
├── src/app/shared/px-notification-bell/  # extend to bulk-job completion notifications
└── (reuse) px-table, popups, spinner, Material progress/expansion

dms-infrastructure/                   # CDK — minimal (config-only if possible)
└── lib/data-stack.ts                 # queue capacity / DLQ / visibility tuning IF required (research R3)
```

**Structure Decision**: Multi-repo web feature. The backend owns all orchestration and state (DMS
constitution I: business logic in services; infra I: no app logic in IaC). The frontend is reuse-first.
Infra is minimal and may resolve to config-only.

## Integration & Side Effects

- **Downstream consumers / callers**: The unified path **wraps** the existing `CommandService.sendCommand()`
  and firmware `createFirmwareUpdateDetail()` flows. Per R12/R13 the **existing** `/commands/send` and
  `/v1/firmwareupdate` endpoints are the entry for all sizes (now persisting a `PENDING` `bulk_job` and
  returning a reference) — **no new submit endpoint**, no client-side branching. The command/firmware
  **history read** becomes job-aware (group by `bulk_job`); a job-level **cancel** is the only genuinely
  new endpoint. Existing single/small submissions keep their immediate-dispatch behavior (SC-008).
- **Data & schema**: New forward-only Flyway migration adds `bulk_job` and `bulk_job_batch` tables in
  `dms` schema; per-device outcomes **reuse** `dat_sent_command_devices` (link via a new nullable
  `bulk_job_batch_key`). Migration applies before the new service code starts. No cross-repo schema
  coupling. See data-model.md.
- **Events / message contracts**: No change to the existing MT-command / FOTA / command-status SQS
  message shapes — the batch advancer dispatches through the same producer path, so device ACKs flow
  back through the existing `mt-message-status` / `fota-status` listeners unchanged. OTEL `traceparent`
  must be carried on the batch-dispatched messages (constitution VI).
- **Caches / feature flags / config**: New configurable keys (per-type batch size default 2000,
  completion threshold, per-batch max-wait, job ceiling default 10,000, progress-poll interval) —
  adjustable without redeploy (FR-003/FR-007). Added to all environment property sets. The Redis
  status cache is reused as-is.
- **Observability & ops**: New job/batch lifecycle logs (ECS-JSON, `trace.id`, **no PII**), metrics for
  jobs in-flight / batch-advance latency / timed-out devices; an alert candidate for jobs stuck near
  max-wait. The batch poller must emit spans (`@WithSpan`) correlating to dispatched-command spans.
- **Docs to propagate**: DMS API docs (springdoc) for the new endpoints; dms-web-app help text for the
  bulk-job progress/cancel UI; quickstart.md here; the spec's Cross-Repo table at ship time.

## Complexity Tracking

*No Constitution Check violations — table intentionally empty.*
