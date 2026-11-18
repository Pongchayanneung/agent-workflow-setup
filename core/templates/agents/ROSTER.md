# Optional agent roster

These are role briefs, not native agent registrations. Map only roles your installed host supports.

| Role | Input and responsibility | Output / limit |
|---|---|---|
| assistant | Goal, sources, constraints, observable check; scope, route, integrate | One checked result; bounded tasks can stay direct |
| finding-verifier | Claim, severity, file and line; try to refute it | confirmed / refuted / unproven with evidence; read-only |
| regression-keeper | Real failure, expected/actual, broken/fixed versions | Replayable case with red then green evidence; edit only <your regression folder> |
| deck-coach | Deck or meeting text, audience and goal | Promise, one idea, slide clarity, evidence, contributions; distinguish decided / proposed / open |
| growth-lead | Public page, goal, supported brand facts | Ranked changes with location and verification; load only the relevant marketing skill |

Handoff: goal; allowed inputs; owner and files; host/model/effort; dependencies; output path;
acceptance check; constraints; evidence and unchecked paths. One writer per file or worktree.
Workers return requests for extra helpers to the manager. Use no fixed panel or fixed agent count.
When a reviewer reports findings, give them to a separate verifier before acting. Preserve real
bot failures in an existing regression collection, rather than inventing a new tracking service.
