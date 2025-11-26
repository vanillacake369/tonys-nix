Orchestrate skills to improve code quality, performance, and maintainability

# Task
$ARGUMENTS

# Workflow

This command orchestrates multiple skills to provide comprehensive improvement strategies:

1. **[security-review]**: Identify security vulnerabilities and quality issues
2. **[code-quality]**: Suggest refactoring and maintainability improvements
3. **[architectural-planning]**: Design safe migration strategy if needed
4. **[code-implementation]**: Provide implementation guidance for improvements
5. **[test-development]**: Ensure improvements are properly tested

# Output Guidelines

Provide **adaptive output** based on improvement scope:

## For Focused Improvements (single file/function)
- Specific issues identified
- Direct improvement recommendation
- Implementation approach
- Quick validation

## For Large-Scale Improvements (system-wide)
- Assessment of current state with metrics
- Prioritized improvement areas (critical → nice-to-have)
- Phased enhancement approach
- Safe migration strategy with rollback plan
- Impact assessment (performance, compatibility, effort)

# Key Principles

- **Safety first**: Never break existing functionality
- **Incremental**: Phase improvements to reduce risk
- **Measurable**: Define success metrics where possible
- **Backward compatible**: Maintain compatibility unless explicitly required otherwise
- **Project-aligned**: Follow existing code patterns and standards from @CLAUDE.md

# Example Output Structure

For a moderate improvement task:

```markdown
## Current State Assessment
[Analysis of existing implementation with identified issues]

## Improvement Opportunities

**Critical** (Fix before release):
- [Security/correctness issue] at [file:line]

**High Priority** (Significant value):
- [Performance bottleneck] at [file:line]
- [Maintainability issue] at [file:line]

**Enhancement** (When convenient):
- [Code style inconsistency] at [file:line]

## Recommended Approach
[Chosen strategy with justification based on project context]

**Why this approach**:
- Minimizes risk by [phasing strategy]
- Reuses [existing patterns/utilities]
- Preserves [backward compatibility]

## Phased Implementation

### Phase 1: Critical Fixes (1-2 hours)
1. [Immediate safety/security fix]
2. [Quick validation]

### Phase 2: Core Improvements (half-day)
1. [Performance optimization]
2. [Refactoring for maintainability]
3. [Comprehensive testing]

### Phase 3: Polish (optional, 1-2 hours)
1. [Code style consistency]
2. [Documentation updates]

## Migration Strategy
- **Rollout**: [How to deploy safely]
- **Validation**: [How to verify improvements]
- **Rollback**: [If issues occur, how to revert]

## Success Metrics
- [ ] [Measurable improvement - e.g., "Response time < 200ms"]
- [ ] All existing tests pass
- [ ] No regressions in [affected areas]
```

Adapt complexity based on improvement scope - simpler for focused changes, detailed for system-wide enhancements.
