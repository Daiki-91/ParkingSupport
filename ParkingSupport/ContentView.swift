//
//  ContentView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/07/18.
//

import SwiftUI

struct ContentView: View {
    // @State: この値が変わったら画面も自動で再描画される、という印
    // private: このView(ContentView)の中だけで使う変数、という制限
    @State private var entryTime = Date()   // 入庫時刻(初期値は今の時刻)
    
    var ratePerHour = 200  // 1時間あたりの料金(円)
    
    var body: some View {
        let now = Date()  // 現在時刻を取得
        // entryTime(入庫時刻)からnow(現在時刻)までの経過時間を「秒」で計算
        let elapsedSeconds = now.timeIntervalSince(entryTime)
        // 秒を分に変換(60秒 = 1分)
        let elapsedMinutes = elapsedSeconds / 60
        // 分を時間に変換し、切り上げる(例: 61分 → 1.01時間 → 切り上げで2時間扱い)
        let hours = ceil(Double(elapsedMinutes) / 60)
        // 時間数 × 時間あたり料金 = 合計料金
        let fee = hours * Double(ratePerHour)
        
        let remainingMinutes = (hours * 60) - elapsedMinutes
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // feeを整数に変換して、¥マークと一緒に大きな文字で表示
                Text("¥\(Int(fee))")
                    .font(.system(size: 48, weight: .bold))
                // 時刻選択UI。selection: $entryTime で、選んだ時刻がentryTimeに反映される
                
                Text("次の段階まであと\(Int(remainingMinutes))分")
                // $をつけることで「entryTimeと値を連動(バインディング)させる」という意味になる
                DatePicker("入庫時間", selection: $entryTime)
                    .tint(Color.white)
            }
            .padding()
            .foregroundStyle(Color.white)
        }
        .preferredColorScheme(.dark)
    }
}
#Preview {
        ContentView()
    }

