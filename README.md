# DeepOne iOS SDK

![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%20%7C%20Mac%20Catalyst-lightgrey)
[![CocoaPods](https://img.shields.io/cocoapods/v/DeepOneSDK.svg)](https://cocoapods.org/pods/DeepOneSDK)
![License](https://img.shields.io/badge/License-MIT-green)

The DeepOne iOS SDK provides powerful **deferred deep linking** and attribution capabilities for iOS applications. Track user journeys across app installs, create smart links that work even when the app isn't installed, and gain valuable insights into your app's performance.

## ✨ **Features**

- 🔗 **Deferred Deep Link Creation** - Generate smart links that work even when app isn't installed
- 📊 **Attribution Tracking** - Track user acquisition and post-install routing  
- 🎯 **Universal Link Processing** - Handle deferred deep links seamlessly after app install
- 📱 **Cross-Platform Support** - iOS, iPadOS, and Mac Catalyst compatible
- 🔄 **First Session Detection** - Track users who install the app from your links
- ⚙️ **Development/Live Modes** - Separate API keys for testing and production

## 🚀 **Installation**

### Swift Package Manager (Recommended)

Add DeepOneSDK to your project using Xcode:

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/deeponelabs/deepone-ios-sdk.git
   ```
3. Select the version range and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/deeponelabs/deepone-ios-sdk.git", from: "1.1.5")
]
```

### CocoaPods

Add this line to your `Podfile`:

```ruby
pod 'DeepOneSDK', '~> 1.1.5'
```

Then run:
```bash
pod install
```



## 🔑 **API Key Setup**

To use DeepOneSDK, you need a free API key:

1. Visit [https://deepone.io](https://deepone.io) to create your account
2. Generate your free API keys from the dashboard (both test and live keys)
3. Add the keys to your app's `Info.plist`:

```xml
<key>DeepOne.keys</key>
<dict>
    <key>test</key>
    <string>your_test_api_key_here</string>
    <key>live</key>
    <string>your_live_api_key_here</string>
</dict>
```

## 📱 **Usage**

### Basic Setup

```swift
import DeepOneSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure DeepOne SDK (reads API keys from Info.plist)
        DeepOne.shared.configure(
            launchOptions: launchOptions,
            developmentMode: false // Set to true for testing with test API key
        ) { attributionData, error in
            if let attribution = attributionData {
                // Handle initial attribution and route user to appropriate screen
                print("App launched with attribution: \\(attribution.marketingCampaign ?? "Direct")")
                
                // Route user based on deep link path
                if let routePath = attribution.routePath {
                    self.routeToScreen(path: routePath)
                }
            }
        }
        
        return true
    }
    
    // Helper method to route user to appropriate screen based on deep link path
    private func routeToScreen(path: String) {
        DispatchQueue.main.async {
            switch path {
            case "/product":
                // Navigate to product page
                print("Routing to product page")
            case "/profile":
                // Navigate to user profile
                print("Routing to profile page")  
            case "/offer":
                // Navigate to special offer
                print("Routing to offer page")
            default:
                // Navigate to home or handle unknown path
                print("Routing to home page")
            }
        }
    }
}
```

### Creating Deferred Deep Links

```swift
import DeepOneSDK

// Create link configuration
let linkBuilder = DeepOneCreateLinkBuilder(
    destinationPath: "/product/123",
    linkIdentifier: "summer_promo_product_123"
)

// Add marketing attribution
linkBuilder.setMarketingSource("email")
linkBuilder.setMarketingMedium("newsletter")  
linkBuilder.setMarketingCampaign("summer_sale_2024")
linkBuilder.setMarketingContent("Summer Sale")

// Add social sharing metadata
linkBuilder.setSocialTitle("Amazing Product")
linkBuilder.setSocialDescription("Check out this amazing product!")

// Generate the deferred deep link
DeepOne.shared.createAttributedLink(configuration: linkBuilder) { url, error in
    if let deferredLink = url {
        print("Generated deferred deep link: \\(deferredLink)")
        // Share the link - works even if app isn't installed yet!
        // Users who don't have the app will be directed to App Store,
        // then after install, they'll be routed to the specified destination
    } else if let error = error {
        print("Error creating link: \\(error.localizedDescription)")
    }
}
```

### Handling Deferred Deep Links

> **How Deferred Deep Linking Works:**  
> 1. User clicks your link but doesn't have the app installed
> 2. They're directed to the App Store to download your app  
> 3. After installing and opening the app, DeepOne automatically detects this was a deferred deep link
> 4. The user is seamlessly routed to the originally intended destination

#### Option 1: Using SceneDelegate (iOS 13+)

```swift
import DeepOneSDK

// In your SceneDelegate
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    // Handle deferred deep links (for users who installed app from your link)
    if DeepOne.shared.processUniversalLink(userActivity) {
        print("Deferred deep link processed by DeepOne")
        // User will be automatically routed to the intended destination
    }
}

// Handle URL schemes
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
        if DeepOne.shared.trackAttributionURL(context.url) {
            print("Attribution URL tracked")
        }
    }
}
```

#### Option 2: Using AppDelegate

```swift
import DeepOneSDK

// In your AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Handle deferred deep links (for users who installed app from your link)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if DeepOne.shared.processUniversalLink(userActivity) {
            print("Deferred deep link processed by DeepOne")
            return true // User will be automatically routed to intended destination
        }
        
        return false
    }
    
    // Handle URL schemes
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if DeepOne.shared.trackAttributionURL(url) {
            print("Attribution URL tracked")
            return true
        }
        
        return false
    }
}
```

### Accessing Attribution Data

```swift
import DeepOneSDK

// The attribution data is automatically provided in the configure callback
// and whenever a new attributed link is opened. You can also access it directly:

DeepOne.shared.configure(launchOptions: launchOptions) { attributionData, error in
    guard let attribution = attributionData else { return }
    
    // Marketing attribution
    print("Source: \\(attribution.marketingSource ?? "Direct")")
    print("Medium: \\(attribution.marketingMedium ?? "Unknown")")  
    print("Campaign: \\(attribution.marketingCampaign ?? "None")")
    print("Content: \\(attribution.marketingContent ?? "None")")
    
    // Deep link routing
    print("Route Path: \\(attribution.routePath ?? "/")")
    print("Query Parameters: \\(attribution.queryParameters)")
    
    // Session tracking
    print("First Session: \\(attribution.isFirstSession)")
}
```

## Configuring Associated Domains

To enable Universal Links in your app, you need to declare the associated domains your app will handle.

1. In Xcode, select your app target.
2. Go to **Signing & Capabilities** → click **+ Capability** → add **Associated Domains**.
3. Under **Associated Domains**, add your domain(s) in the following format:  
`applinks:{your_subdomain}.deepone.io`


## 🛠️ **Advanced Configuration**

### Development vs Live Mode

```swift
// Use test API key during development
DeepOne.shared.configure(
    launchOptions: launchOptions,
    developmentMode: true // Uses "test" key from Info.plist
) { attributionData, error in
    // Handle attribution
}

// Use live API key in production
DeepOne.shared.configure(
    launchOptions: launchOptions,
    developmentMode: false // Uses "live" key from Info.plist
) { attributionData, error in
    // Handle attribution
}
```

### Clearing Attribution Data

```swift
// Clear stored attribution data (useful for testing)
DeepOne.shared.clearAttributionData()
```

## 📋 **Requirements**

- iOS 13.0+ / iPadOS 13.0+
- Mac Catalyst 13.0+
- Xcode 12.0+
- Swift 5.0+


## 💬 **Support**

- 📧 Email: [contact@deepone.io](mailto:contact@deepone.io)
- 💼 Website: [https://deepone.io](https://deepone.io)

## 📄 **License**

DeepOneSDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

**Made with ❤️ by DeepOneIO**
