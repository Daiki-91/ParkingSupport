//
//  ContentView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/07/18.
//

import SwiftUI
import Combine

struct ContentView: View {
   
    @StateObject private var viewModel = ParkingViewModel()
    
    @State private var showAlert = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("¥\(viewModel.fee)")
                    .font(.system(size: 48, weight: .bold))
                
                Text("次の段階まであと\(viewModel.remainingMinutes)分")
                
                DatePicker("入庫時間", selection: $viewModel.entryTime)
                    .tint(Color.white)
                
                Slider(value: $viewModel.adjustmentMinutes, in: -15...15, step: 1)
                
                Button("補正をリセット") {
                    viewModel.adjustmentMinutes = 0
                }
                
                Text("補正: \(Int(viewModel.adjustmentMinutes))分")
                
                Button("アラートテスト") {
                    showAlert = true
                }
                .padding()
                .foregroundStyle(Color.white)
            }
            .preferredColorScheme(.dark)
            .onReceive(timer) { _ in
                viewModel.currentTime = Date()
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
        ContentView()
    }

 
