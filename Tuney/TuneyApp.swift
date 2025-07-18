import SwiftUI
import ApplicationServices
import Cocoa
import ApplicationServices

@main
struct TuneyApp: App {
    @StateObject private var manager = EventTapManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .onAppear {
                    // 앱 시작 시 권한 요청 및 이벤트 탭 시작
                    requestSystemPermissions()
                    manager.start()
                }
        }
    }

    /// 손쉬운 사용(Accessibility) 권한과 입력 모니터링 페이지를 요청합니다.
    func requestSystemPermissions() {
        // 1) Accessibility 권한 요청 (표준 시스템 대화상자 표시)
        let options = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // 2) 입력 모니터링 설정 화면 열기
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring"
        ) {
            NSWorkspace.shared.open(url)
        }
    }
}
