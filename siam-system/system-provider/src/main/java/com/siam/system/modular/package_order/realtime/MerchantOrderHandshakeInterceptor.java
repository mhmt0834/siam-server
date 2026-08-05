package com.siam.system.modular.package_order.realtime;

import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

@Component
public class MerchantOrderHandshakeInterceptor implements HandshakeInterceptor {

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request,
                                   ServerHttpResponse response,
                                   WebSocketHandler wsHandler,
                                   Map<String, Object> attributes) {
        if (!(request instanceof ServletServerHttpRequest)) {
            return reject(response);
        }
        String token = ((ServletServerHttpRequest) request).getServletRequest().getParameter("token");
        if (!StringUtils.hasText(token)) {
            return reject(response);
        }
        Merchant merchant;
        try {
            merchant = merchantSessionManager.getSession(token);
        } catch (RuntimeException ignored) {
            return reject(response);
        }
        if (merchant == null || merchant.getShopId() == null) {
            return reject(response);
        }
        attributes.put(MerchantOrderWebSocketHandler.SHOP_ID_ATTRIBUTE, merchant.getShopId());
        return true;
    }

    private boolean reject(ServerHttpResponse response) {
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        return false;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request,
                               ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
    }
}
