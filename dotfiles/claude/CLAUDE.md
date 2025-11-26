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

## MCP Usage Guidelines

**IMPORTANT:** Use MCP servers intelligently to balance efficiency and capability. Prefer direct analysis for simple tasks.

### When to Use MCP Servers

**Direct Analysis (Default for simple tasks):**
- Single file changes, clear requirements, standard patterns
- Routine git operations, file management, obvious fixes

**MCP-Assisted (Use when genuinely needed):**
- **Context7**: Unfamiliar libraries needing official documentation or API references
- **Sequential Thinking**: Complex architectural decisions with multiple trade-offs, systematic debugging with unclear root cause
- **Memory**: Track important component relationships, record architectural decisions, maintain cross-session context

### Anti-Patterns to Avoid

```
❌ Sequential Thinking for trivial edits (e.g., "add a comma to JSON")
❌ Context7 for libraries already used throughout codebase
❌ Memory for temporary debugging information
❌ Over-relying on MCP without building understanding
❌ Skipping MCP when genuinely stuck on complex problems
```

**Decision Rule:** Start simple (direct analysis) → Escalate to MCP only when complexity or knowledge gaps warrant it.

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

### Skills Architecture

Skills use a **layered approach**:

```
codebase-analysis (Base Skill)
└── Universal pattern recognition and adaptation methodology
    │
    ├── architectural-planning
    │   └── Uses base skill to understand architecture before planning
    │
    ├── code-implementation
    │   └── Uses base skill to match existing code patterns
    │
    ├── code-quality
    │   └── Uses base skill to identify improvement opportunities
    │
    ├── security-review
    │   └── Uses base skill to detect tech-specific vulnerabilities
    │
    └── test-development
        └── Uses base skill to discover testing frameworks and patterns
```

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

### Skills vs Commands vs Agents

**Skills** (what this project uses):
- Portable procedural knowledge
- Automatically activated when relevant
- Reusable across conversations
- Example: `codebase-analysis`, `security-review`

**Slash Commands** (also available):
- User-invoked workflows
- Located in `dotfiles/claude/commands/`
- Example: `/solve`, `/enhance`, `/scaffold`

**Built-in Agents** (system-level):
- Task-specialized autonomous executors
- Independent context windows
- Cannot be customized or overridden
- Example: architect, implementer, refactorer agents

### Skill Development Guidelines

If extending or modifying Skills:

1. **Keep Skills focused**: Each skill should have a clear, single purpose
2. **Reference base skill**: Specialized skills should leverage `codebase-analysis`
3. **Provide examples**: Include concrete code examples in skill documentation
4. **Support modularity**: Split large skills into SKILL.md + supporting files
5. **Test activation**: Ensure skill description triggers appropriate activation

### Skills Location

All skills are located in `dotfiles/claude/skills/` and automatically synced to `~/.claude/skills/` via home-manager.