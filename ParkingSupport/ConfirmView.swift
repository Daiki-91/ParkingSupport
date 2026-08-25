//
//  ConfirmView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/25.
//

import SwiftUI

struct ConfirmView: View {
    // ScanViewから渡される「時間帯・単価」のペア一覧
    let parkingRates: [(String, String)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("読み取り結果を確認")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.top)
                
                if parkingRates.isEmpty {
                    // 何も読み取れなかった場合の表示
                    Text("料金体系を読み取れませんでした")
                        .foregroundStyle(.gray)
                } else {
                    // idを付けて、SwiftUIのListが1つずつ区別できるようにする
                    List(Array(parkingRates.enumerated()), id: \.offset) { _, rate in
                        VStack(alignment: .leading) {
                            Text(rate.0)  // 時間帯
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(rate.1)  // 単価
                                .foregroundStyle(.gray)
                        }
                        .listRowBackground(Color.black)
                    }
                    .scrollContentBackground(.hidden)  // Listのデフォルト背景を消して、黒背景を活かす
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    // プレビュー用にダミーデータを渡す
    ConfirmView(parkingRates: [("8:00~22:00", "20分／330円"), ("22:00~8:00", "60分/ 110円")])
}
