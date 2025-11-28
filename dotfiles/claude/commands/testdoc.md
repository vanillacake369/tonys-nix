Generate comprehensive Korean test case documentation using external policies and code analysis

# Task
$ARGUMENTS

# Workflow

This command orchestrates MCP servers and skills for test documentation:

1. **sequential-thinking MCP**: Systematic analysis planning and hypothesis testing
2. **memory MCP**: Create temporary knowledge graph for analysis context
3. **Figma MCP** (if URL provided): Fetch external design/policy documents
4. **Google Drive MCP** (if URL provided): Access test standards from Google Sheets
5. **[codebase-analysis]**: Understand feature implementation and architecture
6. **[test-development]**: Identify success/failure/edge case scenarios
7. **Documentation generation**: Create structured Korean test case table
8. **memory MCP cleanup**: Preserve patterns, delete temporary analysis data

# Input Format

Provide code files or features to analyze, with optional external document URLs:

```bash
/testdoc "path/to/UserService.java"
/testdoc "OrderAPI feature --figma=https://figma.com/file/xyz"
/testdoc "PaymentController.java --sheets=https://docs.google.com/spreadsheets/d/abc"
/testdoc "Authentication flow --figma=URL --sheets=URL"
```

# MCP Integration Strategy

## sequential-thinking Usage
Use for complex, multi-step analysis:
- Breaking down feature requirements
- Hypothesis testing for edge cases
- Systematic scenario identification
- Trade-off analysis for test priorities

## memory MCP Usage
**Temporary Entities** (deleted after execution):
- `Feature_{name}`: File paths, endpoints, components analyzed
- `Scenario_{id}`: Specific test scenarios identified
- `Analysis_{timestamp}`: Current session findings

**Persistent Entities** (kept for future reference):
- `TestPattern_{category}`: Reusable test scenario patterns
- `ErrorScenario_{type}`: Common failure scenarios by type
- `PolicyReference_{source}`: External policy standards

**Relations to Create**:
- `Feature → has_scenario → Scenario`
- `Scenario → follows → TestPattern`
- `Scenario → references → PolicyReference`

## Figma MCP Usage (Optional)
When `--figma=URL` provided:
- Fetch design specifications and requirements
- Extract policy standards and acceptance criteria
- Reference UI/UX constraints in test cases
- Use design states for test condition variations

## Google Drive MCP Usage (Optional)
When `--sheets=URL` provided:
- Access existing test templates and standards
- Fetch organizational testing policies
- Reference approved test case formats
- Import domain-specific test criteria

# Output Guidelines

Provide **adaptive output** based on feature complexity and available policies:

## For Simple Features (single endpoint/function)
- **Success cases**: 3-5 happy path scenarios
- **Failure cases**: 3-5 key error conditions
- **Edge cases**: 2-3 boundary scenarios
- **Total**: 8-13 test cases
- **Policy references**: Include if external docs provided

## For Complex Features (multi-layer integration)
- **Success cases**: 8-12 comprehensive scenarios
- **Failure cases**: 8-12 error and exception scenarios
- **Edge cases**: 5-10 boundary and concurrency scenarios
- **Total**: 21-34 test cases
- **Policy compliance**: Detailed mapping to external standards
- **DDD layer testing**: API → UseCase → Infrastructure → Model coverage

# Key Principles

- **MCP-driven analysis**: Leverage external tools for comprehensive coverage
- **DDD architecture awareness**: Test across API/UseCase/Infrastructure/Model layers
- **Bilingual approach**: English analysis → Korean documentation
- **Policy compliance**: Reference Figma/Sheets standards when provided
- **Selective memory**: Persist patterns, cleanup temporary analysis
- **Testable precision**: Specific inputs, expected outputs, clear conditions
- **Korean terminology**: Use standard software testing terms (테스트조건, 기대결과, etc.)

# Example Output Structure

```markdown
## Code Analysis (English)

**Feature**: [Feature name and purpose]
**Location**: [File paths with line numbers]
**Architecture Layer**: [API/UseCase/Infrastructure/Model]
**Endpoints**: [API endpoints if applicable]
**Components**:
- **Backend**: [Controllers, Services, Repositories]
- **Frontend**: [Components, pages, forms]

**External Policy References** (if Figma/Sheets provided):
- [Policy document name]: [Relevant requirements]
- [Test standard]: [Acceptance criteria]

**Success Scenarios Identified**:
- [Happy path 1]
- [Happy path 2]
- [Valid alternative flow]

**Failure Scenarios Identified**:
- [Validation error 1]
- [Authorization error]
- [Business rule violation]

**Edge Cases Identified**:
- [Boundary value 1]
- [Concurrency scenario]
- [Special character handling]

---

## Test Cases (Korean)

| NO | 플랫폼 | 기능코드 | 기능 | 테스트조건 | 기대결과 | 백엔드 입력값 | 프론트 입력값 | 비고 |
|----|--------|----------|------|------------|----------|----------------|----------------|------|

### Success Cases (성공 케이스)

| NO | 플랫폼 | 기능코드 | 기능 | 테스트조건 | 기대결과 | 백엔드 입력값 | 프론트 입력값 | 비고 |
|----|--------|----------|------|------------|----------|----------------|----------------|------|
| 1 | API | [CODE-001] | [기능명] | 모든 필수 항목이 유효한 경우 | 200 OK, [예상 응답] | `{"field":"value"}` | [UI 입력] | 정책서 참조: [문서명] |
| 2 | Web | [CODE-002] | [기능명] | 선택 항목 제외하고 등록 | 201 Created, ID 반환 | `{"required":"data"}` | 필수 항목만 입력 | |

### Failure Cases (실패 케이스)

| NO | 플랫폼 | 기능코드 | 기능 | 테스트조건 | 기대결과 | 백엔드 입력값 | 프론트 입력값 | 비고 |
|----|--------|----------|------|------------|----------|----------------|----------------|------|
| 3 | API | [CODE-001] | [기능명] | 필수 항목 누락 | 400 Bad Request, 오류 메시지 | `{"incomplete":"data"}` | 필수 항목 미입력 | 정책서 참조: [검증 규칙] |
| 4 | API | [CODE-001] | [기능명] | 권한 없는 사용자 접근 | 403 Forbidden | Authorization 헤더 없음 | 비로그인 상태 | |

### Edge Cases (엣지 케이스)

| NO | 플랫폼 | 기능코드 | 기능 | 테스트조건 | 기대결과 | 백엔드 입력값 | 프론트 입력값 | 비고 |
|----|--------|----------|------|------------|----------|----------------|----------------|------|
| 5 | API | [CODE-001] | [기능명] | 최대 길이 입력 | 200 OK, 데이터 저장됨 | `{"field":"[255자]"}` | 최대 허용 길이 | |
| 6 | API | [CODE-001] | [기능명] | 특수문자 포함 입력 | 200 OK 또는 400 | `{"field":"test@#$"}` | 특수문자 입력 | 정책 확인 필요 |

---

## Memory Cleanup Summary

**Preserved Patterns**:
- TestPattern_[category]: [Pattern description]
- ErrorScenario_[type]: [Reusable error scenario]

**Deleted Temporary Data**:
- Feature_[name]: [Current analysis context]
- Scenario_[id]: [Specific test scenarios]
- Analysis_[timestamp]: [Session findings]

**Policy References Stored**:
- PolicyReference_[source]: [External standard for future use]
```

# Memory Cleanup Strategy

After generating test documentation, perform selective cleanup:

## Keep (Persistent Knowledge)
```
Entities to preserve:
- TestPattern entities: Reusable scenario templates
  Example: "API validation error pattern: 400 + field-specific messages"

- ErrorScenario entities: Common failure patterns
  Example: "Unauthorized access: 401 vs 403 distinction by context"

- PolicyReference entities: External standards
  Example: "Company test standard: Min 3 success, 3 failure cases per API"

Relations to preserve:
- TestPattern → applies_to → ArchitectureLayer
- ErrorScenario → follows → PolicyReference
```

## Delete (Temporary Analysis)
```
Entities to remove:
- Feature_* entities: File-specific analysis
- Scenario_* entities: Current test scenarios (now in output)
- Analysis_* entities: Session-specific findings

Relations to remove:
- Feature → has_scenario → Scenario
- Any relations with deleted entities
```

## Implementation
Use memory MCP operations:
1. **After analysis**: Create all entities (temporary + persistent)
2. **During generation**: Reference memory for context
3. **After output**: Delete temporary entities via `delete_entities`
4. **Verify**: Confirm persistent patterns remain in graph

# Example Usage Scenarios

## Scenario 1: Simple API Endpoint
```bash
/testdoc "src/domain/user/api/UserController.java:45-89 (createUser method)"
```
**Output**: 10-15 test cases covering basic CRUD, validation, and common errors.

## Scenario 2: Complex Feature with Policy
```bash
/testdoc "Order processing flow --figma=https://figma.com/file/design-spec"
```
**Output**: 25-30 test cases aligned with Figma design states and policy requirements.

## Scenario 3: Multi-Layer DDD Feature
```bash
/testdoc "Payment domain (API + UseCase + Infrastructure)"
```
**Output**: 30-35 test cases covering all architectural layers with DDD pattern awareness.

## Scenario 4: Full Integration with External Docs
```bash
/testdoc "Authentication system --figma=https://figma.com/auth-design --sheets=https://docs.google.com/spreadsheets/d/test-standards"
```
**Output**: 35-40 comprehensive test cases referencing design specs and organizational standards.
