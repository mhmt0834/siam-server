package com.siam.system.modular.package_user.service_impl;

import com.siam.package_common.constant.Quantity;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.package_common.util.CommonUtils;
import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.service.ShopService;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.modular.package_user.model.param.MerchantInitializationParam;
import com.siam.system.modular.package_user.service.MerchantService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class MerchantInitializationService {

    @Autowired
    private MerchantService merchantService;

    @Autowired
    private ShopService shopService;

    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> initialize(MerchantInitializationParam param) {
        validate(param);
        String username = param.getOwnerUsername().trim();
        String mobile = param.getOwnerMobile().trim();
        if (merchantService.selectByUsernameOrMobile(username) != null) {
            throw new StoneCustomerException("老板账号已存在");
        }
        if (merchantService.selectByMobile(mobile) != null) {
            throw new StoneCustomerException("老板手机号已存在");
        }

        Date now = new Date();
        String passwordSalt = CommonUtils.genSalt();
        Merchant merchant = new Merchant();
        merchant.setUsername(username);
        merchant.setMobile(mobile);
        merchant.setPassword(CommonUtils.genMd5Password(param.getInitialPassword(), passwordSalt));
        merchant.setPasswordSalt(passwordSalt);
        merchant.setIsDisabled(false);
        merchant.setIsDeleted(false);
        merchant.setAuditStatus(Quantity.INT_2);
        merchant.setRoles("merchant-owner");
        merchant.setCreateTime(now);
        merchant.setUpdateTime(now);
        merchantService.insertSelective(merchant);

        Shop shop = new Shop();
        shop.setMerchantId(merchant.getId());
        shop.setName(param.getShopName().trim());
        shop.setShopLogoImg(StringUtils.trimToNull(param.getLogo()));
        shop.setStartTime(StringUtils.defaultIfBlank(param.getStartTime(), "09:00"));
        shop.setEndTime(StringUtils.defaultIfBlank(param.getEndTime(), "22:00"));
        shop.setAnnouncement(StringUtils.defaultString(param.getAnnouncement()));
        shop.setContactPhone(StringUtils.defaultIfBlank(param.getContactPhone(), mobile));
        shop.setIsOperating(false);
        shop.setStatus(Quantity.INT_1);
        shop.setAuditStatus(Quantity.INT_2);
        shop.setCheckoutMode(Shop.CHECKOUT_MODE_PAY_FIRST);
        shop.setIsOpenOrderAudio(true);
        shop.setIsOpenLocalPrint(false);
        shop.setIsOpenCloudPrint(false);
        shop.setCreateTime(now);
        shop.setUpdateTime(now);
        shopService.save(shop);

        Merchant binding = new Merchant();
        binding.setId(merchant.getId());
        binding.setShopId(shop.getId());
        binding.setUpdateTime(now);
        merchantService.updateByPrimaryKeySelective(binding);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("merchantId", merchant.getId());
        result.put("shopId", shop.getId());
        result.put("ownerUsername", username);
        result.put("shopName", shop.getName());
        result.put("isOperating", false);
        return result;
    }

    private void validate(MerchantInitializationParam param) {
        if (param == null) {
            throw new StoneCustomerException("商家初始化参数不能为空");
        }
        if (StringUtils.isBlank(param.getOwnerUsername())) {
            throw new StoneCustomerException("老板账号不能为空");
        }
        if (StringUtils.isBlank(param.getOwnerMobile()) || !param.getOwnerMobile().trim().matches("^1\\d{10}$")) {
            throw new StoneCustomerException("老板手机号格式不正确");
        }
        if (StringUtils.isBlank(param.getInitialPassword()) || param.getInitialPassword().length() < 8) {
            throw new StoneCustomerException("初始密码至少8位");
        }
        if (StringUtils.isBlank(param.getShopName())) {
            throw new StoneCustomerException("店铺名称不能为空");
        }
        validateTime(param.getStartTime(), "营业开始时间");
        validateTime(param.getEndTime(), "营业结束时间");
    }

    private void validateTime(String value, String name) {
        if (StringUtils.isNotBlank(value) && !value.matches("^([01]\\d|2[0-3]):[0-5]\\d$")) {
            throw new StoneCustomerException(name + "格式应为HH:mm");
        }
    }
}
