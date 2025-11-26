---
name: security-review
description: Identify security vulnerabilities, performance issues, and code quality problems through systematic analysis adapted to project's technology stack and domain
---

# Security and Code Review Methodology

This skill provides comprehensive code review focusing on security, performance, and quality issues while providing constructive, actionable feedback.

**Leverages:** [codebase-analysis] skill for understanding project technology stack and security context.

## Review Philosophy

### Security First, Context Always
- Identify vulnerabilities specific to project's tech stack
- Consider domain-specific risks (finance, healthcare, IoT)
- Provide practical mitigations, not just warnings
- Prioritize by actual risk and exploitability

### Constructive Feedback
- Explain the "why" behind recommendations
- Provide code examples for fixes
- Acknowledge good practices found
- Guide improvement rather than criticize

## Review Workflow

### Phase 1: Context Analysis
Using [codebase-analysis]:
1. Identify technology stack and frameworks
2. Understand project domain and sensitivity
3. Learn existing security patterns and standards
4. Detect security tools already in use
5. Map attack surface and integration points

### Phase 2: Security Examination
Systematic vulnerability analysis:
1. **Input validation**: All user inputs, API parameters
2. **Authentication/Authorization**: Access control and identity
3. **Data protection**: Encryption, secrets, sensitive data
4. **Injection attacks**: SQL, command, code injection risks
5. **Security misconfigurations**: Defaults, headers, permissions

### Phase 3: Performance Analysis
Technology-appropriate performance review:
1. Algorithm efficiency for detected language
2. Resource management patterns
3. Database query optimization
4. Caching and concurrency appropriateness
5. Memory and resource leak detection

### Phase 4: Quality Assessment
Code quality in project context:
1. Consistency with project patterns
2. Maintainability and readability
3. Error handling completeness
4. Testing adequacy
5. Documentation quality

## Universal Security Vulnerabilities

### Input Validation (Any Language)

```python
# 🚨 CRITICAL: SQL Injection
# ❌ Vulnerable
def get_user(username):
    query = f"SELECT * FROM users WHERE username = '{username}'"
    return db.execute(query)

# ✅ Fixed: Parameterized query
def get_user(username):
    query = "SELECT * FROM users WHERE username = ?"
    return db.execute(query, (username,))
```

```javascript
// 🚨 HIGH: Command Injection
// ❌ Vulnerable
app.post('/convert', (req, res) => {
  exec(`convert ${req.body.file} output.pdf`);
});

// ✅ Fixed: Whitelist and sanitize
app.post('/convert', (req, res) => {
  const file = path.basename(req.body.file);  // Prevent path traversal
  if (!/^[a-zA-Z0-9_-]+\.txt$/.test(file)) {  // Whitelist pattern
    return res.status(400).send('Invalid file');
  }
  exec(`convert ${file} output.pdf`);
});
```

### Authentication & Authorization

```java
// 🚨 CRITICAL: Missing authorization check
// ❌ Vulnerable
@GetMapping("/user/{id}/private-data")
public PrivateData getPrivateData(@PathVariable Long id) {
    return privateDataRepository.findByUserId(id);
    // Anyone can access any user's private data!
}

// ✅ Fixed: Authorization check
@GetMapping("/user/{id}/private-data")
public PrivateData getPrivateData(@PathVariable Long id) {
    Long currentUserId = getCurrentUserId();
    if (!currentUserId.equals(id)) {
        throw new UnauthorizedException("Access denied");
    }
    return privateDataRepository.findByUserId(id);
}
```

### Sensitive Data Exposure

```typescript
// 🛡️ MEDIUM: Sensitive data in logs
// ❌ Problematic
logger.info(`User logged in: ${JSON.stringify(user)}`);
// Logs: { id: 1, email: "user@example.com", password: "hashed..." }

// ✅ Fixed: Sanitized logging
logger.info(`User logged in: ${user.id}`);
// Or use a sanitization function
logger.info(`User logged in: ${sanitizeForLog(user)}`);
```

```go
// 🛡️ MEDIUM: Hardcoded secrets
// ❌ Vulnerable
const apiKey = "sk_live_abc123xyz"  // Secret in source code!

// ✅ Fixed: Environment variable
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    log.Fatal("API_KEY environment variable required")
}
```

## Technology-Specific Security

### Web Applications

```javascript
// 🚨 HIGH: XSS vulnerability
// ❌ Vulnerable (React)
function UserProfile({ user }) {
  return <div dangerouslySetInnerHTML={{ __html: user.bio }} />;
}

// ✅ Fixed: Sanitize or avoid HTML
function UserProfile({ user }) {
  return <div>{user.bio}</div>;  // React escapes by default
  // Or use DOMPurify if HTML needed
}
```

```python
# 🛡️ MEDIUM: Missing CSRF protection
# ❌ Vulnerable (Flask)
@app.route('/transfer', methods=['POST'])
def transfer_money():
    amount = request.form['amount']
    to_account = request.form['account']
    transfer(amount, to_account)

# ✅ Fixed: CSRF token
from flask_wtf.csrf import CSRFProtect
csrf = CSRFProtect(app)

@app.route('/transfer', methods=['POST'])
@csrf.csrf_protect
def transfer_money():
    amount = request.form['amount']
    to_account = request.form['account']
    transfer(amount, to_account)
```

### API Security

```typescript
// 🛡️ HIGH: Missing rate limiting
// ❌ Vulnerable
app.post('/api/login', async (req, res) => {
  const user = await authenticate(req.body.username, req.body.password);
  // Brute force attack possible!
});

// ✅ Fixed: Rate limiting
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 5,  // 5 attempts
  message: 'Too many login attempts'
});

app.post('/api/login', loginLimiter, async (req, res) => {
  const user = await authenticate(req.body.username, req.body.password);
});
```

### Database Security

```java
// 🚨 CRITICAL: Overprivileged database connection
// ❌ Problematic
// Application uses 'root' user with full privileges

// ✅ Fixed: Principle of least privilege
// Create dedicated app user with minimal permissions:
// GRANT SELECT, INSERT, UPDATE ON app_db.* TO 'app_user'@'localhost';
// Use 'app_user' in application config
```

## Performance Review Patterns

### Algorithm Efficiency

```python
# ⚡ MEDIUM: Inefficient algorithm
# ❌ O(n²) performance
def find_duplicates(items):
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                # Performance issue with large lists
                pass

# ✅ O(n) performance
def find_duplicates(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return duplicates
```

### Database Query Optimization

```javascript
// ⚡ HIGH: N+1 query problem
// ❌ Problematic
const users = await User.findAll();
for (const user of users) {
  user.posts = await Post.findAll({ where: { userId: user.id } });
  // Executes N queries!
}

// ✅ Fixed: Eager loading
const users = await User.findAll({
  include: [{ model: Post }]
});
// Executes 1 query with JOIN
```

### Memory Management

```go
// ⚡ MEDIUM: Memory leak potential
// ❌ Problematic
func loadAllUsers() []*User {
    rows, _ := db.Query("SELECT * FROM users")
    // No rows.Close() - connection leak!
    var users []*User
    for rows.Next() {
        // ...
    }
    return users
}

// ✅ Fixed: Proper resource cleanup
func loadAllUsers() ([]*User, error) {
    rows, err := db.Query("SELECT * FROM users")
    if err != nil {
        return nil, err
    }
    defer rows.Close()  // Ensures cleanup

    var users []*User
    for rows.Next() {
        // ...
    }
    return users, rows.Err()
}
```

## Domain-Specific Security

### Financial Systems
- Decimal precision in calculations (no floating point!)
- Transaction integrity and atomicity
- Audit trail completeness
- Regulatory compliance (PCI-DSS)

### Healthcare Systems
- HIPAA compliance (data encryption, access logs)
- Patient data anonymization
- Secure data transmission (TLS 1.2+)
- Access control and authentication

### IoT/Embedded Systems
- Resource constraints awareness
- Secure firmware updates
- Device authentication
- Power consumption security trade-offs

## Review Report Structure

```markdown
## Code Review Summary
**Overall Assessment**: [Excellent/Good/Needs Improvement/Requires Changes]
**Security Risk**: [Low/Medium/High/Critical]
**Performance Impact**: [Positive/Neutral/Negative]

### 🚨 Critical Issues (Must Fix)
**Location**: `file.ext:line`
**Risk**: SQL Injection
**Impact**: Attackers can access entire database

**Vulnerable Code**:
```language
[code snippet]
```

**Recommended Fix**:
```language
[fixed code]
```

**Rationale**: [Explanation]

### 🛡️ Security Concerns (High Priority)
**Location**: `file.ext:line`
**Severity**: High
**OWASP Category**: A01:2021 – Broken Access Control

[Details...]

### ⚡ Performance Issues
**Location**: `file.ext:line`
**Impact**: 2.1s → 180ms (91% improvement possible)

[Details...]

### 📈 Quality Improvements (Recommended)
**Location**: `file.ext:line`
**Category**: Maintainability

[Details...]

### ✅ Good Practices Found
**Location**: `file.ext:line`
**Observation**: Excellent use of parameterized queries throughout codebase

[Why this matters...]
```

## Review Best Practices

### Provide Context

```
✅ "This SQL injection vulnerability exists because user input
   from req.body.search is directly concatenated into the query.
   In this project, use the existing db.query() helper which
   handles parameterization automatically (see auth/login.ts:45)."

❌ "SQL injection vulnerability. Fix it."
```

### Prioritize Realistically

```
🚨 Critical: Fix immediately (security, data loss)
🛡️ High: Fix before release (security, major bugs)
⚡ Medium: Address soon (performance, maintainability)
📈 Low: Improve when convenient (style, minor optimizations)
```

### Reference Project Standards

```
✅ "This violates the project's Clean Code guideline of
   <20 lines per function (see CLAUDE.md). Extract validation
   logic into separate method following pattern from UserService."

❌ "Function is too long."
```

## Quality Checklist

Before finalizing review:
- [ ] Identified security vulnerabilities specific to tech stack
- [ ] Assessed performance in language/framework context
- [ ] Evaluated code quality against project standards
- [ ] Provided specific, actionable recommendations
- [ ] Included code examples for fixes
- [ ] Explained rationale for each concern
- [ ] Acknowledged good practices found
- [ ] Prioritized issues appropriately

---

**Remember**: A great review makes the codebase safer and better while helping developers grow. Use [codebase-analysis] to provide context-aware, technology-specific security and quality guidance.
