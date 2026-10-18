import SwiftUI
import UIKit

struct LockScreenView: View {
    let onUnlock: () -> Void

    /// Hardcoded on purpose: this app has no settings UI for changing it,
    /// and the threat model is "keep casual snoopers off my phone," not
    /// "withstand someone who can read the app's source." Change this one
    /// constant if you want a different code.
    private static let correctPasscode = "2501"

    private enum Phase {
        case ident
        case passcode
    }

    private let wordmark = Array("NOMA")
    private let keypadRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"]
    ]

    @State private var phase: Phase = .ident
    @State private var lettersVisible: [Bool] = Array(repeating: false, count: 4)
    @State private var underlineWidth: CGFloat = 0
    @State private var identOpacity: Double = 1

    @State private var enteredDigits: [Int] = []
    @State private var showError = false
    @State private var shakeOffset: CGFloat = 0
    @State private var pressedKey: String?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if phase == .ident {
                identView
                    .opacity(identOpacity)
            } else {
                passcodeView
                    .transition(.opacity)
            }
        }
        .onAppear { runIdent() }
    }

    private var identView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 2) {
                ForEach(Array(wordmark.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(.primary)
                        .opacity(lettersVisible[index] ? 1 : 0)
                        .offset(y: lettersVisible[index] ? 0 : 14)
                        .animation(.easeOut(duration: 0.4), value: lettersVisible[index])
                }
            }
            Rectangle()
                .fill(Color.coral)
                .frame(width: underlineWidth, height: 2)
        }
    }

    private var passcodeView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("NOMA")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.secondary)

                dotsRow
                    .offset(x: shakeOffset)

                Text(showError ? "Incorrect Passcode" : " ")
                    .font(.caption)
                    .foregroundStyle(Color.coral)
            }

            keypad
        }
        .padding(.bottom, 40)
    }

    private var dotsRow: some View {
        HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .strokeBorder(Color.coral, lineWidth: 1.5)
                    .background(Circle().fill(index < enteredDigits.count ? Color.coral : Color.clear))
                    .frame(width: 14, height: 14)
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 18) {
            ForEach(keypadRows, id: \.self) { row in
                HStack(spacing: 18) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keypadButton(_ key: String) -> some View {
        let isPressed = pressedKey == key

        if key.isEmpty {
            Color.clear.frame(width: 68, height: 68)
        } else if key == "⌫" {
            Button(action: { flash(key); deleteDigit() }) {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isPressed ? .white : Color.primary)
                    .frame(width: 68, height: 68)
                    .background(isPressed ? Color.coral : Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        } else {
            Button(action: { flash(key); tapDigit(Int(key)!) }) {
                Text(key)
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(isPressed ? .white : Color.primary)
                    .frame(width: 68, height: 68)
                    .background(isPressed ? Color.coral : Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
    }

    /// Driven by an explicit timer rather than the button's raw press/release
    /// events, so a fast tap still shows a clearly visible flash instead of
    /// a highlight that comes and goes faster than the eye can register.
    private func flash(_ key: String) {
        pressedKey = key
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            if pressedKey == key {
                pressedKey = nil
            }
        }
    }

    private func runIdent() {
        for index in lettersVisible.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 + Double(index) * 0.1) {
                lettersVisible[index] = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.5)) {
                underlineWidth = 150
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeOut(duration: 0.5)) {
                identOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = .passcode
            }
        }
    }

    private func tapDigit(_ digit: Int) {
        guard enteredDigits.count < 4 else { return }
        showError = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        enteredDigits.append(digit)
        if enteredDigits.count == 4 {
            checkPasscode()
        }
    }

    private func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
    }

    private func checkPasscode() {
        let entered = enteredDigits.map(String.init).joined()
        if entered == Self.correctPasscode {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onUnlock()
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showError = true
            shake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                enteredDigits = []
            }
        }
    }

    private func shake() {
        let steps: [CGFloat] = [-10, 10, -6, 6, 0]
        for (index, value) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                withAnimation(.easeInOut(duration: 0.06)) {
                    shakeOffset = value
                }
            }
        }
    }
}
