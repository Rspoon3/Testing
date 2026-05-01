# Features

## Photo Ranking System
A photo comparison and ranking application that helps users determine their favorite photos through side-by-side comparisons.

## Core Features

### Photo Selection
- Import photos from device photo library using PhotosPicker
- Import photos from Files app using DocumentPicker
- Support for multiple photo selection (up to 20 photos)

### Photo Comparison
- Side-by-side photo comparison interface
- Interactive selection by tapping photos or buttons
- Progress tracking with visual progress bar
- Undo functionality for previous comparisons

### Ranking Algorithm
- Pairwise comparison methodology
- Win-count based ranking system
- Automatic calculation of final rankings

### Results Display
- Ranked list view with visual indicators
- Gold, silver, and bronze medals for top 3 photos
- Numbered rankings for all photos
- Photo thumbnails with rank indicators

### Sharing and Export
- Share ranking results as text
- Start new ranking sessions
- Persistent ranking results during session

## Technical Features
- SwiftUI-based architecture
- MVVM pattern with ObservableObject
- Cross-platform support (iOS/macOS)
- Modern Swift syntax and conventions
- SFSymbols integration for icons