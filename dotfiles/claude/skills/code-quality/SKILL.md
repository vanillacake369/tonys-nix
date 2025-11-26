---
name: code-quality
description: Improve code quality, performance, and maintainability through safe, incremental refactoring while preserving functionality and respecting project patterns. Use when refactoring, optimizing performance, improving readability. Triggers: 'refactor', 'optimize', 'improve', 'clean up', 'performance', 'slow', 'duplication', 'complex', 'technical debt', '리팩토링', '최적화', '개선', '정리', '성능', '느림', '중복', '복잡', '기술부채'.
allowed-tools:
  - Read
  - Edit
  - Grep
  - Bash(test:*)
  - Bash(build:*)
  - Bash(go test:*)
  - Bash(npm test:*)
---

# Code Quality and Refactoring Methodology

This skill enables systematic code improvement through safe refactoring that preserves behavior while enhancing readability, maintainability, and performance.

**Leverages:** [codebase-analysis] skill for understanding project patterns and quality standards.

## Refactoring Philosophy

### Safety First
- **Behavior preservation**: Never change external functionality
- **Incremental improvement**: Small, safe changes that compound
- **Pattern respect**: Follow existing conventions even while improving
- **Test-driven validation**: All tests must pass after each change
- **Reversible changes**: Easy to undo if issues arise

### Quality Focus
- Readability over cleverness
- Maintainability over brevity
- Project patterns over external "best practices"
- Measurable improvements over subjective opinions

## Refactoring Workflow

### Phase 1: Quality Assessment
Using [codebase-analysis]:
1. Understand project quality standards
2. Identify improvement opportunities
3. Study existing tests for expected behavior
4. Assess current performance characteristics
5. Learn project-specific quality metrics

### Phase 2: Improvement Planning
Prioritize refactoring opportunities:
1. **Critical**: Bugs, security issues, breaking changes
2. **High**: Performance bottlenecks, code duplication
3. **Medium**: Readability, maintainability improvements
4. **Low**: Style inconsistencies, minor optimizations

Plan incremental steps with validation points between each.

### Phase 3: Safe Refactoring Execution
Apply improvements incrementally:
1. Make one change at a time
2. Run tests after each change
3. Commit working states frequently
4. Validate performance hasn't degraded
5. Document improvements and rationale

## Common Refactoring Techniques

### Extract Method/Function

```python
# ❌ Before: Long, complex method
def process_order(order):
    # 50 lines of validation
    if not order.customer_id:
        raise ValueError("Missing customer")
    if not order.items:
        raise ValueError("Empty order")
    # ... 46 more lines

    # 30 lines of calculation
    subtotal = sum(item.price * item.quantity for item in order.items)
    tax = subtotal * 0.1
    # ... 26 more lines

    # 20 lines of persistence
    order.total = subtotal + tax
    db.save(order)
    # ... 16 more lines

# ✅ After: Extracted, focused methods
def process_order(order):
    validate_order(order)
    calculate_totals(order)
    save_order(order)

def validate_order(order):
    if not order.customer_id:
        raise ValueError("Missing customer")
    if not order.items:
        raise ValueError("Empty order")

def calculate_totals(order):
    subtotal = sum(item.price * item.quantity for item in order.items)
    order.tax = subtotal * 0.1
    order.total = subtotal + order.tax

def save_order(order):
    db.save(order)
    publish_order_event(order)
```

### Reduce Code Duplication

```javascript
// ❌ Before: Duplicated logic
function getUserById(id) {
  if (!id) throw new Error('ID required');
  const user = db.query('SELECT * FROM users WHERE id = ?', [id]);
  if (!user) throw new Error('User not found');
  return user;
}

function getProductById(id) {
  if (!id) throw new Error('ID required');
  const product = db.query('SELECT * FROM products WHERE id = ?', [id]);
  if (!product) throw new Error('Product not found');
  return product;
}

// ✅ After: Extracted common pattern
function findByIdOrThrow(table, id) {
  if (!id) throw new Error('ID required');
  const record = db.query(`SELECT * FROM ${table} WHERE id = ?`, [id]);
  if (!record) throw new Error(`${table} not found`);
  return record;
}

function getUserById(id) {
  return findByIdOrThrow('users', id);
}

function getProductById(id) {
  return findByIdOrThrow('products', id);
}
```

### Simplify Conditional Logic

```java
// ❌ Before: Complex nested conditions
public boolean canProcessOrder(Order order) {
    if (order != null) {
        if (order.getStatus() == OrderStatus.PENDING) {
            if (order.getItems().size() > 0) {
                if (order.getCustomer() != null) {
                    if (order.getCustomer().isActive()) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

// ✅ After: Guard clauses
public boolean canProcessOrder(Order order) {
    if (order == null) return false;
    if (order.getStatus() != OrderStatus.PENDING) return false;
    if (order.getItems().isEmpty()) return false;
    if (order.getCustomer() == null) return false;
    return order.getCustomer().isActive();
}
```

### Replace Magic Numbers with Constants

```go
// ❌ Before: Magic numbers
func calculateDiscount(amount float64, customerType int) float64 {
    if customerType == 1 {
        return amount * 0.1
    } else if customerType == 2 {
        return amount * 0.15
    } else if customerType == 3 {
        return amount * 0.2
    }
    return 0
}

// ✅ After: Named constants
const (
    CustomerTypeRegular  = 1
    CustomerTypeSilver   = 2
    CustomerTypeGold     = 3

    DiscountRegular = 0.1
    DiscountSilver  = 0.15
    DiscountGold    = 0.2
)

func calculateDiscount(amount float64, customerType int) float64 {
    switch customerType {
    case CustomerTypeRegular:
        return amount * DiscountRegular
    case CustomerTypeSilver:
        return amount * DiscountSilver
    case CustomerTypeGold:
        return amount * DiscountGold
    default:
        return 0
    }
}
```

## Performance Optimization

### Algorithm Optimization

```python
# ❌ Before: O(n²) algorithm
def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                duplicates.append(items[i])
    return list(set(duplicates))

# ✅ After: O(n) algorithm
def find_duplicates(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)
```

### Caching Expensive Operations

```typescript
// ❌ Before: Repeated expensive calculation
class ReportGenerator {
  generateReport(data: Data[]): Report {
    const summary = this.calculateExpensiveSummary(data);  // Slow
    const charts = this.generateCharts(data);
    const table = this.generateTable(data, summary);
    return { summary, charts, table };
  }

  calculateExpensiveSummary(data: Data[]): Summary {
    // 2 seconds of computation
    return complexCalculation(data);
  }
}

// ✅ After: Cached results
class ReportGenerator {
  private summaryCache = new Map<string, Summary>();

  generateReport(data: Data[]): Report {
    const cacheKey = this.hashData(data);
    const summary = this.getCachedSummary(cacheKey, data);
    const charts = this.generateCharts(data);
    const table = this.generateTable(data, summary);
    return { summary, charts, table };
  }

  private getCachedSummary(key: string, data: Data[]): Summary {
    if (!this.summaryCache.has(key)) {
      this.summaryCache.set(key, this.calculateExpensiveSummary(data));
    }
    return this.summaryCache.get(key)!;
  }
}
```

## Refactoring Safety Protocols

### Test-Driven Refactoring

```
1. ✅ Before: Ensure tests exist and pass
   └─ If no tests, write characterization tests first

2. ✅ During: Run tests after each atomic change
   └─ If tests fail, revert immediately

3. ✅ After: Verify all tests still pass
   └─ Check performance hasn't regressed
```

### Safe Refactoring Steps

**Always safe** (low risk):
- Rename variables/methods (with IDE support)
- Extract method within same class
- Replace magic numbers with constants
- Add guard clauses

**Medium risk** (require extra care):
- Move methods between classes
- Change method signatures
- Refactor inheritance hierarchies
- Modify data structures

**High risk** (proceed cautiously):
- Change public APIs
- Modify database schemas
- Alter threading/concurrency patterns
- Change core algorithms

## Project-Specific Quality Improvements

### Learn Project Standards

```python
# If project uses Clean Code principles (found in CLAUDE.md):
# ✅ Apply project-specific guidelines

# Function length guideline: < 20 lines
def complex_operation():  # 50 lines - needs refactoring
    # Extract methods to meet project standard
    pass

# Variable naming: intention-revealing names
x = getData()  # ❌ Violates project standard
userData = getUserData()  # ✅ Follows project standard
```

### Respect Project Patterns

```java
// If project uses DDD pattern (found via analysis):
// ✅ Refactor to align with domain model

// ❌ Before: Anemic domain model
public class Order {
    private BigDecimal amount;
    // Only getters/setters
}

public class OrderService {
    public void applyDiscount(Order order, BigDecimal discount) {
        order.setAmount(order.getAmount().subtract(discount));
    }
}

// ✅ After: Rich domain model (project pattern)
public class Order {
    private BigDecimal amount;

    public void applyDiscount(BigDecimal discount) {
        validateDiscount(discount);
        this.amount = this.amount.subtract(discount);
        recordDiscountEvent();
    }
}
```

## Quality Metrics to Track

### Measurable Improvements

Track these metrics before/after refactoring:
- **Cyclomatic complexity**: Lower is better
- **Code duplication**: Reduce duplicated blocks
- **Method length**: Shorter, focused methods
- **Test coverage**: Maintain or improve
- **Performance**: Execution time, memory usage

### Report Structure

```markdown
## Refactoring Report

**Scope**: [File/module refactored]
**Objective**: [Quality improvement goal]

### Improvements Made
- Reduced cyclomatic complexity from 15 to 4
- Eliminated 200 lines of duplicated code
- Improved performance by 60% (2.1s → 840ms)

### Changes
**Before**: [Original problematic code]
**After**: [Improved code]
**Rationale**: [Why this improves quality]
```

## Anti-Patterns to Avoid

❌ **Over-Engineering**:
```javascript
// Wrong - adding unnecessary abstraction
class UserFactoryBuilderProvider { ... }

// Right - simple and clear
function createUser(data) { ... }
```

❌ **Changing Behavior**:
```python
# Wrong - altering functionality during refactoring
def calculate_total(items):
    return sum(items) * 1.1  # Added 10% fee - BEHAVIOR CHANGE!

# Right - preserve exact behavior
def calculate_total(items):
    return sum(items)  # Same as before
```

❌ **Breaking Tests**:
```java
// Wrong - refactoring that breaks tests
// Tests fail after refactoring → REVERT

// Right - all tests pass after refactoring
// Tests pass → Commit
```

## Quality Checklist

Before finalizing refactoring:
- [ ] All tests pass
- [ ] Performance hasn't degraded
- [ ] Code readability improved
- [ ] Follows project patterns
- [ ] No behavior changes
- [ ] Documentation updated if needed
- [ ] Changes are atomic and reversible

---

**Remember**: Refactoring is about making code better while keeping it working. Use [codebase-analysis] to understand project quality standards, then improve code incrementally toward those standards.
