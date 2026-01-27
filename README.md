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
- Add row button for additional exercises
- Save confirmation and unsaved changes warning
- Loading states during save operations

### Additional Features
- Personal records display with gold/yellow highlighting
- Workout history with search and filter
- Pull-to-refresh in history view
- CSV export functionality
- Settings screen for user preferences
- Haptic feedback for interactions
- Empty states with helpful messages
- Skeleton loading screens

## 🔧 Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS Sonoma or later (for development)
