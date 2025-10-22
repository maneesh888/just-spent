# Just Spent - Cross-Platform Architecture Overview

## Project Structure

This document provides an overview of the architectural organization for both iOS and Android applications.

## Unified Architecture Principles

Both iOS and Android implementations follow **Clean Architecture** with platform-specific MVVM patterns:

- **iOS**: MVVM with SwiftUI
- **Android**: MVVM with Jetpack Compose

## Common Architecture Layers

```
┌─────────────────────────────────────────┐
│       Presentation Layer                │
│    (UI, ViewModels, Screens)           │
│                                         │
│  iOS: SwiftUI Views + ViewModels       │
│  Android: Compose Screens + ViewModels │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Domain Layer                    │
│   (Business Logic, Use Cases)          │
│                                         │
│  Shared concepts, platform-specific    │
│  implementations                        │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          Data Layer                     │
│   (Repositories, Data Sources)         │
│                                         │
│  iOS: Core Data                        │
│  Android: Room Database                │
└─────────────────────────────────────────┘
```

## Directory Structure Comparison

### iOS Structure
```
ios/JustSpent/JustSpent/
├── Presentation/
│   ├── Views/
│   │   ├── Expenses/
│   │   ├── Components/
│   │   └── Voice/
│   └── ViewModels/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   └── Interfaces/
├── Data/
│   ├── Repositories/
│   ├── CoreData/
│   └── Persistence/
├── Common/
│   ├── Extensions/
│   ├── Utilities/
│   ├── Constants/
│   └── LocalizedStrings.swift
├── Resources/
│   └── Localizable.strings
└── Siri/
    ├── Intent/
    └── Shortcuts/
```

### Android Structure
```
android/app/src/main/
├── java/com/justspent/app/
│   ├── ui/
│   │   ├── expenses/
│   │   ├── components/
│   │   └── voice/
│   ├── viewmodel/
│   ├── domain/
│   │   ├── model/
│   │   ├── usecase/
│   │   └── repository/
│   ├── data/
│   │   ├── repository/
│   │   ├── database/
│   │   └── dao/
│   ├── util/
│   │   └── VoiceCommandParser.kt
│   └── constants/
│       └── AppConstants.kt
└── res/
    └── values/
        └── strings.xml
```

## Shared Concepts

### 1. String Localization

Both platforms centralize strings for easy localization:

**iOS**: `Localizable.strings` + `LocalizedStrings.swift`
```swift
// Usage
Text(LocalizedStrings.appTitle)
```

**Android**: `strings.xml` + String Resources
```kotlin
// Usage
Text(stringResource(R.string.app_name))
```

### 2. Constants Management

Both platforms use dedicated constants files:

**iOS**: `AppConstants.swift`
```swift
let category = AppConstants.Category.foodDining
```

**Android**: `AppConstants.kt`
```kotlin
val category = AppConstants.Category.FOOD_DINING
```

### 3. Voice Command Processing

Both platforms have dedicated voice parsing utilities:

**iOS**: `VoiceCommandParser.swift`
```swift
let parser = VoiceCommandParser.shared
let result = parser.parseExpenseCommand(command)
```

**Android**: `VoiceCommandParser.kt`
```kotlin
val parser = VoiceCommandParser
val result = parser.parseExpenseCommand(command)
```

## Category Mappings (Cross-Platform)

Both platforms use identical category keywords for consistency:

1. **Food & Dining**: food, tea, coffee, lunch, dinner, restaurant, etc.
2. **Grocery**: grocery, groceries, supermarket, market, etc.
3. **Transportation**: gas, fuel, taxi, uber, parking, etc.
4. **Shopping**: shopping, clothes, store, mall, purchase, etc.
5. **Entertainment**: movie, cinema, concert, games, etc.
6. **Bills & Utilities**: bill, rent, utility, electricity, internet, etc.
7. **Healthcare**: doctor, hospital, medicine, pharmacy, etc.
8. **Education**: education, school, course, training, books, etc.
9. **Other**: Default fallback category

## Voice Integration

### iOS - Siri Integration
- **SiriKit** for intent handling
- **App Shortcuts** for quick actions
- **User Activities** for Spotlight suggestions
- Native speech recognition with auto-stop detection

### Android - Google Assistant Integration
- **App Actions** for voice commands
- **Deep Links** for navigation
- **Shortcuts API** for quick actions
- Native speech recognition with auto-stop detection

## Data Models (Platform Comparison)

### Expense Entity

**iOS (Core Data)**:
```swift
@NSManaged public var id: UUID
@NSManaged public var amount: NSDecimalNumber
@NSManaged public var currency: String
@NSManaged public var category: String
@NSManaged public var merchant: String?
@NSManaged public var transactionDate: Date
@NSManaged public var source: String
@NSManaged public var voiceTranscript: String?
```

**Android (Room)**:
```kotlin
@Entity(tableName = "expenses")
data class Expense(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "amount") val amount: BigDecimal,
    @ColumnInfo(name = "currency") val currency: String,
    @ColumnInfo(name = "category") val category: Category,
    @ColumnInfo(name = "merchant") val merchant: String?,
    @ColumnInfo(name = "transaction_date") val transactionDate: LocalDateTime,
    @ColumnInfo(name = "source") val source: ExpenseSource,
    @ColumnInfo(name = "voice_transcript") val voiceTranscript: String?
)
```

## Testing Strategy (Cross-Platform)

### Unit Tests
- ViewModel logic testing
- Repository operations
- Voice command parsing
- Utility functions

### Integration Tests
- ViewModel + Repository
- Database operations
- Voice flow end-to-end

### UI Tests
- Critical user journeys
- Voice recording flow
- Permission handling

## Best Practices (Both Platforms)

### 1. Use Localized Strings
❌ **Bad**: Hardcoded strings
```swift
Text("Just Spent")  // iOS
Text("Just Spent")  // Android
```

✅ **Good**: Localized strings
```swift
Text(LocalizedStrings.appTitle)  // iOS
Text(stringResource(R.string.app_name))  // Android
```

### 2. Use Constants
❌ **Bad**: Magic strings/values
```swift
let category = "Food & Dining"
```

✅ **Good**: Constants
```swift
let category = AppConstants.Category.foodDining  // iOS
val category = AppConstants.Category.FOOD_DINING  // Android
```

### 3. Extract Business Logic
❌ **Bad**: Logic in Views
```swift
// Inline parsing in View
let amount = parseAmount(from: text)
```

✅ **Good**: Dedicated utilities
```swift
let result = VoiceCommandParser.shared.parseExpenseCommand(text)
```

### 4. Dependency Injection
✅ **Good**: Constructor injection
```swift
// iOS
init(repository: ExpenseRepositoryProtocol = ExpenseRepository())

// Android
class ExpenseViewModel @Inject constructor(
    private val repository: ExpenseRepository
)
```

## Migration Checklist

When refactoring existing code:

- [ ] Replace all hardcoded strings with localized resources
- [ ] Replace magic values with constants
- [ ] Extract voice parsing to VoiceCommandParser
- [ ] Organize files into proper architecture folders
- [ ] Use dependency injection for repositories
- [ ] Implement proper error handling
- [ ] Add comprehensive tests
- [ ] Update documentation

## String Resource Keys (Cross-Platform Mapping)

| Category | iOS Key | Android Key |
|----------|---------|-------------|
| App Title | `app.title` | `app_name` |
| App Subtitle | `app.subtitle` | `app_subtitle` |
| No Expenses | `emptyState.noExpenses` | `empty_state_no_expenses` |
| Voice Listening | `voice.listening` | `voice_listening` |
| Grant Permissions | `button.grantPermissions` | `button_grant_permissions` |
| Food & Dining | `category.foodDining` | `category_food_dining` |

*Note: iOS uses dot notation, Android uses underscore notation following platform conventions*

## Development Workflow

### Adding a New Feature

1. **Define strings** in both `Localizable.strings` (iOS) and `strings.xml` (Android)
2. **Update constants** in `AppConstants.swift` / `AppConstants.kt`
3. **Create domain models** in respective `Domain/Models` folders
4. **Implement use cases** if complex business logic required
5. **Create repository methods** in `Data/Repositories`
6. **Build ViewModels** in `Presentation/ViewModels`
7. **Create UI** in `Presentation/Views` (iOS) or `ui/` (Android)
8. **Add tests** for all layers
9. **Update documentation**

## Performance Considerations

### iOS
- Use `@Published` and `@State` appropriately
- Lazy load Core Data relationships
- Optimize SwiftUI view updates
- Background processing for voice recognition

### Android
- Use `StateFlow` and `LiveData` appropriately
- Lazy load Room relationships
- Optimize Compose recomposition
- Background processing with WorkManager

## Security

- Encrypt sensitive data at rest
- Never log personal information in production
- Validate all user inputs
- Secure voice transcripts
- Follow platform security best practices

## Documentation

### iOS Documentation
- See `/ios/ARCHITECTURE.md` for detailed iOS architecture
- See `/ios-siri-integration.md` for Siri integration details

### Android Documentation
- See `/android-assistant-integration.md` for Assistant integration details

## Contributing

When contributing to either platform:

1. Follow the established architecture patterns
2. Use centralized strings and constants
3. Write comprehensive tests
4. Update documentation
5. Ensure cross-platform consistency where applicable

---

*Last Updated: October 2024*
*Maintained by: Development Team*
