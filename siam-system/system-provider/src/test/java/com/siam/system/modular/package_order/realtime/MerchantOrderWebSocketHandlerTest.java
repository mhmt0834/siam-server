package com.siam.system.modular.package_order.realtime;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantOrderWebSocketHandlerTest {

    @Mock
    private WebSocketSession shopASession;

    @Mock
    private WebSocketSession shopBSession;

    @Test
    public void messageIsDeliveredOnlyToMatchingShop() throws Exception {
        MerchantOrderWebSocketHandler handler = new MerchantOrderWebSocketHandler();
        when(shopASession.getAttributes()).thenReturn(attributes(1));
        when(shopBSession.getAttributes()).thenReturn(attributes(2));
        when(shopASession.isOpen()).thenReturn(true);
        handler.afterConnectionEstablished(shopASession);
        handler.afterConnectionEstablished(shopBSession);

        handler.push(1, MerchantOrderRealtimeEvent.NEW_ORDER, 11);

        ArgumentCaptor<TextMessage> message = ArgumentCaptor.forClass(TextMessage.class);
        verify(shopASession).sendMessage(message.capture());
        verify(shopBSession, never()).sendMessage(org.mockito.ArgumentMatchers.any());
        assertTrue(message.getValue().getPayload().contains("\"orderId\":11"));
    }

    private Map<String, Object> attributes(int shopId) {
        Map<String, Object> attributes = new HashMap<>();
        attributes.put(MerchantOrderWebSocketHandler.SHOP_ID_ATTRIBUTE, shopId);
        return attributes;
    }
}
