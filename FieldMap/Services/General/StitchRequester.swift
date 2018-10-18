//
//  StitchRequester.swift
//  FarmLens
//
//  Created by Nick Donnelly on 10/10/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation
import Photos
import Alamofire

class StitchRequester {
    private var batch_id: String? = nil;
    private var total_image_count: Int = 0;
    
    init() { }
    
    func startStitch(onComplete complete: @escaping () -> Void) {
        let url = URL(string: NetworkConstants.PATH_START_STITCH)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
            guard let data = data else { return }
            let string_data = String(data: data, encoding: .utf8)!
            self.batch_id = string_data.trimmingCharacters(in: .whitespacesAndNewlines)
            complete()
        }
        task.resume()
    }
    
    /// Add each image one after another with a request.
    func addImages(images: [Data], onImageSuccess success: @escaping () -> Void,
                   onImageFailure failure: @escaping (_ err: String) -> Void) {
        self.total_image_count = images.count
        let serialQueue = DispatchQueue(label: "serialQueue")
        for image in images {
            let headers = [
                "Content-Type": "image/png",
                "Batch-Id": self.batch_id!
            ];
            
            serialQueue.async {
                Alamofire.upload(image, to: NetworkConstants.PATH_ADD_IMAGE, method: .post, headers: headers).responseData { (response) in
                    switch response.result {
                    case .success:
                        success()
                        break
                    case .failure:
                        failure("")
                        break
                    }
                }
            }
        }
    }
    
    /// Lock the stitch after having added all of the images.
    func lockStitch(onSuccess success: @escaping () -> Void, onFailure failure: @escaping () -> Void) {
        let headers: HTTPHeaders = [ "Batch-Id": self.batch_id! ]
        Alamofire.request(NetworkConstants.PATH_LOCK_STITCH, method: .post, headers: headers).responseData { (response) in
            switch response.result {
            case .success:
                success()
                break
            case .failure:
                failure()
                break
            }
        }
    }
    
    func pollStitch(isComplete complete: @escaping (_ isReady: Bool) -> Void) {
        let headers: HTTPHeaders = [ "Batch-Id": self.batch_id! ]
        Alamofire.request(NetworkConstants.PATH_POLL_STITCH, method: .post, headers: headers).responseData { (response) in
            switch response.result {
            case .success:
                complete(response.response!.statusCode == 200)
                break
            case .failure:
                complete(false)
                break
            }
        }
    }
    
    func retrieveResult(onResult retrieved: @escaping (Data?) -> Void) {
        let headers: HTTPHeaders = [ "Batch-Id": self.batch_id! ]
        Alamofire.request(NetworkConstants.PATH_RETRIEVE_STITCH, method: .get, headers: headers).responseData { (response) in
            switch response.result {
            case .success:
                retrieved(response.data)
                break
            case .failure:
                retrieved(nil)
                break
            }
        }
    }
}
