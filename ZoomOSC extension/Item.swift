//
//  Item.swift
//  ZoomOSC extension
//
//  Created by Erick Alvarez on 12/8/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
