//
//  FlightCompleteViewController.swift
//  FarmLens
//
//  Created by Administrator on 10/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit

class FlightCompleteViewController: UIViewController {

    @IBOutlet weak var downloadNow: UIButton!
    @IBOutlet weak var downloadLater: UIButton!
    @IBOutlet weak var cancelDownload: UIButton!
    @IBOutlet weak var checkIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private let totalImagesToDownload: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let trackInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 15)
        var trackImg = UIImage(named: "progress-track")
        var progressImg = UIImage(named: "progress")
        trackImg = trackImg?.resizableImage(withCapInsets: trackInsets)
        progressImg = progressImg?.resizableImage(withCapInsets: trackInsets)
        self.progressBar.trackImage = trackImg
        self.progressBar.progressImage = progressImg
    }
    
    @IBAction func downloadNowClicked(_ sender: Any) {
        self.downloadNow.isHidden = true
        self.downloadLater.isHidden = true
        self.checkIcon.isHidden = true
        self.titleLabel.text = "Downloading Images..."
        self.progressBar.isHidden = false
        self.cancelDownload.isHidden = false
        self.statusLabel.isHidden = false
    }
    
    @IBAction func downloadLaterClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
