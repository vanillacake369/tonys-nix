# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

### Clean Architecture Pattern

The application follows a clean architecture pattern with clear separation of concerns:

```
src/
├── domain/                    # Business domains
│   ├── {domainName}/
│   │   ├── api/              # API endpoints and DTOs
│   │   │   ├── dto/          # Request/Response DTOs
│   │   │   └── events/       # Domain events
│   │   ├── infra/            # Infrastructure layer
│   │   │   ├── data/         # Data entities
│   │   │   ├── dao/          # Repositories
│   │   │   └── mapper/       # Entity-Model mappers
│   │   ├── model/            # Domain models
│   │   └── usecase/          # Business logic
└── global/                    # Cross-cutting concerns
    ├── annotation/            # Custom annotations
    ├── config/               # Configuration classes
    ├── exception/            # Global exception handling
    └── infra/                # Shared infrastructure
```

### Key DDD Concepts

- **Aggregates**: Each domain is an aggregate with clear boundaries
- **Domain Models**: Rich domain objects with business logic
- **Repositories**: Abstracted via Infrastructure interfaces
- **Application Services**: UseCase layer coordinates domain operations
- **Domain Services**: Complex business logic spanning multiple aggregates
- **Value Objects**: Immutable objects with well-defined behavior

### Key Architectural Patterns

1. **Layered Architecture**:
    - API Layer: Controllers with DTOs
    - UseCase Layer: Business logic implementation
    - Infrastructure Layer: Data persistence and external integrations
    - Model Layer: Domain entities

2. **Event-Driven Communication**:
    - Internal events for communication between components
    - Message queues for distributed messaging
    - Event streams for data processing

3. **Aspect-Oriented Programming**:
    - Cross-cutting concerns like logging and security
    - Transaction management
    - Performance monitoring

## Clean Code & DDD Principles

**IMPORTANT:** This project follows Clean Code principles and Domain-Driven Design (DDD) architecture. Claude already understands these universal principles - focus on the project-specific standards below.

## Clean Code Checklist

Use this checklist during development and code reviews:

#### Naming Checklist
- [ ] Do variable, function, and class names clearly express their purpose?
- [ ] Are full words used without abbreviations or shortcuts?
- [ ] Are domain terms used accurately?
- [ ] Do boolean variables start with is/has/can?

#### Function Checklist
- [ ] Is the function under 20 lines?
- [ ] Does it perform only one task?
- [ ] Does the function name clearly express what it does?
- [ ] Are there 3 or fewer parameters?
- [ ] Are there no side effects?

#### Class Checklist
- [ ] Does it follow the single responsibility principle?
- [ ] Are there 5 or fewer instance variables?
- [ ] Is the number of public methods appropriate?
- [ ] Has composition been considered over inheritance?

#### Architecture Checklist
- [ ] Are layer dependencies unidirectional? (API → UseCase → Infrastructure → Model)
- [ ] Is domain logic appropriately distributed between UseCase and Model layers?
- [ ] Does the Infrastructure layer handle only technical details?
- [ ] Are domain events utilized appropriately?

## KISS Principle (Keep It Simple, Stupid)

### Progressive Development Philosophy
Claude should follow KISS principles to avoid overwhelming complexity and ensure solid, incremental progress:

#### Core KISS Guidelines
1. **One Thing at a Time**: Focus on a single, well-defined task before moving to the next
2. **Simple Solutions First**: Always choose the simplest solution that works
3. **Incremental Progress**: Break complex tasks into small, manageable steps
4. **Solid Foundation**: Complete each step thoroughly before proceeding
5. **Clear Communication**: Use simple, direct explanations without unnecessary complexity

#### Implementation Strategy
```
❌ Bad Approach:
- Attempt to solve multiple problems simultaneously
- Over-engineer solutions with complex patterns
- Rush through steps without validation
- Provide overwhelming amounts of information at once

✅ KISS Approach:
- Identify ONE specific problem to solve
- Choose the simplest working solution
- Complete and validate before next step
- Provide focused, actionable guidance
```

#### Progressive Task Management
When given complex requirements:

1. **Analyze & Break Down**: Identify the core problem and break into discrete steps
2. **Prioritize**: Order steps by dependency and importance
3. **Execute One Step**: Focus entirely on the current step
4. **Validate**: Ensure the step works before proceeding
5. **Iterate**: Move to next step only after current step is solid

#### Example KISS Workflow
```
User Request: "Add support for new development tool with configuration, testing, and documentation"

❌ Complex Approach:
- Modify multiple files simultaneously
- Create comprehensive documentation
- Set up complex testing scenarios
- Configure advanced features immediately

✅ KISS Approach:
Step 1: Add basic tool installation to language.nix
Step 2: Test installation works with `just install-pckgs`
Step 3: Add minimal configuration if needed
Step 4: Validate tool functions correctly
Step 5: (Only if requested) Add documentation
```

#### Communication Guidelines
- **Be Specific**: "Added Go debugger to language.nix:45" not "Enhanced development environment"
- **One Action Per Response**: Complete one modification before suggesting the next
- **Clear Next Steps**: Always state exactly what to do next
- **Avoid Assumptions**: Ask for clarification rather than guessing requirements

## Clean Code Principles Summary

### Core Principles
1. **Readability first**: Code is written for humans to read
2. **Pursue simplicity**: Prefer simple solutions over complex ones
3. **Maintain consistency**: Entire team uses the same styles and patterns
4. **Boy Scout rule**: Leave code cleaner than when you found it
5. **KISS principle**: Keep it simple, focus on one thing at a time

### Integration with DDD
- **Ubiquitous language**: Reflect the common language used by domain experts and developers in code
- **Domain-centric design**: Structure code around business domains rather than technology
- **Clear boundaries**: Clearly distinguish responsibilities and boundaries between domains and layers
- **Event-driven thinking**: Model important occurrences in the domain as events

Apply these Clean Code principles together with DDD architecture to build maintainable and extensible codebases.

## Claude Code Skills

This project includes custom Skills that provide specialized expertise for software development tasks. Skills are portable, reusable capabilities that Claude automatically activates when relevant.

### Available Skills

#### 1. Codebase Analysis (`codebase-analysis`)
**Purpose**: Universal methodology for discovering and adapting to any codebase's patterns and conventions.

**When activated**: Automatically when analyzing unfamiliar code, learning project structure, or understanding conventions.

**Key capabilities**:
- Language and framework detection
- Pattern recognition and convention learning
- Technology stack analysis
- Build system understanding

**Supporting files**:
- `pattern-recognition.md` - Deep dive into pattern matching strategies
- `language-detection.md` - Technology identification guides

#### 2. Architectural Planning (`architectural-planning`)
**Purpose**: Create detailed technical plans that integrate seamlessly with existing architecture.

**When activated**: When planning new features, system changes, or architectural improvements.

**Key capabilities**:
- Discovers project architecture patterns
- Designs solutions aligned with existing structure
- Creates implementation plans with specific steps
- Identifies integration points and risks

**Output**: `IMPLEMENTATION_PLAN.md` with context-specific guidance

#### 3. Code Implementation (`code-implementation`)
**Purpose**: Write code that blends naturally with existing codebase as if written by original developers.

**When activated**: When implementing features, fixing bugs, or adding functionality.

**Key capabilities**:
- Matches naming conventions and code style
- Uses same libraries and patterns as existing code
- Follows project error handling patterns
- Integrates with existing test patterns

#### 4. Code Quality (`code-quality`)
**Purpose**: Improve code through safe, incremental refactoring while preserving functionality.

**When activated**: When refactoring, optimizing performance, or improving maintainability.

**Key capabilities**:
- Safe refactoring with behavior preservation
- Performance optimization
- Code duplication elimination
- Complexity reduction

**Approach**: Test-driven validation, incremental improvements

#### 5. Security Review (`security-review`)
**Purpose**: Identify vulnerabilities and quality issues through technology-specific analysis.

**When activated**: When reviewing code, assessing security, or evaluating quality.

**Key capabilities**:
- Technology-specific vulnerability detection
- Performance analysis appropriate to language/framework
- Domain-specific security considerations (finance, healthcare, IoT)
- Constructive feedback with actionable fixes

**Coverage**: OWASP Top 10, injection attacks, authentication/authorization, data protection

#### 6. Test Development (`test-development`)
**Purpose**: Create comprehensive tests by adapting to project's testing framework and patterns.

**When activated**: When writing tests, improving coverage, or validating functionality.

**Key capabilities**:
- Testing framework auto-detection
- Test pattern matching
- Coverage strategy adaptation
- Integration with existing CI/CD

**Supported frameworks**: Jest, pytest, JUnit, Go test, and many others (universal detection)

### Skills Selection Decision Tree

Before starting any task, **automatically evaluate** which Skill(s) are needed:

#### Step 1: Task Type Check
- [ ] Is this analyzing unfamiliar code or project structure?
- [ ] Am I learning patterns/conventions I haven't seen before?
- [ ] Do I need to understand the technology stack?

→ **YES to any**: Use **codebase-analysis**
→ **NO to all**: Proceed to Step 2

#### Step 2: Planning vs Implementation Check
- [ ] Am I designing a new feature or architectural change?
- [ ] Do I need to create an implementation plan?
- [ ] Should this integrate with existing architecture?

→ **YES to any**: Use **architectural-planning**
→ **NO to all**: Proceed to Step 3

#### Step 3: Action Type Check
- [ ] Am I writing/modifying production code?
- [ ] Do I need to match existing code style/patterns?
- [ ] Is this adding functionality (not just simple edits)?

→ **YES to any**: Use **code-implementation**
→ **NO to all**: Proceed to Step 4

#### Step 4: Quality/Testing Check
- [ ] Am I refactoring or improving code quality?
- [ ] Do I need to write/update tests?
- [ ] Should I review security vulnerabilities?

→ **Refactoring/optimization**: Use **code-quality**
→ **Testing**: Use **test-development**
→ **Security**: Use **security-review**
→ **Simple edits**: Direct analysis (no Skill needed)

### Automatic Skill Activation Rules

#### MUST use codebase-analysis when:
- Encountering unfamiliar file/directory structures
- Unknown programming languages or frameworks in use
- Need to identify project conventions (naming, error handling, testing)
- Discovering build systems or dependency management approaches

**Examples**:
```
✅ "What's the architecture of this React project?" → codebase-analysis
✅ Found unknown imports in Go codebase → codebase-analysis
✅ "How are errors handled in this Spring Boot app?" → codebase-analysis
❌ "Add a comment to this function" → Direct (no analysis needed)
❌ Modifying well-understood codebase pattern → Direct
```

#### MUST use architectural-planning when:
- Designing features that span multiple modules/services
- Creating integration plans for new components
- Making architectural decisions with multiple options
- Planning changes that affect system boundaries

**Examples**:
```
✅ "Add OAuth authentication to the app" → architectural-planning
✅ "Integrate payment gateway with existing checkout" → architectural-planning
✅ "Migrate from monolith to microservices" → architectural-planning
❌ "Fix a typo in README" → Direct
❌ "Add a single utility function" → Direct
```

#### MUST use code-implementation when:
- Writing new features or functionality
- Modifying existing code logic (beyond simple edits)
- Implementing planned architectural changes
- Need to match project's coding style and patterns

**Examples**:
```
✅ "Implement user registration endpoint" → code-implementation
✅ "Add caching layer to database queries" → code-implementation
✅ "Refactor authentication logic" → code-implementation
❌ "Fix typo in variable name" → Direct
❌ "Add TODO comment" → Direct
```

#### MUST use test-development when:
- Writing test cases for new/existing features
- Improving test coverage
- Creating integration or E2E tests
- Need to match project's testing patterns

**Examples**:
```
✅ "Write unit tests for UserService" → test-development
✅ "Add E2E tests for checkout flow" → test-development
✅ "Increase coverage for authentication module" → test-development
❌ "Run existing tests" → Direct (use Bash)
❌ "Explain what this test does" → Direct
```

#### MUST use code-quality when:
- Refactoring for better maintainability
- Optimizing performance bottlenecks
- Reducing code duplication
- Improving code readability/structure

**Examples**:
```
✅ "Refactor this 500-line function" → code-quality
✅ "Optimize slow database queries" → code-quality
✅ "Remove code duplication in service layer" → code-quality
❌ "Rename a variable" → Direct
❌ "Add whitespace formatting" → Direct
```

#### MUST use security-review when:
- Reviewing code for vulnerabilities
- Assessing authentication/authorization logic
- Evaluating data protection measures
- Checking for OWASP Top 10 issues

**Examples**:
```
✅ "Review this API for security issues" → security-review
✅ "Check for SQL injection vulnerabilities" → security-review
✅ "Audit authentication implementation" → security-review
❌ "Does this function have a bug?" → Direct
❌ "Why is this test failing?" → Direct
```

#### DO NOT use Skills when:
- Simple file edits (typos, comments, formatting)
- Trivial one-line changes
- Answering questions about visible code
- Running commands or reading files
- Tasks with obvious, single-step solutions

**Examples**:
```
❌ "Add a comma to this JSON" → Direct
❌ "What does this function return?" (code visible) → Direct
❌ "Run the build command" → Direct (use Bash)
❌ "Read config.yaml" → Direct (use Read)
```

### Skills as Independent Tools

Each skill operates independently and can be invoked by other skills when needed:

- **codebase-analysis**: Foundation for understanding any project - frequently used by other skills
- **architectural-planning**: Creates implementation plans, may use codebase-analysis for context
- **code-implementation**: Writes code matching patterns, may use codebase-analysis for conventions
- **code-quality**: Improves code, may reference patterns discovered by codebase-analysis
- **security-review**: Identifies vulnerabilities, may use codebase-analysis for tech stack detection
- **test-development**: Creates tests, may use codebase-analysis for test framework detection

**No rigid hierarchy** - skills collaborate flexibly based on the task at hand.

### Skill Collaboration Patterns

Skills often work together in sequences. Common patterns:

#### Pattern 1: New Feature Implementation
```
User: "Add user authentication"
→ codebase-analysis (understand existing auth patterns)
→ architectural-planning (design integration plan)
→ code-implementation (write auth code)
→ test-development (create test suite)
→ security-review (validate security)
```

#### Pattern 2: Bug Fix & Improvement
```
User: "Fix slow API response"
→ codebase-analysis (identify bottlenecks)
→ code-quality (optimize performance)
→ test-development (verify improvements)
```

#### Pattern 3: Code Review
```
User: "Review this pull request"
→ codebase-analysis (understand context)
→ security-review (check vulnerabilities)
→ code-quality (assess maintainability)
```

#### Skill Invocation Priority

When multiple Skills could apply:
1. **codebase-analysis first** if context is unclear
2. **architectural-planning before implementation** for complex features
3. **security-review last** after implementation for validation
4. **test-development alongside** implementation for TDD workflows

### How Skills Work

**Automatic Activation**: Claude loads relevant Skills based on task context. You don't need to explicitly invoke them.

**Portable Expertise**: Skills carry procedural knowledge across all conversations and projects.

**Context-Aware**: Skills adapt to your project's specific patterns, conventions, and technology stack.

**Example workflow**:
```
User: "Add user authentication"
→ [codebase-analysis] activates to discover existing patterns
→ [architectural-planning] creates integration plan
→ [code-implementation] writes code matching project style
→ [test-development] adds tests following project patterns
→ [security-review] validates security considerations
```

### Skills vs Direct Analysis

| Factor | Skills | Direct Analysis |
|--------|--------|----------------|
| **Complexity** | Multi-step procedures | Single-step tasks |
| **Repetition** | Repeatable patterns | One-off requests |
| **Expertise** | Domain-specific knowledge | General knowledge |
| **Scope** | Procedural workflows | Quick answers |

#### Decision Criteria

**Use Skills when:**
- Task requires specialized procedural knowledge
- Same type of work repeats across conversations
- Need to follow established patterns consistently
- Combining multiple capabilities (code + docs + validation)

**Use Direct Analysis when:**
- Simple, straightforward tasks
- One-time information requests
- Visible code/context provides all needed info
- Task has obvious, single-step solution

### Skills vs Commands vs Agents

**Skills** (building blocks):
- Specialized expertise for specific tasks
- Automatically activated when relevant
- Reusable across conversations and projects
- Can be invoked by other skills or commands
- Example: `codebase-analysis`, `security-review`, `code-implementation`

**Slash Commands** (orchestrators):
- High-level workflows that **orchestrate multiple skills**
- User-invoked for complex, multi-step tasks
- Provide adaptive output based on task complexity
- Located in `dotfiles/claude/commands/`
- Example:
  - `/solve` - orchestrates codebase-analysis → architectural-planning → code-implementation
  - `/enhance` - orchestrates security-review → code-quality → architectural-planning
  - `/debug` - orchestrates codebase-analysis → hypothesis testing → code-implementation

**Built-in Agents** (system-level):
- Task-specialized autonomous executors
- Independent context windows
- Cannot be customized or overridden
- Example: architect, implementer, refactorer agents

**Key Difference**: Skills are individual capabilities, Commands coordinate multiple skills for comprehensive solutions.

### Skill Description Writing Guidelines

When creating or modifying Skills, follow these practices to ensure reliable activation:

#### Required Elements in Description
Each Skill description MUST include:

1. **What it does** (functional capability)
2. **When to use it** (trigger conditions)
3. **Specific trigger terms** (keywords users/Claude would mention)
4. **File types/contexts** (applicable scenarios)

#### Writing Best Practices

**✅ Good Description Example**:
```yaml
description: "Analyze codebase structure, identify technology stack, and learn project conventions. Use when encountering unfamiliar code, unknown frameworks, or need to understand project patterns. Triggers: 'architecture', 'structure', 'conventions', 'tech stack', analyzing .gitignore, package.json, go.mod files."
```

**❌ Bad Description Example**:
```yaml
description: "Helps with code analysis" # Too vague, no triggers
```

#### Activation Optimization Tips

1. **Use third person**: "Analyzes code..." not "I analyze code..."
2. **Include file type mentions**: ".ts files", "YAML configs", "Docker files"
3. **Add contextual keywords**: "when user mentions X", "working with Y"
4. **Be specific, not generic**: "React component refactoring" vs "code improvement"
5. **Keep under 1024 characters**: Concise but complete

#### Testing Activation

After modifying a Skill description:
- Test with 3-5 different prompts that should trigger it
- Verify it doesn't activate for unrelated tasks
- Refine trigger terms if activation is inconsistent

### Skill Development Guidelines

If extending or modifying Skills:

1. **Keep Skills focused**: Each skill should have a clear, single purpose
2. **Reference base skill**: Specialized skills should leverage `codebase-analysis`
3. **Provide examples**: Include concrete code examples in skill documentation
4. **Support modularity**: Split large skills into SKILL.md + supporting files
5. **Test activation**: Ensure skill description triggers appropriate activation

### Anti-Patterns to Avoid

```
❌ Invoking Skills for trivial edits (e.g., "fix typo with code-implementation")
❌ Using codebase-analysis when patterns are already well-understood
❌ Skipping architectural-planning for complex, multi-module features
❌ Using code-implementation for simple copy-paste or template generation
❌ Over-relying on Skills without building understanding of the codebase
❌ Activating multiple Skills simultaneously when one would suffice
❌ Using security-review for non-security code questions
```

**Decision Rule**: Skills are for specialized, repeatable procedures. For simple tasks or quick questions, use direct analysis.

### Skills Location

All skills are located in `dotfiles/claude/skills/` and automatically synced to `~/.claude/skills/` via home-manager.