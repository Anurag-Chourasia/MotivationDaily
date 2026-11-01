# Component design preset

Use `LayoutPreset.softWellness` from DesignTokensKit. App catalog assets own brand colors.
Inject the theme at the root of each opted-in feature:

```swift
let layout = LayoutPreset.softWellness
let colors = SemanticColors(surface: Color("BrandSurface"),
    foreground: Color("BrandText"), border: Color("BrandBorder"),
    action: Color("BrandAction"), onAction: Color("BrandOnAction"))
let theme = ComponentTheme(surface: layout.card, button: layout.button, colors: colors)
// FeatureView().componentTheme(theme)
// ThemedSurface { ... }
// Button("Continue") { ... }.buttonStyle(ThemedButtonStyle())
```

This opts into the new local shared-kit APIs. Existing screens are not automatically
restyled. Release both shared packages and update consumer pins before adopting it.
Background, surface, text, muted text, border, action/on-action, success, warning and
error roles each have light/dark variants in the asset catalog.
