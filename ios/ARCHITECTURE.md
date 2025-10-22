# Just Spent iOS - Architecture Documentation

## Overview
This document describes the iOS application architecture following **Clean Architecture** and **MVVM (Model-View-ViewModel)** design patterns.

## Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  (Views, ViewModels, UI Components)                 │
│  SwiftUI Views, ViewModels, Coordinators            │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                   Domain Layer                       │
│  (Business Logic, Use Cases, Domain Models)         │
│  Core business rules and entity definitions         │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                    Data Layer                        │
│  (Repositories, Data Sources, Persistence)          │
│  Core Data, Network, Local Storage                  │
└─────────────────────────────────────────────────────┘
```

## Directory Structure

```
JustSpent/
├── Presentation/              # UI Layer (SwiftUI)
│   ├── Views/
│   │   ├── Expenses/         # Expense-related views
│   │   ├── Components/       # Reusable UI components
│   │   └── Voice/            # Voice recording UI
│   └── ViewModels/           # ViewModels for business logic
│
├── Domain/                    # Business Logic Layer
│   ├── Models/               # Domain models (Expense, Category)
│   ├── UseCases/             # Use case implementations
│   └── Interfaces/           # Protocol definitions
│
├── Data/                      # Data Access Layer
│   ├── Repositories/         # Repository implementations
│   ├── CoreData/             # Core Data models
│   └── Persistence/          # Persistence controllers
│
├── Common/                    # Shared Resources
│   ├── Extensions/           # Swift extensions
│   ├── Utilities/            # Utility classes
│   │   └── VoiceCommandParser.swift
│   ├── Constants/            # App constants
│   │   └── AppConstants.swift
│   └── LocalizedStrings.swift # String localization
│
├── Resources/                 # Assets & Localization
│   └── Localizable.strings   # Localized strings
│
└── Siri/                     # Siri Integration
    ├── Intent/               # Intent handlers
    └── Shortcuts/            # Shortcut managers
```

## Key Design Patterns

### 1. MVVM (Model-View-ViewModel)
- **View**: SwiftUI views (passive, declarative)
- **ViewModel**: Business logic, state management, data transformation
- **Model**: Domain entities and data structures

### 2. Repository Pattern
- Abstracts data access logic
- Provides clean API for data operations
- Handles Core Data, API calls, caching

### 3. Dependency Injection
- ViewModels receive dependencies via initializers
- Facilitates testing and modularity

### 4. Protocol-Oriented Programming
- Define protocols for repositories and services
- Enable easy mocking for tests

## Core Components

### Presentation Layer

#### Views (`Presentation/Views/`)
- **ContentView.swift**: Main expense list view
- **ExpenseRowView**: Individual expense display
- **VoiceRecordingView**: Voice input interface
- **Components/**: Reusable UI components

#### ViewModels (`Presentation/ViewModels/`)
- **ExpenseListViewModel**: Manages expense list state
- Handles user interactions
- Coordinates with repositories
- Manages UI state and errors

### Domain Layer

#### Models (`Domain/Models/`)
- **Expense**: Core expense entity
- **Category**: Expense category
- **ExpenseError**: Domain-specific errors

#### Use Cases (`Domain/UseCases/`)
- **AddExpenseUseCase**: Add new expense
- **DeleteExpenseUseCase**: Delete expense
- **GetExpensesUseCase**: Retrieve expenses
- **ProcessVoiceCommandUseCase**: Process voice input

#### Interfaces (`Domain/Interfaces/`)
- **ExpenseRepositoryProtocol**: Repository contract
- **VoiceProcessorProtocol**: Voice processing contract

### Data Layer

#### Repositories (`Data/Repositories/`)
- **ExpenseRepository**: Implements ExpenseRepositoryProtocol
- Handles CRUD operations
- Manages Core Data context
- Error handling and validation

#### Core Data (`Data/CoreData/`)
- **Expense+CoreDataClass**: Core Data entity
- **JustSpent.xcdatamodeld**: Data model definition

#### Persistence (`Data/Persistence/`)
- **PersistenceController**: Core Data stack management
- Shared and preview contexts

### Common Layer

#### Utilities (`Common/Utilities/`)
- **VoiceCommandParser**: NLP for voice commands
  - Parses natural language
  - Extracts amount, currency, category
  - Handles written numbers

#### Constants (`Common/Constants/`)
- **AppConstants**: Application-wide constants
  - User activity types
  - Notification names
  - Category definitions
  - Category keyword mappings
  - Currency codes

#### Localization (`Common/`)
- **LocalizedStrings**: Centralized string access
  - Type-safe string access
  - Supports parameterized strings
  - Debug-only debug messages

### Siri Integration

#### Intent Handlers (`Siri/Intent/`)
- **IntentHandler**: Main intent dispatcher
- Handles Siri shortcuts and App Shortcuts

#### Shortcuts (`Siri/Shortcuts/`)
- **ShortcutsManager**: Manages Siri shortcuts
- Donation and suggestion logic

## Data Flow

### Adding an Expense via Voice

```
1. User taps voice button (View)
   ↓
2. ContentView starts speech recognition
   ↓
3. Speech transcription received
   ↓
4. VoiceCommandParser.parseExpenseCommand()
   ↓
5. ParsedExpenseData returned
   ↓
6. ViewModel.addExpense() called
   ↓
7. Repository.addExpense() saves to Core Data
   ↓
8. View updates with new expense
```

### Localization Flow

```
1. UI needs text
   ↓
2. Reference LocalizedStrings.propertyName
   ↓
3. NSLocalizedString fetches from Localizable.strings
   ↓
4. Localized text displayed
```

## String Localization

### Usage

```swift
// Instead of:
Text("Just Spent")

// Use:
Text(LocalizedStrings.appTitle)

// For parameterized strings:
Text(LocalizedStrings.expenseAddedSuccess(
    currency: "USD",
    amount: "50.00",
    category: "Food",
    transcript: "twenty dollars for lunch"
))
```

### Adding New Strings

1. Add to `Localizable.strings`:
```
"feature.newMessage" = "This is a new feature";
```

2. Add to `LocalizedStrings.swift`:
```swift
static let featureNewMessage = NSLocalizedString("feature.newMessage", comment: "New feature message")
```

3. Use in code:
```swift
Text(LocalizedStrings.featureNewMessage)
```

## Constants Usage

### Categories

```swift
// Access category names
let category = AppConstants.Category.foodDining

// Get all categories
let allCategories = AppConstants.Category.allCategories
```

### Voice Recording Configuration

```swift
// Access configuration values
let silenceThreshold = AppConstants.VoiceRecording.silenceThreshold
let minimumDuration = AppConstants.VoiceRecording.minimumSpeechDuration
```

### Currency

```swift
// Default currency
let currency = AppConstants.Currency.defaultCurrency

// Supported currencies
let supported = AppConstants.Currency.supportedCurrencies
```

## Voice Command Processing

The `VoiceCommandParser` utility handles all natural language processing:

```swift
let parser = VoiceCommandParser.shared
let result = parser.parseExpenseCommand("I just spent twenty dollars for tea")

// result contains:
// - amount: 20.0
// - currency: "USD"
// - category: "Food & Dining"
// - merchant: nil
```

### Supported Patterns

1. **Numeric amounts**: "50 dollars", "100 dirhams"
2. **Written numbers**: "twenty dollars", "one hundred"
3. **Multiple currencies**: USD, AED, EUR, GBP
4. **Category keywords**: Extensive keyword matching
5. **Merchant extraction**: "at Starbucks", "from Amazon"

## Testing Strategy

### Unit Tests
- Test ViewModels in isolation
- Mock repositories using protocols
- Test VoiceCommandParser with various inputs
- Test utility functions

### Integration Tests
- Test ViewModel + Repository interaction
- Test Core Data operations
- Test voice command end-to-end flow

### UI Tests
- Test critical user journeys
- Test voice recording flow
- Test permission handling

## Best Practices

### 1. Dependency Injection
```swift
// ViewModel with injected repository
class ExpenseListViewModel: ObservableObject {
    private let repository: ExpenseRepositoryProtocol

    init(repository: ExpenseRepositoryProtocol = ExpenseRepository()) {
        self.repository = repository
    }
}
```

### 2. Error Handling
```swift
do {
    try await repository.addExpense(data)
} catch let error as ExpenseError {
    // Handle domain-specific errors
} catch {
    // Handle unexpected errors
}
```

### 3. String Localization
```swift
// GOOD: Using LocalizedStrings
Text(LocalizedStrings.appTitle)

// BAD: Hardcoded strings
Text("Just Spent")
```

### 4. Constants
```swift
// GOOD: Using AppConstants
let category = AppConstants.Category.foodDining

// BAD: Magic strings
let category = "Food & Dining"
```

## Migration Guide

### Updating Existing Code

When refactoring existing code to use the new architecture:

1. **Replace hardcoded strings** with `LocalizedStrings`
2. **Replace magic values** with `AppConstants`
3. **Use VoiceCommandParser** instead of inline parsing
4. **Move views** to appropriate `Presentation/Views/` subfolder
5. **Ensure ViewModels** are in `Presentation/ViewModels/`
6. **Move data access** to `Data/Repositories/`

## Security Considerations

- Never log sensitive data in production
- Voice transcripts encrypted at rest
- Follow iOS security best practices
- Validate all user inputs

## Performance Optimization

- Lazy loading of expenses
- Efficient Core Data fetching
- Background processing for voice recognition
- Debounced UI updates

## Future Enhancements

- Cloud sync integration
- Multi-language support expansion
- Advanced categorization with ML
- Receipt OCR integration
- Budget tracking features

---

*Last Updated: October 2024*
*Architecture Version: 1.0*
