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
    let startHour: Int      // 開始時刻(例: 8)
    let endHour: Int        // 終了時刻(例: 22)
    let unitMinutes: Int    // 何分ごとの区切りか(例: 20)
    let unitPrice: Int      // その区切りごとの料金(例: 330)
}

class ParkingViewModel: ObservableObject {
    @Published var entryTime = Date()
    @Published var adjustmentMinutes: Double = 0
    @Published var currentTime = Date()
    //値上がり何分前に通知するか
    @Published var alertThresholdMinutes: Double = 5
    // OCRから読み取った料金ルールを保持する配列
    @Published var rateEntries: [RateEntry] = []
    
    var elapsedMinutes: Double {
        let elapsedSeconds = currentTime.timeIntervalSince(entryTime)
        return max(0, elapsedSeconds / 60 + adjustmentMinutes)
    }
    
    // ConfirmViewから渡された「時間帯・単価」の文字列ペアを、
    // 計算に使える数値データ(RateEntry)に変換して保存する
    func applyRates(_ rawRates: [(String, String)]) {
        rateEntries = rawRates.compactMap { time, price in
            // "8:00~22:00" のような文字列を "~" で分割する
            let timeParts = time.components(separatedBy: "~")
            guard timeParts.count == 2 else { return nil }
            
            // それぞれ ":" で分割して、時の部分だけ取り出す
            guard let startHour = Int(timeParts[0].components(separatedBy: ":")[0]),
                  let endHour = Int(timeParts[1].components(separatedBy: ":")[0]) else {
                return nil
            }
            
            // "20分／330円" のような文字列から、「分」「円」を取り除いて数値だけにする
            let cleanedPrice = price.replacingOccurrences(of: "分", with: "")
                                     .replacingOccurrences(of: "円", with: "")
            let priceParts = cleanedPrice.components(separatedBy: "／")
            guard priceParts.count == 2,
                  let unitMinutes = Int(priceParts[0]),
                  let unitPrice = Int(priceParts[1]) else {
                return nil
            }
            
            return RateEntry(startHour: startHour, endHour: endHour, unitMinutes: unitMinutes, unitPrice: unitPrice)
        }
    }
    
    // 現在時刻(entryTime)が、どのRateEntryに該当するかを探す
    var currentRate: RateEntry? {
        let hour = Calendar.current.component(.hour, from: entryTime)
        
        return rateEntries.first { rate in
            if rate.startHour < rate.endHour {
                // 例: 8:00~22:00 のような、日をまたがない時間帯
                return hour >= rate.startHour && hour < rate.endHour
            } else {
                // 例: 22:00~8:00 のような、日をまたぐ時間帯
                return hour >= rate.startHour || hour < rate.endHour
            }
        }
    }
    
    var fee: Int {
        guard let rate = currentRate else {
            // 料金ルールが1つも読み取れなかった場合の保険(仮の固定料金)
            let hours = max(1, ceil(elapsedMinutes / 60))
            return Int(hours * 200)
        }
        // 経過分数を、単位分数(例: 20分)で割って「何区切り分か」を出す
        let units = max(1, ceil(elapsedMinutes / Double(rate.unitMinutes)))
        return Int(units) * rate.unitPrice
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
