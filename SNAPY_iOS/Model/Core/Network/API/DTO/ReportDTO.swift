//
//  ReportDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/26/26.
//

import Foundation

struct ReportData: Codable {
    let reportId: Int64
    let targetType: String
    let targetId: Int64
    let reason: String
}

typealias ReportResponse = BaseResponse<ReportData>
