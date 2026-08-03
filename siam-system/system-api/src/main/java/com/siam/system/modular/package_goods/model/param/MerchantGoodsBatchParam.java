package com.siam.system.modular.package_goods.model.param;

import lombok.Data;

import java.util.List;

@Data
public class MerchantGoodsBatchParam {

    private List<MerchantGoodsBatchItem> items;
}
