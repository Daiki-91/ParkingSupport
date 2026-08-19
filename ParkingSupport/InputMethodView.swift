//
//  InputMethodView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/19.
//

import SwiftUI

struct InputMethodView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("パーサポ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Parking Support System")
                    .foregroundStyle(.gray)
                
                Spacer().frame(height: 40)
                
                NavigationLink(destination: Text("カメラでスキャン(後日実装)")) {
                    Label("カメラで撮影する", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                NavigationLink(destination: ScanView()) {
                    Label("フォルダから選ぶ", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                NavigationLink(destination: Text("手動入力画面(後日実装)")) {
                    Label("手動で入力する", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        InputMethodView()
    }
}
