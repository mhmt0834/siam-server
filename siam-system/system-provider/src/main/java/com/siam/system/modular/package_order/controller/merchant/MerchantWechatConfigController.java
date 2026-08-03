package com.siam.system.modular.package_order.controller.merchant;

import com.siam.package_common.entity.BasicResult;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.model.param.ShopWechatConfigParam;
import com.siam.system.modular.package_order.service_impl.payment.ShopWechatConfigService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "/rest/merchant/shopWechatConfig")
public class MerchantWechatConfigController {

    @Autowired
    private ShopWechatConfigService configService;

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    @PostMapping(value = "/detail")
    public BasicResult detail() {
        return BasicResult.success(configService.detail(getShopId()));
    }

    @PostMapping(value = "/save")
    public BasicResult save(@RequestBody @Validated ShopWechatConfigParam param) {
        return BasicResult.success(configService.save(getShopId(), param));
    }

    private Integer getShopId() {
        Merchant merchant = merchantSessionManager.getSession(TokenUtil.getToken());
        if (merchant == null || merchant.getShopId() == null) {
            throw new StoneCustomerException("当前商家未绑定门店");
        }
        return merchant.getShopId();
    }
}
