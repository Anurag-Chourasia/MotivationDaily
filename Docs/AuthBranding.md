# Auth brand palette

The asset catalog owns AuthAction, AuthOnAction, AuthBackground and AuthForeground.
Light/dark variants are included. AuthKitUI AuthView automatically resolves these
host assets through AuthPalette when integrated. Existing app launch/login flows
have not been replaced. To explicitly pass a palette:

```swift
AuthView(session: session, brand: brand, redirectTo: callback,
         providers: [.google, .github, .apple],
         palette: .appAssets(fallback: .projectDefault(for: brand)))
```

App catalogs own brand values; DesignTokensKit owns shared roles and scales;
UIComponentsKit owns reusable controls; AuthKitUI owns auth composition.
