//
//  Date+Extensions.swift
//

import Foundation

extension Date {
  var formattedTime: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "hh:mm"
    return formatter.string(from: self)
  }

  /// "아침" / "점심" / "저녁" / "추가"
  var timeSlotName: String {
    let hour = Calendar.current.component(.hour, from: self)
    switch hour {
    case 6..<11:  return "아침"
    case 12..<16: return "점심"
    case 17..<24: return "저녁"
    default:      return "추가"   // 0-6, 11-12, 16-17
    }
  }

  /// 카메라 촬영 버튼 영역: "2026.03.23 00:11"
  var shortTimestamp: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy.MM.dd HH:mm"
    return formatter.string(from: self)
  }

  /// 미리보기 화면: "2026년 3월 23일 오전 12시 11분"
  var fullTimestamp: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월 d일 a h시 mm분"
    return formatter.string(from: self)
  }

  /// 앨범 헤더: "2026.03.29 (토)"
  var albumDateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy.MM.dd (E)"
    return formatter.string(from: self)
  }

  /// 앨범 카드 하단: "아침 00시 00분"
  var albumTimestamp: String {
    let slot = self.timeSlotName
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "HH시 mm분"
    return "\(slot) \(formatter.string(from: self))"
  }
}
