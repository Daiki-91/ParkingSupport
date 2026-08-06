//
//  ContentView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/07/18.
//

import SwiftUI
import Combine

struct ContentView: View {
    // @State: この値が変わったら画面も自動で再描画される、という印
    // private: このView(ContentView)の中だけで使う変数、という制限
    // 入庫時刻(初期値は今の時刻)
    @State private var entryTime = Date()
    // 補正分数(-15〜+15分を想定)
    @State private var adjustmentMinutes: Double = 0
    
    @State private var showAlert = false
    // 「今の時刻」を保持する変数を新設
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let elapsedSeconds = currentTime.timeIntervalSince(entryTime)
        // 秒を分に変換(60秒 = 1分)
        let elapsedMinutes = max(0, elapsedSeconds / 60 + adjustmentMinutes)
        // 分を時間に変換し、切り上げる(例: 61分 → 1.01時間 → 切り上げで2時間扱い)
        // 今使ってるカレンダー(地域設定)を取得
        let calender = Calendar.current
        // entryTimeから「時」だけ取り出す
        let hour = calender.component(.hour, from: entryTime)
        
        let ratePerHour = (hour >= 8 && hour < 20) ? 200 : 100
        
        let hours = max(1,ceil(elapsedMinutes / 60))
        // 時間数 × 時間あたり料金 = 合計料金
        let fee = hours * Double(ratePerHour)
        
        let remainingMinutes = (hours * 60) - elapsedMinutes
        
        let shouldShowAlert = remainingMinutes <= 5
        
        
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
                
                Slider(value: $adjustmentMinutes, in: -15...15, step: 1)
                
                Button("補正をリセット"){
                    adjustmentMinutes = 0
                }
                
                Text("補正: \(Int(adjustmentMinutes))分")
                
                Button("アラートテスト") {
                    showAlert = true
                    
                }
                .padding()
                .foregroundStyle(Color.white)
            }
            .preferredColorScheme(.dark)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .alert("まもなく値上がりします",isPresented: $showAlert) {
                Button("OK") {}
            }
            message: {
                Text("あと\(Int(remainingMinutes))分で料金が上がります")
            }
        }
    }
}
 #Preview {
        ContentView()
    }

 
