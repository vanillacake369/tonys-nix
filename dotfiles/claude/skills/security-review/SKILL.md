---
name: security-review
description: Identify security vulnerabilities, performance issues, and code quality problems through systematic analysis adapted to project's technology stack and domain. Use when reviewing code, assessing security, auditing. Triggers: 'security', 'vulnerability', 'audit', 'review', 'OWASP', 'injection', 'authentication', 'authorization', 'XSS', 'CSRF', 'secure', '보안', '취약점', '검토', '리뷰', '감사', '인증', '인가', '보안검사'.
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebSearch
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

## OWASP Top 10 Checklist

### A01: Broken Access Control
- [ ] Authorization checks on all protected resources
- [ ] User can't access other users' data
- [ ] Admin functions require admin role
- [ ] No direct object references without validation

### A02: Cryptographic Failures
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Strong encryption algorithms (AES-256, RSA-2048+)
- [ ] No hardcoded secrets in source code
- [ ] Proper key management

### A03: Injection
- [ ] All SQL queries parameterized
- [ ] Command execution uses argument arrays
- [ ] No eval() or similar dynamic execution
- [ ] Input validation with whitelists

### A04: Insecure Design
- [ ] Threat modeling performed
- [ ] Security controls at design level
- [ ] Rate limiting on sensitive operations
- [ ] Proper session management

### A05: Security Misconfiguration
- [ ] Default credentials changed
- [ ] Error messages don't leak information
- [ ] Security headers configured (CSP, HSTS, etc.)
- [ ] Unnecessary features disabled

### A06: Vulnerable Components
- [ ] Dependencies up to date
- [ ] No known vulnerable libraries
- [ ] Dependency scanning enabled
- [ ] Unused dependencies removed

### A07: Authentication Failures
- [ ] Strong password policies
- [ ] Multi-factor authentication available
- [ ] Session timeout configured
- [ ] Secure password storage (bcrypt, Argon2)

### A08: Data Integrity Failures
- [ ] Digital signatures for critical data
- [ ] Secure deserialization
- [ ] CI/CD pipeline security
- [ ] Input validation on all data sources

### A09: Logging & Monitoring Failures
- [ ] Security events logged
- [ ] No sensitive data in logs
- [ ] Log integrity protected
- [ ] Alerting on suspicious activity

### A10: Server-Side Request Forgery
- [ ] URL validation and whitelisting
- [ ] Network segmentation
- [ ] No user-controlled URLs to internal resources
- [ ] Response validation

## Performance Review Categories

### Algorithm Complexity
- Identify O(n²) or worse algorithms
- Suggest more efficient approaches
- Consider trade-offs (time vs space)

### Database Optimization
- N+1 query detection
- Missing indexes
- Inefficient joins
- Unbounded result sets

### Resource Management
- Memory leaks
- File handle leaks
- Database connection pools
- Proper cleanup (defer, finally, using)

### Caching Strategy
- Missing caching opportunities
- Cache invalidation correctness
- Over-caching (stale data)
- Cache key design

## Domain-Specific Considerations

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
**Risk**: [Vulnerability type]
**Impact**: [What can happen]
**Fix**: [Specific recommendation with code]

### 🛡️ Security Concerns (High Priority)
**Location**: `file.ext:line`
**Severity**: High
**OWASP Category**: [Category]
**Recommendation**: [Fix with code example]

### ⚡ Performance Issues
**Location**: `file.ext:line`
**Impact**: [Performance degradation]
**Fix**: [Optimization with code]

### 📈 Quality Improvements (Recommended)
**Location**: `file.ext:line`
**Category**: [Maintainability/Readability/etc.]
**Suggestion**: [Improvement]

### ✅ Good Practices Found
**Location**: `file.ext:line`
**Observation**: [What's done well]
**Why**: [Why this matters]
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

## Detailed Examples

For comprehensive vulnerability examples and fixes, see:
- **vulnerability-examples.md** - Detailed security and performance examples

---

**Remember**: A great review makes the codebase safer and better while helping developers grow. Use [codebase-analysis] to provide context-aware, technology-specific security and quality guidance.
