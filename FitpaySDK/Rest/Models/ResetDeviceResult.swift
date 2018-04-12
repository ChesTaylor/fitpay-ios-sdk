//
//  ResetDeviceTask.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 4/4/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//

import ObjectMapper

public enum DeviceResetStatus {
    case IN_PROGRESS,
    RESET_COMPLETE,
    DELETED,
    DELETE_FAILED,
    RESET_FAILED
}

@objcMembers
open class ResetDeviceResult: NSObject, Mappable {
    internal var links: [ResourceLink]?
    open var resetId: String?
    open var status: DeviceResetStatus?
    open var seStatus: DeviceResetStatus?


    public required init?(map: Map) {

    }

    open func mapping(map: Map) {
        links <- (map["_links"], ResourceLinkTransformType())
        resetId <- map["resetId"]
        status <- map["status"]
        seStatus <- map["seStatus"]
    }
}
