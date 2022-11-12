import Foundation
import PluginUtils

final public class UserDefaultsPlugin: FlipperPlugin {
    public let id: String = "Preferences"
    public let runInBackground: Bool = true
    
    private weak var connection: FlipperConnection?
    
    let suiteName: String?
    let standardUserDefaults: UserDefaults = .standard
    
    public init(suiteName: String?) {
        self.suiteName = suiteName
        FKUserDefaultsSwizzleUtility.listen { [weak self] userDefaults, value, key in
            self?.userDefaults(userDefaults, changedWithValue: value, key: key)
        }
    }
    
    public func didConnect(connection: FlipperConnection) {
        self.connection = connection
        connection.receive(method: "getAllSharedPreferences") { [weak self] params, responder in
            guard let `self` = self else { return }
            var userDefaultsDict = [String: Any]()
            userDefaultsDict[self.kStandardUserDefaultsName] = self.standardUserDefaults.dictionaryRepresentation()
            if let appSuiteUserDefaults = self.appSuiteUserDefaults {
                userDefaultsDict[self.kAppSuiteUserDefaultsName] = appSuiteUserDefaults.dictionaryRepresentation()
            }
            responder.success(response: .dict(userDefaultsDict))
        }
        
        connection.receive(method: "setSharedPreference") { [weak self] params, responder in
            guard let `self` = self,
                  let sharedPreferences = self.sharedPreferencesForParams(params: params),
                  let preferenceName = params["preferenceName"] as? String else { return }
            sharedPreferences.set(params["preferenceValue"],
                                  forKey: preferenceName)
            responder.success(response: .dict(sharedPreferences.dictionaryRepresentation()))
        }
        
        connection.receive(method: "deleteSharedPreference") { [weak self] params, responder in
            guard let `self` = self,
                  let sharedPreferences = self.sharedPreferencesForParams(params: params),
                  let preferenceName = params["preferenceName"] as? String else { return }
            sharedPreferences.removeObject(forKey: preferenceName)
            responder.success(response: .dict(sharedPreferences.dictionaryRepresentation()))
        }
    }
    
    public func didDisconnect() {
        self.connection = nil
    }
    
    // MARK: Private
    
    private lazy var appSuiteUserDefaults: UserDefaults? = {
        if let suiteName,
           !suiteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return UserDefaults(suiteName: suiteName)
        }
        return nil
    }()
    
    private func userDefaults(_ userDefaults: UserDefaults?,
                              changedWithValue value: Any?,
                              key: String) {
        guard let userDefaults = userDefaults else { return }
        let interval = Date().timeIntervalSince1970 * 1000
        let intervalString = String(format: "%f", interval)
        var params: [String: Any] = [
            "name": key,
            "time": intervalString
        ]
        if let value = value {
            params["value"] = value
        } else {
            params["deleted"] = "YES"
        }
        let sharedPreferencesName = userDefaults == standardUserDefaults ?
        kStandardUserDefaultsName : kAppSuiteUserDefaultsName
        params["preferences"] = sharedPreferencesName
        connection?.send(method: "sharedPreferencesChange",
                         params: params)
    }
    
    private func sharedPreferencesForParams(params: [String: Any]) -> UserDefaults? {
        let sharedPreferencesNameKey = "sharedPreferencesName"
        if let value = params[sharedPreferencesNameKey] as? String {
            return value == kAppSuiteUserDefaultsName ? appSuiteUserDefaults : standardUserDefaults
        } else {
            return standardUserDefaults
        }
    }
    
    private let kStandardUserDefaultsName = "Standard UserDefaults"
    private let kAppSuiteUserDefaultsName = "App Suite UserDefaults"
}
