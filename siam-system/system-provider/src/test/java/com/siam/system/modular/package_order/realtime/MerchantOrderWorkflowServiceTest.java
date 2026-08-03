package com.siam.system.modular.package_order.realtime;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.mapper.OrderMapper;
import com.siam.system.modular.package_order.service_impl.MerchantOrderWorkflowService;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantOrderWorkflowServiceTest {

    @Mock
    private OrderMapper orderMapper;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    private MerchantOrderWorkflowService service;

    @Before
    public void setUp() {
        service = new MerchantOrderWorkflowService();
        ReflectionTestUtils.setField(service, "orderMapper", orderMapper);
        ReflectionTestUtils.setField(service, "eventPublisher", eventPublisher);
    }

    @Test
    public void acceptMovesWaitHandleToPreparing() {
        Order order = order(11, 1, Order.STATUS_OF_WAIT_HANDLE);
        when(orderMapper.selectById(11)).thenReturn(order);
        when(orderMapper.transitionStatus(11, 1, Order.STATUS_OF_WAIT_HANDLE,
                Order.STATUS_OF_WAIT_PICKUP)).thenReturn(1);

        service.accept(11, 1);

        verify(orderMapper).transitionStatus(11, 1, Order.STATUS_OF_WAIT_HANDLE,
                Order.STATUS_OF_WAIT_PICKUP);
        verify(eventPublisher).publishEvent(any(MerchantOrderRealtimeEvent.class));
    }

    @Test
    public void completeMovesPreparingToCompleted() {
        Order order = order(11, 1, Order.STATUS_OF_WAIT_PICKUP);
        when(orderMapper.selectById(11)).thenReturn(order);
        when(orderMapper.transitionStatus(11, 1, Order.STATUS_OF_WAIT_PICKUP,
                Order.STATUS_OF_COMPLETED)).thenReturn(1);

        service.complete(11, 1);

        verify(orderMapper).transitionStatus(11, 1, Order.STATUS_OF_WAIT_PICKUP,
                Order.STATUS_OF_COMPLETED);
    }

    @Test
    public void anotherShopCannotOperateOrder() {
        when(orderMapper.selectById(11)).thenReturn(order(11, 1, Order.STATUS_OF_WAIT_HANDLE));

        expectRejected(() -> service.accept(11, 2));

        verify(orderMapper, never()).transitionStatus(any(), any(), any(), any());
    }

    @Test
    public void duplicateAcceptIsRejected() {
        when(orderMapper.selectById(11)).thenReturn(order(11, 1, Order.STATUS_OF_WAIT_PICKUP));

        expectRejected(() -> service.accept(11, 1));

        verify(orderMapper, never()).transitionStatus(any(), any(), any(), any());
    }

    @Test
    public void concurrentTransitionIsRejected() {
        when(orderMapper.selectById(11)).thenReturn(order(11, 1, Order.STATUS_OF_WAIT_HANDLE));
        when(orderMapper.transitionStatus(11, 1, Order.STATUS_OF_WAIT_HANDLE,
                Order.STATUS_OF_WAIT_PICKUP)).thenReturn(0);

        expectRejected(() -> service.accept(11, 1));

        verify(eventPublisher, never()).publishEvent(any());
    }

    private Order order(int id, int shopId, int status) {
        Order order = new Order();
        order.setId(id);
        order.setShopId(shopId);
        order.setStatus(status);
        return order;
    }

    private void expectRejected(Runnable runnable) {
        try {
            runnable.run();
            throw new AssertionError("Operation should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        }
    }
}
