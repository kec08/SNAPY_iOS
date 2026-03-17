//
//  AppleSignInButton.swift
//  Qiri
//
//  Created by 김은찬 on 5/15/25.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton()
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTapButton() {
            action()
        }
    }
}
