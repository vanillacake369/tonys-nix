Debug specific issue with systematic root cause analysis

# Context
Issue description, symptoms, and context:
$ARGUMENTS

# Requirements
1. **Issue Reproduction**: Understand exact conditions and symptoms:
   - When does the issue occur?
   - What are the exact error messages or symptoms?
   - What environment/configuration is involved?
   - Can the issue be consistently reproduced?
2. **Root Cause Analysis**: Use systematic debugging approach:
   - Trace the issue from symptom to source
   - Identify contributing factors
   - Rule out false leads
   - Validate hypotheses with evidence
3. **Fix Strategies**: Present multiple fix approaches with:
   - Immediate/temporary solutions
   - Proper long-term fixes
   - Risk assessment for each approach
4. **Optimal Fix**: Choose best solution for current codebase:
   - Follow patterns from @CLAUDE.md
   - Consider impact on system stability
   - Evaluate maintenance burden
5. **Prevention**: Suggest measures to prevent similar issues:
   - Code patterns to avoid
   - Monitoring and alerting
   - Testing improvements

# Output Format
## Issue Summary
[Clear description of the problem and its impact]

## Reproduction Steps
1. [Step-by-step reproduction guide]
2. [Expected vs actual behavior]

## Investigation Process
### Initial Observations
[What we can observe directly]

### Hypotheses
1. **Hypothesis 1**: [Potential cause]
   - Evidence: [Supporting data]
   - Likelihood: [High/Medium/Low]

2. **Hypothesis 2**: [Alternative cause]
   - Evidence: [Supporting data] 
   - Likelihood: [High/Medium/Low]

### Root Cause
[Confirmed underlying cause with evidence]

## Fix Options
### Quick Fix (Temporary)
- **Solution**: [Immediate workaround]
- **Pros**: [Benefits]
- **Cons**: [Limitations and risks]
- **Timeline**: [Implementation time]

### Proper Fix (Long-term)
- **Solution**: [Comprehensive solution]
- **Pros**: [Benefits]
- **Cons**: [Complexity and effort required]
- **Timeline**: [Implementation time]

### Alternative Approaches
[Other viable solutions with trade-offs]

## Recommended Solution
[Chosen approach with detailed justification]

## Implementation Steps
1. **Preparation**: [Pre-fix steps and safety measures]
2. **Implementation**: [Step-by-step fix process]
3. **Validation**: [How to verify the fix works]
4. **Monitoring**: [What to watch for post-fix]

## Prevention Strategy
### Code Improvements
[Changes to prevent recurrence]

### Process Improvements
[Testing, monitoring, or workflow changes]

### Documentation
[Knowledge sharing and runbook updates]

## Rollback Plan
[What to do if the fix causes new issues]