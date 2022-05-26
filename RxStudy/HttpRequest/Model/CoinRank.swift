//
//  CoinRank.swift
//  RxStudy
//
//  Created by season on 2021/5/21.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

struct CoinRank : Codable {

    let coinCount : Int?
    let level : Int?
    let nickname : String?
    let rank : String?
    let userId : Int?
    let username : String?
    
    var myInfo: String {
        guard let rank = self.rank,
              let level = self.level,
              let coinCount = self.coinCount else {
            return "排名: -- 等级: -- 积分: --"
        }
        return "排名: \(rank) 等级: \(level) 积分: \(coinCount)"
    }
}
