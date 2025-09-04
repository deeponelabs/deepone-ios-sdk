import Foundation
import DeepOneCore

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

@objcMembers
public class DeepOne: NSObject {
    
    @objc public static let AttributionParameterOriginURL = "origin_url"
    @objc public static let AttributionParameterRoutePath = "route_path"
    @objc public static let AttributionParameterQueryParameters = "query_params"
    @objc public static let AttributionParameterIsFirstSession = "is_first_session"
    @objc public static let AttributionParameterAttributionData = "attribution_data"
    
    @objc public static let DeepOneErrorDomain = "DeepOneErrorDomain"
    
    @objc public enum DeepOneErrorCode: Int {
        case invalidConfiguration = 1001
        case networkError = 1002
        case attributionFailed = 1003
        case invalidURL = 1004
        case missingCredentials = 1005
    }
    
    public typealias AttributionHandler = (_ attributionData: DeepOneAttributionData?, _ error: NSError?) -> Void
    
    public static let shared = DeepOne()

    private var isDevelopmentMode = false
    private var attributionHandler: AttributionHandler?
    
    private var apiKey: String? {
        guard
            let keys = Bundle.main.object(forInfoDictionaryKey: "DeepOne.keys") as? [String: Any],
            let key = keys[isDevelopmentMode ? "test" : "live"] as? String else { return nil }
        return key
    }
    
    private var isFirstSession: Bool {
        didSet {
            if !isFirstSession {
                DeepOneCoreAPI.setKeychainData(value: Data(), forKey: "first_session_marker")
            } else {
                DeepOneCoreAPI.deleteKeychainData(key: "first_session_marker")
            }
        }
    }

    private override init() {
        isFirstSession = DeepOneCoreAPI.getKeychainData(key: "first_session_marker") == nil
        super.init()
        defer {
            isFirstSession = false
        }
    }

#if canImport(UIKit)
    public func configure(launchOptions: [UIApplication.LaunchOptionsKey: Any]?, 
                         developmentMode: Bool = false,  
                         attributionHandler: AttributionHandler?) {
        _configure(developmentMode: developmentMode, attributionHandler: attributionHandler)
    }
#elseif canImport(Cocoa)
    public func configure(notification: Notification, 
                         developmentMode: Bool = false,  
                         attributionHandler: AttributionHandler?) {
        _configure(developmentMode: developmentMode, attributionHandler: attributionHandler)
    }
#endif

    @objc public func createAttributedLink(configuration: DeepOneCreateLinkBuilder, completion: @escaping (URL?, NSError?) -> Void) {
        guard let parameters = configuration.buildParameters() else { 
            let error = NSError(domain: DeepOne.DeepOneErrorDomain, 
                              code: DeepOneErrorCode.invalidConfiguration.rawValue,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid link configuration provided"])
            completion(nil, error)
            return 
        }
        
        DeepOneCoreAPI.shared.createLink(params: parameters,
                                         apiKey: apiKey ?? "") { result in
            switch result {
                case .success(let url):
                    completion(url, nil)
                case .failure(let error):
                    let nsError = NSError(domain: DeepOne.DeepOneErrorDomain,
                                        code: DeepOneErrorCode.networkError.rawValue,
                                        userInfo: [NSLocalizedDescriptionKey: "Network error: \(error.localizedDescription)",
                                                 NSUnderlyingErrorKey: error])
                    completion(nil, nsError)
            }
        }
    }

    private func _configure(developmentMode: Bool = false, attributionHandler: AttributionHandler?) {
        self.isDevelopmentMode = developmentMode
        self.attributionHandler = attributionHandler
        performAttributionAnalysis { url, error in
            DispatchQueue.main.async {
                if let error {
                    attributionHandler?(nil, error)
                } else {
                    self.processAttributionData(from: url)
                }
            }
        }
    }

    @objc(continueUserActivity:)
    @discardableResult public func processUniversalLink(_ activity: NSUserActivity) -> Bool {
        guard
            activity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = activity.webpageURL else { return false }
        return processAttributionData(from: url)
    }

    @objc public func clearAttributionData() {
        DeepOneCoreAPI.deleteKeychainData(key: "first_session_marker")
    }

    @objc @discardableResult
    public func trackAttributionURL(_ url: URL) -> Bool {
        return processAttributionData(from: url)
    }

    @discardableResult private func processAttributionData(from url: URL?) -> Bool {
        var attributionData = [String: Any]()

        attributionData[DeepOne.AttributionParameterIsFirstSession] = isFirstSession
        
        if let url {
            attributionData[DeepOne.AttributionParameterOriginURL] = url.absoluteString
            
            if let components = URLComponents(string: url.absoluteString) {
                attributionData[DeepOne.AttributionParameterRoutePath] = components.path

                var queryParams = [String: Any]()
                components.queryItems?.forEach { item in
                    queryParams[item.name] = item.value
                }
                attributionData[DeepOne.AttributionParameterQueryParameters] = queryParams
                
                // Extract marketing attribution data
                let marketingData = extractMarketingAttribution(from: queryParams)
                if !marketingData.isEmpty {
                    attributionData[DeepOne.AttributionParameterAttributionData] = marketingData
                }
            }
        }

        DispatchQueue.main.async() {
            let attributionObject = DeepOneAttributionData(from: attributionData)
            self.attributionHandler?(attributionObject, nil)
        }
        return url != nil
    }

    private func performAttributionAnalysis(callback: @escaping (URL?, NSError?) -> Void) {
        DeepOneCoreAPI.shared.verify(deviceFingerprint: getDeviceFingerprint(), 
                                     apiKey: apiKey ?? "") { result in
            switch result {
                case .success(let response):
                    if let isFirstSession = response["isFirstSession"] as? Bool {
                        self.isFirstSession = isFirstSession
                    }

                    let attributedURL = URL(string: response["link"] as? String ?? "")
                    callback(attributedURL, nil)
                    
                case .failure(let error):
                    let nsError = NSError(domain: DeepOne.DeepOneErrorDomain,
                                        code: DeepOneErrorCode.attributionFailed.rawValue,
                                        userInfo: [NSLocalizedDescriptionKey: "Attribution analysis failed: \(error.localizedDescription)",
                                                 NSUnderlyingErrorKey: error])
                    callback(nil, nsError)
            }
        }
    }
    
    private func extractMarketingAttribution(from queryParams: [String: Any]) -> [String: Any] {
        var marketingData = [String: Any]()
        
        // UTM parameters
        let utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"]
        for key in utmKeys {
            if let value = queryParams[key] {
                marketingData[key] = value
            }
        }
        
        // Custom attribution parameters
        if let referrer = queryParams["ref"] {
            marketingData["referrer"] = referrer
        }
        
        if let campaign = queryParams["campaign_id"] {
            marketingData["campaign_identifier"] = campaign
        }
        
        return marketingData
    }
}

#if swift(>=5.5)
extension DeepOne {
    
    @available(iOS 13.0, macOS 10.15, *)
    public func createAttributedLink(configuration: DeepOneCreateLinkBuilder) async -> Result<URL, DeepOneSwiftError> {
        return await withCheckedContinuation { continuation in
            createAttributedLink(configuration: configuration) { url, error in
                if let error = error {
                    continuation.resume(returning: .failure(DeepOneSwiftError.from(nsError: error)))
                } else if let url = url {
                    continuation.resume(returning: .success(url))
                } else {
                    continuation.resume(returning: .failure(.invalidURL))
                }
            }
        }
    }
}

public enum DeepOneSwiftError: Error, LocalizedError {
    case invalidConfiguration
    case networkError(Error)
    case attributionFailed(Error)
    case invalidURL
    case missingCredentials
    
    static func from(nsError: NSError) -> DeepOneSwiftError {
        switch nsError.code {
            case DeepOne.DeepOneErrorCode.invalidConfiguration.rawValue:
            return .invalidConfiguration
            case DeepOne.DeepOneErrorCode.networkError.rawValue:
            return .networkError(nsError.userInfo[NSUnderlyingErrorKey] as? Error ?? nsError)
            case DeepOne.DeepOneErrorCode.attributionFailed.rawValue:
            return .attributionFailed(nsError.userInfo[NSUnderlyingErrorKey] as? Error ?? nsError)
            case DeepOne.DeepOneErrorCode.invalidURL.rawValue:
            return .invalidURL
            case DeepOne.DeepOneErrorCode.missingCredentials.rawValue:
            return .missingCredentials
        default:
            return .networkError(nsError)
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid link configuration provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .attributionFailed(let error):
            return "Attribution analysis failed: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL provided"
        case .missingCredentials:
            return "Missing API credentials in configuration"
        }
    }
}
#endif
