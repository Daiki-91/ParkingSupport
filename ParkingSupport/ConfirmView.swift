//
//  ConfirmView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/25.
//

import SwiftUI

struct ConfirmView: View {
    @ObservedObject var viewModel: ParkingViewModel   // 自分では作らず、外から受け取る
    let parkingRates: [(String, String)]
    
    @State private var navigateToContent = false
    
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
                    Text("料金体系を読み取れませんでした")
                        .foregroundStyle(.gray)
                } else {
                    List(Array(parkingRates.enumerated()), id: \.offset) { _, rate in
                        VStack(alignment: .leading) {
                            Text(rate.0)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(rate.1)
                                .foregroundStyle(.gray)
                        }
                        .listRowBackground(Color.black)
                    }
                    .scrollContentBackground(.hidden)
                }
                
                // 確定ボタン。ViewModelに料金ルールを反映してから、計算画面へ遷移する
                Button("この内容で確定") {
                    viewModel.applyRates(parkingRates)
                    navigateToContent = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                NavigationLink(
                    destination: ContentView(viewModel: viewModel),
                    isActive: $navigateToContent
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ConfirmView(viewModel: ParkingViewModel(), parkingRates: [("8:00~22:00", "20分／330円"), ("22:00~8:00", "60分／110円")])
}
