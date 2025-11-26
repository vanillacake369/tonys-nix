# Pattern Recognition Strategies

## Naming Pattern Analysis

### Identification Process
1. Scan 5-10 representative files from different areas
2. Categorize naming patterns by element type
3. Identify majority pattern as project standard

### Common Patterns by Element

**Variables/Fields:**
- `camelCase` - JavaScript, Java, TypeScript
- `snake_case` - Python, Ruby, Rust
- `PascalCase` - Rarely for variables, sometimes in C#
- `SCREAMING_SNAKE_CASE` - Constants across languages

**Functions/Methods:**
- `camelCase` - Java, JavaScript, TypeScript, Go
- `snake_case` - Python, Ruby, Rust
- `PascalCase` - C#, sometimes Go exported functions

**Classes/Types:**
- `PascalCase` - Universal across OOP languages
- `snake_case` - Some Python, Rust modules
- Prefixes: `I` for interfaces (C#, TypeScript), `Abstract` prefix

**Files:**
- `kebab-case.js` - Common in frontend projects
- `PascalCase.tsx` - React components
- `snake_case.py` - Python modules
- `camelCase.java` - Java classes

## Code Structure Patterns

### Organizational Approaches

**By Layer (Horizontal):**
```
src/
├── controllers/
├── services/
├── repositories/
└── models/
```

**By Feature (Vertical):**
```
src/
├── user/
│   ├── user.controller.ts
│   ├── user.service.ts
│   └── user.repository.ts
└── order/
    ├── order.controller.ts
    └── order.service.ts
```

**By Component:**
```
src/
├── auth/
├── api/
└── core/
```

### Detecting the Pattern
1. Count how many directories contain mixed concerns vs single concerns
2. Check if related files are grouped by feature or separated by type
3. Identify by analyzing import paths (local vs cross-cutting)

## Dependency Patterns

### Import Style Analysis

**Absolute vs Relative:**
```typescript
// Absolute imports
import { User } from '@/models/User'

// Relative imports
import { User } from '../../models/User'
```

**Aliasing Patterns:**
```python
# Common aliases
import numpy as np
import pandas as pd

# Project-specific
from myproject import config as cfg
```

**Grouping Conventions:**
```javascript
// Standard library
import fs from 'fs'
import path from 'path'

// External dependencies
import express from 'express'
import mongoose from 'mongoose'

// Internal modules
import { UserService } from './services'
```

## Error Handling Patterns

### Detection Strategy
Search for error handling across 10+ files to identify pattern:

**Exception-Based:**
```java
try {
    operation();
} catch (SpecificException e) {
    logger.error("Context", e);
    throw new CustomException(e);
}
```

**Result/Option Types:**
```rust
fn operation() -> Result<Data, Error> {
    // Pattern: Explicit error types
}
```

**Error Codes:**
```c
int status = operation();
if (status != SUCCESS) {
    handle_error(status);
}
```

### Custom Error Patterns
Look for:
- Custom exception hierarchies
- Error wrapper classes
- Standard error response formats
- Logging integration with errors

## Testing Patterns

### Test Organization
```
# By mirroring source structure
src/services/user.service.ts
tests/services/user.service.test.ts

# By test type
tests/unit/
tests/integration/
tests/e2e/

# Inline with source
src/user/user.service.ts
src/user/user.service.test.ts
```

### Test Naming Conventions
```python
# Pattern: test_methodName_condition_expectedResult
def test_createUser_withValidData_returnsUser():
    pass

# Pattern: descriptive sentence
def test_user_creation_fails_with_duplicate_email():
    pass
```

### Assertion Styles
```javascript
// expect() style (Jest, Chai)
expect(result).toBe(expected)
expect(array).toHaveLength(3)

// assert style (Node.js)
assert.equal(result, expected)
assert.strictEqual(result, expected)

// should style (Should.js)
result.should.equal(expected)
result.should.be.an.Array()
```

## Documentation Patterns

### Comment Styles

**JavaDoc/JSDoc:**
```java
/**
 * Brief description
 *
 * @param name Description
 * @return Description
 * @throws Exception Description
 */
```

**Python Docstrings:**
```python
"""
Brief description.

Args:
    param: Description

Returns:
    Description
"""
```

**Inline Comments:**
```javascript
// Explain WHY, not WHAT
const timeout = 5000  // API sometimes slow during peak hours
```

### Documentation Placement
- Above functions (most languages)
- Module-level docs at file top
- README in each major directory
- Inline for complex algorithms

## Synthesis Process

### Creating Pattern Profile
After discovery, create project profile:

```yaml
Project Pattern Profile:
  naming:
    variables: camelCase
    functions: camelCase
    classes: PascalCase
    files: kebab-case
  structure:
    organization: by-feature
    test_location: alongside-source
  imports:
    style: absolute
    grouping: standard, external, internal
  error_handling:
    approach: exceptions
    custom_types: yes
    logging: integrated
  testing:
    framework: Jest
    naming: descriptive-sentence
    assertions: expect-style
```

Use this profile to ensure all new code matches existing patterns.
