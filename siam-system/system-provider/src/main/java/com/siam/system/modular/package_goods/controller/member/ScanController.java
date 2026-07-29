package com.siam.system.modular.package_goods.controller.member;

import com.siam.package_common.entity.BasicResult;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.service.DiningTableService;
import com.siam.system.modular.package_goods.service.ShopService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping(value = "/rest/scan")
public class ScanController {

    @Autowired
    private DiningTableService diningTableService;

    @Autowired
    private ShopService shopService;

    @PostMapping(value = "/resolve")
    public BasicResult resolve(@RequestBody @Validated(value = {}) DiningTable param) {
        DiningTable table = diningTableService.resolveActiveTable(param.getSceneToken());
        Shop shop = shopService.getById(table.getShopId());
        if (shop == null || !Integer.valueOf(2).equals(shop.getStatus())) {
            throw new StoneCustomerException("门店不存在或已停用");
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("shopId", shop.getId());
        result.put("shopName", shop.getName());
        result.put("shopLogoImg", shop.getShopLogoImg());
        result.put("isOperating", shop.getIsOperating());
        result.put("tableId", table.getId());
        result.put("tableNo", table.getTableNo());
        result.put("tableName", table.getTableName());
        result.put("sceneToken", table.getSceneToken());
        return BasicResult.success(result);
    }
}
