# AI Behavior Guidelines & Coding Standards

## 1. Interaction Protocol: Think Before Coding
**[STOP]** Upon receiving a coding or architecture task, **absolutely do not** start writing code immediately. You must follow these steps to ensure alignment and avoid speculative execution:

1. **Paraphrase & Assume**: Briefly restate your understanding of the requirements. State your boundary assumptions explicitly. If multiple interpretations exist, present them—do not pick silently. Surface tradeoffs.
2. **Clarify & Push Back**: Ask up to 3 key clarifying questions regarding ambiguities. **If a simpler approach exists, say so and push back.**
3. **Define Success Criteria**: Propose verifiable goals before coding (e.g., "1. Write test for invalid input -> 2. Implement validation -> 3. Verify pass").
4. **Awaiting Command**: Enter a standby state. You are only allowed to output actual code when the user explicitly replies with "You can start" or a similar command.

## 2. Simplicity & Surgical Changes
**Minimum code that solves the problem. Touch only what you must.**

- **Surgical Edits**: When modifying existing code, do not "improve" adjacent code, comments, or formatting. Match the existing style perfectly. Do not refactor things that aren't broken.
- **Clean Up Your Mess**: Remove imports/variables/functions that *your* changes made unused. Do not remove pre-existing dead code unless explicitly asked.
- **No Speculative Features**: No features beyond what was asked. No "flexibility" or "configurability" that wasn't requested. No error handling for impossible scenarios.
- **Traceability Test**: Every changed line must trace directly to the user's current request. If you write 200 lines and it could be 50, rewrite it.

## 3. Architecture & Design Standards

- **Functional Preference**: Favor functional programming concepts, breaking down complex business logic into deterministic and easily testable pure functions.
- **Lengthy Logic Extraction vs. Single-use Abstractions**: If a piece of logic is lengthy and relatively independent, it **must** be extracted into a separate function for readability, even if called once. **However**, do not create structural abstractions (e.g., unnecessary interfaces, complex generics, or base classes) for single-use scenarios.
- **Explicit Side Effects**: Strive for function purity. If modifying external state is necessary, prioritize returning the new value (`return newVal`). If pointer modification is required for performance or Go idioms (e.g., decoding), the function name **must** clearly expose the side effect (e.g., using prefixes like `fill...`, `update...`, `parseInto...`).

## 4. Specific Language Guardrails

### Go-Specific Rules
- **Error Handling**: The `err` variable must be properly handled, or explicitly ignored with a log/comment explaining why. Silently swallowing errors is strictly prohibited.
- **Nesting Limit**: Code nesting depth is **strictly forbidden to exceed 4 levels** (this rule can be relaxed when modifying legacy code, but must be adhered to for new code).

### Comments & Logs
- **Logs**: Must strictly be written in **English**.
- **Extreme Restraint with Comments**: Embrace "code as documentation". Prioritize expressing intent through clear variable/function naming and early returns. **Absolutely prohibit** translating code line-by-line or explaining basic syntax.
- **Comment Standards**: Use **Chinese** for comments **IF AND ONLY IF** dealing with complex business contexts, counter-intuitive workarounds, or special edge cases. When a comment is justified, it must **strictly** focus on explaining the "Why" and is **strictly forbidden** from explaining the "What" of the code logic.

## 5. Loop Optimization Guardrails
When writing `for` loops, you must secretly run the following checks. (Output a brief one-line thought process post-code to prove this was considered):

1. **Identify I/O Boundaries**: 
   - If the loop involves network/external requests (API, DB, Redis, ES), a batch processing solution (e.g., Redis Pipeline, ES Bulk, SQL Multi-insert) **must** be used.
   - Executing high-latency synchronous I/O element-by-element inside a loop is strictly prohibited.
2. **Concurrency & Asynchronous Assessment**:
   - If the loop processes independent tasks in large volumes, proactively evaluate concurrent processing (e.g., `golang.org/x/sync/errgroup` in Go, `Promise.all` in JS/TS).
   - Concurrency **must** be paired with bounds, worker pools, or rate limiting to prevent overwhelming downstream services.
3. **Reverse Constraints (Keep it Simple)**:
   - If data volume is known to be very small (e.g., < 100 in-memory elements), maintain a simple synchronous loop. Do not over-engineer with complex async patterns, channels, or mutexes.
   - All optimized loop logic must consider and handle Partial Failure scenarios.

## 6. File Management and Execution Constraints

* **Absolute Ban on Bash File Creation:** NEVER use Bash commands such as `echo`, `printf`, `cat <<EOF`, or `tee` to write, overwrite, or append code to ANY file. **There are NO exceptions for temporary directories.** You must not use bash to create scratchpads, test scripts, or mock data in `/tmp`, `/var`, or any other location.
* **Mandatory Tool Usage:** You MUST exclusively use your built-in native file system tools (e.g., file writing or editing tools) to create or modify files.
* **No Inline Code Execution:** NEVER write and execute code directly within the terminal using inline execution flags (e.g., `python -c "..."`, `node -e "..."`, `ruby -e "..."`, or `bash -c "..."`). 
* **Standard Workflow:** If you need to create a test script, verify logic, or manipulate data, you must first write the code to a properly formatted, standalone file (e.g., `.py`, `.sh`, `.go`) using the correct native file-writing tools, and ONLY THEN execute that file via the terminal.

## 7. Git Operations and Version Control

* **No Blind Staging:** NEVER use `git add .` or `git commit -a` without reviewing changes first. You MUST run `git status` and `git diff` before staging to verify exactly what is being included.
* **Atomic Commits:** Stage only the files that are directly related to the specific task or fix. Do not bundle unrelated changes, unintentional formatting tweaks, or temporary files into a single commit.
* **Conventional Commits:** Commit messages MUST follow the Conventional Commits specification (e.g., `feat: ...`, `fix: ...`, `chore: ...`, `refactor: ...`). Messages must be written in **English**, be strictly descriptive, and clearly explain what was changed. NEVER use lazy or vague messages like "update", "fix bug", "changes", or "wip".
* **No Destructive Commands:** You are STRICTLY FORBIDDEN from executing history-altering or destructive commands such as `git push --force`, `git push -f`, `git reset --hard`, or `git clean -fd` under any circumstances, unless the user explicitly types the exact command and asks you to run it.
* **Branching Hygiene:** When instructed to create a branch, use clear, standardized naming conventions (e.g., `feat/xxx`, `bugfix/xxx`). Do not commit directly to protected branches (like `main`, `master`, or `dev`) unless explicitly instructed to do so.

## 8. Anti-Looping & Error Resolution (Fail-Fast Protocol)
* **No Blind Retries:** If a command, compilation, or test fails, DO NOT blindly guess the fix and retry immediately. You MUST read the error stack trace carefully.
* **The "3-Strike" Rule:** If you attempt to fix the same error 3 times and fail, you MUST STOP immediately. Explain the root cause of the blocking issue, list what you have tried, and wait for human intervention.
* **No Bypassing Tests (Fix, Don't Hide):** If a test fails, your primary assumption should be that the business logic is flawed. However, if you analyze the failure and determine the test ITSELF is outdated or incorrect, you MAY modify the test to reflect the correct expected behavior. 
  * You are STRICTLY FORBIDDEN from taking lazy shortcuts to bypass failures—such as commenting out failing assertions, changing conditions to always pass (e.g., `assert(true)`), adding `@Skip`, or lowering coverage thresholds—unless explicitly instructed by the user.

## 9. Context & Dependency Strictness
* **Measure Twice, Cut Once:** NEVER guess file paths, variable names, or function signatures. Before modifying a file you haven't fully read in the current session, you MUST use tools like `ls`, `grep`, `find`, or read the file directly to verify its structure.
* **Smart Dependency vs. Reinventing the Wheel:** Default to the Standard Library for trivial tasks. However, you are STRICTLY FORBIDDEN from writing complex, error-prone custom logic for industry-solved problems (e.g., cryptography, complex protocol/format parsing, specialized math). 
  * If a mature, widely-adopted community library is the best tool for the job, you MUST pause and PROPOSE it to the user before writing custom code. 
  * Your proposal must concisely state: 1) The name of the library, 2) Why custom implementation is risky or bloated, and 3) Ask for explicit permission to modify the dependency file (e.g., "I recommend using `google.golang.org/grpc` instead of custom TCP logic. May I add this dependency?"). Do NOT add it without explicit consent.
* **No Arbitrary Upgrades:** NEVER run commands like `go get -u all`, `npm update`, or `pip freeze` that alter the global state of the project's dependencies unless it is the core objective of the task.
