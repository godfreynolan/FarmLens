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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            print("Error creating the connectedKey")
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { 
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    if newValue!.boolValue {
                        // At this point, a product is connected so we can show it.
                        
                        // UI goes on MT.
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
            DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                if let unwrappedValue = value {
                    if unwrappedValue.boolValue {
                        // UI goes on MT.
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    func resetUI() {
        self.title = "FarmLens"
//        self.openComponents.isEnabled = false;
        self.imgDrone.image = UIImage(named: "DroneNotConnected")
    }
    
    // MARK : Product connection UI changes
    
    func productConnected() {
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }

        //Updates the product's model
        self.productModel.text = "Model: \((newProduct.model)!)"
        
        //Updates the product's connection status
        self.productConnectionStatus.text = "Status: Product Connected"
        
        self.openComponents.isEnabled = true;
        self.openComponents.alpha = 1.0;
        
        self.imgDrone.image = UIImage(named: "DroneConnected")
        
        print("Product Connected")
    }
    
    func productDisconnected() {
        self.productConnectionStatus.text = "Status: No Product Connected"
        
        self.productModel.text = "Model: Not Available"

//        self.openComponents.isEnabled = false;
        self.openComponents.alpha = 0.8;
        
        self.imgDrone.image = UIImage(named: "DroneNotConnected")
        print("Product Disconnected")
    }
}
