//
//  Untitled.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/15.
//
import Foundation
import Combine

class ParkingViewModel: ObservableObject {
    @Published var entryTime = Date()
    @Published var adjustmentMinutes: Double = 0
    @Published var currentTime = Date()
    
    var elapsedMinutes: Double {
        let elapsedSeconds = currentTime.timeIntervalSince(entryTime)
        return max(0, elapsedSeconds / 60 + adjustmentMinutes)
    }
    
    var ratePerHour: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entryTime)
        if hour >= 8 && hour < 20 {
            return 200
        } else {
            return 100
        }
    }
    
    var fee: Int {
        let hours = max(1, ceil(elapsedMinutes / 60))
        return Int(hours * Double(ratePerHour))
    }
    
    var remainingMinutes: Int {
        let hours = max(1, ceil(elapsedMinutes / 60))
        return Int((hours * 60) - elapsedMinutes)
    }
}
