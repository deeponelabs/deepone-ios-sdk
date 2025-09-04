import Foundation

/// Configuration builder for creating attributed deep links with marketing parameters
@objcMembers
public class DeepOneCreateLinkBuilder: NSObject {
    // MARK: - Core Properties
    let destinationPath: String
    let linkIdentifier: String
    
    // MARK: - Content Properties
    var linkDescription: String?
    var socialTitle: String?
    var socialDescription: String?
    var socialImageURL: String?
    
    // MARK: - Marketing Attribution
    var marketingSource: String?
    var marketingMedium: String?
    var marketingCampaign: String?
    var marketingTerm: String?
    var marketingContent: String?
    
    // MARK: - Custom Parameters
    private var customParameters: [String: Any] = [:]

    /// Creates a link builder with basic routing information
    /// - Parameters:
    ///   - destinationPath: The deep link path for routing
    ///   - linkIdentifier: Unique identifier for this link
    public init(destinationPath: String, linkIdentifier: String) {
        self.destinationPath = destinationPath
        self.linkIdentifier = linkIdentifier
        super.init()
    }

    /// Creates a link builder with comprehensive configuration
    public init(destinationPath: String,
                linkIdentifier: String,
                linkDescription: String? = nil,
                socialTitle: String? = nil,
                socialDescription: String? = nil,
                socialImageURL: String? = nil,
                marketingSource: String? = nil,
                marketingMedium: String? = nil,
                marketingCampaign: String? = nil,
                marketingTerm: String? = nil,
                marketingContent: String? = nil) {
        self.destinationPath = destinationPath
        self.linkIdentifier = linkIdentifier
        self.linkDescription = linkDescription
        self.socialTitle = socialTitle
        self.socialDescription = socialDescription
        self.socialImageURL = socialImageURL
        self.marketingSource = marketingSource
        self.marketingMedium = marketingMedium
        self.marketingCampaign = marketingCampaign
        self.marketingTerm = marketingTerm
        self.marketingContent = marketingContent
        super.init()
    }
}

// MARK: - Builder Methods

extension DeepOneCreateLinkBuilder {
    /// Adds a custom parameter to the link configuration
    /// - Parameters:
    ///   - key: Parameter key
    ///   - value: Parameter value
    /// - Returns: Self for method chaining
    @objc @discardableResult
    public func addCustomParameter(key: String, value: Any) -> Self {
        customParameters[key] = value
        return self
    }
    
    /// Sets social media preview content
    @objc @discardableResult
    public func setSocialPreview(title: String, description: String, imageURL: String?) -> Self {
        socialTitle = title
        socialDescription = description
        socialImageURL = imageURL
        return self
    }
    
    /// Sets social media preview content (Objective-C convenience method)
    @objc @discardableResult
    public func setSocialPreviewWithTitle(_ title: String, description: String) -> Self {
        return setSocialPreview(title: title, description: description, imageURL: nil)
    }
}

// MARK: - Parameter Building

extension DeepOneCreateLinkBuilder: Encodable {
    enum CodingKeys: String, CodingKey {
        case destinationPath = "path"
        case linkIdentifier = "name"
        case linkDescription = "description"
        case socialTitle = "previewTitle"
        case socialDescription = "previewDescription"
        case socialImageURL = "previewImageUrl"
        case marketingSource = "utmSource"
        case marketingMedium = "utmMedium"
        case marketingCampaign = "utmCampaign"
        case marketingTerm = "utmTerm"
        case marketingContent = "utmContent"
    }
    
    /// Builds the parameter dictionary for API submission
    /// - Returns: Dictionary containing all link parameters, or nil if invalid
    @objc public func buildParameters() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard var parameters = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        // Add custom parameters
        for (key, value) in customParameters {
            parameters[key] = value
        }
        
        return parameters
    }
    
    /// Legacy method for backward compatibility
    @objc public func toDic() -> [String: Any]? {
        return buildParameters()
    }
}
