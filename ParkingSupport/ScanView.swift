//
//  ScanView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/19.
//

import SwiftUI
import PhotosUI
import Vision

struct ScanView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var recognizedText: String = ""  // 認識されたテキストをまとめて表示する
    
    
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
            
            // 認識結果を画面にも表示しておく(コンソールだけでなく確認しやすくするため)
            Text(recognizedText)
                .padding()
        }
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                    recognizeText(from: uiImage)  // 画像が選ばれたら、すぐに文字認識を実行
                }
            }
        }
    }
    
    func recognizeText(from uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            
            // 認識結果を、画面表示用の変数に反映する(改行区切りでまとめる)
            DispatchQueue.main.async {
                recognizedText = recognizedStrings.joined(separator: "\n")
            }
        }
        
        request.recognitionLanguages = ["ja", "en"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
}

#Preview {
    ScanView()
}
