//
//  SiginUpViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/25/26.
//

import Foundation
import SwiftUI
import Combine

final class SiginUpViewModel: ObservableObject {
    // 회원가입 입력 필드
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerPasswordConfirm = ""
    @Published var registerCarrier = "SKT"
    @Published var registerPhone = ""
    @Published var registerUserID = ""    // handle
    @Published var registerUsername = ""   // username
    @Published var registerName = ""
    @Published var verificationCode = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistered = false

    private let authService = AuthService.shared

    // 회원가입 유효성 검사
    var isEmailValid: Bool {
        registerEmail.contains("@") && registerEmail.contains(".") && registerEmail.count > 5
    }

    var isPasswordValid: Bool {
        registerPassword.count >= 8 && registerPassword == registerPasswordConfirm
    }

    var isPhoneValid: Bool {
        return !registerCarrier.isEmpty
        && registerPhone.count >= 10
        && verificationCode.count >= 4
    }

    var isProfileValid: Bool {
        !registerUsername.isEmpty && !registerName.isEmpty
    }

    func register() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response = try await authService.signup(
                username: registerUsername,
                handle: registerUserID,
                email: registerEmail,
                phone: registerPhone,
                password: registerPassword
            )

            await MainActor.run {
                if response.success {
                    isRegistered = true
                } else {
                    errorMessage = response.message
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func clearFields() {
        registerEmail = ""
        registerPassword = ""
        registerPasswordConfirm = ""
        registerPhone = ""
        registerUserID = ""
        registerUsername = ""
        registerName = ""
        verificationCode = ""
        isRegistered = false
    }
}
