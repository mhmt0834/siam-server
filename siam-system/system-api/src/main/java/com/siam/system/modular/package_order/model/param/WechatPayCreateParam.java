package com.siam.system.modular.package_order.model.param;

import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
public class WechatPayCreateParam {

    @NotBlank(message = "订单号不能为空")
    private String orderNo;
}
