package com.siam.system.modular.package_order.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("tb_shop_wechat_config")
public class ShopWechatConfig {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Integer shopId;

    private String appid;

    private String mchid;

    private String merchantSerialNo;

    private String apiV3KeyCiphertext;

    private String merchantPrivateKeyCiphertext;

    private String wechatPayPublicKeyId;

    private String wechatPayPublicKeyCiphertext;

    private String callbackToken;

    private Boolean enabled;

    private Date createTime;

    private Date updateTime;
}
