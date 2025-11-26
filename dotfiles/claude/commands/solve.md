Orchestrate skills to analyze and solve problems comprehensively

# Task
$ARGUMENTS

# Workflow

This command orchestrates multiple skills to provide comprehensive problem-solving:

1. **[codebase-analysis]**: Understand the context and existing patterns
2. **[architectural-planning]**: Design the solution approach if needed
3. **[code-implementation]**: Provide implementation guidance
4. **[security-review]**: Identify potential security concerns
5. **[test-development]**: Suggest testing approach

# Output Guidelines

Provide **adaptive output** based on problem complexity:

## For Simple Problems
- Direct root cause analysis
- Single recommended solution
- Specific implementation steps
- Quick validation approach

## For Complex Problems
- Thorough context analysis using discovered patterns
- 2-3 viable solution options with trade-offs
- Recommended approach with detailed justification
- Phased implementation plan with dependencies
- Risk assessment and mitigation strategies
- Comprehensive testing strategy

# Key Principles

- **Context-aware**: Reference existing code patterns from codebase
- **Practical**: Provide actionable solutions, not just theory
- **Risk-conscious**: Identify potential issues and preventions
- **Validation-focused**: Always include how to verify the solution works

# Example Output Structure

For a moderate complexity problem:

```markdown
## Problem Analysis
[Root cause in context of existing codebase]

## Recommended Solution
[Chosen approach with justification based on project patterns]

**Why this approach**:
- Fits existing [pattern] from [file:line]
- Reuses [existing utility/component]
- Minimizes impact on [affected areas]

## Implementation Steps
1. [Specific action referencing existing code]
2. [Next action with pattern example]
3. [Testing approach following project conventions]

## Validation
- [ ] [Specific check]
- [ ] [Another verification step]

## Risks & Mitigations
- **[Potential risk]**: [How to prevent/handle]
```

Adapt this structure based on the actual complexity - simpler for straightforward issues, more detailed for complex problems.
