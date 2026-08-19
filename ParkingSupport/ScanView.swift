//
//  ScanView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/19.
//

import SwiftUI
import PhotosUI

struct ScanView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    var body: some View {
        VStack {
            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Text("まだ画像が選択されていません")
                    .foregroundStyle(.gray)
            }
            
            PhotosPicker("看板を選択", selection: $selectedItem, matching: .images)
                .padding()
        }
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

#Preview {
    ScanView()
}
