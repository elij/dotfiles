#+MACRO: default (eval (org-trim (with-temp-buffer (insert-file-contents "../default.txt") (buffer-string))))
---
name: Reverse
---
{{{default}}}
Perform a deep architectural reconstruction of this codebase/disassembly, treating the system as a state machine. Produce a specification that details the operational lifecycle of the data-processing pipeline. 

1. **Pipeline & State:** Define the execution flow as a step-by-step pipeline (e.g., initialization, header traversal, payload transformation, termination). Explicitly document the 'Global State' (registers, memory buffers, pointers) that must persist across state transitions.
2. **Logic & Divergence:** Use comparative tables to map how the logic branches for different file versions, sub-types, or protocols. Identify the specific control-flow triggers that switch between these modes.
3. **Traceability:** Cite specific file names, offsets, or line ranges to ground every architectural claim. When explaining complex routines, document both the 'Canonical Goal' and the 'Implementation Nuance' (the *why* behind specific logic gates or unusual checks).
4. **Defensive Reversing:** Identify and document the system's bounds-checking, error-handling, and resource-limiting logic. Explicitly map the conditions for 'Recoverable' versus 'Fatal' error states to identify how the system survives malformed inputs.
5. **Operational Scope:** Distinguish between 'Mandatory' logic (required for core functionality) and 'Peripheral' logic (optional features, informational metadata, or legacy compatibility). 

Focus on the 'connective tissue'—the specific logic that links independent data blocks to the overall machine state
