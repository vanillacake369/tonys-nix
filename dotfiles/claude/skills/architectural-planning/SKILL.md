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

## Output Structure

### IMPLEMENTATION_PLAN.md Template

```markdown
# Implementation Plan: [Feature Name]

## Discovered Architecture

**Architecture Pattern**: [Identified pattern - layered, hexagonal, microservices, etc.]
**Primary Language**: [Detected from analysis]
**Key Frameworks**: [Found in dependencies]
**Project Structure**: [How code is organized]

**Similar Features**: [Reference existing similar functionality]
- `path/to/similar/feature.ext` - [How it relates]

## Solution Approach

[High-level approach aligned with discovered patterns]

**Integration Points**:
- [Existing component 1] - [How solution connects]
- [Existing component 2] - [Why this integration point]

**New Components Needed**:
- [Component name] - [Responsibility, location, reasoning]

## Implementation Steps

### Step 1: [Specific, atomic task]
**Files**:
- `path/to/file` (modify/create)

**Action**: [What to change, following which existing pattern]

**Example**: [Reference to similar existing code]
```
[code example from codebase]
```

**Rationale**: [Why this approach fits the architecture]

### Step 2: [Next task]
[Continue with same structure]

## Dependencies & Risks

**Dependencies**:
- [Internal dependency] - [Why it's needed]
- [External library] - [If new, justify addition]

**Potential Risks**:
- [Risk] - **Mitigation**: [How to handle]

**Breaking Changes**:
- [Any breaking change] - **Migration**: [How to update callers]

## Testing Strategy

**Test Location**: [Where tests go based on project structure]

**Test Approach**: [Following existing test patterns]
- Unit tests: [What to test, using which framework]
- Integration tests: [If needed, following existing patterns]

**Manual Validation**:
- [ ] [Specific validation step]
- [ ] [Another validation step]

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] All existing tests pass
- [ ] New code follows project conventions
```

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

---

**Remember**: A great plan reads like it was written by someone deeply familiar with the codebase. Use the [codebase-analysis] skill to become that familiar before planning.
