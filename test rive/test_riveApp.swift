//
//  test_riveApp.swift
//  test rive
//
//  Created by Duẩn Phạm on 13/5/25.
//

import RiveRuntime
import SwiftUI

@main
struct TestRiveApp: App {
    init() {
        // Pre-download any Rive animations if needed
        // This is optional but can improve initial load times
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                RiveDemoView()
            }
        }
    }
}
