import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
import IOKit
import IOKit.serial
#endif

internal extension OperatingSystemVersion {
    var formatted: String {
        return [majorVersion, minorVersion, patchVersion].map(String.init).joined(separator: ".")
    }
}

internal extension Locale {
    static var preferredLanguageCode: String {
        guard let preferredLanguage = preferredLanguages.first,
              let code = Locale(identifier: preferredLanguage).languageCode else {
            return "en"
        }
        return code
    }

    static var preferredLanguageCodes: [String] {
        return Locale.preferredLanguages.compactMap({Locale(identifier: $0).languageCode})
    }
}

/// Generates device fingerprint data for attribution analysis
internal func getDeviceFingerprint() -> [String: Any] {
    var deviceInfo = [String: Any]()
    
    // Platform information
    deviceInfo["os"] = "iOS"
    deviceInfo["osVersion"] = ProcessInfo.processInfo.operatingSystemVersion.formatted
    
#if canImport(UIKit)
    // iOS device information
    deviceInfo["screenSize"] = "\(Int(UIScreen.main.nativeBounds.width)) x \(Int(UIScreen.main.nativeBounds.height))"
    deviceInfo["model"] = UIDevice.current.model
    deviceInfo["deviceId"] = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
#elseif canImport(Cocoa)
    // macOS device information
    deviceInfo["screenSize"] = "\(Int(NSScreen.main?.frame.width ?? 0)) x \(Int(NSScreen.main?.frame.height ?? 0))"
    deviceInfo["model"] = ProcessInfo.processInfo.hostName
    deviceInfo["deviceId"] = getMacSerialIdentifier() ?? UUID().uuidString
#endif
    
    // Localization information
    deviceInfo["languageCode"] = Locale.preferredLanguageCode
    
    return deviceInfo
}

#if canImport(Cocoa)
/// Retrieves the Mac hardware serial number for device identification
internal func getMacSerialIdentifier() -> String? {
    var platformExpert: io_service_t = 0
    guard let serviceName = "IOPlatformExpertDevice" as NSString? else { return nil }

    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName.utf8String))
    if platformExpert == 0 {
        return nil
    }

    guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0) else {
        IOObjectRelease(platformExpert)
        return nil
    }

    IOObjectRelease(platformExpert)
    return serialNumberAsCFString.takeUnretainedValue() as? String
}
#endif
