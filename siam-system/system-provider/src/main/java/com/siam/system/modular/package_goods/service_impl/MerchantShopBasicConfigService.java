package com.siam.system.modular.package_goods.service_impl;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.model.param.ShopBasicConfigParam;
import com.siam.system.modular.package_goods.service.ShopService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.util.TokenUtil;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class MerchantShopBasicConfigService {

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    @Autowired
    private ShopService shopService;

    public Map<String, Object> get() {
        Integer shopId = currentShopId();
        Shop shop = shopService.getById(shopId);
        if (shop == null) {
            throw new StoneCustomerException("店铺不存在");
        }
        return toResult(shop);
    }

    public Map<String, Object> update(ShopBasicConfigParam param) {
        validate(param);
        Integer shopId = currentShopId();
        if (shopService.getById(shopId) == null) {
            throw new StoneCustomerException("店铺不存在");
        }

        Shop shop = new Shop();
        shop.setId(shopId);
        shop.setName(param.getName().trim());
        shop.setShopLogoImg(StringUtils.trimToNull(param.getShopLogoImg()));
        shop.setStartTime(param.getStartTime().trim());
        shop.setEndTime(param.getEndTime().trim());
        shop.setAnnouncement(StringUtils.defaultString(param.getAnnouncement()).trim());
        shop.setContactPhone(param.getContactPhone().trim());
        shop.setIsOperating(param.getIsOperating());
        shop.setReducedDeliveryPrice(param.getReducedDeliveryPrice());
        shop.setKitchenTotalOrderPrinterId(param.getKitchenTotalOrderPrinterId());
        shop.setCheckoutPrinterId(param.getCheckoutPrinterId());
        shop.setUpdateTime(new Date());
        shopService.updateById(shop);
        return get();
    }

    private Integer currentShopId() {
        Merchant merchant = merchantSessionManager.getSession(TokenUtil.getToken());
        if (merchant == null || merchant.getShopId() == null) {
            throw new StoneCustomerException("当前商家未绑定店铺");
        }
        return merchant.getShopId();
    }

    private void validate(ShopBasicConfigParam param) {
        if (param == null || StringUtils.isBlank(param.getName())) {
            throw new StoneCustomerException("店铺名称不能为空");
        }
        if (StringUtils.isBlank(param.getContactPhone())) {
            throw new StoneCustomerException("联系方式不能为空");
        }
        validateTime(param.getStartTime(), "营业开始时间");
        validateTime(param.getEndTime(), "营业结束时间");
        if (param.getIsOperating() == null) {
            throw new StoneCustomerException("营业状态不能为空");
        }
    }

    private void validateTime(String value, String name) {
        if (StringUtils.isBlank(value) || !value.matches("^([01]\\d|2[0-3]):[0-5]\\d$")) {
            throw new StoneCustomerException(name + "格式应为HH:mm");
        }
    }

    private Map<String, Object> toResult(Shop shop) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", shop.getId());
        result.put("name", shop.getName());
        result.put("shopLogoImg", shop.getShopLogoImg());
        result.put("startTime", shop.getStartTime());
        result.put("endTime", shop.getEndTime());
        result.put("announcement", shop.getAnnouncement());
        result.put("contactPhone", shop.getContactPhone());
        result.put("isOperating", shop.getIsOperating());
        result.put("reducedDeliveryPrice", shop.getReducedDeliveryPrice());
        result.put("kitchenTotalOrderPrinterId", shop.getKitchenTotalOrderPrinterId());
        result.put("checkoutPrinterId", shop.getCheckoutPrinterId());
        return result;
    }
}
