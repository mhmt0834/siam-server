package com.siam.system.modular.package_goods.model.param;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class ShopBasicConfigParam {

    private String name;

    private String shopLogoImg;

    private String startTime;

    private String endTime;

    private String announcement;

    private String contactPhone;

    private Boolean isOperating;

    private BigDecimal reducedDeliveryPrice;

    private Integer kitchenTotalOrderPrinterId;

    private Integer checkoutPrinterId;
}
