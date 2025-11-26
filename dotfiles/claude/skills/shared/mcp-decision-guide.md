# MCP Decision Guide

This guide provides centralized decision criteria for when to use each MCP (Model Context Protocol) server.

## Available MCP Servers

### Context7 - Library Documentation
**Purpose**: Fetch up-to-date documentation for libraries and frameworks

**When to use**:
- Unknown library in imports/dependencies
- Framework mentioned but unfamiliar
- API patterns unclear from code alone
- Need official documentation for architecture

**Examples**:
```
✅ Unfamiliar @upstash/redis import → Context7
✅ Unknown React hooks API → Context7
✅ Need Nix flakes documentation → Context7
❌ Standard JavaScript Array methods → Skip (well-known)
```

**Usage**:
```javascript
// 1. Resolve library ID
mcp__context7__resolve-library-id("upstash redis")

// 2. Fetch documentation
mcp__context7__get-library-docs("/upstash/upstash-redis", topic="usage patterns")
```

---

### WebSearch - Current Information
**Purpose**: Search for latest information beyond knowledge cutoff

**When to use**:
- Version number suggests recent release (post-knowledge-cutoff)
- Technology name suggests new framework/tool
- "Latest" or "new" mentioned in task
- Breaking changes suspected
- Need current best practices

**Examples**:
```
✅ React 19 features (knowledge cutoff: Jan 2025) → WebSearch
✅ "Latest Nix best practices" → WebSearch
✅ Recent CVE vulnerabilities → WebSearch
❌ Established patterns (e.g., Clean Code principles) → Skip
```

**Usage**:
```javascript
WebSearch("React 19 new features breaking changes")
```

---

### Sequential Thinking - Complex Decisions
**Purpose**: Systematic analysis for multi-dimensional architectural decisions

**When to use**:
- 3+ viable architectural approaches
- 5+ trade-off dimensions to consider
- High/critical decision impact
- Path unclear (trade-offs not obvious)
- Need evidence-based decision rationale

**Examples**:
```
✅ Microservices vs Monolith decision → Sequential Thinking
✅ Database selection (PostgreSQL vs MongoDB vs Redis) → Sequential Thinking
✅ Authentication strategy (OAuth vs JWT vs Session) → Sequential Thinking
❌ Add single utility function → Skip (straightforward)
❌ Fix typo in variable name → Skip (trivial)
```

**Decision Criteria**:
| Factor | Use Sequential Thinking | Skip |
|--------|------------------------|------|
| Approaches | 3+ options | 1-2 options |
| Dimensions | 5+ trade-offs | <5 trade-offs |
| Impact | High/Critical | Low/Medium |
| Clarity | Unclear path | Obvious solution |

**Usage**:
```javascript
// Thought-by-thought analysis
mcp__sequential-thinking__sequentialthinking({
  thought: "Analyze current system constraints...",
  thoughtNumber: 1,
  totalThoughts: 8,
  nextThoughtNeeded: true
})
```

---

### Memory - Session Persistence
**Purpose**: Store and recall information across conversation sessions

**When to use**:
- Record architectural decisions and rationale
- Preserve decision context ("why we chose X over Y")
- Track trade-offs considered
- Document future implications
- Store project-specific patterns discovered

**Examples**:
```
✅ After choosing modular monolith → Save decision rationale
✅ Discovered critical security pattern → Store for future reference
✅ Team preferences learned → Remember across sessions
❌ Temporary calculations → Skip (not worth persisting)
```

**Usage**:
```javascript
// Create entities
mcp__memory__create_entities([{
  name: "Architecture Decision - Modular Monolith",
  entityType: "Architectural Decision",
  observations: [
    "Chose modular monolith over microservices (2025-01-26)",
    "Reason: Team size (3 devs) favors simplicity",
    "Trade-off: Accept scaling limitations for reduced complexity"
  ]
}])

// Create relations
mcp__memory__create_relations([{
  from: "Architecture Decision - Modular Monolith",
  to: "Team Size Constraint",
  relationType: "influenced by"
}])

// Search/retrieve
mcp__memory__search_nodes("monolith decision")
```

---

## Decision Flow

### Step 1: Knowledge Gap?
- Need library docs? → **Context7**
- Need current info? → **WebSearch**
- Already know? → Skip MCP

### Step 2: Complex Decision?
- Multi-dimensional architectural choice? → **Sequential Thinking**
- Straightforward? → Direct analysis

### Step 3: Should Persist?
- Important decision/pattern? → **Memory**
- Temporary info? → Skip

---

## Anti-Patterns

❌ **Don't use Context7 for**:
- Standard library APIs (Array, String, etc.)
- Well-known frameworks within knowledge
- Language syntax questions

❌ **Don't use WebSearch for**:
- Established principles (SOLID, DDD, Clean Code)
- Historical information
- Code visible in current context

❌ **Don't use Sequential Thinking for**:
- Simple "yes/no" decisions
- Single obvious solution
- Low-impact choices

❌ **Don't use Memory for**:
- Temporary calculations
- Information specific to current task only
- Data that will be outdated quickly

---

## Integration Examples

### Example 1: Unknown Library + Complex Decision
```
Task: "Choose and integrate a caching solution"

Flow:
1. Context7: Fetch docs for Redis, Memcached, etc.
2. Sequential Thinking: Analyze trade-offs systematically
3. Memory: Save decision rationale for future reference
```

### Example 2: Familiar Stack + Simple Task
```
Task: "Add validation to user input"

Flow:
1. Skip MCPs - use existing project validation patterns
2. Implement directly using discovered conventions
```

### Example 3: New Framework + Straightforward Integration
```
Task: "Add Zod schema validation following project patterns"

Flow:
1. Context7: Fetch Zod documentation (if unfamiliar)
2. Skip Sequential Thinking - integration pattern is clear
3. Implement using project conventions
```

---

## Tips for Effective MCP Usage

1. **Combine MCPs strategically**: Context7 for docs → Sequential Thinking for decision → Memory for persistence
2. **Don't over-use**: MCPs add latency; skip when direct analysis suffices
3. **Progressive**: Start with Context7/WebSearch for knowledge, then deeper analysis if needed
4. **Document**: Use Memory for important decisions that affect future work
5. **Validate**: After using Context7/WebSearch, verify information applies to project version

---

**Remember**: MCPs are tools for enhancing analysis, not replacements for understanding the codebase. Use them when they add genuine value.
