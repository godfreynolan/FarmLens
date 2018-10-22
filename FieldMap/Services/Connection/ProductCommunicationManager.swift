//
//  ProductCommunicationManager.swift
//

import DJISDK

class ProductCommunicationManager: NSObject {
    
    func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        
        guard appKey != nil && appKey!.isEmpty == false else {
            NSLog("Please enter your app key in the info.plist")
            return
        }
        DJISDKManager.registerApp(with: self)
    }
}

extension ProductCommunicationManager : DJISDKManagerDelegate {
    func appRegisteredWithError(_ error: Error?) {
        if error == nil {
            print("SDK Registered successfully")
            DJISDKManager.enableRemoteLogging(withDeviceID: "0123", logServerURLString: "10.5.2.16:4567")
        } else {
            print("SDK Registered with error \(error?.localizedDescription ?? "")")
        }

        DJISDKManager.startConnectionToProduct()
    }
    
}
