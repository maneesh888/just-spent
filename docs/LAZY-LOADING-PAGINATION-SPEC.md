# Lazy Loading & Pagination Feature Specification

## 📋 Document Information

**Feature Name:** Lazy Loading & Pagination for Expense Lists
**Version:** 1.0.0
**Date:** December 3, 2025
**Status:** 📝 Planning Phase
**Branch:** `claude/add-lazy-loading-pagination-01BoS15CruSkHX5PRwUD5hnA`
**Approach:** Test-Driven Development (TDD)

---

## 🎯 Feature Overview

### Problem Statement

Currently, the Just Spent app loads **all expenses** from the database at once when displaying expense lists. This can cause performance issues as the number of expenses grows:

- **Memory overhead**: All expense objects loaded into memory simultaneously
- **Initial load time**: Slow first render when thousands of expenses exist
- **UI responsiveness**: Potential lag when scrolling through large lists
- **Battery drain**: Unnecessary processing of off-screen items

### Goals

1. **Improve initial load performance** by limiting initial data fetch
2. **Reduce memory footprint** by loading expenses incrementally
3. **Maintain smooth scrolling** experience during pagination
4. **Preserve existing functionality** (filtering, deletion, currency separation)
5. **Follow TDD principles** with comprehensive test coverage

### Success Metrics

- Initial load time: **< 500ms** (down from current ~1-2s for 1000+ expenses)
- Memory usage: **< 50MB** for expense list (down from current ~100MB+)
- Scroll performance: **60 FPS** maintained during pagination
- User experience: **No perceived lag** when scrolling
- Test coverage: **≥ 85%** for new pagination code

---

## 📐 Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   UI Layer                          │
│  ┌──────────────────────────────────────────────┐   │
│  │  CurrencyExpenseListView (iOS)               │   │
│  │  CurrencyExpenseListScreen (Android)         │   │
│  │  - Displays paginated expenses               │   │
│  │  - Triggers load more on scroll              │   │
│  │  - Shows loading indicators                  │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                ViewModel / Logic Layer              │
│  ┌──────────────────────────────────────────────┐   │
│  │  ExpenseListViewModel (Android)              │   │
│  │  ExpenseFetchManager (iOS)                   │   │
│  │  - Manages pagination state                  │   │
│  │  - Triggers repository fetches               │   │
│  │  - Combines paginated results                │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│              Repository / Data Layer                │
│  ┌──────────────────────────────────────────────┐   │
│  │  ExpenseRepository (Android)                 │   │
│  │  ExpenseDataService (iOS)                    │   │
│  │  - Queries database with LIMIT/OFFSET        │   │
│  │  - Returns paginated results                 │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                 Database Layer                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Room Database (Android)                     │   │
│  │  Core Data (iOS)                             │   │
│  │  - Paged queries with offset                 │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Pagination Strategy

#### Configuration

```yaml
page_size: 20  # Number of expenses per page
initial_load: 20  # First page size
prefetch_distance: 5  # Load next page when 5 items from end
max_cache_size: 100  # Maximum items to keep in memory
```

#### Flow Diagram

```
User Opens Expense List
    ↓
Load Initial Page (20 items)
    ↓
Display Expenses + Loading Indicator
    ↓
User Scrolls Down
    ↓
Detect Scroll Position
    ├─ Within Last 5 Items?
    │   ↓ YES
    │   Load Next Page (20 more)
    │   ↓
    │   Append to List
    │   ↓
    │   Hide Loading Indicator
    │
    └─ NO: Continue Scrolling
```

---

## 🧪 Test-Driven Development Plan

### Phase 1: RED - Write Failing Tests

#### iOS Unit Tests

**File:** `ios/JustSpent/JustSpentTests/ExpensePaginationTests.swift`

Tests to write:
1. `testInitialPageLoad_loads20Expenses()`
2. `testLoadNextPage_appendsNextPageExpenses()`
3. `testPagination_respectsCurrencyFilter()`
4. `testPagination_respectsDateFilter()`
5. `testEndOfList_doesNotLoadMore()`
6. `testLoadingState_updatesCorrectly()`
7. `testErrorHandling_pagination()`
8. `testMemoryManagement_doesNotExceedCache()`

**File:** `ios/JustSpent/JustSpentUITests/ExpensePaginationUITests.swift`

UI Tests to write:
1. `testScrollToBottom_triggersNextPageLoad()`
2. `testLoadingIndicator_showsWhileLoading()`
3. `testPaginatedList_maintainsSmoothScrolling()`
4. `testFilterChange_resetsAndPaginates()`

#### Android Unit Tests

**File:** `android/app/src/test/java/com/justspent/expense/ExpensePaginationTest.kt`

Tests to write:
1. `initialPageLoad_loads20Expenses()`
2. `loadNextPage_appendsNextPageExpenses()`
3. `pagination_respectsCurrencyFilter()`
4. `pagination_respectsDateFilter()`
5. `endOfList_doesNotLoadMore()`
6. `loadingState_updatesCorrectly()`
7. `errorHandling_pagination()`
8. `memoryManagement_doesNotExceedCache()`

**File:** `android/app/src/androidTest/kotlin/com/justspent/expense/ExpensePaginationUITest.kt`

UI Tests to write:
1. `scrollToBottom_triggersNextPageLoad()`
2. `loadingIndicator_showsWhileLoading()`
3. `paginatedList_maintainsSmoothScrolling()`
4. `filterChange_resetsAndPaginates()`

### Phase 2: GREEN - Implement Minimal Code

#### iOS Implementation Files

1. **ExpensePaginationManager.swift**
   - Manages pagination state (current page, has more, loading)
   - Coordinates fetch requests
   - Maintains in-memory cache

2. **ExpenseDataService+Pagination.swift**
   - Extension with paginated fetch methods
   - Core Data queries with LIMIT/OFFSET

3. **CurrencyExpenseListView+Pagination.swift**
   - Updated view with pagination support
   - Scroll detection logic
   - Loading indicator UI

#### Android Implementation Files

1. **ExpensePagingSource.kt**
   - Jetpack Paging 3 PagingSource implementation
   - Handles load requests with keys

2. **ExpenseRepository+Pagination.kt**
   - Paginated Flow methods
   - Pager configuration

3. **ExpenseListViewModel+Pagination.kt**
   - PagingData management
   - State updates

4. **CurrencyExpenseListScreen+Pagination.kt**
   - LazyPagingItems integration
   - Loading state composables

### Phase 3: REFACTOR - Optimize & Clean

- Extract common pagination logic
- Add comprehensive error handling
- Optimize memory management
- Improve loading indicators
- Add analytics tracking

---

## 🛠️ Implementation Details

### iOS Implementation

#### 1. Core Data Query with Pagination

```swift
// ExpenseDataService+Pagination.swift
extension ExpenseDataService {
    func fetchExpenses(
        currency: String,
        dateFilter: DateFilter,
        page: Int,
        pageSize: Int = 20
    ) async throws -> [Expense] {
        let offset = page * pageSize

        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "currency == %@", currency)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)
        ]
        request.fetchLimit = pageSize
        request.fetchOffset = offset

        return try viewContext.fetch(request)
    }
}
```

#### 2. Pagination Manager

```swift
// ExpensePaginationManager.swift
@MainActor
class ExpensePaginationManager: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var hasMore = true

    private var currentPage = 0
    private let pageSize = 20

    func loadInitialPage(currency: String, dateFilter: DateFilter) async {
        currentPage = 0
        expenses = []
        await loadNextPage(currency: currency, dateFilter: dateFilter)
    }

    func loadNextPage(currency: String, dateFilter: DateFilter) async {
        guard !isLoading && hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newExpenses = try await dataService.fetchExpenses(
                currency: currency,
                dateFilter: dateFilter,
                page: currentPage,
                pageSize: pageSize
            )

            if newExpenses.count < pageSize {
                hasMore = false
            }

            expenses.append(contentsOf: newExpenses)
            currentPage += 1
        } catch {
            print("Pagination error: \(error)")
        }
    }

    func shouldLoadMore(currentItem: Expense) -> Bool {
        guard let index = expenses.firstIndex(where: { $0.id == currentItem.id }) else {
            return false
        }
        return index >= expenses.count - 5
    }
}
```

#### 3. Updated SwiftUI View

```swift
// CurrencyExpenseListView+Pagination.swift
struct CurrencyExpenseListView: View {
    @StateObject private var paginationManager = ExpensePaginationManager()

    var body: some View {
        List {
            ForEach(paginationManager.expenses, id: \.id) { expense in
                CurrencyExpenseRowView(expense: expense, currency: currency)
                    .onAppear {
                        if paginationManager.shouldLoadMore(currentItem: expense) {
                            Task {
                                await paginationManager.loadNextPage(
                                    currency: currency.code,
                                    dateFilter: dateFilter
                                )
                            }
                        }
                    }
            }

            if paginationManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .task {
            await paginationManager.loadInitialPage(
                currency: currency.code,
                dateFilter: dateFilter
            )
        }
    }
}
```

### Android Implementation

#### 1. Room DAO with Pagination

```kotlin
// ExpenseDao.kt - Add paginated queries
@Dao
interface ExpenseDao {
    @Query("""
        SELECT * FROM expenses
        WHERE user_id = :userId
        AND currency = :currency
        ORDER BY transaction_date DESC
        LIMIT :limit OFFSET :offset
    """)
    suspend fun getExpensesPaginated(
        userId: String = "default_user",
        currency: String,
        limit: Int,
        offset: Int
    ): List<Expense>

    @Query("""
        SELECT COUNT(*) FROM expenses
        WHERE user_id = :userId
        AND currency = :currency
    """)
    suspend fun getExpensesCount(
        userId: String = "default_user",
        currency: String
    ): Int
}
```

#### 2. Paging Source

```kotlin
// ExpensePagingSource.kt
class ExpensePagingSource(
    private val expenseDao: ExpenseDao,
    private val currency: String,
    private val dateFilter: DateFilter
) : PagingSource<Int, Expense>() {

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, Expense> {
        return try {
            val page = params.key ?: 0
            val pageSize = params.loadSize
            val offset = page * pageSize

            val expenses = expenseDao.getExpensesPaginated(
                currency = currency,
                limit = pageSize,
                offset = offset
            ).filter { expense ->
                DateFilterUtils.isDateInFilter(expense.transactionDate, dateFilter)
            }

            LoadResult.Page(
                data = expenses,
                prevKey = if (page == 0) null else page - 1,
                nextKey = if (expenses.isEmpty()) null else page + 1
            )
        } catch (e: Exception) {
            LoadResult.Error(e)
        }
    }

    override fun getRefreshKey(state: PagingState<Int, Expense>): Int? {
        return state.anchorPosition?.let { anchorPosition ->
            state.closestPageToPosition(anchorPosition)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(anchorPosition)?.nextKey?.minus(1)
        }
    }
}
```

#### 3. Repository Update

```kotlin
// ExpenseRepository+Pagination.kt
fun getExpensesPaginated(currency: String, dateFilter: DateFilter): Flow<PagingData<Expense>> {
    return Pager(
        config = PagingConfig(
            pageSize = 20,
            initialLoadSize = 20,
            prefetchDistance = 5,
            enablePlaceholders = false
        ),
        pagingSourceFactory = {
            ExpensePagingSource(expenseDao, currency, dateFilter)
        }
    ).flow
}
```

#### 4. ViewModel Update

```kotlin
// ExpenseListViewModel+Pagination.kt
@HiltViewModel
class ExpenseListViewModel @Inject constructor(
    private val repository: ExpenseRepository
) : ViewModel() {

    private val _selectedCurrency = MutableStateFlow(Currency.AED)
    private val _dateFilter = MutableStateFlow(DateFilter.ALL)

    val expensesPaginated: StateFlow<PagingData<Expense>> = combine(
        _selectedCurrency,
        _dateFilter
    ) { currency, filter ->
        Pair(currency, filter)
    }.flatMapLatest { (currency, filter) ->
        repository.getExpensesPaginated(currency.code, filter)
    }.cachedIn(viewModelScope)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = PagingData.empty()
        )
}
```

#### 5. Updated Composable

```kotlin
// CurrencyExpenseListScreen+Pagination.kt
@Composable
fun CurrencyExpenseListScreen(
    currency: Currency,
    dateFilter: DateFilter,
    onDateFilterChanged: (DateFilter) -> Unit,
    viewModel: ExpenseListViewModel = hiltViewModel()
) {
    val lazyPagingItems = viewModel.expensesPaginated.collectAsLazyPagingItems()

    Column(modifier = Modifier.fillMaxSize()) {
        if (lazyPagingItems.itemCount > 0) {
            FilterStrip(
                selectedFilter = dateFilter,
                onFilterSelected = onDateFilterChanged
            )
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(
                count = lazyPagingItems.itemCount,
                key = lazyPagingItems.itemKey { it.id }
            ) { index ->
                val expense = lazyPagingItems[index]
                expense?.let {
                    CurrencyExpenseRow(
                        expense = it,
                        currency = currency,
                        onDelete = { viewModel.deleteExpense(it) }
                    )
                }
            }

            lazyPagingItems.apply {
                when {
                    loadState.refresh is LoadState.Loading -> {
                        item {
                            LoadingIndicator()
                        }
                    }
                    loadState.append is LoadState.Loading -> {
                        item {
                            LoadingIndicator()
                        }
                    }
                    loadState.refresh is LoadState.Error -> {
                        item {
                            ErrorMessage(
                                message = "Failed to load expenses",
                                onRetry = { retry() }
                            )
                        }
                    }
                }
            }
        }
    }
}
```

---

## 🎨 UI/UX Improvements

### Loading Indicators

#### iOS
- **Top loading**: Subtle progress bar at top of list during initial load
- **Bottom loading**: Spinner at bottom when loading next page
- **Skeleton loading**: Optional shimmer effect for first load

#### Android
- **Material 3 CircularProgressIndicator**: Bottom of list during pagination
- **Pull-to-refresh**: SwipeRefresh for manual reload
- **Error states**: Retry button with error message

### Empty States

- **No expenses**: Existing empty state preserved
- **Loading first page**: Show skeleton items
- **End of list**: "You've reached the end" message

### Performance Optimizations

1. **Virtualization**: Only render visible + buffer items
2. **Image caching**: Cache merchant logos if added
3. **Lazy evaluation**: Defer formatting until needed
4. **Memory limits**: Clear old pages when cache full

---

## 📊 Performance Benchmarks

### Test Scenarios

| Scenario | Expense Count | Current Load Time | Target Load Time |
|----------|---------------|-------------------|------------------|
| Small | 0-50 | ~100ms | ~50ms |
| Medium | 51-500 | ~500ms | ~200ms |
| Large | 501-2000 | ~2s | ~500ms |
| Very Large | 2001+ | ~5s+ | ~500ms |

### Memory Usage

| Scenario | Current Memory | Target Memory |
|----------|----------------|---------------|
| Small (50) | ~20MB | ~15MB |
| Medium (500) | ~80MB | ~40MB |
| Large (2000) | ~200MB | ~50MB |
| Very Large (5000+) | ~500MB+ | ~60MB |

---

## 🔄 Migration Strategy

### Phase 1: Add Pagination (Feature Flag)
- Implement pagination alongside existing code
- Add feature flag to toggle pagination
- Test thoroughly in development

### Phase 2: Beta Testing
- Enable for internal testers
- Monitor performance metrics
- Collect feedback

### Phase 3: Gradual Rollout
- Enable for 10% of users
- Monitor crash reports
- Increase to 50%, then 100%

### Phase 4: Remove Legacy Code
- Remove old non-paginated code
- Clean up feature flags
- Update documentation

---

## ✅ Definition of Done

- [ ] All unit tests passing (≥ 85% coverage)
- [ ] All UI tests passing
- [ ] iOS pagination implemented and tested
- [ ] Android pagination implemented and tested
- [ ] Performance benchmarks met
- [ ] Memory usage within targets
- [ ] Code review completed
- [ ] Documentation updated
- [ ] TESTING-GUIDE.md updated with pagination tests
- [ ] CLAUDE.md updated with pagination patterns

---

## 📚 Related Documentation

- `data-models-spec.md` - Database schema and queries
- `ui-design-spec.md` - UI component specifications
- `TESTING-GUIDE.md` - Testing strategies
- `CLAUDE.md` - Development standards

---

## 🔮 Future Enhancements

1. **Intelligent prefetching**: Predict scroll direction and prefetch
2. **Cursor-based pagination**: More efficient than offset-based
3. **Virtual scrolling**: Render only visible items
4. **Progressive image loading**: Load images on demand
5. **Adaptive page size**: Adjust based on device performance

---

**Document Status:** ✅ Ready for Implementation
**Next Steps:** Begin TDD Phase 1 - Write Failing Tests

---

*This specification follows TDD principles and ensures comprehensive planning before implementation.*
