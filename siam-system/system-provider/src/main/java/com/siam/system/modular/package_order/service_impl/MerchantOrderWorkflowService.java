package com.siam.system.modular.package_order.service_impl;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.mapper.OrderMapper;
import com.siam.system.modular.package_order.realtime.MerchantOrderRealtimeEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;

@Service
public class MerchantOrderWorkflowService {

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    @Transactional(rollbackFor = Exception.class)
    public void accept(Integer orderId, Integer shopId) {
        transition(orderId, shopId, Order.STATUS_OF_WAIT_HANDLE, Order.STATUS_OF_WAIT_PICKUP);
    }

    @Transactional(rollbackFor = Exception.class)
    public void complete(Integer orderId, Integer shopId) {
        transition(orderId, shopId, Order.STATUS_OF_WAIT_PICKUP, Order.STATUS_OF_COMPLETED);
    }

    private void transition(Integer orderId, Integer shopId, int expectedStatus, int targetStatus) {
        if (orderId == null || shopId == null) {
            throw new StoneCustomerException("订单参数不完整");
        }
        Order order = orderMapper.selectById(orderId);
        if (order == null) {
            throw new StoneCustomerException("订单不存在");
        }
        if (!Objects.equals(shopId, order.getShopId())) {
            throw new StoneCustomerException("无权操作该订单");
        }
        if (order.getStatus() == null || order.getStatus() != expectedStatus) {
            throw new StoneCustomerException("订单状态已变化，请刷新后重试");
        }
        if (orderMapper.transitionStatus(orderId, shopId, expectedStatus, targetStatus) != 1) {
            throw new StoneCustomerException("订单已被处理，请刷新后重试");
        }
        eventPublisher.publishEvent(new MerchantOrderRealtimeEvent(this, shopId, orderId,
                MerchantOrderRealtimeEvent.ORDER_STATUS_CHANGED));
    }
}
