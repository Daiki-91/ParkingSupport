//
//  ParkingSupportApp.swift
//  ParkingSupport
//
//  Created by DaikiMaeda on 2026/07/18.
//

import SwiftUI

@main
struct ParkingSupportApp: App {
    var body: some Scene {
        WindowGroup {
            // アプリ起動時、最初に表示する画面をTopView(スプラッシュ画面)に設定
            TopView()
        }
    }
}
