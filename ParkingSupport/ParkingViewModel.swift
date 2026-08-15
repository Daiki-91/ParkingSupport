//
//  Untitled.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/15.
//
import Foundation
import Combine

// 料金計算に関するロジックをまとめたViewModel
// ContentView(見た目)から計算処理を切り離すことで、役割分担を明確にしている

class ParkingViewModel: ObservableObject {
    @Published var entryTime = Date() // 入庫時刻(初期値は今の時刻)
    @Published var adjustmentMinutes: Double = 0 // 補正分数(-15〜+15分を想定)
    @Published var currentTime = Date() // 「今の時刻」。Timerで1秒ごとに更新される
    
    // 経過時間(分)を計算して返す
    // マイナスにならないよう、下限を0に制限している(補正スライダーの誤操作対策)
    var elapsedMinutes: Double {
        let elapsedSeconds = currentTime.timeIntervalSince(entryTime)
        return max(0, elapsedSeconds / 60 + adjustmentMinutes)
    }
    
    // 現在の時間帯に応じた、1時間あたりの料金(円)を返す
    // 8時〜20時未満: 昼間料金(200円)、それ以外: 夜間料金(100円)
    var ratePerHour: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entryTime)
        if hour >= 8 && hour < 20 {
            return 200
        } else {
            return 100
        }
    }
    
    // 現在の合計料金を計算して返す
    // 経過時間がどれだけ短くても、最低1時間分の料金が発生する前提で計算(hoursの下限を1に制限)
    var fee: Int {
        let hours = max(1, ceil(elapsedMinutes / 60))
        return Int(hours * Double(ratePerHour))
    }
    
    // 次の料金段階(次の1時間の壁)まで、あと何分かを計算して返す
    var remainingMinutes: Int {
        let hours = max(1, ceil(elapsedMinutes / 60))
        return Int((hours * 60) - elapsedMinutes)
    }
}
