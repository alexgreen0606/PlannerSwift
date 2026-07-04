# SwiftUI

## Modifier Order

Apply view modifiers in a consistent order.

```swift
Text("Title")
    // Identity / Animation
    .id(...)
    .animation(...)

    // View-Specific
    .textSelection(...)
    .scrollTransition(...)

    // Styling
    .font(...)
    .foregroundStyle(...)
    .opacity(...)
    .background(...)

    // Layout
    .frame(...)
    .padding(...)

    // Safe Area
    .ignoresSafeArea(...)
    .safeAreaInset(...)

    // Overlay
    .overlay(...)
    .background(...)

    // Toolbar
    .toolbar(...)

    // Custom
    .plannerStyle(...)

    // Transition
    .transition(...)

    // User Interaction
    .onTapGesture(...)

    // Async
    .task(...)
    .onChange(...)

    // Presentation
    .sheet(...)
    .fullScreenCover(...)
```
