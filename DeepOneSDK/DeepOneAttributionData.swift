import Foundation

@objcMembers
public class DeepOneAttributionData: NSObject {
    
    public let originURL: String?
    
    public let routePath: String?
    
    public let isFirstSession: Bool
    
    public let queryParameters: [String: String]
    
    public let marketingSource: String?
    
    public let marketingMedium: String?
    
    public let marketingCampaign: String?
    
    public let marketingTerm: String?
    
    public let marketingContent: String?
    
    public let referrer: String?
    
    public let campaignIdentifier: String?

    public let rawData: [String: Any]

    internal init(from dictionary: [String: Any]) {
        self.rawData = dictionary
        
        self.originURL = dictionary[DeepOne.AttributionParameterOriginURL] as? String
        self.routePath = dictionary[DeepOne.AttributionParameterRoutePath] as? String
        self.isFirstSession = (dictionary[DeepOne.AttributionParameterIsFirstSession] as? Bool) ?? false
        
        self.queryParameters = (dictionary[DeepOne.AttributionParameterQueryParameters] as? [String: String]) ?? [:]
        
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
    
    @objc public var hasMarketingData: Bool {
        return marketingSource != nil || marketingMedium != nil || marketingCampaign != nil
    }
    
    @objc public var hasUTMParameters: Bool {
        return marketingSource != nil || marketingMedium != nil || marketingCampaign != nil || marketingTerm != nil || marketingContent != nil
    }
    
    @objc public func customParameter(for key: String) -> Any? {
        return rawData[key]
    }
    
    @objc public func customStringParameter(for key: String) -> String? {
        return rawData[key] as? String
    }
    
    @objc public var utmParameters: [String: String] {
        var utm: [String: String] = [:]
        if let source = marketingSource { utm["utm_source"] = source }
        if let medium = marketingMedium { utm["utm_medium"] = medium }
        if let campaign = marketingCampaign { utm["utm_campaign"] = campaign }
        if let term = marketingTerm { utm["utm_term"] = term }
        if let content = marketingContent { utm["utm_content"] = content }
        return utm
    }
    
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

#if swift(>=5.5)
extension DeepOneAttributionData {
    
    public var url: URL? {
        guard let originURL = originURL else { return nil }
        return URL(string: originURL)
    }
    
    public func matches(route: String) -> Bool {
        return routePath == route
    }
    
    public func hasRoute(withPrefix prefix: String) -> Bool {
        return routePath?.hasPrefix(prefix) ?? false
    }
    
    public func extractID(fromRoute routePrefix: String) -> String? {
        guard let path = routePath, path.hasPrefix(routePrefix) else { return nil }
        let idStartIndex = path.index(path.startIndex, offsetBy: routePrefix.count)
        return String(path[idStartIndex...])
    }
}
#endif
