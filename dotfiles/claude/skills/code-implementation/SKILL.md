---
name: code-implementation
description: Implement code changes by learning from and precisely matching existing codebase patterns, ensuring seamless integration with surrounding code
---

# Code Implementation Methodology

This skill provides systematic approach to implementing code that blends naturally with existing codebase as if written by the original developers.

**Leverages:** [codebase-analysis] skill for discovering project conventions and patterns.

## Core Implementation Principle

**Mimic, Don't Import**: Every line of new code should feel like it was written by the same developer who wrote the surrounding code.

## Implementation Workflow

### Phase 1: Context Learning
Before writing any code:
1. **Study neighbors**: Read 3-5 files in same directory/module
2. **Analyze similar features**: Find comparable functionality
3. **Learn patterns**: Identify repeated structures and approaches
4. **Understand dependencies**: See how libraries are used
5. **Examine tests**: Learn validation approaches

### Phase 2: Pattern Matching
Match existing code exactly:
1. **Naming**: Use same case, prefixes, suffixes as neighbors
2. **Structure**: Follow same file organization and class/function layout
3. **Style**: Match indentation, spacing, bracing, comments
4. **Libraries**: Use same dependencies and utilities as existing code
5. **Error handling**: Follow same error patterns and logging

### Phase 3: Implementation
Write code that blends in:
1. Copy structural patterns from similar existing code
2. Reuse existing utilities and helper functions
3. Follow same abstraction levels as surrounding code
4. Match comment style and documentation format
5. Use same testing patterns and assertions

### Phase 4: Integration Validation
Ensure seamless integration:
1. Run existing tests - all must pass
2. Execute build commands - must compile/run
3. Verify style consistency with surrounding code
4. Check that integration points work correctly
5. Ensure no new dependencies without justification

## Style Matching Strategies

### Naming Convention Matching

```javascript
// ✅ Learn and apply existing pattern
// Found in codebase:
function getUserById(id) { ... }
function getOrderById(id) { ... }

// New code matches:
function getProductById(id) { ... }

// ❌ Don't impose different pattern:
function fetchProduct(id) { ... }  // Wrong - breaks convention
```

### Structural Pattern Matching

```python
# ✅ Follow existing structure
# Found in codebase:
class UserService:
    def __init__(self, repository, cache):
        self.repository = repository
        self.cache = cache

    def get_user(self, id):
        # Implementation

# New code matches structure:
class ProductService:
    def __init__(self, repository, cache):
        self.repository = repository
        self.cache = cache

    def get_product(self, id):
        # Implementation
```

### Import Pattern Matching

```typescript
// ✅ Match existing import organization
// Found in existing files:
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '../entities/user.entity';
import { CreateUserDto } from '../dto/create-user.dto';

// New code follows same pattern:
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Product } from '../entities/product.entity';
import { CreateProductDto } from '../dto/create-product.dto';
```

### Error Handling Pattern Matching

```java
// ✅ Match existing error handling
// Found in UserService.java:
public User findById(Long id) {
    return repository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException(
            ErrorCode.USER_NOT_FOUND,
            "User not found with id: " + id
        ));
}

// New code in OrderService.java matches:
public Order findById(Long id) {
    return repository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException(
            ErrorCode.ORDER_NOT_FOUND,
            "Order not found with id: " + id
        ));
}
```

## Library and Framework Integration

### Using Existing Libraries

```python
# ✅ Study how existing code uses libraries
# Found in existing services:
from app.utils.logger import get_logger
logger = get_logger(__name__)

# New code uses same approach:
from app.utils.logger import get_logger
logger = get_logger(__name__)

# ❌ Don't introduce different logging:
import logging  # Wrong - project has custom logger
```

### Dependency Consistency

```go
// ✅ Use existing dependencies
// Found in existing handlers:
import (
    "github.com/gin-gonic/gin"
    "project/internal/service"
)

// New handler uses same:
import (
    "github.com/gin-gonic/gin"
    "project/internal/service"
)

// ❌ Don't add new HTTP framework:
import "github.com/gorilla/mux"  // Wrong - project uses Gin
```

## Code Quality Integration

### Comment Style Matching

```rust
// ✅ Match existing comment patterns
// Found in existing code:
/// Validates user credentials and returns auth token.
///
/// # Arguments
/// * `username` - The user's username
/// * `password` - The user's password
///
/// # Returns
/// * `Result<Token, AuthError>` - Auth token or error
pub fn authenticate(username: &str, password: &str) -> Result<Token, AuthError>

// New code matches style:
/// Validates product availability and reserves inventory.
///
/// # Arguments
/// * `product_id` - The product identifier
/// * `quantity` - Requested quantity
///
/// # Returns
/// * `Result<Reservation, InventoryError>` - Reservation or error
pub fn reserve_inventory(product_id: &str, quantity: u32) -> Result<Reservation, InventoryError>
```

### Formatting and Spacing

```javascript
// ✅ Match exact formatting
// Found in existing code (2 spaces, no semicolons):
function processUser(user) {
  const validated = validateUser(user)
  const enriched = enrichData(validated)
  return saveUser(enriched)
}

// New code matches formatting:
function processOrder(order) {
  const validated = validateOrder(order)
  const enriched = enrichData(validated)
  return saveOrder(enriched)
}

// ❌ Don't use different style:
function processOrder(order) {
    const validated = validateOrder(order);  // Wrong indentation and semicolons
    const enriched = enrichData(validated);
    return saveOrder(enriched);
}
```

## Testing Integration

### Test Pattern Matching

```python
# ✅ Follow existing test structure
# Found in test_user_service.py:
class TestUserService:
    @pytest.fixture
    def service(self, mock_repository):
        return UserService(mock_repository)

    def test_get_user_success(self, service):
        # Arrange
        user_id = 1
        expected_user = User(id=user_id, name="Test")

        # Act
        result = service.get_user(user_id)

        # Assert
        assert result == expected_user

# New test_product_service.py matches:
class TestProductService:
    @pytest.fixture
    def service(self, mock_repository):
        return ProductService(mock_repository)

    def test_get_product_success(self, service):
        # Arrange
        product_id = 1
        expected_product = Product(id=product_id, name="Test")

        # Act
        result = service.get_product(product_id)

        # Assert
        assert result == expected_product
```

## Implementation Safety

### Before Implementation
- [ ] Study at least 3 similar files to understand patterns
- [ ] Identify exact naming, structure, and style conventions
- [ ] Locate existing utilities/helpers to reuse
- [ ] Check what testing patterns to follow

### During Implementation
- [ ] Make small, atomic changes
- [ ] Test each change before proceeding
- [ ] Maintain backward compatibility
- [ ] Follow plan precisely - don't add scope

### After Implementation
- [ ] Run all tests - ensure none break
- [ ] Build project - ensure it compiles/runs
- [ ] Review code side-by-side with similar existing files
- [ ] Verify no debug code or TODOs remain

## Common Implementation Patterns

### Adding CRUD Operations
When adding CRUD, find existing CRUD examples:
1. Copy the structure exactly
2. Adjust entity/model names
3. Keep same validation patterns
4. Use same repository patterns
5. Follow same endpoint/API structure

### Adding API Endpoints
When adding endpoints, find similar endpoints:
1. Copy routing pattern
2. Match request/response DTOs structure
3. Use same validation approach
4. Follow same error response format
5. Apply same authentication/authorization

### Adding Business Logic
When adding logic, study similar use cases:
1. Follow same service/use case structure
2. Use existing domain models
3. Apply same transaction patterns
4. Reuse existing validation
5. Match logging and error handling

## Anti-Patterns to Avoid

❌ **Imposing External Style**:
```javascript
// Wrong - introducing new style
const result = await service.execute();  // Project uses promises, not async/await
```

✅ **Matching Project Style**:
```javascript
// Right - following project pattern
const result = service.execute().then(data => data);
```

❌ **Adding Unnecessary Dependencies**:
```python
import requests  # Wrong - project uses httpx
```

✅ **Using Existing Dependencies**:
```python
from app.http import client  # Right - project's HTTP client
```

❌ **Reinventing Existing Utilities**:
```java
// Wrong - creating own date formatter
SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");
```

✅ **Reusing Project Utilities**:
```java
// Right - using project's date utility
String formatted = DateUtils.formatDate(date);
```

## Quality Checklist

Before considering implementation complete:
- [ ] Does code match naming conventions of surrounding files?
- [ ] Are imports organized like existing files?
- [ ] Does error handling follow project patterns?
- [ ] Are same libraries/utilities used?
- [ ] Do comments match existing style?
- [ ] Does code structure align with similar features?
- [ ] All existing tests still pass?
- [ ] New code follows discovered patterns?

---

**Remember**: The best implementation is invisible - it looks like it was always part of the codebase. Use [codebase-analysis] to understand the codebase's voice, then write in that voice.
