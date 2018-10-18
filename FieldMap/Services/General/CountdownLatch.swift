//
//  CountdownLatch.swift
//  FarmLens
//
//  Provides an atomic method by which to await completion of a task on a separate thread.
//
//  Created by Nick Donnelly on 10/10/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation

final class CountdownLatch {
    private var count: Int32
    private let status = DispatchSemaphore(value: 0)
    
    init(count: Int32) {
        self.count = count
    }
    
    /// Reduce the count by 1
    func countdown() {
        OSAtomicDecrement32(&count) // decrement thread-safely
        if count == 0 {
            self.status.signal()
        }
    }
    
    /// Block until the countdown reaches zero.
    func await() {
        self.status.wait(timeout: DispatchTime.distantFuture)
    }
}
