//
//  Untitled.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/15.
//
import Foundation
import Combine

// 1つの時間帯における料金ルールを表す型
struct RateEntry {
    let startHour: Int
    let endHour: Int
    let unitMinutes: Int
    let unitPrice: Int
}

// 「最大料金」が、何を基準に判定されるかを表す
enum FeeBasis {
    case duration   // 入庫からの経過時間で判定(例: 入庫後3時間)
    case timeOfDay  // 時計の時刻で判定(例: 21:00〜8:00)
}

// 「最大料金(上限)」のルールを表す型
struct MaxFeeRule {
    let maxFee: Int
    let basis: FeeBasis
    let durationMinutes: Int?   // durationの場合に使う
    let startHour: Int?         // timeOfDayの場合に使う
    let endHour: Int?           // timeOfDayの場合に使う
}

class ParkingViewModel: ObservableObject {
    @Published var entryTime = Date()
    @Published var adjustmentMinutes: Double = 0
    @Published var currentTime = Date()
    @Published var alertThresholdMinutes: Double = 5
    @Published var rateEntries: [RateEntry] = []
    
    // 複数の最大料金ルールを持てるようにする(単一のmaxFeeから変更)
    @Published var maxFeeRules: [MaxFeeRule] = []
    
    var elapsedMinutes: Double {
        let elapsedSeconds = currentTime.timeIntervalSince(entryTime)
        return max(0, elapsedSeconds / 60 + adjustmentMinutes)
    }
    
    func applyRates(_ rawRates: [(String, String)]) {
        rateEntries = rawRates.compactMap { time, price in
            let timeParts = time.components(separatedBy: CharacterSet(charactersIn: "~～"))
            guard timeParts.count == 2 else { return nil }
            
            guard let startHour = Int(timeParts[0].components(separatedBy: ":")[0]),
                  let endHour = Int(timeParts[1].components(separatedBy: ":")[0]) else {
                return nil
            }
            
            let cleanedPrice = price.replacingOccurrences(of: "分", with: "")
                                     .replacingOccurrences(of: "円", with: "")
                                     .replacingOccurrences(of: "毎に", with: "／")
            let priceParts = cleanedPrice.components(separatedBy: "／")
            guard priceParts.count == 2,
                  let unitMinutes = Int(priceParts[0]),
                  let unitPrice = Int(priceParts[1]) else {
                return nil
            }
            
            return RateEntry(startHour: startHour, endHour: endHour, unitMinutes: unitMinutes, unitPrice: unitPrice)
        }
    }
    
    var currentRate: RateEntry? {
        let hour = Calendar.current.component(.hour, from: entryTime)
        return rateEntries.first { rate in
            if rate.startHour < rate.endHour {
                return hour >= rate.startHour && hour < rate.endHour
            } else {
                return hour >= rate.startHour || hour < rate.endHour
            }
        }
    }
    
    // 今、有効な最大料金ルールを1つ探す(複数あれば最初に見つかったものを採用)
    var activeMaxFeeRule: MaxFeeRule? {
        let hour = Calendar.current.component(.hour, from: entryTime)
        
        return maxFeeRules.first { rule in
            switch rule.basis {
            case .duration:
                // 経過時間基準:今の経過時間が、指定の分数以内かどうか
                guard let duration = rule.durationMinutes else { return false }
                return elapsedMinutes <= Double(duration)
                
            case .timeOfDay:
                // 時刻基準:入庫時刻が、指定の時間帯に含まれるかどうか
                guard let start = rule.startHour, let end = rule.endHour else { return false }
                if start < end {
                    return hour >= start && hour < end
                } else {
                    return hour >= start || hour < end
                }
            }
        }
    }
    
    var fee: Int {
        guard let rate = currentRate else {
            let hours = max(1, ceil(elapsedMinutes / 60))
            return Int(hours * 200)
        }
        
        // 基本単価での計算(積み上げ方式)
        let units = max(1, ceil(elapsedMinutes / Double(rate.unitMinutes)))
        let baseFee = Int(units) * rate.unitPrice
        
        // 有効な最大料金ルールがあれば、そちらで頭打ちにする
        if let rule = activeMaxFeeRule {
            return min(baseFee, rule.maxFee)
        }
        
        return baseFee
    }
    
    var remainingMinutes: Int {
        guard let rate = currentRate else {
            let hours = max(1, ceil(elapsedMinutes / 60))
            return Int((hours * 60) - elapsedMinutes)
        }
        let units = max(1, ceil(elapsedMinutes / Double(rate.unitMinutes)))
        let nextBoundary = units * Double(rate.unitMinutes)
        return Int(nextBoundary - elapsedMinutes)
    }
}
