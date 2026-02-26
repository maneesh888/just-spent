# Lazy Loading & Pagination Feature

## 🎯 Quick Overview

This feature adds **lazy loading and pagination** to expense lists in Just Spent, significantly improving performance for users with many expenses.

### Problem
- Currently loads **ALL expenses** at once
- Slow initial load with 1000+ expenses (~1-2s)
- High memory usage (~100MB+ for large lists)
- Potential UI lag when scrolling

### Solution
- Load expenses in **pages of 20 items**
- Fetch more as user scrolls
- Reduce memory footprint by 50%+
- Improve initial load time to < 500ms

---

## 📚 Documentation

### Primary Documents

1. **[LAZY-LOADING-PAGINATION-SPEC.md](docs/LAZY-LOADING-PAGINATION-SPEC.md)**
   - Complete technical specification
   - Architecture diagrams
   - Implementation details
   - Test specifications

2. **[PAGINATION-IMPLEMENTATION-TRACKER.md](docs/PAGINATION-IMPLEMENTATION-TRACKER.md)**
   - Implementation progress tracker
   - File checklist
   - Test checklist
   - Performance targets

---

## 🧪 Test-Driven Development Approach

This feature follows **strict TDD principles**:

### Phase 1: RED (Write Failing Tests)
- ✅ Documentation complete
- ⏳ Write 24 tests (12 iOS + 12 Android)
- ⏳ Verify all tests fail (expected)

### Phase 2: GREEN (Implement Code)
- ⏳ Implement pagination logic
- ⏳ Make all tests pass
- ⏳ No premature optimization

### Phase 3: REFACTOR (Optimize)
- ⏳ Clean up code
- ⏳ Optimize performance
- ⏳ Keep tests passing

---

## 📊 Expected Improvements

### Load Time Improvements

| Expense Count | Current | Target | Improvement |
|---------------|---------|--------|-------------|
| 0-50 | ~100ms | ~50ms | **50% faster** |
| 51-500 | ~500ms | ~200ms | **60% faster** |
| 501-2000 | ~2s | ~500ms | **75% faster** |
| 2001+ | ~5s+ | ~500ms | **90% faster** |

### Memory Usage Improvements

| Expense Count | Current | Target | Improvement |
|---------------|---------|--------|-------------|
| 50 | ~20MB | ~15MB | **25% reduction** |
| 500 | ~80MB | ~40MB | **50% reduction** |
| 2000 | ~200MB | ~50MB | **75% reduction** |
| 5000+ | ~500MB+ | ~60MB | **88% reduction** |

---

## 🏗️ Implementation Strategy

### iOS
- **Custom pagination manager** for state management
- **Core Data** queries with LIMIT/OFFSET
- **SwiftUI** `.onAppear()` for scroll detection

### Android
- **Jetpack Paging 3** (industry standard)
- **Room** DAO with paginated queries
- **Compose** `collectAsLazyPagingItems()`

### Configuration
```yaml
page_size: 20          # Items per page
initial_load: 20       # First page size
prefetch_distance: 5   # Load when 5 from end
max_cache_size: 100    # Max in-memory items
```

---

## 📁 Key Files

### Documentation
- `docs/LAZY-LOADING-PAGINATION-SPEC.md` - Full specification
- `docs/PAGINATION-IMPLEMENTATION-TRACKER.md` - Progress tracker
- `PAGINATION-README.md` - This file

### iOS Implementation
- `ios/JustSpent/JustSpent/Services/ExpensePaginationManager.swift` (new)
- `ios/JustSpent/JustSpent/Services/ExpenseDataService+Pagination.swift` (new)
- `ios/JustSpent/JustSpent/Views/CurrencyExpenseListView.swift` (modify)

### Android Implementation
- `android/app/src/main/java/com/justspent/expense/data/paging/ExpensePagingSource.kt` (new)
- `android/app/src/main/java/com/justspent/expense/data/dao/ExpenseDao.kt` (modify)
- `android/app/src/main/java/com/justspent/expense/data/repository/ExpenseRepository.kt` (modify)
- `android/app/src/main/java/com/justspent/expense/ui/expenses/CurrencyExpenseListScreen.kt` (modify)

### Tests
- **iOS:** 8 unit tests + 4 UI tests
- **Android:** 8 unit tests + 4 UI tests
- **Total:** 24 tests

---

## 🚦 Current Status

**Phase:** 🔴 RED (Write Failing Tests)
**Branch:** `claude/add-lazy-loading-pagination-01BoS15CruSkHX5PRwUD5hnA`

### Completed
- ✅ Feature specification document
- ✅ Implementation tracker
- ✅ TODO list created

### In Progress
- ⏳ Writing iOS unit tests
- ⏳ Writing Android unit tests

### Next Steps
1. Write iOS unit tests (8 tests)
2. Write iOS UI tests (4 tests)
3. Write Android unit tests (8 tests)
4. Write Android UI tests (4 tests)
5. Verify all tests fail
6. Begin implementation (GREEN phase)

---

## 🎓 Learning Resources

### iOS Pagination
- [Core Data Fetching](https://developer.apple.com/documentation/coredata/nsfetchrequest)
- [SwiftUI List Performance](https://developer.apple.com/documentation/swiftui/list)

### Android Pagination
- [Jetpack Paging 3](https://developer.android.com/topic/libraries/architecture/paging/v3-overview)
- [Paging with Compose](https://developer.android.com/jetpack/compose/lists#large-datasets)

### TDD Resources
- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [iOS Testing](https://developer.apple.com/documentation/xctest)
- [Android Testing](https://developer.android.com/training/testing)

---

## 💡 Tips for Implementation

1. **Follow TDD strictly** - Tests first, code second
2. **Keep tests focused** - One assertion per test
3. **Use descriptive names** - Test names should explain behavior
4. **Run tests frequently** - After every small change
5. **Commit often** - Small, focused commits

---

## 🆘 Need Help?

### Common Issues
- **Tests not compiling:** Check dependency imports
- **Pagination not triggering:** Verify scroll detection logic
- **Memory issues:** Check cache size configuration
- **Slow tests:** Use test data with fewer items

### Resources
- Feature Spec: `docs/LAZY-LOADING-PAGINATION-SPEC.md`
- Implementation Tracker: `docs/PAGINATION-IMPLEMENTATION-TRACKER.md`
- Testing Guide: `TESTING-GUIDE.md`
- Development Guide: `CLAUDE.md`

---

## ✅ Definition of Done

- [ ] All 24 tests passing
- [ ] Code coverage ≥ 85%
- [ ] Performance targets met
- [ ] Memory usage within targets
- [ ] Documentation updated
- [ ] Code review approved
- [ ] CI/CD passing

---

## 🎉 Success Criteria

This feature will be considered successful when:

1. **Performance:** Initial load < 500ms for any list size
2. **Memory:** < 60MB usage regardless of total expense count
3. **UX:** Smooth 60 FPS scrolling with no perceived lag
4. **Quality:** All tests passing with ≥ 85% coverage
5. **Reliability:** No crashes or data loss during pagination

---

**Ready to start?** Begin with Phase 1: Write failing tests! 🚀

**Branch:** `claude/add-lazy-loading-pagination-01BoS15CruSkHX5PRwUD5hnA`
**Next:** Create `ios/JustSpent/JustSpentTests/ExpensePaginationTests.swift`
