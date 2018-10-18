//
//  MasterViewController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import MapKit

class MasterViewController: UITableViewController {
    private var isLoadingTable = true
    
    override func viewDidLoad() {
        let img = #imageLiteral(resourceName: "agribotix")
        let imgView = UIImageView(image:img)
        
        let bannerWidth  = (navigationController?.navigationBar.frame.size.width)! - 10
        let bannerHeight = (navigationController?.navigationBar.frame.size.height)! - 10
        
        let bannerX = bannerWidth / 2 - img.size.width
        let bannerY = bannerHeight / 2 - img.size.height
        
        imgView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight)
        imgView.contentMode = .scaleAspectFit
        
        navigationItem.titleView = imgView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Flight Plan"
            cell.detailTextLabel?.text = ""
        case 1:
            cell.textLabel?.text = "Image Download"
            cell.detailTextLabel?.text = ""
        case 2:
            cell.textLabel?.text = "View Images"
            cell.detailTextLabel?.text = ""
        default:
            cell.textLabel?.text = "test"
            cell.detailTextLabel?.text = "test"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLoadingTable && tableView.indexPathsForVisibleRows?.last?.row == indexPath.row {
            isLoadingTable = false
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "FlightPathSegue", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "ImageDownloadSegue", sender: nil)
        case 2:
            self.performSegue(withIdentifier: "ViewImagesSegue", sender: nil)
        default:
            break
        }
    }
}
