//
//  UIImage+Extensions.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/13/26.
//

import UIKit

extension UIImage {
    /// 최대 dimension에 맞춰 비율 유지하며 리사이즈
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1.0 { return self } // 이미 작으면 그대로
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return resized
    }
}
