//
//  enums.swift
//  FastDowloader
//
//  Created by Jose Fidalgo on 18-08-26.
//

import Foundation

enum Quality: String, CaseIterable, Identifiable {
    case normal, low, extra_low
    var id: Self { self }
}
