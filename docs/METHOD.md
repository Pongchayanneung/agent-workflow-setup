# Working method and optional modules

The shared rules template is policy. Native permissions, tool availability and approval settings
remain the host's responsibility. Reading a rule does not establish that a hook ran.

## Route and verify

Start with the user's outcome and an observable check. Search `cap <your search terms>` and the
memory index before adding a tool. Reuse existing code, stdlib and native platform features.
Keep routine work direct. Delegate for a distinct capability, independent review or substantial
bounded unit. Pass the brief described in [the roster](../core/templates/agents/ROSTER.md).
Use the active primary model; choose helper model and effort for the task and record the choice.
Do not route one vendor's credentials through another tool.

Review changed code and add security review when security changes. Ask a separate verifier to
try to refute findings. Run the smallest meaningful check with real input. A new hook gets a
sample-payload dry run before wiring. Check public paths as the actual user when applicable.
For exact WIP recovery clone into a new directory; chain clone, fetch and reset with `&&` so a
failed earlier step cannot reset another working tree.

`core/bin/routelog` is an optional stdlib Python CLI, copied manually to `<your bin directory>`.
Run `python3 core/bin/routelog --selftest` first. Then use `routelog add --help` for required fields,
`routelog summary` for local counts, minutes and retries. Its default file is
`~/.agent-workflow/route-log.jsonl`; override with `ROUTELOG_PATH`. It does not measure billing.
The logger expects valid JSON on every nonblank line. A truncated or malformed line makes
summary fail visibly; preserve the file and repair it from evidence before retrying. It does
not silently skip damaged rows or repair logs.
No new scheduling, background observers or automatic promotion are part of this method.

## Confidentiality gate and wrappers

The optional design has four entry points: `agy-media` for media, `agy-bulk` for mechanical
batches, `agy-review` for independent critique and `agy-browse` for public browser work.
These names describe a pattern; this repository does not install these wrappers or a gate.
Use a reviewed local implementation for `<your installed CLI version>` and test it before use.
The only shipped deny list is the zero-byte [template](../core/templates/agy/deny.txt).
An empty list blocks no confidential roots. Populate a private copy before enabling delegation.

A gate must fail closed if its list is missing or unreadable. Expand home paths and canonicalise
both denied roots and input paths with the same API. Refuse a root and its descendants, including
symlinks and parent-directory escapes. Test safe, denied, mixed-batch, missing-list and symlink
cases with synthetic files. Refuse excessively broad shared directories. Check the entire exposed
folder, not only explicitly referenced files. Browser wrappers restrict destinations to public URLs.
Resolve helper locations through wrapper symlinks. Pass a narrow directory with `--add-dir` rather
than assuming the CLI inherits the shell's working directory. Verify these flags on your version.

Path gates cannot inspect confidential text pasted into prompts or stdin. The caller screens all
inline text before dispatch. Check destination account terms and allowed data independently.
Batch compatible public inputs into one call. Pipe small text on stdin rather than using file
references; measure local token and time results before claiming savings. Never loop one call per
file when one bounded batch suffices. Retain usage only when the runtime exposes it.

## Shared memory

Use one index and linked user, feedback, project and reference notes. Keep index entries short,
with a source/date and reason to open the note. Do not copy private memory into a public setup.
Search existing notes before writing; re-read the latest text before appending a dated correction.
Save reusable failures, decisions and lessons, not routine status visible in git. Fix the cause
in its owning script or skill; verify the formerly failing case and a nearby working case.
Installation, static review, runtime success and memory capture are separate claims.

Optional speech glossary format: `<your heard term> -> <your intended term> (<your context>,
<your date>, <your confirmed or inferred status>)`. Record repeated mistakes that change actions.
For an uncertain negation next to send/delete/deploy, state the reading and resolve it first.

## Optional grill module

Enable by adding the chosen level to your shared rules. Default level is a user choice.
Deep: before a new build or workflow change with multiple open decisions, look up facts first,
then ask numbered rounds until material decisions are settled. Each question has options and a
recommendation; wait for answers. End with one line recording what was settled.
Light: one round, at most three questions about hard-to-reverse choices; state the remaining
reversible assumptions. Off: ask only about material unknowns. Clear bounded edits and read-only
requests need no interview. Existing approval remains valid within scope.
The live-source design stores the level per session in a router helper. This repository ships
policy only, with no grill hook or session-state wiring. Do not infer persistence from this text.

## Optional close-out module

For multi-step or consequential work, report: the actual check and real input; what was corrected
and why; what was not checked; any reusable lesson. Skip for routine single-step tasks. A clean
pass needs no new memory rule. Record a real failure in the existing log or relevant note.

## Optional vault capture module

Use existing folders for inbox, projects, areas, resources, archive, daily notes, maps of content,
templates, attachments and system instructions. Read the vault's own rules before writing.
Do not add top-level folders, move notes or archive them without the owner's authorization.
Capture reusable tool evaluations, decisions and bugs only when the owner enables capture.
Search first; append dated updates to existing notes. Use the matching template with title,
type, status, created, updated, tags, related links and source provenance. Mark unknown fields
`<your missing value>`; do not invent facts. Match the owner's language.
Verify every note link exists, add a reverse link in an editable Connections block or map,
and keep generated query blocks untouched. If no target exists, list candidates for review.
Keep the reason in the vault and link to source code for implementation. Never copy secrets,
private client material or another person's data. Use a reversible local checkpoint that includes
only the intended note edits. Report the path. No vault contents or automatic sync ship here.
