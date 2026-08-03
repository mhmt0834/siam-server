package com.siam.system.modular.package_order.service_impl.payment;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.entity.ShopWechatConfig;
import com.siam.system.modular.package_order.entity.WechatPaymentRecord;
import com.siam.system.modular.package_order.mapper.OrderMapper;
import com.siam.system.modular.package_order.mapper.WechatPaymentRecordMapper;
import com.siam.system.modular.package_user.entity.Member;
import com.wechat.pay.java.core.RSAPublicKeyConfig;
import com.wechat.pay.java.core.notification.NotificationParser;
import com.wechat.pay.java.core.notification.RequestParam;
import com.wechat.pay.java.service.payments.jsapi.JsapiServiceExtension;
import com.wechat.pay.java.service.payments.jsapi.model.Amount;
import com.wechat.pay.java.service.payments.jsapi.model.Payer;
import com.wechat.pay.java.service.payments.jsapi.model.PrepayRequest;
import com.wechat.pay.java.service.payments.jsapi.model.PrepayWithRequestPaymentResponse;
import com.wechat.pay.java.service.payments.model.Transaction;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.PrivateKey;
import java.security.Signature;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class WechatPayV3Service {

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private WechatPaymentRecordMapper paymentRecordMapper;

    @Autowired
    private ShopWechatConfigService configService;

    @Autowired
    private PaymentSecretCrypto secretCrypto;

    @Value("${WECHAT_PAY_NOTIFY_BASE_URL:}")
    private String notifyBaseUrl;

    public Map<String, String> createAppletPayment(String orderNo, Member member) {
        Order order = orderMapper.selectByOrderNo(orderNo);
        validatePayableOrder(order, member);

        ShopWechatConfig merchantConfig = configService.getRequiredEnabled(order.getShopId());
        long amountCent = toAmountCent(order.getActualPrice());
        WechatPaymentRecord paymentRecord = getOrCreatePaymentRecord(order, merchantConfig, amountCent);
        if (StringUtils.hasText(paymentRecord.getPrepayId())) {
            return signAppletParameters(merchantConfig, paymentRecord.getPrepayId());
        }

        PrepayRequest request = new PrepayRequest();
        request.setAppid(merchantConfig.getAppid());
        request.setMchid(merchantConfig.getMchid());
        request.setDescription(buildDescription(order));
        request.setOutTradeNo(order.getOrderNo());
        request.setAttach(buildAttach(order));
        request.setNotifyUrl(buildNotifyUrl(merchantConfig));

        Amount amount = new Amount();
        amount.setTotal(Math.toIntExact(amountCent));
        amount.setCurrency("CNY");
        request.setAmount(amount);

        Payer payer = new Payer();
        payer.setOpenid(member.getOpenId());
        request.setPayer(payer);

        RSAPublicKeyConfig sdkConfig = configService.getSdkConfig(merchantConfig);
        PrepayWithRequestPaymentResponse response = new JsapiServiceExtension.Builder()
                .config(sdkConfig)
                .build()
                .prepayWithRequestPayment(request);
        String prepayId = extractPrepayId(response.getPackageVal());
        paymentRecordMapper.savePrepayId(paymentRecord.getId(), prepayId, new Date());
        return toResponseMap(response);
    }

    public VerifiedNotification verifyNotification(String callbackToken,
                                                   String body,
                                                   String signature,
                                                   String serial,
                                                   String nonce,
                                                   String timestamp,
                                                   String signType) {
        RequestParam.Builder requestBuilder = new RequestParam.Builder()
                .serialNumber(serial)
                .nonce(nonce)
                .signature(signature)
                .timestamp(timestamp)
                .body(body);
        if (StringUtils.hasText(signType)) {
            requestBuilder.signType(signType);
        }
        RequestParam requestParam = requestBuilder.build();

        if (StringUtils.hasText(callbackToken)) {
            ShopWechatConfig config = configService.getByCallbackToken(callbackToken);
            if (config == null) {
                throw new StoneCustomerException("支付回调路由无效");
            }
            return parse(config, requestParam);
        }

        List<ShopWechatConfig> configs = configService.listEnabled();
        for (ShopWechatConfig config : configs) {
            try {
                return parse(config, requestParam);
            } catch (RuntimeException ignored) {
                // The compatibility endpoint has no shop hint; only a fully verified config is accepted.
            }
        }
        throw new StoneCustomerException("微信支付回调验签失败");
    }

    @Transactional(rollbackFor = Exception.class)
    public void applySuccessfulNotification(VerifiedNotification verified) {
        ShopWechatConfig config = verified.getConfig();
        Transaction transaction = verified.getTransaction();
        if (transaction.getTradeState() != Transaction.TradeStateEnum.SUCCESS) {
            throw new StoneCustomerException("微信支付交易未成功");
        }
        if (!config.getMchid().equals(transaction.getMchid())
                || !config.getAppid().equals(transaction.getAppid())) {
            throw new StoneCustomerException("支付商户信息不匹配");
        }

        Order order = orderMapper.selectByOrderNo(transaction.getOutTradeNo());
        if (order == null || !config.getShopId().equals(order.getShopId())) {
            throw new StoneCustomerException("支付订单与门店不匹配");
        }
        if (!buildAttach(order).equals(transaction.getAttach())) {
            throw new StoneCustomerException("支付订单附加信息不匹配");
        }
        if (transaction.getAmount() == null || transaction.getAmount().getTotal() == null
                || toAmountCent(order.getActualPrice()) != transaction.getAmount().getTotal().longValue()) {
            throw new StoneCustomerException("支付金额不匹配");
        }
        if (!StringUtils.hasText(transaction.getTransactionId())) {
            throw new StoneCustomerException("微信支付单号为空");
        }

        WechatPaymentRecord record = paymentRecordMapper.selectByOrderId(order.getId());
        validatePaymentRecord(record, order, config, transaction);
        if (WechatPaymentRecord.STATUS_SUCCESS == record.getStatus()) {
            if (!transaction.getTransactionId().equals(record.getTransactionId())) {
                throw new StoneCustomerException("重复通知的微信支付单号不一致");
            }
            return;
        }

        Date paidAt = parsePaidAt(transaction.getSuccessTime());
        int orderUpdated = orderMapper.markWechatPaid(order.getId(), config.getShopId(), paidAt);
        if (orderUpdated == 0) {
            Order latest = orderMapper.selectByOrderNo(order.getOrderNo());
            WechatPaymentRecord latestRecord = paymentRecordMapper.selectByOrderId(order.getId());
            if (latest != null && Order.STATUS_OF_WAIT_HANDLE == latest.getStatus()
                    && Boolean.TRUE.equals(latest.getIsPayment())
                    && latestRecord != null
                    && WechatPaymentRecord.STATUS_SUCCESS == latestRecord.getStatus()
                    && transaction.getTransactionId().equals(latestRecord.getTransactionId())) {
                return;
            }
            throw new StoneCustomerException("订单状态不允许支付确认");
        }
        if (paymentRecordMapper.markSuccess(record.getId(), config.getShopId(),
                transaction.getTransactionId(), paidAt) != 1) {
            throw new StoneCustomerException("支付记录状态更新失败");
        }
    }

    private VerifiedNotification parse(ShopWechatConfig config, RequestParam requestParam) {
        Transaction transaction = new NotificationParser(configService.getSdkConfig(config))
                .parse(requestParam, Transaction.class);
        return new VerifiedNotification(config, transaction);
    }

    private void validatePayableOrder(Order order, Member member) {
        if (order == null) {
            throw new StoneCustomerException("订单不存在");
        }
        if (member == null || !member.getId().equals(order.getMemberId())) {
            throw new StoneCustomerException("无权支付该订单");
        }
        if (order.getShopId() == null) {
            throw new StoneCustomerException("订单未绑定门店");
        }
        if (order.getStatus() != Order.STATUS_OF_WAIT_PAYMENT || Boolean.TRUE.equals(order.getIsPayment())) {
            throw new StoneCustomerException("订单状态不允许支付");
        }
        if (!StringUtils.hasText(member.getOpenId())) {
            throw new StoneCustomerException("当前用户未绑定微信 OpenID");
        }
        toAmountCent(order.getActualPrice());
    }

    private WechatPaymentRecord getOrCreatePaymentRecord(Order order,
                                                         ShopWechatConfig config,
                                                         long amountCent) {
        WechatPaymentRecord existing = paymentRecordMapper.selectByOrderId(order.getId());
        if (existing != null) {
            validatePaymentRecord(existing, order, config, null);
            return existing;
        }
        WechatPaymentRecord record = new WechatPaymentRecord();
        record.setShopId(order.getShopId());
        record.setOrderId(order.getId());
        record.setOrderNo(order.getOrderNo());
        record.setAppid(config.getAppid());
        record.setMchid(config.getMchid());
        record.setAmountCent(amountCent);
        record.setStatus(WechatPaymentRecord.STATUS_INIT);
        record.setCreateTime(new Date());
        record.setUpdateTime(new Date());
        try {
            paymentRecordMapper.insert(record);
            return record;
        } catch (DuplicateKeyException e) {
            WechatPaymentRecord concurrent = paymentRecordMapper.selectByOrderId(order.getId());
            validatePaymentRecord(concurrent, order, config, null);
            return concurrent;
        }
    }

    private void validatePaymentRecord(WechatPaymentRecord record,
                                       Order order,
                                       ShopWechatConfig config,
                                       Transaction transaction) {
        if (record == null
                || !order.getId().equals(record.getOrderId())
                || !order.getOrderNo().equals(record.getOrderNo())
                || !order.getShopId().equals(record.getShopId())
                || !config.getAppid().equals(record.getAppid())
                || !config.getMchid().equals(record.getMchid())
                || record.getAmountCent() == null
                || record.getAmountCent() != toAmountCent(order.getActualPrice())) {
            throw new StoneCustomerException("支付记录与订单不匹配");
        }
        if (transaction != null && StringUtils.hasText(record.getTransactionId())
                && !record.getTransactionId().equals(transaction.getTransactionId())) {
            throw new StoneCustomerException("微信支付单号不匹配");
        }
    }

    private long toAmountCent(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new StoneCustomerException("订单金额不正确");
        }
        try {
            long cents = amount.movePointRight(2).longValueExact();
            if (cents > Integer.MAX_VALUE) {
                throw new ArithmeticException();
            }
            return cents;
        } catch (ArithmeticException e) {
            throw new StoneCustomerException("订单金额精度不正确");
        }
    }

    private String buildDescription(Order order) {
        String shopName = StringUtils.hasText(order.getShopName()) ? order.getShopName() : "店内点餐";
        String value = shopName + "-" + order.getOrderNo();
        return value.length() > 127 ? value.substring(0, 127) : value;
    }

    private String buildAttach(Order order) {
        return "shop:" + order.getShopId() + ":order:" + order.getId();
    }

    private String buildNotifyUrl(ShopWechatConfig config) {
        if (!StringUtils.hasText(notifyBaseUrl)) {
            throw new StoneCustomerException("服务端未配置 WECHAT_PAY_NOTIFY_BASE_URL");
        }
        String base = notifyBaseUrl.trim();
        if (!base.startsWith("https://") || base.contains("?") || base.contains("#")) {
            throw new StoneCustomerException("微信支付回调地址必须是无参数的 HTTPS 地址");
        }
        while (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base + "/rest/member/wxPay/notify/" + config.getCallbackToken();
    }

    private String extractPrepayId(String packageValue) {
        if (!StringUtils.hasText(packageValue) || !packageValue.startsWith("prepay_id=")) {
            throw new StoneCustomerException("微信预支付响应不完整");
        }
        return packageValue.substring("prepay_id=".length());
    }

    private Map<String, String> toResponseMap(PrepayWithRequestPaymentResponse response) {
        Map<String, String> data = new LinkedHashMap<>();
        data.put("timeStamp", response.getTimeStamp());
        data.put("nonceStr", response.getNonceStr());
        data.put("package", response.getPackageVal());
        data.put("signType", response.getSignType());
        data.put("paySign", response.getPaySign());
        return data;
    }

    private Map<String, String> signAppletParameters(ShopWechatConfig config, String prepayId) {
        try {
            String timeStamp = String.valueOf(System.currentTimeMillis() / 1000);
            String nonceStr = UUID.randomUUID().toString().replace("-", "");
            String packageValue = "prepay_id=" + prepayId;
            String message = config.getAppid() + "\n" + timeStamp + "\n"
                    + nonceStr + "\n" + packageValue + "\n";
            PrivateKey privateKey = com.wechat.pay.java.core.util.PemUtil.loadPrivateKeyFromString(
                    secretCrypto.decrypt(config.getShopId(), "merchantPrivateKey",
                            config.getMerchantPrivateKeyCiphertext()));
            Signature signer = Signature.getInstance("SHA256withRSA");
            signer.initSign(privateKey);
            signer.update(message.getBytes(StandardCharsets.UTF_8));

            Map<String, String> data = new LinkedHashMap<>();
            data.put("timeStamp", timeStamp);
            data.put("nonceStr", nonceStr);
            data.put("package", packageValue);
            data.put("signType", "RSA");
            data.put("paySign", Base64.getEncoder().encodeToString(signer.sign()));
            return data;
        } catch (Exception e) {
            throw new StoneCustomerException("小程序支付参数签名失败");
        }
    }

    private Date parsePaidAt(String successTime) {
        if (!StringUtils.hasText(successTime)) {
            return new Date();
        }
        try {
            return Date.from(OffsetDateTime.parse(successTime).toInstant());
        } catch (Exception ignored) {
            return new Date();
        }
    }

    public static class VerifiedNotification {
        private final ShopWechatConfig config;
        private final Transaction transaction;

        public VerifiedNotification(ShopWechatConfig config, Transaction transaction) {
            this.config = config;
            this.transaction = transaction;
        }

        public ShopWechatConfig getConfig() {
            return config;
        }

        public Transaction getTransaction() {
            return transaction;
        }
    }
}
