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
    @StateObject private var viewModel = ParkingViewModel()
    // ユーザーが選んだ写真(選択前はnil)
    @State private var selectedItem: PhotosPickerItem?
    // 画面に表示する用の画像
    @State private var selectedImage: Image?
    // 画面に表示する用の画像
    @State private var recognizedText: String = ""
    // OCRで認識した文字列をまとめて表示する用
    @State private var parkingRates: [(String, String)] = []
    @State private var navigateToConfirm = false
    
    var body: some View {
        
        VStack {
            if let selectedImage {
                // 画像が選ばれていたら、それを表示する
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                // まだ何も選ばれていない時の案内表示
                Text("まだ画像が選択されていません")
                    .foregroundStyle(.gray)
            }
            
            // 写真ライブラリから画像を選ぶボタン
            PhotosPicker("看板を選択", selection: $selectedItem, matching: .images)
                .padding()
            
            // OCRの認識結果をそのまま画面にも表示(確認用)
            Text(recognizedText)
                .padding()
            // ← viewModelを渡す
            NavigationLink(
                destination: ConfirmView(viewModel: viewModel, parkingRates: parkingRates),
                isActive: $navigateToConfirm) {
                    
                EmptyView()
            }
        }
        .onChange(of: selectedItem) {
            // 選んだ画像が変わるたびに実行される
            Task {
                // 選ばれた画像データを取得し、UIImageに変換する
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)  // 画面表示用に変換
                    recognizeText(from: uiImage)              // 選ばれたらすぐOCRを実行
                }
            }
        }
    }
    
    func recognizeText(from uiImage: UIImage) {
        // UIImageを、Visionが扱える形式(CGImage)に変換する。失敗したら処理を抜ける
        guard let cgImage = uiImage.cgImage else { return }
        
        // 「テキストを認識してほしい」というリクエストを作る
        let request = VNRecognizeTextRequest { request, error in
            // 認識結果を、Visionが返す専用の型にキャストする。失敗したら抜ける
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            // 認識結果(observations)から、それぞれの一番確からしい文字列だけを取り出して配列にする
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // 画面表示やprintはメインスレッドで行う必要があるため、ここで切り替える
            DispatchQueue.main.async {
                // 認識結果を改行区切りでまとめて、画面表示用の変数に反映する
                recognizedText = recognizedStrings.joined(separator: "\n")
                
                // 「時間帯」の形にマッチする正規表現パターン(例: 8:00~22:00)
                // \d{1,2} → 1〜2桁の数字(時)
                // :\d{2}  → コロン+2桁の数字(分)
                // ~       → 時間帯の区切り文字
                // 後半も同じ形の繰り返し
                let timePattern = /\d{1,2}:\d{2}~\d{1,2}:\d{2}/
                
                // 「単価」の形にマッチする正規表現パターン(例: 20分／330円)
                // \d{1,2} → 1〜2桁の数字(分)
                // 分      → そのままの文字
                // [／/]   → 全角スラッシュ・半角スラッシュ、どちらでもOK
                // \s*     → スラッシュの後にスペースが0個以上あってもOK
                // \d+     → 1文字以上の数字(円、桁数自由)
                // 円      → そのままの文字
                // #/ .../# で囲むことで、パターンの中に生のスラッシュを含められる
                let pricePattern = #/\d{1,2}分[／/]\s*\d+円/#
                
                // recognizedStringsの中から、時間帯パターンに一致する行だけを取り出す
                let timeLines = recognizedStrings.filter { $0.contains(timePattern) }
                
                // recognizedStringsの中から、単価パターンに一致する行だけを取り出す
                let priceLines = recognizedStrings.filter { $0.contains(pricePattern) }
                
                // 「時間帯」と「単価」のペアを貯めていく、空の配列を用意する
                var parkingRates: [(String, String)] = []
                
                // timeLinesとpriceLinesを、同じ順番同士でペアにしながらループする
                for (time, price) in zip(timeLines, priceLines) {
                
                    // 単価の中の半角スラッシュを、全角スラッシュに統一してから保存する
                    let normalizedPrice = price.replacingOccurrences(of: "/", with: "／")
                    // 1組ずつ、parkingRatesの末尾に追加していく
                    parkingRates.append((time, normalizedPrice))
                }
                if let maxFeeIndex = recognizedStrings.firstIndex(where: { $0.contains("最大料金") }) {
                    
                    // 前後の行の候補を集める(存在する場合のみ)
                    var nearbyLines: [String] = []
                    
                    // 1個前の行があれば追加
                    if maxFeeIndex > 0 {
                        nearbyLines.append(recognizedStrings[maxFeeIndex - 1])
                    }
                    
                    // 1個後の行があれば追加
                    if maxFeeIndex < recognizedStrings.count - 1 {
                        nearbyLines.append(recognizedStrings[maxFeeIndex + 1])
                    }
                    
                    // 前後の候補の中から、金額パターンにマッチする行を探す
                    let maxFeePattern = #/\d+[,]\d+円/#
                    let maxFeeLine = nearbyLines.compactMap { line in
                        line.firstMatch(of: maxFeePattern)?.output
                    }.first
                    
                    print("最大料金:", maxFeeLine ?? "見つかりませんでした")
                }
                // 確認用に、完成したペアの配列をコンソールに出力する
                print("料金ペア:", parkingRates)
                
                self.parkingRates = parkingRates
                navigateToConfirm = true
            }
        }
        
        // 認識対象の言語を指定(日本語・英語)
        request.recognitionLanguages = ["ja", "en"]
        
        // 画像に対してリクエストを実行するためのハンドラーを作る
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        // リクエストを実行する(失敗しても今回はエラー処理を省略)
        try? handler.perform([request])
    }
}

#Preview {
    ScanView()
}
