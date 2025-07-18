// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var output: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Run keyhook and Show Output") {
                runBinary()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .background(Color(NSColor.textBackgroundColor).opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 300)
    }
    
    /// keyhook 바이너리를 실행하고, 표준출력 결과를 `output`에 저장
    func runBinary() {
        // 1) 앱 번들에서 keyhook 실행 파일 경로 가져오기
        guard let binaryURL = Bundle.main.url(forResource: "keyhook", withExtension: nil) else {
            output = "앱 번들에 keyhook이 없습니다."
            return
        }

        // 2) 프로세스 실행
        let task = Process()
        task.executableURL = binaryURL
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = pipe

        do {
            try task.run()
        } catch {
            output = "실행 오류: \(error)"
            return
        }

        // 3) 출력 읽기
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.output += line
            }
        }

        task.terminationHandler = { _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                output += "\n🔹 프로세스 종료"
            }
        }
    }
}
