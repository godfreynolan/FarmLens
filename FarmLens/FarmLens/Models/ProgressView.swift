//
//  ProgressView.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/1/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit

class ProgressView : NSObject {
    private var alertController: UIAlertController!
    
    override init() {
        alertController = UIAlertController(title: "Status", message: "", preferredStyle: .alert)
    }
    
    func showAlertWithMessage(viewController: UIViewController, message: String) {
        alertController.message = message
        viewController.present(alertController, animated: true)
    }
    
    func updateMessage(message: String) {
        alertController.message = message
    }
    
    func dismissAlert() {
        alertController.dismiss(animated: true, completion: nil)
    }
}
