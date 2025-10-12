# Just Spent - Android

Voice-enabled expense tracking application for Android with Google Assistant integration.

## Features

- 🎤 **Voice Integration**: Log expenses using Google Assistant
- 📱 **Modern UI**: Jetpack Compose with Material Design 3
- 💾 **Local Storage**: Room database with offline capability
- 🏗️ **Clean Architecture**: MVVM pattern with Repository
- 🧪 **Testing**: Comprehensive unit, integration, and UI tests
- 🔒 **Security**: Encrypted data storage and privacy controls

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │     Domain      │    │      Data       │
│                 │    │                 │    │                 │
│  - Compose UI   │◄──►│  - Repository   │◄──►│  - Room DB      │
│  - ViewModels   │    │  - Use Cases    │    │  - DAOs         │
│  - Activities   │    │  - Models       │    │  - Entities     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Tech Stack

- **UI**: Jetpack Compose + Material Design 3
- **Architecture**: MVVM + Repository Pattern
- **Database**: Room with SQLite
- **DI**: Hilt (Dagger)
- **Async**: Kotlin Coroutines + Flow
- **Voice**: Google Assistant App Actions
- **Testing**: JUnit, Espresso, Truth, Mockito
- **Build**: Gradle with Kotlin DSL

## Project Structure

```
app/src/
├── main/
│   ├── java/com/justspent/app/
│   │   ├── data/              # Data layer
│   │   │   ├── dao/           # Room DAOs
│   │   │   ├── database/      # Database setup
│   │   │   ├── model/         # Data models
│   │   │   └── repository/    # Repository implementations
│   │   ├── di/                # Dependency injection
│   │   ├── ui/                # Presentation layer
│   │   │   ├── expenses/      # Expense list screens
│   │   │   ├── voice/         # Voice interaction
│   │   │   └── theme/         # UI theming
│   │   └── JustSpentApplication.kt
│   ├── res/                   # Resources
│   └── AndroidManifest.xml
├── test/                      # Unit tests
└── androidTest/               # Integration tests
```

## Setup

### Prerequisites

- Android Studio Arctic Fox or later
- JDK 11+
- Android SDK 26+
- Google Assistant Test Tool (for voice testing)

### Build

```bash
./gradlew build
```

### Test

```bash
# Unit tests
./gradlew test

# Integration tests
./gradlew connectedAndroidTest

# All tests
./gradlew check
```

## Voice Commands

The app supports natural language voice commands via Google Assistant:

- "Hey Google, I just spent 50 dollars on groceries in Just Spent"
- "Hey Google, log 25 AED for coffee in Just Spent"
- "Hey Google, add expense 100 dirhams transportation"

### Supported Categories

- Food & Dining
- Grocery
- Transportation
- Shopping
- Entertainment
- Bills & Utilities
- Healthcare
- Education
- Other

### Supported Currencies

- AED (UAE Dirham)
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)

## Development

### Adding New Features

1. Create data models in `data/model/`
2. Add database entities and DAOs in `data/dao/`
3. Implement repository pattern in `data/repository/`
4. Create ViewModels in `ui/*/`
5. Build Compose UI screens
6. Add comprehensive tests

### Testing Strategy

- **Unit Tests**: 85%+ coverage for business logic
- **Integration Tests**: Database operations and repositories
- **UI Tests**: Critical user flows and interactions
- **Voice Tests**: Google Assistant integration

### Code Quality

```bash
# Lint check
./gradlew lint

# Detekt static analysis
./gradlew detekt

# Format code
./gradlew ktlintFormat
```

## Voice Integration

### Google Assistant Setup

1. Enable App Actions in Google Play Console
2. Upload `actions.xml` to configure intents
3. Test with App Actions Test Tool
4. Submit for review

### Deep Link Handling

The app handles voice commands via deep links:

```
https://justspent.app/expense?amount=25.50&category=food&merchant=Starbucks
```

## Security

- Encrypted database storage
- No sensitive data in logs
- Privacy-compliant data handling
- Secure deep link validation

## Performance

- Room database with optimized queries
- Coroutines for async operations
- Compose with lazy loading
- Minimal memory footprint

## Deployment

### Debug Build

```bash
./gradlew assembleDebug
```

### Release Build

```bash
./gradlew assembleRelease
```

### Play Store

1. Generate signed APK/AAB
2. Upload to Play Console
3. Configure App Actions
4. Submit for review

## Contributing

1. Fork the repository
2. Create feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub issue tracker.