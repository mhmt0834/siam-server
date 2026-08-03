package com.siam.system.modular.package_order.realtime;

import org.springframework.context.ApplicationEvent;

public class MerchantOrderRealtimeEvent extends ApplicationEvent {

    public static final String NEW_ORDER = "NEW_ORDER";
    public static final String ORDER_STATUS_CHANGED = "ORDER_STATUS_CHANGED";

    private final Integer shopId;
    private final Integer orderId;
    private final String type;

    public MerchantOrderRealtimeEvent(Object source, Integer shopId, Integer orderId, String type) {
        super(source);
        this.shopId = shopId;
        this.orderId = orderId;
        this.type = type;
    }

    public Integer getShopId() {
        return shopId;
    }

    public Integer getOrderId() {
        return orderId;
    }

    public String getType() {
        return type;
    }
}
