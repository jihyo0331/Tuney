// EventTapManager.swift
import Foundation
import ApplicationServices
import Carbon.HIToolbox
import SwiftUI

class EventTapManager: ObservableObject {
    @Published var isEnabled       = true
    @Published var lastInput       = ""
    @Published var showReplaceAlert = false

    private var eventTap: CFMachPort?
    private var runLoopSrc: CFRunLoopSource?
    private var buffer = [UniChar]()

    func start() {
        guard eventTap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, ev, ref in
                let manager = Unmanaged<EventTapManager>.fromOpaque(ref!).takeUnretainedValue()
                return manager.handle(ev: ev, type: type)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        if let tap = eventTap {
            runLoopSrc = CFMachPortCreateRunLoopSource(nil, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSrc {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
        eventTap = nil
        runLoopSrc = nil
        buffer.removeAll()
        lastInput = ""
    }

    private func handle(ev: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(ev) }

        let code = ev.getIntegerValueField(.keyboardEventKeycode)
        if code == UInt16(kVK_Return) {
            DispatchQueue.main.async { self.showReplaceAlert = true }
            lastInput = String(utf16CodeUnits: buffer, count: buffer.count)
            buffer.removeAll()
            return Unmanaged.passUnretained(ev)
        }

        // 일반 문자 버퍼링
        var buf = [UniChar](repeating: 0, count: 1)
        var len: Int = 0
        ev.keyboardGetUnicodeString(maxStringLength: 1,
                                   actualStringLength: &len,
                                   unicodeString: &buf)
        if len == 1 {
            buffer.append(buf[0])
        }
        return Unmanaged.passUnretained(ev)
    }

    // Alert “예” 눌렀을 때
    func applyReplacement() {
        // 버퍼 길이만큼 백스페이스
        for _ in lastInput.utf16 {
            if let down = CGEvent(keyboardEventSource: nil,
                                  virtualKey: CGKeyCode(kVK_Delete),
                                  keyDown: true),
               let up   = CGEvent(keyboardEventSource: nil,
                                  virtualKey: CGKeyCode(kVK_Delete),
                                  keyDown: false) {
                down.post(tap: .cghidEventTap)
                up.post(tap: .cghidEventTap)
            }
        }
        // “안녕하세요” 입력
        let rep = "안녕하세요"
        for scalar in rep.unicodeScalars {
            var uc = UniChar(scalar.value)
            if let d = CGEvent(keyboardEventSource: nil,
                                virtualKey: 0,
                                keyDown: true),
               let u = CGEvent(keyboardEventSource: nil,
                                virtualKey: 0,
                                keyDown: false) {
                d.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uc)
                u.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uc)
                d.post(tap: .cghidEventTap)
                u.post(tap: .cghidEventTap)
            }
        }
        lastInput = ""
        showReplaceAlert = false
    }
}
