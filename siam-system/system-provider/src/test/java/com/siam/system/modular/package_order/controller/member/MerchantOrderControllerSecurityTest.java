package com.siam.system.modular.package_order.controller.member;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.model.param.OrderParam;
import com.siam.system.modular.package_order.service.OrderService;
import com.siam.system.modular.package_order.service_impl.MerchantOrderWorkflowService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Arrays;

import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantOrderControllerSecurityTest {

    @Mock private MerchantSessionManager merchantSessionManager;
    @Mock private OrderService orderService;
    @Mock private MerchantOrderWorkflowService workflowService;

    private MerchantOrderController controller;

    @Before
    public void setUp() {
        controller = new MerchantOrderController();
        ReflectionTestUtils.setField(controller, "merchantSessionManager", merchantSessionManager);
        ReflectionTestUtils.setField(controller, "orderService", orderService);
        ReflectionTestUtils.setField(controller, "merchantOrderWorkflowService", workflowService);

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "merchant-token");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));

        Merchant merchant = new Merchant();
        merchant.setShopId(Integer.valueOf(1000));
        when(merchantSessionManager.getSession("merchant-token")).thenReturn(merchant);
    }

    @After
    public void tearDown() {
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void selectByIdUsesValueEqualityForShopId() {
        Order order = order(51, Integer.valueOf(1000), Order.STATUS_OF_WAIT_HANDLE);
        when(orderService.getById(51)).thenReturn(order);
        OrderParam param = new OrderParam();
        param.setId(51);

        controller.selectById(param);
    }

    @Test
    public void printUpdateIsAlwaysScopedToLoginShop() {
        OrderParam param = new OrderParam();
        param.setIdListStr("[51,52]");

        controller.batchUpdateIsPrintedTrue(param);

        verify(orderService).batchUpdateIsPrintedTrueForShop(Arrays.asList(51, 52), 1000);
        verify(orderService, never()).batchUpdateIsPrintedTrue(Arrays.asList(51, 52));
    }

    @Test
    public void legacyStatusEndpointCannotBypassWorkflow() {
        Order order = order(51, 1000, Order.STATUS_OF_WAIT_PAYMENT);
        when(orderService.getById(51)).thenReturn(order);
        OrderParam param = new OrderParam();
        param.setId(51);
        param.setFlag(6);

        expectRejected(() -> controller.updateStatus(param));

        verify(orderService, never()).updateById(order);
        verify(workflowService, never()).accept(51, 1000);
        verify(workflowService, never()).complete(51, 1000);
    }

    private Order order(int id, Integer shopId, int status) {
        Order order = new Order();
        order.setId(id);
        order.setShopId(shopId);
        order.setStatus(status);
        return order;
    }

    private void expectRejected(Runnable action) {
        try {
            action.run();
            throw new AssertionError("Operation should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        }
    }
}
