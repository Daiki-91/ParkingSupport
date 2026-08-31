//
//  ScanView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/19.
//

import SwiftUI      // UIを組み立てるための基本フレームワーク
import PhotosUI     // 写真ライブラリから画像を選ぶための機能(PhotosPicker)
import Vision        // OCR(画像からの文字認識)を行うためのフレームワーク

struct ScanView: View {
    // このタイミングでParkingViewModelを生成する(自分で作る側なので@StateObject)
    // この画面から、確認画面・計算画面へと同じインスタンスを引き継いでいく
    @StateObject private var viewModel = ParkingViewModel()
    
    // ユーザーが写真ライブラリで選んだ項目(選択前はnil)
    @State private var selectedItem: PhotosPickerItem?
    
    // 画面に表示する用に変換した画像
    @State private var selectedImage: Image?
    
    // OCRで認識した文字列を、確認用にまとめて画面に表示するための変数
    @State private var recognizedText: String = ""
    
    // 「時間帯・単価」のペアを貯めておく配列(ConfirmViewに渡す)
    @State private var parkingRates: [(String, String)] = []
    
    // 「最大料金っぽい行」の候補をすべて貯めておく配列(複数見つかることもある)
    @State private var maxFeeCandidates: [String] = []
    
    // OCRが完了したら、この値をtrueにしてConfirmViewへ自動遷移させる
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
            
            // 画面には見えないが、navigateToConfirmがtrueになった瞬間に
            // ConfirmViewへ自動的に画面遷移させるための仕掛け
            NavigationLink(
                destination: ConfirmView(viewModel: viewModel, parkingRates: parkingRates, maxFeeCandidates: maxFeeCandidates),
                isActive: $navigateToConfirm
            ) {
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
    
    // ある行(line)が、「最大料金」を示唆するキーワードを含んでいるかどうかを判定する関数
    func isMaxFeeAnchor(_ line: String) -> Bool {
        // 「最大料金」的な意味を持つ、代表的なキーワードのリスト
        let anchorWords = ["最大料金", "駐車後", "入庫後", "1日最大", "当日最大", "とめても", "夜間最大", "昼間最大"]
        
        // リストの中のどれか1つでも、lineに含まれていればtrueを返す
        if anchorWords.contains(where: { line.contains($0) }) {
            return true
        }
        
        // "3時間最大" のような、数字が可変するパターンにも対応する正規表現
        let hourMaxPattern = #/\d+時間最大/#
        // このパターンにマッチする部分が含まれていればtrueを返す
        return line.contains(hourMaxPattern)
    }
    
    // アンカー行(index)の近くから、金額のパターンにマッチする部分を探して返す関数
    func extractPrice(near index: Int, in lines: [String]) -> String? {
        // 金額のパターン(カンマがあってもなくても対応: 1,400円 も 1200円 も拾える)
        let maxFeePattern = #/[\d,]+円/#
        
        // まず、アンカー行自身の中に金額が同居していないか確認する(中崎の看板はこのパターン)
        if let match = lines[index].firstMatch(of: maxFeePattern)?.output {
            return String(match)
        }
        
        // 同居していなければ、前後の行を調べる候補としてまとめる
        var nearby: [String] = []
        // 1個前の行が存在すれば追加
        if index > 0 { nearby.append(lines[index - 1]) }
        // 1個後の行が存在すれば追加
        if index < lines.count - 1 { nearby.append(lines[index + 1]) }
        
        // 前後の候補の中から、最初に金額パターンにマッチしたものを返す
        return nearby.compactMap { $0.firstMatch(of: maxFeePattern)?.output }.first.map { String($0) }
    }
    
    // 近くの注意書きから、経過時間基準か時刻基準かを判定する
       func detectFeeBasis(near index: Int, in lines: [String]) -> (basis: FeeBasis, durationMinutes: Int?, hour: Int?) {
           var nearbyLines: [String] = []
           for offset in -2...2 {
               let targetIndex = index + offset
               if targetIndex >= 0 && targetIndex < lines.count {
                   nearbyLines.append(lines[targetIndex])
               }
           }
           
           let durationPattern = #/入庫後(\d+)時間/#
           for line in nearbyLines {
               if let match = line.firstMatch(of: durationPattern) {
                   let hours = Int(match.1) ?? 0
                   return (.duration, hours * 60, nil)
               }
           }
           
           let hourPattern = #/(\d{1,2})時を過ぎると/#
           for line in nearbyLines {
               if let match = line.firstMatch(of: hourPattern) {
                   let hour = Int(match.1) ?? 0
                   return (.timeOfDay, nil, hour)
               }
           }
           
           return (.timeOfDay, nil, nil)
       }
       
       // アンカー行の近くから、時間帯表記(例: 21:00~8:00)を探して、開始時刻だけを取り出す
       func findNearbyTimeRange(near index: Int, in lines: [String]) -> (start: Int, end: Int)? {
           let timePattern = #/(\d{1,2}):\d{2}[~～](\d{1,2}):\d{2}/#
           
           for offset in -2...2 {
               let targetIndex = index + offset
               guard targetIndex >= 0 && targetIndex < lines.count else { continue }
               
               if let match = lines[targetIndex].firstMatch(of: timePattern) {
                   let start = Int(match.1) ?? 0
                   let end = Int(match.2) ?? 0
                   return (start, end)
               }
           }
           return nil
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
                
                // デバッグ用: 認識された全ての行を、番号付きで確認する
                for (index, line) in recognizedStrings.enumerated() {
                    print("[\(index)] \(line)")
                }
                // 半角チルダ(~)と全角チルダ(～)、どちらにも対応
                let timePattern = #/\d{1,2}:\d{2}[~～]\d{1,2}:\d{2}/#

                // 「分／円」(全角/半角スラッシュ)と「分毎に円」、どちらの表記にも対応
                let pricePattern = #/\d{1,2}分(?:[／/]\s*|毎に)\d+円/#
                
                // recognizedStringsの中から、時間帯パターンに一致する行だけを取り出す
                let timeLines = recognizedStrings.filter { $0.contains(timePattern) }
                
                // recognizedStringsの中から、単価パターンに一致する行だけを取り出す
                let priceLines = recognizedStrings.filter { $0.contains(pricePattern) }
                
                // 「時間帯」と「単価」のペアを貯めていく、空の配列を用意する
                var rates: [(String, String)] = []
                
                // timeLinesとpriceLinesを、同じ順番同士でペアにしながらループする
                for (time, price) in zip(timeLines, priceLines) {
                    // 単価の中の半角スラッシュを、全角スラッシュに統一してから保存する
                    let normalizedPrice = price.replacingOccurrences(of: "/", with: "／")
                    // 1組ずつ、ratesの末尾に追加していく
                    rates.append((time, normalizedPrice))
                }
                
                // 完成したペアの配列を、画面用の状態変数に反映する
                parkingRates = rates
                
                var maxFees: [String] = []
                var rules: [MaxFeeRule] = []

                for (index, line) in recognizedStrings.enumerated() {
                    guard isMaxFeeAnchor(line) else { continue }
                    guard let priceString = extractPrice(near: index, in: recognizedStrings) else { continue }
                    
                    let cleanedPrice = priceString.replacingOccurrences(of: ",", with: "")
                                                   .replacingOccurrences(of: "円", with: "")
                    guard let maxFeeValue = Int(cleanedPrice) else { continue }
                    
                    maxFees.append("\(line) \(priceString)")
                    
                    let detected = detectFeeBasis(near: index, in: recognizedStrings)
                    
                    if detected.basis == .duration, let duration = detected.durationMinutes {
                        rules.append(MaxFeeRule(maxFee: maxFeeValue, basis: .duration, durationMinutes: duration, startHour: nil, endHour: nil))
                    } else if let hour = detected.hour {
                        if let timeRange = findNearbyTimeRange(near: index, in: recognizedStrings) {
                            rules.append(MaxFeeRule(maxFee: maxFeeValue, basis: .timeOfDay, durationMinutes: nil, startHour: timeRange.start, endHour: hour))
                        }
                    }
                }

                maxFeeCandidates = maxFees
                viewModel.maxFeeRules = rules
                
                // デバッグ用:ここまで処理が到達してるか確認
                print("ここまで到達。ルール数:", rules.count)

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
