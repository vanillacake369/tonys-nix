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

## Clean Code Guidelines

This project follows Robert C. Martin's Clean Code principles. All developers should adhere to the guidelines below.

### Naming Conventions

#### Core Principles
- **Use meaningful and descriptive names**: Variable, function, and class names should clearly express what they do
- **Choose pronounceable names**: Names that team members can easily pronounce during discussions
- **Use searchable names**: Names that can be easily found in IDE searches
- **Avoid encoding and prefixes**: Avoid unnecessary prefixes like Hungarian notation

#### Examples
```
// ❌ Bad examples
int d; // Unclear meaning
List<Item> itemList; // Unnecessary List suffix
boolean flag; // Unclear purpose

// ✅ Good examples
int daysSinceCreation;
List<Item> activeItems;
boolean isValid;
```

### Function Design Principles

#### Core Principles
1. **Small functions**: Functions should fit on one screen (recommended under 20 lines)
2. **Single responsibility**: Each function should do one thing only
3. **Descriptive names**: Function names should clearly express what they do
4. **Minimize parameters**: Ideally 0-2 parameters, maximum 3
5. **No side effects**: Avoid unexpected state changes

#### Layered Function Design
```
// UseCase Layer - Business logic coordination
public class OrderUseCaseImpl {
    // ✅ Clear business intent
    public void processNewOrder(OrderCreateRequest request) {
        validateOrderRequest(request);
        Order newOrder = createOrderFromRequest(request);
        orderRepository.save(newOrder);
        publishOrderCreatedEvent(newOrder);
    }
    
    // ✅ Single responsibility principle
    private void validateOrderRequest(OrderCreateRequest request) {
        if (request.getAmount().compareTo(MIN_AMOUNT) < 0) {
            throw new InvalidOrderAmountException("Amount below minimum");
        }
    }
}

// Infrastructure Layer - Simple data operations
public class OrderRepositoryImpl {
    // ✅ Clear query intent
    public List<Order> findActiveOrdersByUserId(Long userId) {
        return repository.findByUserIdAndStatus(userId, ACTIVE);
    }
}
```

### Comments

#### Good Comments
1. **Legal comments**: Copyright and license information
2. **Informative comments**: Complex regex or algorithm explanations
3. **Intent explanations**: Why the implementation was chosen this way
4. **Warning comments**: Performance warnings or execution time alerts

```
/**
 * Detects anomalies in the data using Z-Score algorithm.
 * Values with Z-Score greater than 3 standard deviations are considered anomalies.
 * 
 * @param dataPoints List of data points to analyze
 * @return List of detected anomalies
 */
public List<DataPoint> detectAnomalies(List<DataPoint> dataPoints) {
    // Z-Score threshold: statistically includes 99.7% of normal data
    double threshold = 3.0;
    return dataPoints.stream()
        .filter(data -> calculateZScore(data) > threshold)
        .collect(toList());
}
```

#### Comments to Avoid
```
// ❌ Bad examples
i++; // increment i by 1 (obvious statement)
// This code doesn't work (commented-out code)
int userId = 1; // TODO: fix later (vague TODO)

// ✅ Better examples
incrementRetryCount(); // Clear function name replaces comment
// Remove legacy code and use new implementation
Long authenticatedUserId = getCurrentUserId(); // TODO: Remove after auth system upgrade (Dec 2024)
```

### Formatting and Structure

#### Vertical Formatting
- **Concept separation**: Separate different concepts with blank lines
- **Related code proximity**: Keep related code close together
- **Variable declaration**: Declare variables close to their usage

```
public class OrderService {
    private final OrderRepository repository;
    private final EventPublisher eventPublisher;

    public Order createOrder(CreateOrderRequest request) {
        // Step 1: Validation
        validateRequest(request);
        
        // Step 2: Domain object creation
        Order newOrder = Order.builder()
            .customerId(request.getCustomerId())
            .amount(request.getAmount())
            .build();
        
        // Step 3: Save and publish event
        Order savedOrder = repository.save(newOrder);
        eventPublisher.publish(new OrderCreatedEvent(savedOrder));
        
        return savedOrder;
    }
}
```

#### Horizontal Formatting
- **Line length**: Recommended within 120 characters
- **Whitespace usage**: Use appropriate spacing around operators and to separate arguments
- **Indentation**: Use consistent indentation (typically 2 or 4 spaces)

### Error Handling

#### Exception Design Principles
1. **Minimize checked exceptions**: Use only when necessary for business logic
2. **Specific exception types**: Use specific exceptions rather than generic Exception
3. **Clear exception messages**: Include problem context and potential solutions

```
// ✅ Good exception handling pattern
public class OrderUseCase {
    public void updateOrderStatus(Long orderId, OrderStatus newStatus) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new EntityNotFoundException(
                ErrorCode.ORDER_NOT_FOUND, 
                "Order ID " + orderId + " not found"
            ));
            
        if (!order.canTransitionTo(newStatus)) {
            throw new InvalidStateTransitionException(
                ErrorCode.INVALID_ORDER_STATUS_TRANSITION,
                String.format("Cannot transition order status from %s to %s", 
                    order.getStatus(), newStatus)
            );
        }
        
        order.updateStatus(newStatus);
        orderRepository.save(order);
    }
}
```

### Objects and Data Structures

#### Domain Object Design
```
// ✅ Well-designed domain object
public class Order {
    private final String customerEmail;
    private final BigDecimal amount;
    private OrderStatus status;
    private List<OrderItem> items;
    
    // Business logic as behavior
    public void updateStatus(OrderStatus newStatus) {
        validateStatusTransition(newStatus);
        this.status = newStatus;
        recordStatusChangeEvent();
    }
    
    public boolean exceedsMaxAmount(BigDecimal maxAmount) {
        return amount.compareTo(maxAmount) > 0;
    }
    
    // Hide internal structure
    public List<OrderItem> getRecentItems(int days) {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
        return items.stream()
            .filter(item -> item.getCreatedAt().isAfter(cutoff))
            .collect(toList());
    }
}
```

#### DTO Design
```
// ✅ Simple data transfer object
public record OrderResponse(
    Long id,
    String customerEmail,
    BigDecimal amount,
    OrderStatus status,
    LocalDateTime createdAt
) {
    // Static factory method for clear creation intent
    public static OrderResponse from(Order order) {
        return new OrderResponse(
            order.getId(),
            order.getCustomerEmail(),
            order.getAmount(),
            order.getStatus(),
            order.getCreatedAt()
        );
    }
}
```

## Code Quality Standards

### Class Design Principles

#### Size and Responsibility
- **Small classes**: Prefer classes with single responsibility
- **Minimize instance variables**: Recommended within 5 instance variables
- **High cohesion**: Group related data and methods together

```
// ✅ Good class design example
@UseCase
public class OrderStatusUseCase {
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final NotificationService notificationService;
    
    // Single responsibility: Order status management
    public void checkAndUpdateOrderStatus(Long orderId) {
        Order order = findOrderById(orderId);
        PaymentStatus paymentStatus = getPaymentStatus(orderId);
        OrderStatus newStatus = evaluateStatus(order, paymentStatus);
        
        if (order.getStatus() != newStatus) {
            updateOrderStatus(order, newStatus);
            notifyStatusChange(order, newStatus);
        }
    }
}
```

#### Composition Over Inheritance
```
// ❌ Inheritance overuse
public class PremiumOrder extends Order {
    // Complex inheritance structure
}

// ✅ Composition approach
public class PremiumOrder {
    private final Order baseOrder;
    private final PremiumService premiumService;
    private final LoyaltyProgram loyaltyProgram;
    
    public void applyPremiumBenefits() {
        Benefits benefits = premiumService.calculateBenefits();
        loyaltyProgram.applyPoints(baseOrder, benefits);
    }
}
```

### Testing Standards

#### Test Structure (AAA Pattern)
```
class OrderUseCaseTest {
    
    @Test
    @DisplayName("Order creation should set default status to PENDING")
    void createOrder_ShouldSetDefaultStatusToPending() {
        // Arrange
        CreateOrderRequest request = CreateOrderRequest.builder()
            .customerEmail("test@example.com")
            .amount(BigDecimal.valueOf(100.0))
            .build();
        
        // Act
        Order result = orderUseCase.createOrder(request);
        
        // Assert
        assertThat(result.getStatus()).isEqualTo(OrderStatus.PENDING);
        assertThat(result.getCustomerEmail()).isEqualTo("test@example.com");
        assertThat(result.getAmount()).isEqualByComparingTo(request.getAmount());
    }
    
    @Test
    @DisplayName("Validation should pass with valid data")
    void validateData_ShouldPassWithValidData() {
        // Arrange
        ValidDataRequest validData = ValidDataRequest.builder()
            .measuredTime(LocalDateTime.now().minusHours(1))
            .predictedTime(LocalDateTime.now().plusHours(1))
            .build();
        
        // Act
        ValidationResult result = DataValidator.validateData(validData);
        
        // Assert
        assertThat(result.isValid()).isTrue();
        assertThat(result.getErrors()).isEmpty();
    }
}
```

#### Test Naming Conventions
- **Descriptive display names**: Use clear descriptions that express business requirements
- **Method naming**: Follow `methodName_Condition_ExpectedResult` pattern
- **Meaningful test data**: Use meaningful constants instead of magic numbers

```
class DataAnalysisTest {
    private static final BigDecimal NORMAL_VALUE = BigDecimal.valueOf(25.0);
    private static final BigDecimal HIGH_VALUE = BigDecimal.valueOf(35.0);
    private static final int ANALYSIS_PERIOD_DAYS = 7;
    
    @Test
    @DisplayName("Should create warning notification when average exceeds normal range over 7 days")
    void analyzeData_WhenAverageExceedsNormalRange_ShouldCreateWarningNotification() {
        // Test implementation...
    }
}
```

#### Integration Test Guidelines
```
@IntegrationTest
@Sql(scripts = "/datasets/test-data.sql")
class OrderEndpointIntegrationTest {
    
    @Test
    @DisplayName("Order list retrieval should work correctly with pagination")
    void getOrders_WithPagination_ShouldReturnCorrectPage() {
        // Given
        int pageSize = 5;
        int pageNumber = 1;
        
        // When
        ResponseEntity<PageResult<OrderResponse>> response = 
            restTemplate.exchange(
                "/api/orders?size={size}&page={page}",
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<PageResult<OrderResponse>>() {},
                pageSize, pageNumber
            );
        
        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getContent()).hasSize(pageSize);
        assertThat(response.getBody().hasNext()).isTrue();
    }
}
```

### Performance and Optimization Standards

#### Database Access Optimization
```
// ✅ Solve N+1 problems with fetch joins
@Query("SELECT o FROM Order o " +
       "JOIN FETCH o.items i " +
       "WHERE o.customerId = :customerId " +
       "AND i.createdAt >= :fromDate")
List<Order> findOrdersWithRecentItems(
    @Param("customerId") Long customerId, 
    @Param("fromDate") LocalDateTime fromDate
);

// ✅ Control memory usage with pagination
public PageResult<OrderResponse> getOrdersPaged(
    Long customerId, String cursor, int size) {
    
    Pageable pageable = PageRequest.of(0, size);
    List<Order> orders = repository.findByCustomerIdWithCursor(
        customerId, cursor, pageable
    );
    
    return PageResult.of(
        orders.stream().map(OrderResponse::from).toList(),
        generateNextCursor(orders)
    );
}
```

#### Caching Strategy
```
@Service
public class DataCacheService {
    private static final Duration CACHE_TTL = Duration.ofMinutes(30);
    
    @Cacheable(value = "external-data", key = "#entityId")
    public ExternalData getCurrentData(Long entityId) {
        // External API calls optimized through caching
        return externalClient.fetchCurrentData(entityId);
    }
    
    @CacheEvict(value = "external-data", key = "#entityId")
    public void evictDataCache(Long entityId) {
        // Cache invalidation logic
    }
}
```

### Security and Validation Standards

#### Input Validation
```
public record CreateItemRequest(
    @NotBlank(message = "Name is required")
    @Size(max = 50, message = "Name cannot exceed 50 characters")
    String name,
    
    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be at least 0.01")
    @DecimalMax(value = "10000.0", message = "Amount cannot exceed 10000")
    BigDecimal amount,
    
    @NotNull(message = "Category ID is required")
    @Positive(message = "Category ID must be positive")
    Long categoryId
) {
    // Business rule validation
    public void validate() {
        if (amount.scale() > 2) {
            throw new ValidationException("Amount can only have up to 2 decimal places");
        }
    }
}
```

#### Sensitive Information Protection
```
@Entity
public class User {
    @Column(name = "password")
    @JsonIgnore // Exclude from JSON serialization
    private String encryptedPassword;
    
    @Column(name = "phone_number")
    @JsonSerialize(using = PhoneNumberMaskingSerializer.class) // Apply masking
    private String phoneNumber;
    
    // Prevent sensitive information exposure in logs
    @Override
    public String toString() {
        return String.format("User{id=%d, name='%s'}", id, name);
    }
}
```

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

## Clean Code Principles Summary

### Core Principles
1. **Readability first**: Code is written for humans to read
2. **Pursue simplicity**: Prefer simple solutions over complex ones
3. **Maintain consistency**: Entire team uses the same styles and patterns
4. **Boy Scout rule**: Leave code cleaner than when you found it

### Integration with DDD
- **Ubiquitous language**: Reflect the common language used by domain experts and developers in code
- **Domain-centric design**: Structure code around business domains rather than technology
- **Clear boundaries**: Clearly distinguish responsibilities and boundaries between domains and layers
- **Event-driven thinking**: Model important occurrences in the domain as events

Apply these Clean Code principles together with DDD architecture to build maintainable and extensible codebases.