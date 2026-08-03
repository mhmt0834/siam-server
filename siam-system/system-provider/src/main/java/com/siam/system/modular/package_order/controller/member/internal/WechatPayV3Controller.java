package com.siam.system.modular.package_order.controller.member.internal;

import com.siam.package_common.entity.BasicResult;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.model.param.WechatPayCreateParam;
import com.siam.system.modular.package_order.service_impl.payment.WechatPayV3Service;
import com.siam.system.modular.package_user.auth.cache.MemberSessionManager;
import com.siam.system.modular.package_user.entity.Member;
import com.siam.system.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping(value = "/rest/member/wxPay")
public class WechatPayV3Controller {

    @Autowired
    private WechatPayV3Service wechatPayV3Service;

    @Autowired
    private MemberSessionManager memberSessionManager;

    @PostMapping(value = "/toPay4Applet")
    public BasicResult toPay4Applet(@RequestBody @Validated WechatPayCreateParam param) {
        Member member = memberSessionManager.getSession(TokenUtil.getToken());
        if (member == null) {
            throw new StoneCustomerException("登录已失效，请重新登录");
        }
        return BasicResult.success(wechatPayV3Service.createAppletPayment(param.getOrderNo(), member));
    }

    @PostMapping(value = {"/notify", "/notify/{callbackToken}"})
    public ResponseEntity<Map<String, String>> notify(
            @PathVariable(value = "callbackToken", required = false) String callbackToken,
            @RequestHeader(value = "Wechatpay-Signature", required = false) String signature,
            @RequestHeader(value = "Wechatpay-Serial", required = false) String serial,
            @RequestHeader(value = "Wechatpay-Nonce", required = false) String nonce,
            @RequestHeader(value = "Wechatpay-Timestamp", required = false) String timestamp,
            @RequestHeader(value = "Wechatpay-Signature-Type", required = false) String signType,
            HttpServletRequest request) {
        try {
            if (!StringUtils.hasText(signature) || !StringUtils.hasText(serial)
                    || !StringUtils.hasText(nonce) || !StringUtils.hasText(timestamp)) {
                return callbackResponse(HttpStatus.UNAUTHORIZED, "FAIL", "签名请求头不完整");
            }
            String body = StreamUtils.copyToString(request.getInputStream(), StandardCharsets.UTF_8);
            WechatPayV3Service.VerifiedNotification verified = wechatPayV3Service.verifyNotification(
                    callbackToken, body, signature, serial, nonce, timestamp, signType);
            wechatPayV3Service.applySuccessfulNotification(verified);
            return callbackResponse(HttpStatus.OK, "SUCCESS", "成功");
        } catch (Exception e) {
            return callbackResponse(HttpStatus.UNAUTHORIZED, "FAIL", "支付通知验证失败");
        }
    }

    private ResponseEntity<Map<String, String>> callbackResponse(HttpStatus status,
                                                                  String code,
                                                                  String message) {
        Map<String, String> body = new LinkedHashMap<>();
        body.put("code", code);
        body.put("message", message);
        return ResponseEntity.status(status).body(body);
    }
}
