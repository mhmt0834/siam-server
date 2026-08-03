package com.siam.system.modular.package_order.realtime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class MerchantOrderRealtimeEventListener {

    @Autowired
    private MerchantOrderWebSocketHandler handler;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onOrderChanged(MerchantOrderRealtimeEvent event) {
        handler.push(event.getShopId(), event.getType(), event.getOrderId());
    }
}
