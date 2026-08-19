//
//  TopView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/18.
//

import SwiftUI

// アプリ起動時に一瞬だけ表示するスプラッシュ画面
struct TopView: View {
    @State private var isActive = false
    
    // trueになったらContentView(計算画面)に自動で切り替わる
    var body: some View {
        if isActive {
            // 一定時間経過後、計算画面へ遷移
            NavigationStack {
                InputMethodView()
            }
        } else {
            // ロゴを表示するスプラッシュ画面本体
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("パーサポ")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Parking Support System")
                        .foregroundStyle(.gray)
                }
            }
            // 画面が表示された瞬間に実行される
            .onAppear {
                // 3秒後にisActiveをtrueにして、計算画面へ切り替える
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    isActive = true
                }
            }
        }
    }
}
