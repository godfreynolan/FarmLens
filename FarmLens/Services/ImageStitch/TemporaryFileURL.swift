//
//  TemporaryFileURL.swift
//  FarmLens
//
//  Created by Ian Timmis on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation

public final class TemporaryFileURL: ManagedURL {
    
    public let contentURL: URL
    
    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
    
    deinit {
        DispatchQueue.global(qos: .utility).async { [contentURL = self.contentURL] in
            try? FileManager.default.removeItem(at: contentURL)
        }
    }
}

public protocol ManagedURL {
    var contentURL: URL { get }
    func keepAlive()
}

public extension ManagedURL {
    public func keepAlive() { }
}

extension URL: ManagedURL {
    public var contentURL: URL { return self }
}
