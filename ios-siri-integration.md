# iOS Siri Integration Guide for Just Spent

## Overview
This document provides comprehensive instructions for integrating Siri with the Just Spent iOS app, enabling voice-activated expense logging.

## Prerequisites
- iOS 14.0+ (minimum for enhanced Siri capabilities)
- Xcode 14.0+
- Apple Developer Account (for Siri capability)
- App Groups capability enabled

## Integration Architecture

```
User Voice Command
    ↓
Siri Recognition
    ↓
Intent Extension (JustSpentIntentsExtension)
    ↓
Intent Handler Processing
    ↓
Data Parsing & Validation
    ↓
Main App Data Store (via App Groups)
    ↓
UI Update (if app is open)
```

## Implementation Steps

### Step 1: Project Configuration

#### Capabilities Setup
1. Enable Siri capability in project settings
2. Enable App Groups for data sharing
3. Add Background Modes (processing, fetch)
4. Configure Push Notifications (optional for confirmations)

#### Info.plist Configuration
```xml
<key>NSSiriUsageDescription</key>
<string>Just Spent uses Siri to quickly log your expenses using voice commands</string>
<key>NSUserActivityTypes</key>
<array>
    <string>com.justspent.logExpense</string>
    <string>com.justspent.viewExpenses</string>
</array>
```

### Step 2: Intent Definition File Structure

#### Custom Intent Definition
Create `JustSpent.intentdefinition` with:

**LogExpenseIntent**
- Parameters:
  - amount (Currency) - Required
  - category (Enum) - Optional
  - merchant (String) - Optional
  - note (String) - Optional
  - date (Date) - Optional

**Categories Enum:**
- Food & Dining
- Grocery
- Transportation
- Shopping
- Entertainment
- Bills & Utilities
- Healthcare
- Education
- Other

### Step 3: Intent Extension Target

#### Target Structure
```
JustSpentIntentsExtension/
├── IntentHandler.swift
├── LogExpenseIntentHandler.swift
├── ExpenseParser.swift
├── CategoryClassifier.swift
└── SharedDataManager.swift
```

### Step 4: Voice Command Patterns

#### Supported Patterns
1. "Hey Siri, I just spent [amount] [currency] on [category]"
2. "Hey Siri, I just spent [amount] at [merchant]"
3. "Hey Siri, log [amount] [currency] for [category] in Just Spent"
4. "Hey Siri, add expense [amount] [category]"
5. "Hey Siri, I paid [amount] for [item/service]"

#### Natural Language Processing
- Extract monetary values with currency
- Identify category keywords
- Parse merchant names
- Handle relative dates ("yesterday", "last week")
- Support multiple languages

### Step 5: Shortcuts Integration

#### Creating Shortcuts
1. Donate intents after successful expense logging
2. Suggest relevant shortcuts based on patterns
3. Create parameterized shortcuts for frequent expenses

#### Shortcut Phrases Examples
- "Coffee time" → Log $5 for Coffee
- "Lunch expense" → Log $15 for Food & Dining
- "Gas fill up" → Log $50 for Transportation
- "Weekly groceries" → Open grocery expense form

### Step 6: Data Synchronization

#### App Groups Configuration
```
Group Identifier: group.com.justspent.shared
Shared Container Path: /shared/expenses.db
```

#### Shared Data Manager Components
1. Core Data stack with shared container
2. UserDefaults suite for settings
3. File coordinator for concurrent access
4. Notification center for real-time updates

### Step 7: Error Handling

#### Voice Recognition Errors
- Ambiguous amount: Request clarification
- Missing required info: Prompt for details
- Invalid category: Suggest alternatives
- Network issues: Queue for later sync

#### User Feedback
- Confirmation dialogs for large amounts
- Voice feedback for successful logging
- Visual feedback in Siri UI
- Push notifications for background logging

### Step 8: Testing Scenarios

#### Unit Tests
1. Intent parameter parsing
2. Category classification accuracy
3. Currency conversion
4. Date parsing
5. Data persistence

#### Integration Tests
1. Siri → Intent Extension flow
2. Data sharing between targets
3. Background processing
4. Shortcut donation
5. Multi-language support

#### UI Tests
1. Siri UI presentation
2. Confirmation dialogs
3. Error state handling
4. App launch from Siri

### Step 9: Performance Optimization

#### Best Practices
- Minimize intent extension memory footprint (<30MB)
- Cache frequently used data
- Optimize NLP processing time (<1 second)
- Implement progressive disclosure
- Use lazy loading for resources

### Step 10: Privacy & Security

#### Data Protection
1. Encrypt sensitive financial data
2. Implement biometric authentication
3. Sanitize voice input
4. Audit trail for all transactions
5. GDPR/CCPA compliance

#### Privacy Considerations
- Minimal data collection
- On-device processing preferred
- Clear privacy policy
- User consent for voice data
- Data retention policies

## Advanced Features

### 1. Contextual Awareness
- Location-based merchant suggestions
- Time-based category predictions
- Recurring expense detection
- Budget alerts integration

### 2. Multi-User Support
- Family sharing compatibility
- Separate user profiles
- Shared expense categories
- Privacy controls

### 3. Widget Integration
- Quick expense logging widget
- Spending summary widget
- Voice command launcher
- Recent expenses display

## Debugging Guide

### Common Issues & Solutions

1. **"Sorry, you'll need to continue in the app"**
   - Check intent handler implementation
   - Verify required parameters
   - Review memory constraints

2. **Data not syncing**
   - Verify App Groups configuration
   - Check file coordinator usage
   - Review Core Data conflicts

3. **Voice recognition failures**
   - Test with different phrasings
   - Check locale settings
   - Review NLP patterns

## Code Generation Instructions for Claude Code

When implementing with Claude Code:

1. **Start with Intent Handler**
   - Request basic intent handler setup
   - Include parameter validation
   - Add error handling

2. **Implement Parser**
   - Natural language processing logic
   - Currency detection
   - Category classification

3. **Build Data Layer**
   - Core Data models
   - App Groups integration
   - Synchronization logic

4. **Add UI Components**
   - Siri UI extensions
   - Confirmation views
   - Error states

5. **Create Tests**
   - Unit tests for each component
   - Integration test suites
   - UI test scenarios

## Checklist for Production

- [ ] All voice patterns tested
- [ ] Error handling comprehensive
- [ ] Performance benchmarks met
- [ ] Privacy policy updated
- [ ] App Store description includes Siri
- [ ] Shortcuts documented for users
- [ ] Localization completed
- [ ] Analytics integrated
- [ ] Crash reporting enabled
- [ ] Beta testing completed

## Resources

- [Apple SiriKit Documentation](https://developer.apple.com/documentation/sirikit)
- [Shortcuts Programming Guide](https://developer.apple.com/documentation/sirikit/shortcuts)
- [App Groups Programming Guide](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Core Data Sharing Guide](https://developer.apple.com/documentation/coredata/sharing_core_data_objects_between_icloud_users)

---

*This guide will be continuously updated as new Siri capabilities are released.*