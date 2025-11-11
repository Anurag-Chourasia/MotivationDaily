# MotivationDaily Architecture

This app follows **Clean Architecture + MVVM** with explicit layer boundaries.

## Layers

### 1) App (Composition Root)
- Path: `App/`
- Responsibility: wires concrete implementations to use cases and view models.
- Entry point: `MotivationDailyApp.swift` creates `AppContainer` and injects VMs.

### 2) Domain (Pure Business Rules)
- Path: `Domain/`
- Contains:
  - `Entities/` (core models)
  - `Repositories/` (abstractions/protocols)
  - `UseCases/` (application-specific business actions)
  - `Errors/` (domain-level app errors)
- Rule: no dependency on Presentation or Data concrete types.

### 3) Data (Implementation Details)
- Path: `Data/`
- Contains:
  - `Network/APIService.swift` (async/await HTTP client, iOS 15+)
  - `Repositories/` (concrete implementations of domain repository protocols)
- Rule: depends on Domain contracts, never on Presentation.

### 4) Presentation (MVVM + UI)
- Path: `Presentation/`
- Contains:
  - `ViewModels/` (state orchestration for UI)
  - `Views/` (SwiftUI views)
  - `Shared/` (UI-only helpers: image analysis, snapshot/share)
- Rule: depends on Domain use cases, never on Data concrete classes.

## Dependency Direction

`Presentation -> Domain <- Data`

`App` is the only layer allowed to know all layers and compose them.

## MVVM in this project

- `QuoteViewModel` and `WallpaperViewModel` are in `Presentation/ViewModels`.
- Views in `Presentation/Views` bind only to view models.
- View models call use cases instead of networking/storage directly.
