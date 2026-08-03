package com.siam.system.modular.package_order.realtime;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class MerchantOrderWebSocketHandler extends TextWebSocketHandler {

    public static final String SHOP_ID_ATTRIBUTE = "merchantOrderShopId";

    private final ConcurrentHashMap<Integer, Set<WebSocketSession>> sessionsByShop = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Integer shopId = (Integer) session.getAttributes().get(SHOP_ID_ATTRIBUTE);
        if (shopId == null) {
            session.close(CloseStatus.NOT_ACCEPTABLE);
            return;
        }
        sessionsByShop.computeIfAbsent(shopId, key -> ConcurrentHashMap.newKeySet()).add(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        if ("PING".equalsIgnoreCase(message.getPayload())) {
            session.sendMessage(new TextMessage("PONG"));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        remove(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        remove(session);
        if (session.isOpen()) {
            session.close(CloseStatus.SERVER_ERROR);
        }
    }

    public void push(Integer shopId, String type, Integer orderId) {
        Set<WebSocketSession> sessions = sessionsByShop.get(shopId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }
        TextMessage message = new TextMessage("{\"type\":\"" + type + "\",\"orderId\":" + orderId + "}");
        sessions.removeIf(session -> !send(session, message));
        if (sessions.isEmpty()) {
            sessionsByShop.remove(shopId, sessions);
        }
    }

    private boolean send(WebSocketSession session, TextMessage message) {
        if (!session.isOpen()) {
            return false;
        }
        try {
            synchronized (session) {
                if (!session.isOpen()) {
                    return false;
                }
                session.sendMessage(message);
            }
            return true;
        } catch (IOException ignored) {
            return false;
        }
    }

    private void remove(WebSocketSession session) {
        Integer shopId = (Integer) session.getAttributes().get(SHOP_ID_ATTRIBUTE);
        Set<WebSocketSession> sessions = shopId == null ? null : sessionsByShop.get(shopId);
        if (sessions != null) {
            sessions.remove(session);
            if (sessions.isEmpty()) {
                sessionsByShop.remove(shopId, sessions);
            }
        }
    }
}
