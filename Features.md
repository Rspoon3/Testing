# Features

## Locks and Keys Pattern
A SwiftUI implementation of the locks and keys architectural pattern for managing object dependencies and state. The pattern uses factories to ensure compile-time safety when creating views that require specific dependencies (like a logged-in user), preventing undefined states and reducing reliance on optionals and global state.

## Factory Hierarchy
The app demonstrates a 3-level factory hierarchy:

1. **RootFactory** - Manages shared services and creates user-bound factories
   - Holds shared services: `ImageLoader`, `APIClient`
   - Creates `UserBoundFactory` (requires User key)
   - Creates `LoginViewModel`

2. **UserBoundFactory** - Creates user-specific views and order-bound factories
   - Requires a valid User to be created
   - Creates user-specific view models: `ProfileViewModel`, `SettingsViewModel`, `OrderHistoryViewModel`
   - Creates `OrderBoundFactory` (requires Order key)
   - Provides access to shared services from RootFactory

3. **OrderBoundFactory** - Creates order-specific views
   - Requires both a valid User AND a valid Order to be created
   - Creates `OrderTrackingViewModel`
   - Provides access to shared services from RootFactory

## Shared Services
- **ImageLoader**: Service for loading and caching images
- **APIClient**: Service for making API requests

Services are created once in RootFactory and shared throughout the app, demonstrating proper dependency management.

## Views and Navigation
- **LoginView/LoginViewModel**: Handles authentication and creates user-bound factories
- **ProfileView/ProfileViewModel**: Displays user profile (requires User via UserBoundFactory)
- **SettingsView/SettingsViewModel**: Manages user settings (requires User via UserBoundFactory)
- **OrderHistoryView/OrderHistoryViewModel**: Lists user orders (Level 1, requires User)
- **OrderDetailView/OrderDetailViewModel**: Shows order details (Level 2, requires User)
- **OrderItemView/OrderItemViewModel**: Displays item details (Level 3, requires User)
- **OrderTrackingView/OrderTrackingViewModel**: Tracks order shipment (requires User AND Order via OrderBoundFactory)

## Environment Integration
The RootFactory is injected via SwiftUI's environment system:
- Created in `TestDriveApp` and provided to the view hierarchy
- Accessed in `ContentView` using `@Environment(\.factory)`
- Demonstrates proper SwiftUI integration and testability

## Key Benefits Demonstrated
- **Compile-time safety**: Views can only be created when required dependencies exist
- **Shared service management**: Services created once and passed through factories
- **Clear dependency boundaries**: Each factory level has explicit requirements
- **No global state**: All dependencies explicitly passed through factory chain
- **Testability**: Can inject mock factories via environment for testing

The pattern demonstrates how to use factory methods as "locks" that can only be opened with the right "key" (User, Order, etc.), ensuring more robust and predictable application architecture.
