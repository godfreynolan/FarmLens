//
//  StartupViewController.swift
//

import UIKit
import DJISDK

class StartupViewController: UIViewController {

    weak var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var productConnectionStatus: UILabel!
    @IBOutlet weak var productModel: UILabel!
    @IBOutlet weak var openComponents: UIButton!
    @IBOutlet weak var imgDrone: UIImageView!
    @IBOutlet weak var imgStatusCircle: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: DJIProductKey(param: DJIParamConnection)!, withListener: self, andUpdate: { (oldValue, newValue) in
                self.handleConnectionResponse(keyValue: newValue)
            })
            
            DJISDKManager.keyManager()?.getValueFor(DJIProductKey(param: DJIParamConnection)!, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                self.handleConnectionResponse(keyValue: value)
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    func resetUI() {
        self.title = "FarmLens"
//        self.openComponents.isEnabled = false;
        self.imgDrone.image = UIImage(named: "drone-camera")
        self.imgStatusCircle.image = UIImage(named: "circle-off")
    }
    
    // MARK : Product connection UI changes
    
    func productConnected() {
        if DJISDKManager.product() == nil {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            self.productDisconnected()
            return;
        }

        // Fetches the initial number of files on the SD Card. This is used to determine how many images we have to download later
        let initialCameraCallback = InitialCameraCallback(camera: self.fetchCamera()!, viewController: self)
        initialCameraCallback.fetchInitialData()
    }
    
    func productDisconnected() {
        self.productConnectionStatus.text = "Trying to connect..."
        
        self.productModel.text = "No Drone Connected"

//        self.openComponents.isEnabled = false;
        self.openComponents.alpha = 0.8;
        
        self.imgDrone.image = UIImage(named: "drone-camera")
        self.imgStatusCircle.image = UIImage(named: "circle-off")
    }
    
    func setPreFlightImageCount(imageCount: Int) {
        self.appDelegate.preFlightImageCount = imageCount
    }
    
    func handleConnected() {
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            self.productDisconnected()
            return;
        }
        
        //Updates the product's model
        self.productModel.text = "\((newProduct.model)!)"
        
        //Updates the product's connection status
        self.productConnectionStatus.text = "Drone Connected"
        
        self.openComponents.isEnabled = true;
        self.openComponents.alpha = 1.0;
        
        self.imgDrone.image = UIImage(named: "drone-camera-enabled")
        self.imgStatusCircle.image = UIImage(named: "circle-on")
    }
    
    private func handleConnectionResponse(keyValue: DJIKeyedValue?) {
        if keyValue != nil {
            DispatchQueue.main.async {
                if keyValue!.boolValue {
                    self.productConnected()
                } else {
                    self.productDisconnected()
                }
            }
        }
    }
    
    private func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        }
        
        return nil
    }
}
