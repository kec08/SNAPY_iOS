//
//  MoyaProvider2.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/9/26.
//

import Moya

extension MoyaProvider {
    func requestAsync(_ target: Target) async -> Result<Response, MoyaError> {
        await withCheckedContinuation { continuation in
            self.request(target) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
