//
//  ContentView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/07/18.
//

import SwiftUI
import Combine

struct ContentView: View {
   
    // 自分で作らず、外から受け取る形に変更
    @ObservedObject var viewModel: ParkingViewModel
    // アラート(次の段階まであと5分等の通知)を表示するかどうかのスイッチ
    // 計算結果ではなく画面固有の状態なので、ViewModelではなくここで管理
    @State private var showAlert = false
    // 既にアラートを表示したかどうかのフラグ(何度も表示されるのを防ぐ)
    @State private var hasAlerted = false
    // 1秒ごとに時刻を更新するためのタイマー
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                
                // 現在の料金を表示
                Text("¥\(viewModel.fee)")
                    .font(.system(size: 48, weight: .bold))
                
                // 次の料金段階までの残り時間を表示
                Text("次の段階まであと\(viewModel.remainingMinutes)分")
                
                // 入庫時刻を選択するUI。viewModel.entryTimeと連動
                DatePicker("入庫時間", selection: $viewModel.entryTime)
                    .tint(Color.white)
                
                // 入庫時刻を手動で微調整するスライダー
                Slider(value: $viewModel.adjustmentMinutes, in: -15...15, step: 1)
                
                // 補正値を0に戻すボタン(誤操作対策)
                Button("補正をリセット") {
                    viewModel.adjustmentMinutes = 0
                }
                
                Text("補正: \(Int(viewModel.adjustmentMinutes))分")
                
                Text("通知タイミング: \(Int(viewModel.alertThresholdMinutes))分前")

                Slider(value: $viewModel.alertThresholdMinutes, in: 1...30, step: 1)
                
                // アラート表示のテスト用ボタン(本来は自動発火が理想、今後の課題)
                Button("アラートテスト") {
                    showAlert = true
                }
                .padding()
                .foregroundStyle(Color.white)
            }
            .preferredColorScheme(.dark)
            
            // 1秒ごとにcurrentTimeを更新し、画面を再計算させる
            .onReceive(timer) { _ in
                viewModel.currentTime = Date()
                
                if viewModel.remainingMinutes <= Int(viewModel.alertThresholdMinutes) && !hasAlerted {
                    showAlert = true
                    hasAlerted = true
                }
            }
            
            .onChange(of: viewModel.entryTime) {
                hasAlerted = false
            }
            
            .alert("まもなく値上がりします", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text("あと\(viewModel.remainingMinutes)分で料金が上がります")
            }
        }
    }
}
 #Preview {
        ContentView(viewModel: ParkingViewModel())
    }

 
