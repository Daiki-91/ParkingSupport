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
            
            // [12]番目(60分／ 110円が入ってる行)だけ、文字を1個ずつ数値化して確認する
            if recognizedStrings.indices.contains(12) {
                let target = recognizedStrings[12]
                for scalar in target.unicodeScalars {
                    
                    // 各文字を「文字そのもの」と「内部コード(16進数)」のセットで出力
                    print("文字: \(scalar) / コード: \(String(format: "%04X", scalar.value))")
                }
            }
            
            // 認識結果を、画面表示用の変数に反映する(改行区切りでまとめる)
            DispatchQueue.main.async {
                recognizedText = recognizedStrings.joined(separator: "\n")
                
                let pricePattern = #/\d{1,2}分[／/]\s*\d+円/#
                
                // recognizedStrings(OCRが認識した行の配列)からpricePatternに一致する行だけを取り出す
                let priceLines = recognizedStrings.filter { line in
                    
                    // 「lineの中にこのパターンに一致する部分があるか」をBool値で返す
                    line.contains(pricePattern)
                    
                }
                
                // デバッグ用:認識された全ての行を、1行ずつ番号付きで確認する
                for (index, line) in recognizedStrings.enumerated() {
                    print("[\(index)] \(line)")
                }
                
                // 確認用に、絞り込めた結果をコンソールに出力
                print("料金っぽい行:", priceLines)
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
