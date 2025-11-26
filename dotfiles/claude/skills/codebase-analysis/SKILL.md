---
name: codebase-analysis
description: Universal methodology for discovering and adapting to any codebase's patterns, conventions, and architectural decisions. Automatically detects technology stack, learns project structure, and identifies coding standards.
---

# Universal Codebase Analysis

This skill provides a systematic methodology for analyzing any codebase regardless of language, framework, or architectural style.

## Core Principles

### Universal Adaptability
- **No assumptions**: Never assume specific languages, frameworks, or tools
- **Pattern recognition**: Learn from what exists in the project
- **Context-driven**: Let the codebase tell you its conventions
- **Technology-agnostic**: Work with any stack, from assembly to modern frameworks

### Discovery-First Approach
Every analysis must begin with systematic discovery:
1. **Project structure**: How is code organized?
2. **Technology stack**: What languages, frameworks, and tools are used?
3. **Conventions**: What patterns and standards does the project follow?
4. **Build systems**: How is the project built and deployed?
5. **Testing approach**: How are tests structured and executed?

## Discovery Methodology

### Phase 0: Knowledge Expansion (If Needed)

Before analyzing the codebase, automatically evaluate if external knowledge is required using the MCP Decision Tree from @CLAUDE.md.

#### Knowledge Gap Detection

**Scan for unfamiliar technology**:
1. Check file extensions (`.rs`, `.go`, `.nix`, etc.)
2. Read package managers (package.json, Cargo.toml, flake.nix)
3. Identify unknown frameworks in imports

**Evaluation**:
- Is this library/framework unfamiliar? → **Use Context7**
- Is the version potentially newer than knowledge cutoff? → **Use WebSearch**
- Are all technologies familiar? → **Proceed to Phase 1**

#### Knowledge Expansion Process

**When Context7 needed**:
```
1. Detect unfamiliar library (e.g., @upstash/redis)
2. Resolve library ID: mcp__context7__resolve-library-id("upstash redis")
3. Fetch docs: mcp__context7__get-library-docs("/upstash/upstash-redis", topic="architecture")
4. Integrate documentation into analysis
```

**When WebSearch needed**:
```
1. Detect version mismatch (e.g., React 19 vs knowledge cutoff)
2. Search: WebSearch("React 19 new features breaking changes")
3. Update understanding with latest information
4. Proceed with current knowledge
```

#### Examples

**Example 1: Unfamiliar Library (Use Context7)**
```
Scans codebase → Finds `import { Redis } from '@upstash/redis'`
Question: "Is @upstash/redis familiar?"
Answer: No → Use Context7

Process:
1. mcp__context7__resolve-library-id("upstash redis")
2. mcp__context7__get-library-docs("/upstash/upstash-redis", topic="usage patterns")
3. Learn: Serverless Redis, REST-based API, specific patterns
4. Proceed to Phase 1 with enriched knowledge
```

**Example 2: Version Mismatch (Use WebSearch)**
```
Scans package.json → Finds "react": "19.0.0"
Question: "Is React 19 potentially newer than my knowledge?"
Answer: Yes (knowledge cutoff is earlier) → Use WebSearch

Process:
1. WebSearch("React 19 new features")
2. Learn: New hooks, breaking changes, migration patterns
3. Proceed to Phase 1 with updated understanding
```

**Example 3: Familiar Technology (Skip MCP)**
```
Scans codebase → Finds justfile, Nix flakes, home-manager
Question: "Are these technologies familiar?"
Answer: Yes → Skip MCP, proceed directly to Phase 1

Reason: Standard Nix ecosystem tools, well within knowledge base
```

#### Decision Criteria

**Use Context7 when**:
- Unknown library in imports/dependencies
- Framework mentioned in docs but unfamiliar
- API patterns unclear from code alone
- Official documentation would clarify architecture

**Use WebSearch when**:
- Version number suggests recent release
- Technology name suggests post-knowledge-cutoff
- "Latest" or "new" mentioned in task
- Breaking changes suspected

**Skip MCP when**:
- All technologies in common use
- Patterns clear from code inspection
- Standard libraries/frameworks
- No version concerns

### Phase 1: Structural Analysis
```bash
# Use Glob and LS to understand organization
1. Identify root directory structure
2. Locate source code directories (src/, lib/, pkg/, etc.)
3. Find configuration files (any naming pattern)
4. Discover build/dependency management files
5. Identify test directories and patterns
```

### Phase 2: Technology Detection
```bash
# Detect from file extensions and content:
- Source files: *.ext → Analyze content for language/framework
- Build files: *build*, *make*, package.*, *.gradle, go.*, Cargo.*, etc.
- Dependencies: Parse imports, includes, require statements
- Frameworks: Identify from import patterns and directory structure
```

### Phase 3: Convention Learning
```bash
# Study existing code for patterns:
1. Naming conventions (camelCase, snake_case, PascalCase)
2. File organization (by feature, by layer, by component)
3. Code structure (class-based, functional, procedural)
4. Error handling patterns
5. Logging and debugging approaches
6. Documentation style
```

### Phase 4: Build System Understanding
```bash
# Identify how the project builds:
- Build commands from scripts, Makefiles, justfiles
- Dependency management approach
- Test execution commands
- Deployment/packaging methods
```

## Pattern Recognition Framework

### Adaptive Analysis Questions
For ANY project, systematically ask:
1. "What file extensions do source files use?" → Language identification
2. "How are files organized in directories?" → Architectural pattern
3. "What naming patterns repeat across files?" → Conventions
4. "How do tests look and where are they?" → Testing methodology
5. "What tools and commands are mentioned?" → Ecosystem

### Language-Agnostic Detection
```python
# Universal detection patterns (not hardcoded):

# Imports/Dependencies
import, require, include, use, using, from, #include

# Build systems (find by pattern matching)
*build*, *make*, *.toml, *.yaml, *.json, *file
package.*, project.*, cargo.*, go.*, pom.*, *.gradle

# Testing (discover from any naming)
*test*, *spec*, test_*, Test*, *_test.*, *Spec.*
test/, tests/, spec/, __tests__/
```

### Convention Synthesis
After discovery, synthesize project conventions:
- **Naming**: Observed patterns across variables, functions, files
- **Structure**: How code is layered and organized
- **Style**: Indentation, spacing, comment formats
- **Patterns**: Repeated architectural or design patterns
- **Dependencies**: How external libraries are used

## Integration with Specialized Skills

This base skill provides the foundation for specialized skills:
- **architectural-planning**: Uses discovery to understand existing architecture
- **code-implementation**: Uses conventions to match existing code style
- **code-quality**: Uses patterns to identify improvement opportunities
- **security-review**: Uses tech stack to identify relevant vulnerabilities
- **test-development**: Uses testing patterns to create consistent tests

## Best Practices

### Always Start with Discovery
```
❌ Wrong: "I'll add a React component..."
✅ Right: "Let me first analyze the project structure...
          [Discovers it's Vue, not React]
          I'll add a Vue component following the existing patterns..."
```

### Learn, Don't Impose
```
❌ Wrong: "Best practice is to use TypeScript strict mode"
✅ Right: "This project uses JavaScript without type checking.
          I'll follow the existing approach for consistency."
```

### Reference Existing Examples
```
✅ Always cite existing code as justification:
"Following the pattern from UserService.java, I'll structure
 OrderService with the same dependency injection approach."
```

## Example Discovery Process

### Unknown Project Type
```
User: "Add authentication"
Claude:
1. [Scans directory structure]
2. [Finds *.rs files, Cargo.toml]
3. "Detected Rust project with Actix-web framework"
4. [Analyzes existing auth middleware patterns]
5. "I'll implement authentication following your existing
   middleware pattern in src/middleware/auth.rs"
```

### Mixed Technology Stack
```
User: "Implement data pipeline"
Claude:
1. [Discovers Python scripts/, Go services/, K8s configs/]
2. "Multi-language project: Python for data processing,
   Go for microservices, Kubernetes for orchestration"
3. [Analyzes integration patterns between components]
4. "I'll create a pipeline that integrates with your existing
   Python processors and Go service mesh..."
```

## Anti-Patterns to Avoid

❌ **Never**:
- Assume a specific technology without verification
- Impose external conventions on the project
- Skip the discovery phase for "simple" changes
- Use generic examples not grounded in the actual codebase
- Recommend technologies not already in use

✅ **Always**:
- Analyze before acting
- Learn project-specific patterns
- Reference existing code examples
- Respect established conventions
- Adapt recommendations to project context

## Supporting Files

For detailed strategies, see:
- `pattern-recognition.md` - Deep dive into pattern matching
- `language-detection.md` - Technology identification guides
- `convention-mapping.md` - Common convention patterns across languages

---

**Remember**: Every codebase has its own personality. This skill teaches you to discover and respect that personality rather than imposing external standards.
