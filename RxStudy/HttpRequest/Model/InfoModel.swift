//
//  InfoModel.swift
//  RxStudy
//
//  Created by season on 2021/5/20.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

/// 单个信息模型,用于首页,项目,公众号,搜索关键词,体系,收藏夹
struct InfoModel : Codable {
    
    let apkLink : String?
    let audit : Int?
    let author : String?
    let canEdit : Bool?
    let chapterId : Int?
    let chapterName : String?
    let collect : Bool?
    let courseId : Int?
    let desc : String?
    let descMd : String?
    let envelopePic : String?
    let fresh : Bool?
    let id : Int?
    let link : String?
    let niceDate : String?
    let niceShareDate : String?
    let origin : String?
    let prefix : String?
    let projectLink : String?
    let publishTime : Int?
    let selfVisible : Int?
    let shareDate : Int?
    let shareUser : String?
    let superChapterId : Int?
    let superChapterName : String?
    let tags : [Tag]?
    let title : String?
    let type : Int?
    let userId : Int?
    let visible : Int?
    let zan : Int?
}

struct Tag : Codable {

    let name : String?
    let url : String?
}
