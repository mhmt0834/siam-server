package com.siam.system.modular.package_order.model.param;

import lombok.Data;

@Data
public class ShopWechatConfigParam {

    private String appid;

    private String mchid;

    private String merchantSerialNo;

    private String apiV3Key;

    private String merchantPrivateKey;

    private String wechatPayPublicKeyId;

    private String wechatPayPublicKey;

    private Boolean enabled;
}
