//
//  NetworkInformation.swift
//  FarmLens
//
//  Created by Administrator on 10/10/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation

struct NetworkConstants {
    static let HOSTNAME = "http://54.210.89.81:80"
    static let PATH_START_STITCH = HOSTNAME + "/start_stitch_batch"
    static let PATH_ADD_IMAGE = HOSTNAME + "/add_stitch_image"
    static let PATH_LOCK_STITCH = HOSTNAME + "/lock_batch"
    static let PATH_POLL_STITCH = HOSTNAME + "/poll_batch"
    static let PATH_RETRIEVE_STITCH = HOSTNAME + "/retrieve_result"
}
