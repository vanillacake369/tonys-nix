---
name: architectural-planning
description: Create detailed technical plans and implementation roadmaps by analyzing project architecture and designing solutions that integrate seamlessly with existing patterns
---

# Architectural Planning Methodology

This skill enables creating comprehensive technical plans for features and changes by discovering and following project architectural patterns.

**Leverages:** [codebase-analysis] skill for project discovery and pattern recognition.

## Planning Philosophy

### Integration Over Innovation
- Design solutions that fit naturally into existing architecture
- Respect established boundaries and responsibilities
- Follow discovered organizational patterns
- Use existing libraries and approaches

### Clarity and Actionability
- Create plans others can execute without clarification
- Break work into atomic, testable steps
- Identify dependencies and risks explicitly
- Provide clear success criteria

## Planning Workflow

### Phase 1: Architectural Discovery
Using [codebase-analysis] methodology:
1. Understand overall architecture (layered, microservices, modular, etc.)
2. Identify existing components and their responsibilities
3. Map dependencies and integration points
4. Learn architectural boundaries and conventions
5. Find similar features as reference examples

### Phase 1.5: Deep Reasoning (If Complex)

After architectural discovery, automatically evaluate if systematic thinking is needed using the MCP Decision Tree from @CLAUDE.md.

#### Complexity Assessment

**Evaluate the planning task**:
- Count viable architectural approaches (1, 2, 3+?)
- Identify trade-off dimensions (performance, cost, complexity, maintainability, scalability, etc.)
- Assess decision impact (low, medium, high, critical?)
- Determine path clarity (obvious, somewhat clear, unclear?)

**Decision**:
- 3+ approaches AND 5+ dimensions AND unclear path → **Use Sequential Thinking**
- Otherwise → **Proceed to Phase 2**

#### Sequential Thinking Activation

When complexity indicators are met, use Sequential Thinking MCP for systematic analysis:

**Process**:
```
1. Invoke mcp__sequential-thinking__sequentialthinking
2. Thought 1: Analyze current system constraints
3. Thought 2: Evaluate Option A (pros, cons, risks)
4. Thought 3: Evaluate Option B (pros, cons, risks)
5. Thought 4: Evaluate Option C (pros, cons, risks)
6. Thought 5: Compare options across all dimensions
7. Thought N: Synthesize final recommendation with evidence
8. nextThoughtNeeded: false → Proceed with recommendation
```

#### Examples

**Example 1: Complex Decision (Use Sequential Thinking)**
```
User: "Should we use microservices or monolith for this feature?"

Complexity Check:
✅ Approaches: 3 (microservices, monolith, modular monolith)
✅ Dimensions: 7 (scalability, complexity, cost, team size, deployment, monitoring, debugging)
✅ Impact: High (affects entire architecture)
✅ Clarity: Unclear (trade-offs not obvious)

Decision: Use Sequential Thinking

Sequential Process:
Thought 1: Current system handles 10k req/s, team of 3 developers
Thought 2: Microservices - Benefits: independent scaling, tech diversity
                         Drawbacks: complexity, distributed debugging, overhead
Thought 3: Monolith - Benefits: simplicity, easy debugging, lower ops cost
                      Drawbacks: scaling limitations, deployment coupling
Thought 4: Modular Monolith - Benefits: best of both, easier migration path
                               Drawbacks: requires discipline, eventual split needed
Thought 5: Compare across dimensions:
           - Team size (3 devs) → favors simpler approach
           - Current scale → monolith sufficient
           - Future growth → need migration path
Thought 6: Evidence-based conclusion:
           Start with modular monolith, designed for future microservices split
           Rationale: Balances current simplicity with future scalability

Result: Detailed implementation plan with modular monolith approach
```

**Example 2: Simple Decision (Skip Sequential Thinking)**
```
User: "Add a new Nix module for VSCode"

Complexity Check:
❌ Approaches: 1 (add to modules/apps.nix following existing pattern)
❌ Dimensions: 2 (package selection, configuration)
❌ Impact: Low (isolated addition)
✅ Clarity: Clear (pattern exists in apps.nix)

Decision: Skip Sequential Thinking, proceed to Phase 2

Reason: Straightforward addition following existing pattern from modules/apps.nix:15-20
```

**Example 3: Moderate Complexity (Borderline)**
```
User: "Refactor home.nix activation scripts for better maintainability"

Complexity Check:
⚠️ Approaches: 2-3 (keep inline, extract to functions, move to separate files)
⚠️ Dimensions: 4 (readability, maintainability, testability, performance)
❌ Impact: Medium (affects build process but not critical)
⚠️ Clarity: Somewhat clear (prefer extraction but details vary)

Decision: Skip Sequential Thinking (borderline, but not meeting all criteria)

Reason: While moderate complexity, optimal approach is fairly clear from Clean Code principles
        Trade-offs are straightforward: inline simplicity vs extracted reusability
        Can analyze directly without systematic thought chain
```

#### Memory Integration

After completing deep reasoning and making architectural decisions, consider using Memory MCP to record:
- **Decision rationale**: Why Option X was chosen over Option Y
- **Trade-offs considered**: What was sacrificed and why
- **Future implications**: When to revisit this decision
- **Constraints**: Factors that influenced the choice

**Example**:
```
After choosing modular monolith approach:

mcp__memory__create_entities([{
  name: "Architecture Decision - Modular Monolith",
  entityType: "Architectural Decision",
  observations: [
    "Chose modular monolith over microservices (2025-01-26)",
    "Reason: Team size (3 devs) favors simplicity",
    "Designed for future microservices migration when scale requires it",
    "Trade-off: Accept scaling limitations for reduced operational complexity"
  ]
}])

mcp__memory__create_relations([{
  from: "Architecture Decision - Modular Monolith",
  to: "Team Size Constraint",
  relationType: "influenced by"
}])
```

### Phase 2: Solution Design
Design within discovered constraints:
1. Identify which existing components are affected
2. Determine if new components are needed
3. Choose integration points that match existing patterns
4. Plan data flows following project conventions
5. Design APIs consistent with current style

### Phase 3: Implementation Planning
Create actionable steps:
1. Order tasks by dependency and logical progression
2. Specify exact files to modify or create
3. Reference existing code as implementation examples
4. Identify potential conflicts or breaking changes
5. Plan validation and testing approach

## Plan Structure Guidelines

### Essential Elements

**Context Section**:
- Discovered architecture pattern
- Technology stack
- Similar existing features
- Integration points

**Approach Section**:
- High-level solution
- Why it fits the architecture
- New vs existing components
- Pattern references

**Implementation Section**:
- Atomic, ordered steps
- File paths (create/modify)
- Code examples from codebase
- Rationale for each step

**Risk Section**:
- Dependencies (internal/external)
- Potential issues and mitigations
- Breaking changes and migrations
- Performance impact

**Validation Section**:
- Testing strategy
- Success criteria
- Manual verification steps

## Planning Best Practices

### Reference Real Examples
```
✅ "Following the UserService pattern in services/user.service.ts,
   OrderService will inject repositories via constructor and
   use the same error handling approach."

❌ "Create OrderService using dependency injection."
```

### Be Specific About Locations
```
✅ "Create auth/middleware/jwt-validator.ts following the
   pattern from auth/middleware/session-validator.ts"

❌ "Add JWT validation middleware"
```

### Quantify When Possible
```
✅ "Affects 3 API endpoints and 2 background jobs.
   Estimated: 2-3 hours implementation + 1 hour testing."

❌ "This will take some time to implement."
```

### Identify Patterns, Not Just Tasks
```
✅ "Implement using the Command pattern like existing
   payment/commands/ProcessPayment.java uses"

❌ "Implement the feature"
```

## Common Architectural Patterns

### Layered Architecture
```
Plan should respect layers:
- API/Presentation → UseCase/Application → Infrastructure → Domain
- Dependencies flow inward
- Each layer uses only the layer below
```

### Microservices
```
Plan should consider:
- Service boundaries
- Inter-service communication patterns
- Data consistency approaches
- Shared libraries vs duplication
```

### Hexagonal/Clean Architecture
```
Plan should:
- Keep business logic in core
- Adapt external dependencies at boundaries
- Use dependency inversion
- Preserve testability
```

### Event-Driven
```
Plan should:
- Identify events to publish/consume
- Follow existing event schemas
- Use project's message infrastructure
- Consider eventual consistency
```

## Anti-Patterns to Avoid

❌ **Generic Plans**:
- "Add authentication" without specifying how it integrates

✅ **Context-Specific Plans**:
- "Extend existing OAuth2 middleware in auth/oauth2.go to support
  refresh tokens, following the pattern from auth/session.go"

❌ **Technology Mismatch**:
- Recommending GraphQL when project uses REST

✅ **Technology Alignment**:
- "Add REST endpoint to api/v1/orders.ts following OpenAPI
  spec pattern from api/v1/users.ts"

❌ **Ignoring Existing Solutions**:
- Creating new pagination when project has existing implementation

✅ **Leverage Existing**:
- "Use existing utils/pagination.ts helper, same as
  services/user-service.ts uses"

## Quality Checklist

Before finalizing plan:
- [ ] Have I identified the architectural pattern?
- [ ] Does the solution fit naturally into existing structure?
- [ ] Are all steps grounded in discovered conventions?
- [ ] Have I referenced specific existing code as examples?
- [ ] Are integration points clearly identified?
- [ ] Is each step atomic and testable?
- [ ] Have I considered risks and provided mitigations?
- [ ] Will someone unfamiliar with my thinking understand this plan?

## Plan Templates

For detailed templates and architecture-specific examples, see:
- **templates.md** - Full plan template and common scenarios

---

**Remember**: A great plan reads like it was written by someone deeply familiar with the codebase. Use the [codebase-analysis] skill to become that familiar before planning.
