package com.siam.system.modular.package_user.model.param;

import lombok.Data;

@Data
public class MerchantInitializationParam {

    private String ownerUsername;

    private String ownerMobile;

    private String initialPassword;

    private String shopName;

    private String logo;

    private String startTime;

    private String endTime;

    private String announcement;

    private String contactPhone;
}
