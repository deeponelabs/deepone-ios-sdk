import Foundation

/// Attribution data model providing type-safe access to attribution information
@objcMembers
public class DeepOneAttributionData: NSObject {
    
    // MARK: - Core Attribution Properties
    
    /// The original URL that triggered the attribution
    public let originURL: String?
    
    /// The path component of the attribution URL
    public let routePath: String?
    
    /// Whether this is the user's first session ever (persists across app reinstalls)
    public let isFirstSession: Bool
    
    /// All query parameters from the attribution URL
    public let queryParameters: [String: String]
    
    // MARK: - Marketing Attribution Properties
    
    /// UTM source parameter
    public let marketingSource: String?
    
    /// UTM medium parameter  
    public let marketingMedium: String?
    
    /// UTM campaign parameter
    public let marketingCampaign: String?
    
    /// UTM term parameter
    public let marketingTerm: String?
    
    /// UTM content parameter
    public let marketingContent: String?
    
    /// Custom referrer parameter
    public let referrer: String?
    
    /// Campaign identifier
    public let campaignIdentifier: String?
    
    // MARK: - Additional Properties
    
    /// Raw attribution data dictionary (for custom parameters)
    public let rawData: [String: Any]
    
    // MARK: - Initialization
    
    /// Internal initializer from dictionary data
    internal init(from dictionary: [String: Any]) {
        self.rawData = dictionary
        
        // Core attribution data
        self.originURL = dictionary[DeepOne.AttributionParameterOriginURL] as? String
        self.routePath = dictionary[DeepOne.AttributionParameterRoutePath] as? String
        self.isFirstSession = (dictionary[DeepOne.AttributionParameterIsFirstSession] as? Bool) ?? false
        
        // Query parameters
        self.queryParameters = (dictionary[DeepOne.AttributionParameterQueryParameters] as? [String: String]) ?? [:]
        
        // Marketing attribution data
        let marketingData = dictionary[DeepOne.AttributionParameterAttributionData] as? [String: Any] ?? [:]
        
        self.marketingSource = marketingData["utm_source"] as? String
        self.marketingMedium = marketingData["utm_medium"] as? String
        self.marketingCampaign = marketingData["utm_campaign"] as? String
        self.marketingTerm = marketingData["utm_term"] as? String
        self.marketingContent = marketingData["utm_content"] as? String
        self.referrer = marketingData["referrer"] as? String
        self.campaignIdentifier = marketingData["campaign_identifier"] as? String
        
        super.init()
    }
    
    // MARK: - Convenience Methods
    
    /// Checks if this attribution contains marketing data
    @objc public var hasMarketingData: Bool {
        return marketingSource != nil || marketingMedium != nil || marketingCampaign != nil
    }
    
    /// Checks if this attribution contains UTM parameters
    @objc public var hasUTMParameters: Bool {
        return marketingSource != nil || marketingMedium != nil || marketingCampaign != nil || marketingTerm != nil || marketingContent != nil
    }
    
    /// Gets a custom parameter value
    @objc public func customParameter(for key: String) -> Any? {
        return rawData[key]
    }
    
    /// Gets a custom string parameter
    @objc public func customStringParameter(for key: String) -> String? {
        return rawData[key] as? String
    }
    
    /// Gets all UTM parameters as a dictionary
    @objc public var utmParameters: [String: String] {
        var utm: [String: String] = [:]
        if let source = marketingSource { utm["utm_source"] = source }
        if let medium = marketingMedium { utm["utm_medium"] = medium }
        if let campaign = marketingCampaign { utm["utm_campaign"] = campaign }
        if let term = marketingTerm { utm["utm_term"] = term }
        if let content = marketingContent { utm["utm_content"] = content }
        return utm
    }
    
    // MARK: - Debug Description
    
    public override var description: String {
        var components: [String] = []
        
        if let url = originURL {
            components.append("originURL: \(url)")
        }
        
        if let path = routePath {
            components.append("routePath: \(path)")
        }
        
        components.append("isFirstSession: \(isFirstSession)")
        
        if hasMarketingData {
            var marketingComponents: [String] = []
            if let source = marketingSource { marketingComponents.append("source: \(source)") }
            if let campaign = marketingCampaign { marketingComponents.append("campaign: \(campaign)") }
            components.append("marketing: [\(marketingComponents.joined(separator: ", "))]")
        }
        
        return "DeepOneAttributionData(\(components.joined(separator: ", ")))"
    }
}

// MARK: - Swift Convenience Extensions

#if swift(>=5.5)
extension DeepOneAttributionData {
    
    /// URL of the attributed link
    public var url: URL? {
        guard let originURL = originURL else { return nil }
        return URL(string: originURL)
    }
    
    /// Checks if the attribution indicates a specific route
    public func matches(route: String) -> Bool {
        return routePath == route
    }
    
    /// Checks if the attribution has a route with a specific prefix
    public func hasRoute(withPrefix prefix: String) -> Bool {
        return routePath?.hasPrefix(prefix) ?? false
    }
    
    /// Extracts an ID from a route path (e.g., "/product/123" -> "123")
    public func extractID(fromRoute routePrefix: String) -> String? {
        guard let path = routePath, path.hasPrefix(routePrefix) else { return nil }
        let idStartIndex = path.index(path.startIndex, offsetBy: routePrefix.count)
        return String(path[idStartIndex...])
    }
}
#endif
