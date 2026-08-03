package com.siam.system.modular.package_order.service_impl.payment;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.ShopWechatConfig;
import com.siam.system.modular.package_order.mapper.ShopWechatConfigMapper;
import com.siam.system.modular.package_order.model.param.ShopWechatConfigParam;
import com.wechat.pay.java.core.RSAPublicKeyConfig;
import com.wechat.pay.java.core.util.PemUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ShopWechatConfigService {

    private static final String FIELD_API_V3_KEY = "apiV3Key";
    private static final String FIELD_MERCHANT_PRIVATE_KEY = "merchantPrivateKey";
    private static final String FIELD_WECHAT_PAY_PUBLIC_KEY = "wechatPayPublicKey";

    @Autowired
    private ShopWechatConfigMapper configMapper;

    @Autowired
    private PaymentSecretCrypto secretCrypto;

    private final Map<Integer, CachedSdkConfig> sdkConfigCache = new ConcurrentHashMap<>();

    public ShopWechatConfig getRequiredEnabled(Integer shopId) {
        ShopWechatConfig config = configMapper.selectByShopId(shopId);
        if (!isComplete(config) || !Boolean.TRUE.equals(config.getEnabled())) {
            throw new StoneCustomerException("当前门店尚未完成微信支付配置");
        }
        return config;
    }

    public ShopWechatConfig getByCallbackToken(String callbackToken) {
        if (!StringUtils.hasText(callbackToken)) {
            return null;
        }
        return configMapper.selectByCallbackToken(callbackToken);
    }

    public List<ShopWechatConfig> listEnabled() {
        return configMapper.selectEnabled();
    }

    public RSAPublicKeyConfig getSdkConfig(ShopWechatConfig config) {
        long version = config.getUpdateTime() == null ? 0L : config.getUpdateTime().getTime();
        CachedSdkConfig cached = sdkConfigCache.get(config.getShopId());
        if (cached != null && cached.version == version) {
            return cached.config;
        }
        RSAPublicKeyConfig sdkConfig = new RSAPublicKeyConfig.Builder()
                .merchantId(config.getMchid())
                .privateKey(secretCrypto.decrypt(config.getShopId(), FIELD_MERCHANT_PRIVATE_KEY,
                        config.getMerchantPrivateKeyCiphertext()))
                .merchantSerialNumber(config.getMerchantSerialNo())
                .publicKey(secretCrypto.decrypt(config.getShopId(), FIELD_WECHAT_PAY_PUBLIC_KEY,
                        config.getWechatPayPublicKeyCiphertext()))
                .publicKeyId(config.getWechatPayPublicKeyId())
                .apiV3Key(secretCrypto.decrypt(config.getShopId(), FIELD_API_V3_KEY,
                        config.getApiV3KeyCiphertext()))
                .build();
        sdkConfigCache.put(config.getShopId(), new CachedSdkConfig(version, sdkConfig));
        return sdkConfig;
    }

    public Map<String, Object> detail(Integer shopId) {
        ShopWechatConfig config = configMapper.selectByShopId(shopId);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("configured", isComplete(config));
        result.put("enabled", config != null && Boolean.TRUE.equals(config.getEnabled()));
        result.put("appidMasked", config == null ? null : mask(config.getAppid(), 4, 3));
        result.put("mchidMasked", config == null ? null : mask(config.getMchid(), 4, 4));
        result.put("merchantSerialNoMasked",
                config == null ? null : mask(config.getMerchantSerialNo(), 4, 4));
        result.put("wechatPayPublicKeyIdMasked",
                config == null ? null : mask(config.getWechatPayPublicKeyId(), 5, 4));
        result.put("updatedAt", config == null ? null : config.getUpdateTime());
        return result;
    }

    public Map<String, Object> save(Integer shopId, ShopWechatConfigParam param) {
        secretCrypto.requireReady();
        ShopWechatConfig config = configMapper.selectByShopId(shopId);
        boolean insert = config == null;
        if (insert) {
            config = new ShopWechatConfig();
            config.setShopId(shopId);
            config.setCallbackToken(UUID.randomUUID().toString().replace("-", ""));
            config.setCreateTime(new Date());
        }

        config.setAppid(required(param.getAppid(), config.getAppid(), "AppID"));
        config.setMchid(required(param.getMchid(), config.getMchid(), "商户号"));
        config.setMerchantSerialNo(required(param.getMerchantSerialNo(),
                config.getMerchantSerialNo(), "商户证书序列号"));
        config.setWechatPayPublicKeyId(required(param.getWechatPayPublicKeyId(),
                config.getWechatPayPublicKeyId(), "微信支付公钥ID"));

        if (StringUtils.hasText(param.getApiV3Key())) {
            String apiV3Key = param.getApiV3Key().trim();
            if (apiV3Key.getBytes(StandardCharsets.UTF_8).length != 32) {
                throw new StoneCustomerException("APIv3 Key 必须是 32 字节");
            }
            config.setApiV3KeyCiphertext(secretCrypto.encrypt(shopId, FIELD_API_V3_KEY, apiV3Key));
        }
        if (StringUtils.hasText(param.getMerchantPrivateKey())) {
            String privateKey = normalizePem(param.getMerchantPrivateKey());
            try {
                PemUtil.loadPrivateKeyFromString(privateKey);
            } catch (Exception e) {
                throw new StoneCustomerException("商户私钥格式不正确");
            }
            config.setMerchantPrivateKeyCiphertext(
                    secretCrypto.encrypt(shopId, FIELD_MERCHANT_PRIVATE_KEY, privateKey));
        }
        if (StringUtils.hasText(param.getWechatPayPublicKey())) {
            String publicKey = normalizePem(param.getWechatPayPublicKey());
            try {
                PemUtil.loadPublicKeyFromString(publicKey);
            } catch (Exception e) {
                throw new StoneCustomerException("微信支付公钥格式不正确");
            }
            config.setWechatPayPublicKeyCiphertext(
                    secretCrypto.encrypt(shopId, FIELD_WECHAT_PAY_PUBLIC_KEY, publicKey));
        }
        if (!isComplete(config)) {
            throw new StoneCustomerException("请完整填写微信支付配置");
        }

        config.setEnabled(Boolean.TRUE.equals(param.getEnabled()));
        config.setUpdateTime(new Date());
        if (insert) {
            configMapper.insert(config);
        } else {
            configMapper.updateById(config);
        }
        sdkConfigCache.remove(shopId);
        return detail(shopId);
    }

    private boolean isComplete(ShopWechatConfig config) {
        return config != null
                && StringUtils.hasText(config.getAppid())
                && StringUtils.hasText(config.getMchid())
                && StringUtils.hasText(config.getMerchantSerialNo())
                && StringUtils.hasText(config.getApiV3KeyCiphertext())
                && StringUtils.hasText(config.getMerchantPrivateKeyCiphertext())
                && StringUtils.hasText(config.getWechatPayPublicKeyId())
                && StringUtils.hasText(config.getWechatPayPublicKeyCiphertext())
                && StringUtils.hasText(config.getCallbackToken());
    }

    private String required(String incoming, String existing, String label) {
        if (StringUtils.hasText(incoming)) {
            return incoming.trim();
        }
        if (StringUtils.hasText(existing)) {
            return existing;
        }
        throw new StoneCustomerException(label + "不能为空");
    }

    private String normalizePem(String value) {
        return value.trim().replace("\\n", "\n");
    }

    private String mask(String value, int prefix, int suffix) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        if (value.length() <= prefix + suffix) {
            return "****";
        }
        return value.substring(0, prefix) + "****" + value.substring(value.length() - suffix);
    }

    private static class CachedSdkConfig {
        private final long version;
        private final RSAPublicKeyConfig config;

        private CachedSdkConfig(long version, RSAPublicKeyConfig config) {
            this.version = version;
            this.config = config;
        }
    }
}
