# OneRM - iOS Workout Tracking App

A native iOS workout tracking application built with Swift and SwiftUI, designed to communicate with a backend API.

## 📱 Features

### Screen 1: Workout Setup
- Date picker (defaults to today)
- Optional workout name field
- Multi-select body parts with default options (Chest, Back, Shoulders, Arms, Legs, Core/Abs, Full Body)
- Add custom body parts
- Visual chip/tag display for selected body parts
- Continue button (enabled when at least one body part is selected)

### Screen 2: Exercise Tracking
- Table-style interface with columns: Exercise (35%), Weight (20%), Reps (20%), Total (25%)
- Real-time total volume calculation (Weight × Reps)
- Weight unit toggle (lbs/kg)
- Swipe-to-delete functionality
- Add row button for additional exercises
- Save confirmation and unsaved changes warning
- Loading states during save operations

### Additional Features
- Personal records display with gold/yellow highlighting
- Workout history with search and filter
- Pull-to-refresh in history view
- CSV export functionality
- Settings screen for user preferences
- Dark mode support
- Haptic feedback for interactions
- Empty states with helpful messages
- Skeleton loading screens

## 🏗 Architecture

### MVVM Pattern
```
OneRM/
├── Models/
│   ├── WorkoutModels.swift      # Core data models
│   └── APIModels.swift          # API request/response models
├── ViewModels/
│   ├── WorkoutSetupViewModel.swift
│   ├── ExerciseTrackingViewModel.swift
│   └── WorkoutHistoryViewModel.swift
├── Views/
│   ├── WorkoutSetupView.swift
│   ├── ExerciseTrackingView.swift
│   ├── WorkoutHistoryView.swift
│   └── SettingsView.swift
├── Components/
│   ├── BodyPartChip.swift
│   ├── ExerciseRowView.swift
│   ├── LoadingView.swift
│   ├── EmptyStateView.swift
│   └── WorkoutCardView.swift
├── Networking/
│   ├── APIClient.swift          # Generic API client with async/await
│   ├── WorkoutRepository.swift  # Repository pattern implementation
│   └── MockDataProvider.swift   # Mock data for development
└── Utilities/
    ├── UserPreferences.swift    # UserDefaults wrapper
    ├── Configuration.swift      # Environment configuration
    ├── HapticManager.swift      # Haptic feedback
    └── Extensions.swift         # Utility extensions
```

## 🔧 Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS Sonoma or later (for development)

### Installation
1. Clone the repository
2. Open `OneRM.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on simulator or device

### Configuration
The app uses environment-based configuration in `Configuration.swift`:

```swift
// Development (DEBUG builds)
baseURL = "http://localhost:3000"
useMockData = true

// Production (RELEASE builds)
baseURL = "https://api.onerm.app"
useMockData = false
```

## 📡 API Contract

The app is prepared to communicate with the following backend endpoints:

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/bodyparts` | Fetch available body parts |
| POST | `/api/workouts` | Save new workout |
| GET | `/api/workouts` | Fetch workout history |
| GET | `/api/exercises/suggestions?query={text}` | Exercise name autocomplete |
| GET | `/api/prs` | Fetch personal records |

### Request/Response Models

#### POST /api/workouts
```json
// Request
{
  "name": "Push Day",
  "date": "2024-01-23T00:00:00Z",
  "body_parts": ["Chest", "Shoulders"],
  "exercises": [
    {
      "name": "Bench Press",
      "weight": 185,
      "reps": 8,
      "unit": "lbs"
    }
  ]
}

// Response
{
  "id": "uuid",
  "name": "Push Day",
  "date": "2024-01-23T00:00:00Z",
  "body_parts": [
    { "id": "uuid", "name": "Chest", "is_custom": false }
  ],
  "exercises": [
    {
      "id": "uuid",
      "name": "Bench Press",
      "weight": 185,
      "reps": 8,
      "unit": "lbs",
      "total_volume": 1480
    }
  ],
  "created_at": "2024-01-23T10:30:00Z",
  "updated_at": "2024-01-23T10:30:00Z"
}
```

#### GET /api/prs
```json
{
  "records": [
    {
      "id": "uuid",
      "exercise_name": "Bench Press",
      "weight": 225,
      "reps": 5,
      "unit": "lbs",
      "date": "2024-01-20T00:00:00Z",
      "workout_session_id": "uuid",
      "estimated_one_rep_max": 253.125
    }
  ]
}
```

## 🧪 Testing

### Unit Tests
```bash
# Run unit tests
xcodebuild test -scheme OneRM -destination 'platform=iOS Simulator,name=iPhone 15'
```

Tests cover:
- Volume calculation logic
- Model validation
- Weight unit conversion
- API model conversion

### UI Tests
```bash
# Run UI tests
xcodebuild test -scheme OneRMUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

Tests cover:
- Workout creation flow
- Tab navigation
- Body part selection
- Settings interaction

## 📋 Design Guidelines

The app follows Apple Human Interface Guidelines:
- Native iOS components and SF Symbols
- Light and dark mode support
- Dynamic Type for accessibility
- Minimum 44×44pt touch targets
- Minimalistic monochromatic color scheme
- Smooth transitions and animations
- Haptic feedback for important actions

## 🔐 Data Storage

| Data Type | Storage |
|-----------|---------|
| User preferences | UserDefaults |
| API base URL | Configuration.swift |
| Auth tokens | Keychain (when implemented) |

## 📦 Dependencies

No external dependencies - pure Swift/SwiftUI implementation using:
- URLSession for networking
- Codable for JSON parsing
- Combine for reactive updates (via @Published)

## 🚀 Future Enhancements

- [ ] Authentication system
- [ ] Offline mode with local persistence
- [ ] Apple Watch companion app
- [ ] HealthKit integration
- [ ] Workout templates
- [ ] Progress charts and analytics
- [ ] Social sharing features
- [ ] iCloud sync

## 📄 License

MIT License - see LICENSE file for details.

## 👥 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

Built with ❤️ using SwiftUI
