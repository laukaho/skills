# Code Review Examples

## Example 1: Bug Detection

```typescript
// PR Code
function processUsers(users: User[]) {
  const results = [];
  for (let i = 0; i <= users.length; i++) {  // Bug here
    results.push(transform(users[i]));
  }
  return results;
}
```

### Review Comment

**[CRITICAL]** Array index out of bounds
- **Line(s):** 3
- **Issue:** Loop uses `<=` instead of `<`, causing undefined access on final iteration
- **Suggestion:** Change to `i < users.length`
- **Impact:** Throws runtime error when processing any user list

---

## Example 2: Code Smell

```python
# PR Code
def calculate_price(order):
    if order.type == 'domestic':
        base = order.amount * 1.05
        if order.customer.vip:
            return base * 0.9
        return base
    elif order.type == 'international':
        base = order.amount * 1.15
        if order.customer.vip:
            return base * 0.9
        return base
    elif order.type == 'wholesale':
        base = order.amount * 1.02
        if order.customer.vip:
            return base * 0.9
        return base
```

### Review Comment

**[WARNING]** Duplicated VIP discount logic and similar structure
- **Line(s):** 4-5, 9-10, 14-15
- **Issue:** VIP discount repeated 3 times. Adding new order types requires copy-pasting
- **Suggestion:** Extract strategy pattern or lookup table:
```python
TAX_RATES = {'domestic': 1.05, 'international': 1.15, 'wholesale': 1.02}

def calculate_price(order):
    base = order.amount * TAX_RATES[order.type]
    return base * 0.9 if order.customer.vip else base
```
- **Reference:** DRY principle, Strategy pattern

---

## Example 3: API Design

```csharp
// PR Code
public class DataService
{
    public async Task<string> GetData(int id, bool quick)
    {
        if (quick)
        {
            return await _cache.GetAsync(id);
        }
        return await _db.QueryAsync(id);
    }
}
```

### Review Comment

**[WARNING]** Unclear boolean parameter
- **Line(s):** 3, 5
- **Issue:** Caller sees `GetData(42, true)` with no context on what `true` means
- **Suggestion:** Split into explicit methods or use enum:
```csharp
public async Task<string> GetDataFromCacheAsync(int id) { }
public async Task<string> GetDataFromDatabaseAsync(int id) { }
```
- **Reference:** [Google C# Style - Method Overloading](https://google.github.io/styleguide/csharp-style.html)

---

## Example 4: Performance

```cpp
// PR Code
std::vector<std::string> process_logs(const std::vector<std::string>& logs) {
    std::vector<std::string> results;
    for (const auto& log : logs) {
        std::string processed;
        for (size_t i = 0; i < log.size(); i++) {
            processed += log[i];  // O(n²) allocation
        }
        results.push_back(processed);
    }
    return results;
}
```

### Review Comment

**[WARNING]** Quadratic string concatenation in hot path
- **Line(s):** 6
- **Issue:** `processed +=` reallocates string each iteration. For 10KB logs, this is ~50MB of allocations
- **Suggestion:** Reserve capacity or use `std::ostringstream`:
```cpp
std::string processed;
processed.reserve(log.size());
// ... or use std::copy
```
- **Impact:** 100x speedup for large log processing

---

## Example 5: Architecture

```typescript
// PR Code - mixing concerns
class UserController {
  async createUser(req: Request) {
    const user = new User(req.body);
    await user.save();
    await EmailService.sendWelcomeEmail(user.email);
    await AnalyticsService.trackSignup(user.id);
    await NotificationService.notifyAdmins('new_user');
    return user;
  }
}
```

### Review Comment

**[SUGGESTION]** Controller has too many responsibilities
- **Line(s):** 1-10
- **Issue:** Controller directly calls 3 external services. Hard to test, violates SRP
- **Suggestion:** Extract use case or domain service:
```typescript
class CreateUserUseCase {
  constructor(
    private userRepo: UserRepository,
    private eventBus: EventBus
  ) {}
  
  async execute(data: UserData) {
    const user = await this.userRepo.save(data);
    await this.eventBus.publish(new UserCreatedEvent(user));
    return user;
  }
}
```
- **Benefit:** Services react to events, controller stays thin

---

## Example 6: Security

```python
# PR Code
@app.route('/search')
def search():
    query = request.args.get('q')
    results = db.execute(f"SELECT * FROM items WHERE name = '{query}'")
    return jsonify(results)
```

### Review Comment

**[CRITICAL]** SQL Injection vulnerability
- **Line(s):** 4
- **Issue:** Direct string interpolation into SQL query
- **Suggestion:** Use parameterized queries:
```python
results = db.execute("SELECT * FROM items WHERE name = %s", (query,))
```
- **Impact:** Attacker can extract/destroy entire database
- **Reference:** OWASP SQL Injection

---

## Review Summary Template

```markdown
## Review Summary

**Files reviewed:** 12
**Issues found:** 8 (2 CRITICAL, 3 WARNING, 3 SUGGESTION)

### Must Fix Before Merge
- [ ] SQL injection in search.py:42 [CRITICAL]
- [ ] Array bounds in process.ts:15 [CRITICAL]

### Should Fix
- [ ] Duplicate logic in pricing.py [WARNING]
- [ ] Boolean parameter ambiguity in DataService.cs [WARNING]

### Optional Improvements
- [ ] Extract UserController use case [SUGGESTION]
- [ ] String concatenation optimization [SUGGESTION]

### Praise
- Good test coverage on the new auth module
- Clean error handling in the payment flow
```