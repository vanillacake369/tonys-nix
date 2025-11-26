Orchestrate skills to systematically debug issues with root cause analysis

# Task
$ARGUMENTS

# Workflow

This command orchestrates skills for systematic debugging:

1. **[codebase-analysis]**: Understand the context and reproduce the issue
2. **Hypothesis testing**: Systematic root cause analysis
3. **[code-implementation]**: Apply the fix following project patterns
4. **[test-development]**: Add tests to prevent regression

# Output Guidelines

Provide **adaptive output** based on issue urgency and complexity:

## For Critical Production Issues
- Immediate reproduction steps
- Quick fix (temporary workaround)
- Proper fix (long-term solution)
- Monitoring to ensure resolution

## For Development Bugs
- Thorough root cause analysis
- Single recommended fix
- Implementation with pattern references
- Regression prevention strategy

# Key Principles

- **Evidence-based**: Test hypotheses, don't guess
- **Reproducible**: Provide exact steps to reproduce
- **Prioritized fixes**: Quick fix vs proper fix when needed
- **Prevention-focused**: Add tests to catch similar issues
- **Context-aware**: Reference existing debugging patterns and error handling

# Example Output Structure

For a typical debugging session:

```markdown
## Issue Summary
[Clear description of the problem and its impact]

## Reproduction
**Steps**:
1. [Exact step to reproduce]
2. [Next step]

**Expected**: [What should happen]
**Actual**: [What actually happens]

## Root Cause Analysis

**Initial Observations**:
- [What we can see directly]
- [Error messages, logs, symptoms]

**Investigation**:
Hypothesis 1: [Potential cause]
- Test: [How to verify]
- Result: ✅/❌ [Evidence found/not found]

Hypothesis 2: [Another possible cause]
- Test: [Verification approach]
- Result: ✅/❌ [Evidence]

**Root Cause**: [Confirmed underlying cause with evidence]
- Location: [file:line]
- Reason: [Why this causes the issue]

## Fix Strategy

### Option A: Quick Fix (if critical)
**Solution**: [Immediate workaround]
**Implementation**: [How to apply]
**Timeline**: [How fast can be deployed]
**Trade-offs**: [What's not addressed]

### Option B: Proper Fix (recommended)
**Solution**: [Comprehensive fix addressing root cause]
**Pattern**: Following [existing error handling] from [file:line]
**Timeline**: [Implementation time]
**Benefits**: [Why this is better long-term]

## Implementation Steps
1. [Specific change referencing existing code patterns]
2. [Next change]
3. [Add test to prevent regression]

## Prevention Strategy
**Tests to Add**:
- [Test case for this scenario]
- [Edge case uncovered]

**Monitoring**:
- Watch [metric] for [expected behavior]
- Alert on [error pattern]

**Code Improvements** (optional):
- [Pattern to avoid in future]
- [Defensive check to add]

## Verification
- [ ] Issue no longer reproduces
- [ ] Test case added and passes
- [ ] No regressions in [affected areas]
- [ ] [Performance/behavior] as expected
```

Adapt based on urgency - minimal for quick production fixes, comprehensive for development debugging.
