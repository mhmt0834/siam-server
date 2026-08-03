package com.siam.system.modular.package_goods.model.param;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class MerchantGoodsBatchItem {

    private String name;

    private String image;

    private Integer menuId;

    private String categoryName;

    private BigDecimal price;

    private Integer status;

    private String description;
}
