//
//  ConfirmView.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/08/25.
//

import SwiftUI  // UIを組み立てるための基本フレームワーク

struct ConfirmView: View {
    // 自分では作らず、ScanViewから受け取ったものをそのまま使う(参照を共有する)
    @ObservedObject var viewModel: ParkingViewModel
    
    // ScanViewから渡される「時間帯・単価」のペア一覧
    let parkingRates: [(String, String)]
    
    // ScanViewから渡される「最大料金っぽい行」の候補一覧
    let maxFeeCandidates: [String]
    
    // 最大料金の手入力欄に、ユーザーが入力した文字列を保持する
    @State private var maxFeeText: String = ""
    
    // 「確定」ボタンが押されたら、この値をtrueにして計算画面へ自動遷移させる
    @State private var navigateToContent = false
    
    var body: some View {
        ZStack {
            // 背景を黒で塗りつぶす(セーフエリアも含めて)
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // 画面タイトル
                Text("読み取り結果を確認")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.top)
                
                if parkingRates.isEmpty {
                    // 時間帯・単価が1つも読み取れなかった場合の表示
                    Text("料金体系を読み取れませんでした")
                        .foregroundStyle(.gray)
                } else {
                    // 読み取れた時間帯・単価のペアを、1行ずつリスト表示する
                    // enumerated()で番号を振ることで、Listが要素を区別できるようにする
                    List(Array(parkingRates.enumerated()), id: \.offset) { _, rate in
                        VStack(alignment: .leading) {
                            Text(rate.0)  // 時間帯
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(rate.1)  // 単価
                                .foregroundStyle(.gray)
                        }
                        // 行の背景を明示的に黒にする(白飛び防止)
                        .listRowBackground(Color.black)
                    }
                    // Listのデフォルト背景を消して、ZStackの黒背景を活かす
                    .scrollContentBackground(.hidden)
                }
                
                // 最大料金の候補が1つ以上見つかっていれば、この欄を表示する
                if !maxFeeCandidates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最大料金の候補")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        // 見つかった候補を、すべて一覧表示する(ForEachでループ)
                        ForEach(maxFeeCandidates, id: \.self) { candidate in
                            Text(candidate)
                                .foregroundStyle(.gray)
                        }
                        
                        // 自動読み取りが完璧ではないことを伝える注意書き
                        Text("※自動での読み取りが不完全な場合があります。金額をご確認の上、下欄に反映してください。")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        // 最大料金を手入力するためのテキストフィールド
                        TextField("最大料金(円)", text: $maxFeeText)
                            .keyboardType(.numberPad)  // 数字専用キーボードを表示する
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.top)
                }
                
                // 「この内容で確定」ボタン
                Button("この内容で確定") {
                    // 読み取った時間帯・単価のペアを、ViewModelに反映して数値データに変換させる
                    viewModel.applyRates(parkingRates)
                    // 手入力された最大料金を、Int型に変換してViewModelにセットする
                    // 空欄や数値以外の文字列だった場合は自動的にnil(最大料金なし)になる
                    // 計算画面への遷移を発火させる
                    navigateToContent = true
                }
                .padding()
                .frame(maxWidth: .infinity)  // 横幅いっぱいに広げる
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // 画面には見えないが、navigateToContentがtrueになった瞬間に
                // ContentViewへ自動的に画面遷移させるための仕掛け
                NavigationLink(
                    destination: ContentView(viewModel: viewModel),
                    isActive: $navigateToContent
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
        // ダークモードを強制して、他の画面とデザインを統一する
        .preferredColorScheme(.dark)
    }
}

#Preview {
    // プレビュー用にダミーデータを渡す
    ConfirmView(
        viewModel: ParkingViewModel(),
        parkingRates: [("8:00~22:00", "20分／330円"), ("22:00~8:00", "60分／110円")],
        maxFeeCandidates: ["3時間最大 1200円", "夜間最大 700円"]
    )
}
