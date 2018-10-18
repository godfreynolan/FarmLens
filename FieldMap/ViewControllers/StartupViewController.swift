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
    @IBOutlet weak var downloadLaterBtn: UIButton!
    
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
        self.downloadLaterBtn.isEnabled = false
        self.downloadLaterBtn.alpha = 0.5
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

        self.openComponents.alpha = 0.8;
        self.downloadLaterBtn.alpha = 0.5
        self.downloadLaterBtn.isEnabled = false
        
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
        
        self.downloadLaterBtn.isEnabled = true;
        self.downloadLaterBtn.alpha = 1.0
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "downloadLastSegue" {
            let controller = segue.destination as! FlightCompleteViewController
            controller.shouldStartImmediately = true
        }
    }
    
//    @IBAction func downloadPreviousClicked(_ sender: Any) {
//        let alert = UIAlertController(title: "Image Download", message: "This will download ALL images on the drone. Would you like to continue? Note: Ensure you have an internet connection.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(action) in
//            self.appDelegate.preFlightImageCount = 0
//            self.performSegue(withIdentifier: "segueFlightComplete", sender: nil)
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in return}))
//        self.present(alert, animated: true)
//
//    }
}
