# Agentic Coding Workflows & Best Practices: 2025-2026 Research Report

**Research Date**: May 2026  
**Cutoff Knowledge**: February 2025  
**Primary Sources**: Martin Fowler / ThoughtWorks, Kent Beck, Simon Willison, Anthropic, Academic Research

---

## Executive Summary

The agentic coding landscape has crystallized around a **core loop paradigm** that emphasizes:
1. **Structured verification** (tests, specs, scripts) as force multipliers
2. **Context-efficient state management** to overcome token economics
3. **Multi-phase workflows** separating exploration from implementation
4. **Human-in-the-loop at strategic gates** rather than continuous oversight

This document synthesizes insights from industry leaders and academic research to provide actionable patterns for production agentic systems.

---

## 1. CORE WORKFLOWS: The 4-Phase Model

### 1.1 The "Explore-Plan-Implement-Commit" Pattern (Anthropic/Claude Code)

**Phase 1: Explore (Plan Mode)**
- Agent reads codebase without making changes
- Questions and context gathering dominate
- Goal: Build understanding of existing patterns and constraints

**Phase 2: Plan**
- Agent generates detailed implementation plan
- Identifies which files must change and what the flow is
- Output written to text editor for human refinement before proceeding
- This **gate prevents solving the wrong problem**

**Phase 3: Implement**
- Agent exits plan mode and codes against the refined plan
- Tests run automatically as part of implementation
- Agent verifies work against success criteria
- Failures trigger self-correction

**Phase 4: Commit**
- Agent creates git commit with descriptive message
- Opens PR for human review
- Clear handoff to review process

**Key Insight**: Plan mode adds overhead but is **critical for multi-file changes** or uncertain approaches. Skip it only for small, well-scoped tasks.

---

### 1.2 Spec-Driven Development (ThoughtWorks, 2025)

**What It Is**: A development paradigm where **well-crafted specifications serve as the primary artifact**, not secondary documentation.

**Formula**: `Specifications → Planning → Implementation → Validation`

**Three Levels of Implementation Maturity**:
1. **Spec-First**: Specification guides initial development; code becomes primary
2. **Spec-Anchored**: Specifications evolve with code; tests enforce alignment
3. **Spec-as-Source**: Specifications are the only human-edited artifact; code is entirely generated

**Differs from TDD Because**:
- TDD operates at **unit level** (test-driven design)
- SDD operates at **system level** (behavior-driven architecture)
- TDD emphasizes incremental refinement; SDD emphasizes upfront clarity
- With AI: specs provide "super-prompts" that eliminate ambiguity, reducing AI guess-work by ~50% (measured via error reduction)

**Workflow**:
```
1. Write detailed behavioral specifications (Markdown)
2. Include acceptance criteria and constraints
3. Human review and iteration on specs
4. Finalize specs as canonical requirements
5. Agent receives specs and implements to specification
6. Automated tests validate against spec
```

**Token Efficiency**: Detailed upfront specifications eliminate multiple agent attempts to "figure out" requirements.

---

### 1.3 Red/Green TDD with Agents (Simon Willison, Kent Beck)

**What It Is**: Test-first development adapted for agentic code generation.

**The Loop**:
1. **Red**: Write a failing test
2. **Green**: Agent implements code to pass the test
3. **Refactor**: (Optional) Agent improves code quality

**Why It Works with Agents**:
- Tests provide **unambiguous success criteria** (the most high-leverage thing you can provide)
- Agent can verify its own work and self-correct
- No need for human to manually inspect code
- Prevents "vibe coding" (plausible but broken implementations)

**Key Quote (Kent Beck)**: "Canon TDD" is: list test scenarios → write one concrete runnable test → code to pass → refactor. If you're critiquing TDD, you must critique this specific workflow, not a strawman.

**Psychological Shift**: The agent becomes an "unpredictable genie" that grants wishes in unexpected ways. TDD keeps it honest.

---

### 1.4 Multi-Agent State Management (Anthropic Long-Running Agents)

For tasks spanning multiple context windows:

**The Two-Agent System**:

**Initializer Agent (First Run)**:
- Sets up `init.sh` script
- Creates `claude-progress.txt` (human-readable work log)
- Initial git commit with baseline
- Generates feature list (JSON, 200+ items for complex apps)

**Coding Agent (All Subsequent Runs)**:
- Reads progress file and git history to understand state
- Works on **one feature at a time** to avoid context exhaustion
- Commits changes frequently
- Updates progress documentation

**State Artifacts**:
- Git history = snapshots of working code
- Progress file = human-readable summary (not parsed by agent)
- Feature list = structured requirements (agent only updates completion flags, never deletes)

**Why This Works**:
- Clear handoffs between sessions
- No need to re-read entire codebase
- Human can track what was done
- Deterministic initialization ritual (read working dir → read progress → read git log)

---

## 2. VERIFICATION & SELF-CORRECTION: The Critique Loop

### 2.1 Naive vs. Adaptive Critique

**Naive Self-Critique** (❌ Anti-pattern):
- Agent generates code
- Agent reviews its own output with generic quality checks
- Flawed critique can reinforce errors

**Adaptive Critique Refinement** (✅ Pattern):
- Agent generates code
- **Specific error analysis**: identify particular classes of bugs
- **Targeted feedback**: corrections address identified problems, not blanket rules
- **Iterative refinement**: each round builds on previous insights
- Prevents reinforcement of flawed patterns

**Result**: 2-3 iterations typically produce passing output.

---

### 2.2 Concrete Verification Mechanisms

**Highest-Leverage Verification**:
1. **Tests** (automated, runnable)
   - Unit tests for logic
   - Integration tests for features
   - Agent can detect and fix failures immediately
   - Prevents the "looks right" trap

2. **Screenshots/Visual Verification** (for UI)
   - Agent takes screenshots
   - Compares to expected design
   - Lists differences and fixes them
   - Claude in Chrome extension opens new tabs and iterates

3. **Linting & Type Checking**
   - Run immediately after code edits
   - Agent fixes violations
   - Continuous feedback loop

4. **End-to-End Test Suites**
   - Claude performs better when explicitly prompted to use browser automation
   - Tests UI as a human would
   - Catches integration issues

**Anti-Pattern**: "The build is failing" without providing error messages.  
**Pattern**: "The build fails with [error]. Fix it and verify the build succeeds. Address the root cause, don't suppress the error."

---

### 2.3 ReAct Loop (Reasoning + Action)

**Architecture**:
```
Agent State → [Reason] → Action Plan → [Execute] → Observe → Evaluate → Loop
```

**Concrete Example**:
1. Agent reasons: "This test is failing because the async promise isn't being awaited"
2. Agent modifies file: adds `await`
3. Executes: runs test suite
4. Observes: test now passes
5. Evaluates: success criteria met
6. Loop: move to next failing test

**Self-Correction Capability**: Separates 2026 agents from 2024 chatbots. The agent reads failures and tries different approaches.

---

## 3. TOKEN EFFICIENCY & CONTEXT MANAGEMENT

### 3.1 The Token Economics Crisis

**Baseline**: Agentic coding sessions average **1-3.5M tokens per task** including retries and self-correction.

**The Problem**: By turn 30 of a session, the agent carries **25,000-35,000 input tokens** of accumulated context on every request, degrading performance.

**Cost Implications**:
- Production agents typically consume **100:1 input-output ratio**
- A 15-turn customer service conversation costs $0.07
- Scales to $255,000 annually for 10,000 daily conversations
- With optimization: reduces to ~$102,000 (40% savings)

---

### 3.2 Context Engineering Framework (Production Optimization)

**Core Insight**: "Context management represents the most significant operational cost factor in production agent systems." Performance degrades from 98.1% to 64.1% accuracy based solely on how information is structured.

**Token Allocation Budget** (per session):
- System instructions: 10-15%
- Tools/MCP schemas: 15-20%
- Knowledge/documentation: 30-40%
- Conversation history: 20-30%
- Buffer reserve: 10-15%

**Lifecycle Management Strategies**:

1. **Initialization**: Structured startup with clear token accounting
2. **Incremental Summarization**: Compress older turns as context fills
3. **Reference-Based Storage**: Don't repeat large outputs; reference them
4. **Automatic Compaction**: Trigger when utilization exceeds 70% threshold

---

### 3.3 Concrete Token Reduction Tactics

#### GitHub's Production Results (62% reduction across workflows):

1. **Remove Unused MCP Tools**
   - Unused tool schemas = 10-15 KB each
   - Removing unused tools saved 8-12 KB per API call
   - Cumulative: thousands of tokens per run

2. **Replace GitHub MCP with CLI**
   - Move data-fetching outside the LLM loop
   - **Pre-agentic downloads**: Run `gh api` commands before agent starts
   - Write results to files agent reads
   - **Principle**: "The cheapest LLM call is the one you don't make"

3. **CLI Proxy Substitution**
   - Route agent CLI requests directly to API
   - Skip LLM reasoning for deterministic operations

4. **Observability & Auditing**
   - Log token usage through API proxy
   - Flag unusual consumption patterns
   - Recommend optimizations per workflow

**Measured Savings**:
- Auto-Triage Issues: 62% reduction
- Security Guard: 43% reduction
- Smoke Test: 59% reduction

#### Structured Output Formats:

- Native Markdown vs. raw HTML: **67% token savings**
- Semantic locators vs. full DOM trees: **93% savings**
- Caching static components: **10x cost reduction** on cached tokens

#### Prompt Caching (Multi-Provider):

- Anthropic, OpenAI, Bedrock all support prompt caching
- Cached input charged at 10-25% of normal input cost
- Static system instructions achieve **95%+ cache hit rates**
- Semi-static user data: 60-80% hit rates
- Result: 60-80% reduction in operational costs

---

## 4. COMPARISON: The 4-Phase Model vs. CLAUDE.md Pattern

### Your Current Pattern (tonys-nix CLAUDE.md):
```
Phase 1: RESEARCH (현황 파악 및 도구 탐색)
Phase 2: STRATEGY (전략 수립 & 컨펌)
Phase 3: EXECUTION (구현 및 검증)
Phase 4: REPORT & EXIT (세션 종료 및 핸드오버)
```

### Industry Standard (2025-2026):
```
Explore → Plan → Implement → Commit
```

### Key Alignment & Differences:

| Your Model | Industry Standard | Mapping |
|-----------|------------------|---------|
| RESEARCH (Zero-Inference) | Explore (Plan Mode) | ✓ Same: read-only analysis |
| STRATEGY (Peer Review) | Plan | ✓ Similar: design review gate |
| EXECUTION | Implement | ✓ Same: code generation & test |
| REPORT & EXIT | Commit | ✓ Similar: handoff documentation |

**Key Insight**: Your 4-phase model is **aligned with industry best practices**. The main difference is:
- Industry calls it "Explore-Plan-Implement-Commit"
- You call it "Research-Strategy-Execution-Report"
- Functionally they're nearly identical
- Your pattern is **more rigorous** with explicit peer review gates

---

## 5. THOUGHT LEADER SYNTHESIS

### 5.1 Martin Fowler / ThoughtWorks

**Core Position**: TDD is the strongest form of prompt engineering for AI.

**Key Insights**:
- TDD teams release **32% more frequently** (2024 survey)
- Three experiments: vibe coding produces unmaintainable software
- Structured guidance (TDD + conversation) significantly improves quality
- **"TDD keeps it honest"**: when directing thousands of lines of code generation, tests act as forcing function

**AI-Aided Test-First Development**: 
- Generate tests with ChatGPT/Claude
- Developers implement functionality
- Prevents exposing sensitive implementation code to external models

**Emerging Practice**: Spec-Driven Development (SDD) as natural evolution combining TDD + specification clarity.

---

### 5.2 Kent Beck

**Core Position**: AI agents are "unpredictable genies" that grant wishes in unexpected ways.

**Key Insights**:
- He's **re-energized** by AI agents because he doesn't need to know all details upfront
- Can be more ambitious: let agent explore
- **Canon TDD** is the strawman target: test list → concrete test → code → refactor
- TDD is even more relevant now: provides clear exit criteria for agents

**Philosophical Shift**: From "I know exactly what to build" → "I have clear success criteria; agent figures out path"

---

### 5.3 Simon Willison

**Core Position**: "Writing code is cheap now." Engineers must rethink workflows.

**Key Patterns** (Daily Use):
1. **Red/Green TDD**: Test-first development to minimize prompting
2. **Templates**: Reusable code structures to reduce token spent on common patterns
3. **Hoarding**: Collecting working examples and patterns locally for reuse

**Definition of Agentic Engineering**: Building software with tools that can both **generate AND execute code**, creating feedback loops. Distinct from "vibe coding"—applies to professional engineers amplifying expertise.

**November 2025 Inflection Point**: AI coding agents crossed from "mostly works" to "actually works" (production-grade).

---

### 5.4 Anthropic (Claude Code)

**Core Architecture**: 98.4% is deterministic infrastructure; only 1.6% is AI decision logic.

**Best Practice Framework**:

1. **Give Claude Verification Criteria**
   - Include tests, screenshots, expected outputs
   - "Single highest-leverage thing you can do"

2. **CLAUDE.md as Persistent Context**
   - Project-level conventions (code style, workflow rules)
   - Keep concise: if Claude can infer from code, delete it
   - Git-checked-in for team access

3. **Context Window Management**
   - Most critical resource is context space
   - Use `/clear` between unrelated tasks
   - Automatic compaction at 70% threshold
   - Rewind checkpoints for course-correction

4. **Subagents for Investigation**
   - Delegate research to separate context
   - Keeps main conversation clean for implementation
   - Reports back summaries

5. **Multi-Session Patterns**
   - Worktrees for parallel isolated sessions
   - Writer/Reviewer pattern for quality focus
   - Agent teams for coordinated multi-session work

---

## 6. SELF-CRITIQUE & ITERATIVE REFINEMENT: Academic Findings

### 6.1 SEW (Self-Evolving Workflows)

**Pattern**: Automatically design and optimize agentic workflows through self-evolution.

**Results**: Up to 12% improvement on LiveCodeBench compared to backbone LLM alone.

**Process**:
- Decompose complex task into sub-tasks
- Assign to specialized agents
- Refine assignments iteratively
- Optimize both topology and prompts

**Insight**: Move from hand-crafted workflows to automatically-optimized ones.

---

### 6.2 Adaptive Critique Refinement (RefineCoder)

**Innovation**: Instead of generic self-review, provide problem-specific feedback.

**Process**:
1. Agent generates code
2. Identify specific error classes (logic bugs, type errors, boundary conditions)
3. Target feedback on those specific issues
4. Iterate with context from previous failures

**vs. Naive Critique**:
- Naive: "Review this for quality issues"
- Adaptive: "This failed on edge case X; here's why; fix that specific issue"

---

### 6.3 Chain-of-Thought for Code Reasoning (Jason Wei)

**Finding**: Generating intermediate reasoning steps significantly improves code generation.

**Mechanism**:
- Agent articulates *why* it's making a change before implementing
- Forces step-by-step logic
- Enables verification of reasoning before code

**Application to Agentic Code**:
- "Agentic code reasoning" = agent's ability to navigate files, trace dependencies, gather context iteratively
- Enables deep semantic analysis without execution

---

## 7. EMERGING CONSENSUS & KEY PATTERNS

### 7.1 The Verification-First Imperative

**Consensus**: Provide verification mechanisms before agent starts coding.

**Concrete Checklist**:
- [ ] Tests exist or are specified
- [ ] Success criteria are measurable
- [ ] Expected output is clear (screenshot, file contents, test results)
- [ ] Agent can run verification command directly

**Result**: Dramatically better code quality, fewer corrections needed.

---

### 7.2 Explore-Then-Plan Separation

**Consensus**: Don't let agent jump straight to coding.

**Pattern**:
1. Read codebase (plan mode)
2. Generate implementation plan
3. Human refines plan
4. Agent codes against plan

**Exception**: Small, well-scoped changes (typo fixes, variable renames) can skip planning.

---

### 7.3 State Management Across Context Windows

**Consensus**: Structure state as git history + progress artifacts, not conversation history.

**Pattern**:
- Git commits = snapshots of working code
- Progress file = human-readable summary
- Feature list = structured requirements

**Why**: Enables agents to work effectively across multiple sessions without context explosion.

---

### 7.4 Context Engineering as Core Discipline

**Consensus**: Token efficiency is not an optimization detail—it's a primary design constraint.

**Investment Areas**:
- Structured output formats (save 67%)
- Strategic caching (save 10x on static content)
- Pre-agentic CLI operations (skip LLM calls entirely)
- Observability and auditing

**ROI**: 60-80% cost reduction possible through engineering alone.

---

## 8. COMPARATIVE ANALYSIS: Traditional vs. Agentic TDD

### Traditional TDD (Human-Written Code)
```
Red (write test) → Green (write code) → Refactor
```

### AI-Augmented TDD (with Agent)
```
Red (write test) → Green (agent writes code) → Refactor (agent improves) → Verify (human checks)
```

### Key Differences:

| Aspect | Traditional | AI-Augmented |
|--------|------------|-------------|
| **Who writes test?** | Developer | Developer (or AI with spec) |
| **Who writes code?** | Developer | Agent |
| **Feedback loop** | Manual implementation | Automated test + self-correction |
| **Iteration time** | Seconds per cycle | Milliseconds per cycle |
| **Leverage** | 1x human effort | 5-10x human time (with verification) |
| **Risk** | Misunderstanding logic | Agent misinterprets requirements |
| **Mitigation** | Code review | Tests + verification criteria |

---

## 9. SUMMARY TABLE: Workflow Recommendations by Scenario

| Scenario | Recommended Pattern | Key Tool |
|----------|-------------------|----------|
| **New feature, large scope** | Spec-Driven Dev | Specifications |
| **Bug fix, small scope** | Red/Green TDD | Tests |
| **API integration** | Plan mode → Implement | Plan gate |
| **Refactoring** | Red/Green TDD | Tests |
| **Complex logic** | Chain-of-thought | Reasoning prompts |
| **Long-running task** | Multi-agent + state artifacts | Progress file + git |
| **UI work** | Screenshots + visual verification | Claude in Chrome |
| **Cost-sensitive** | Context engineering | Caching + CLI proxy |

---

## 10. RECOMMENDED ACTION ITEMS FOR YOUR PROJECT

### For tonys-nix (Multi-Provider Agent Architecture):

1. **Alignment Check** (No Change Needed)
   - Your 4-phase model (Research-Strategy-Execution-Report) is already aligned with industry best practices
   - Consider renaming for clarity: RESEARCH → EXPLORE, STRATEGY → PLAN
   - Continue requiring peer review gates before execution

2. **Token Efficiency**
   - Implement context lifecycle management (summarization at 70% threshold)
   - Add observability logging for Gemini/Codex calls to track token usage
   - Consider structured output formats for Gemini responses

3. **Verification First**
   - In EXECUTION phase: always define success criteria before starting
   - Leverage nix flake check, helm lint, test suites as verification oracles

4. **State Management for Subagents**
   - If implementing subagent patterns: structure handoffs via progress files + git
   - Avoid relying on conversation history alone

---

## 11. CONFIDENCE ASSESSMENT

| Finding | Confidence | Source |
|---------|-----------|--------|
| Explore-Plan-Implement-Commit is consensus pattern | **High** | Anthropic, ThoughtWorks, Simon Willison |
| TDD/Verification-first improves output quality | **High** | Kent Beck, Martin Fowler, multiple studies |
| Spec-Driven Development reduces iterations | **High** | ThoughtWorks research, academic studies |
| Token efficiency is critical production concern | **High** | GitHub, Anthropic, multiple case studies |
| Context engineering achieves 60-80% cost reduction | **Medium-High** | Context Engineering article, industry reports |
| Adaptive critique beats naive self-critique | **Medium** | RefineCoder paper, limited field data |
| Multi-agent state artifacts scale better than history | **Medium-High** | Anthropic research, limited production data |

---

## Sources

- [Martin Fowler: January 2026](https://martinfowler.com/fragments/2026-01-08.html)
- [Martin Fowler: February 2026](https://martinfowler.com/fragments/2026-02-18.html)
- [ThoughtWorks Future of Software Development 2026](https://www.metasticworld.com/en/insights/thoughtworks-future-of-software-development-retreat-2026-insights)
- [Kent Beck on AI Agents and TDD](https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent-beck)
- [Simon Willison: Agentic Engineering Patterns](https://simonwillison.net/2026/Feb/23/agentic-engineering-patterns/)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [ThoughtWorks: Spec-Driven Development](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
- [SEW: Self-Evolving Agentic Workflows](https://arxiv.org/abs/2505.18646)
- [RefineCoder: Adaptive Critique Refinement](https://arxiv.org/pdf/2502.09183)
- [GitHub: Improving Token Efficiency in Agentic Workflows](https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/)
- [Context Engineering for Production Agents](https://www.getmaxim.ai/articles/context-engineering-for-ai-agents-production-optimization-strategies/)
- [Tokenomics: Quantifying Where Tokens Are Used in Agentic Software Engineering](https://arxiv.org/html/2601.14470v1)
- [Agentic Verification of Software Systems](https://arxiv.org/html/2511.17330v3)
- [2026 Agentic Coding Trends Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)

