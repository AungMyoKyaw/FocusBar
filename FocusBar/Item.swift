//
//  Item.swift
//  FocusBar
//
//  Created by Aung Myo Kyaw on 2/14/26.
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
