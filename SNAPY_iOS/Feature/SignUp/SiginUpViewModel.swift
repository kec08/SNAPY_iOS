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

    /// 화면에 표시되는 포맷된 전화번호 (010-1234-5678)
    var formattedPhone: String {
        get { formatPhoneNumber(registerPhone) }
        set { registerPhone = newValue.replacingOccurrences(of: "-", with: "") }
    }

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistered = false

    private let authService = AuthService.shared

    // MARK: - 유효성 검사

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

    // MARK: - 필드별 유효성 안내 메시지

    var emailValidationMessage: String? {
        guard !registerEmail.isEmpty else { return nil }
        if !registerEmail.contains("@") || !registerEmail.contains(".") {
            return "올바른 이메일 형식이 아닙니다"
        }
        if registerEmail.count <= 5 {
            return "이메일이 너무 짧습니다"
        }
        return nil
    }

    var passwordValidationMessage: String? {
        guard !registerPassword.isEmpty else { return nil }
        if registerPassword.count < 8 {
            return "비밀번호가 8자 미만입니다"
        }
        return nil
    }

    var passwordConfirmValidationMessage: String? {
        guard !registerPasswordConfirm.isEmpty else { return nil }
        if registerPassword != registerPasswordConfirm {
            return "비밀번호가 일치하지 않습니다"
        }
        return nil
    }

    var phoneValidationMessage: String? {
        guard !registerPhone.isEmpty else { return nil }
        if registerPhone.count < 10 {
            return "전화번호는 10자리 이상이어야 합니다"
        }
        return nil
    }

    var userIDValidationMessage: String? {
        guard !registerUserID.isEmpty else { return nil }
        if registerUserID.count < 3 {
            return "아이디는 3자 이상이어야 합니다"
        }
        if registerUserID.contains(" ") {
            return "아이디에 공백을 사용할 수 없습니다"
        }
        return nil
    }

    // MARK: - 서버 에러 한국어 변환

    private func translateError(_ message: String) -> String {
        let lower = message.lowercased()

        // 이메일 관련
        if lower.contains("email") && (lower.contains("exist") || lower.contains("duplicate") || lower.contains("already") || lower.contains("taken")) {
            return "이미 사용 중인 이메일입니다"
        }
        if lower.contains("email") && (lower.contains("invalid") || lower.contains("format")) {
            return "올바른 이메일 형식이 아닙니다"
        }

        // 전화번호 관련
        if lower.contains("phone") && (lower.contains("exist") || lower.contains("duplicate") || lower.contains("already") || lower.contains("taken")) {
            return "이미 등록된 전화번호입니다"
        }
        if lower.contains("phone") && (lower.contains("invalid") || lower.contains("format")) {
            return "올바른 전화번호 형식이 아닙니다"
        }

        // 아이디(handle) 관련
        if (lower.contains("handle") || lower.contains("user")) && (lower.contains("exist") || lower.contains("duplicate") || lower.contains("already") || lower.contains("taken")) {
            return "이미 사용 중인 아이디입니다"
        }

        // 비밀번호 관련
        if lower.contains("password") && (lower.contains("short") || lower.contains("weak") || lower.contains("invalid") || lower.contains("length")) {
            return "비밀번호 조건을 확인해주세요"
        }

        // 네트워크/서버 관련
        if lower.contains("network") || lower.contains("internet") || lower.contains("connection") {
            return "네트워크 연결을 확인해주세요"
        }
        if lower.contains("timeout") {
            return "서버 응답 시간이 초과되었습니다"
        }
        if lower.contains("server") || lower.contains("500") || lower.contains("internal") {
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요"
        }

        // 디코딩 에러 (The data couldn't be read...)
        if lower.contains("couldn't be read") || lower.contains("could not be read") || lower.contains("data") && lower.contains("read") {
            return "서버 응답을 처리할 수 없습니다. 잠시 후 다시 시도해주세요"
        }

        // 기타 알 수 없는 에러
        if lower.contains("conflict") || lower.contains("409") {
            return "이미 등록된 정보입니다. 입력 내용을 확인해주세요"
        }

        // 원본 메시지가 이미 한국어면 그대로 반환
        if message.first?.isASCII == false {
            return message
        }

        return "오류가 발생했습니다. 잠시 후 다시 시도해주세요"
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

            guard response.success else {
                await MainActor.run {
                    errorMessage = translateError(response.message)
                    isLoading = false
                }
                return
            }

            // 회원가입 성공 후 자동 로그인 (연락처 동기화에 토큰 필요)
            do {
                _ = try await authService.login(
                    email: registerEmail,
                    password: registerPassword
                )
                print("[SignUp] 자동 로그인 성공")
            } catch {
                print("[SignUp] 자동 로그인 실패: \(error) — 연락처 동기화 불가")
            }

            await MainActor.run {
                isRegistered = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = translateError(error.localizedDescription)
                isLoading = false
            }
        }
    }

    // MARK: - 전화번호 포맷 (010-1234-5678)

    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.count <= 3 {
            return digits
        } else if digits.count <= 7 {
            let prefix = digits.prefix(3)
            let middle = digits.dropFirst(3)
            return "\(prefix)-\(middle)"
        } else {
            let prefix = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(4)
            let suffix = digits.dropFirst(7).prefix(4)
            return "\(prefix)-\(middle)-\(suffix)"
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
