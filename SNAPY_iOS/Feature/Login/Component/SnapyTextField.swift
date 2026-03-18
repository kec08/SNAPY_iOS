//
//  snapyTextField.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct SnapyTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isFocused ? Color.mainYellow : .customGray300)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 20))
                        .foregroundColor(isFocused ? Color.textWhite : .customGray300)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }

                if isSecure {
                    SecureField("", text: $text)
                        .font(.system(size: 20))
                        .foregroundColor(Color.textWhite)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                }
            }
            .padding(.vertical, 12)

            // 하단 라인
            Rectangle()
                .fill(isFocused ? Color.mainYellow : (text.isEmpty ? Color.textWhite : Color.textWhite))
                .frame(height: 3)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}
