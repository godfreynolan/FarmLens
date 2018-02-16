//
//  TimelineElementKind.swift
//  FarmLens
//
//  Created by Tom Kocik on 2/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

enum TimelineElementKind: String {
    case takeOff = "Take Off"
    case goTo = "Go To"
    case goHome = "Go Home"
    case gimbalAttitude = "Gimbal Attitude"
    case singleShootPhoto = "Single Photo"
    case continuousShootPhoto = "Continuous Photo"
    case recordVideoDuration = "Record Duration"
    case recordVideoStart = "Start Record"
    case recordVideoStop = "Stop Record"
    case waypointMission = "Waypoint Mission"
    case hotpointMission = "Hotpoint Mission"
    case aircraftYaw = "Aircraft Yaw"
}
