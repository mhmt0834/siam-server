package com.siam.system.modular.package_order.payment;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.entity.ShopWechatConfig;
import com.siam.system.modular.package_order.entity.WechatPaymentRecord;
import com.siam.system.modular.package_order.mapper.OrderMapper;
import com.siam.system.modular.package_order.mapper.WechatPaymentRecordMapper;
import com.siam.system.modular.package_order.service_impl.payment.WechatPayV3Service;
import com.wechat.pay.java.service.payments.model.Transaction;
import com.wechat.pay.java.service.payments.model.TransactionAmount;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.Date;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class WechatPayV3ServiceTest {

    @Mock
    private OrderMapper orderMapper;

    @Mock
    private WechatPaymentRecordMapper paymentRecordMapper;

    private WechatPayV3Service service;

    @Before
    public void setUp() {
        service = new WechatPayV3Service();
        ReflectionTestUtils.setField(service, "orderMapper", orderMapper);
        ReflectionTestUtils.setField(service, "paymentRecordMapper", paymentRecordMapper);
    }

    @Test
    public void successfulNotificationMovesOrderToWaitHandle() {
        Fixture fixture = fixture(1, 1, WechatPaymentRecord.STATUS_INIT,
                Transaction.TradeStateEnum.SUCCESS);
        when(orderMapper.markWechatPaid(eq(11), eq(1), any(Date.class))).thenReturn(1);
        when(paymentRecordMapper.markSuccess(eq(21L), eq(1), eq("wx-transaction-1"),
                any(Date.class))).thenReturn(1);

        service.applySuccessfulNotification(fixture.verified);

        verify(orderMapper).markWechatPaid(eq(11), eq(1), any(Date.class));
        verify(paymentRecordMapper).markSuccess(eq(21L), eq(1), eq("wx-transaction-1"),
                any(Date.class));
    }

    @Test
    public void failedPaymentDoesNotChangeOrder() {
        Fixture fixture = fixture(1, 1, WechatPaymentRecord.STATUS_INIT,
                Transaction.TradeStateEnum.NOTPAY);

        expectRejected(fixture.verified);

        verify(orderMapper, never()).markWechatPaid(any(Integer.class), any(Integer.class), any(Date.class));
        verify(paymentRecordMapper, never()).markSuccess(any(Long.class), any(Integer.class),
                any(String.class), any(Date.class));
    }

    @Test
    public void duplicateSuccessfulNotificationIsIdempotent() {
        Fixture fixture = fixture(1, 1, WechatPaymentRecord.STATUS_SUCCESS,
                Transaction.TradeStateEnum.SUCCESS);

        service.applySuccessfulNotification(fixture.verified);

        verify(orderMapper, never()).markWechatPaid(any(Integer.class), any(Integer.class), any(Date.class));
        verify(paymentRecordMapper, never()).markSuccess(any(Long.class), any(Integer.class),
                any(String.class), any(Date.class));
    }

    @Test
    public void anotherShopConfigurationCannotConfirmOrder() {
        Fixture fixture = fixture(1, 2, WechatPaymentRecord.STATUS_INIT,
                Transaction.TradeStateEnum.SUCCESS);

        expectRejected(fixture.verified);

        verify(orderMapper, never()).markWechatPaid(any(Integer.class), any(Integer.class), any(Date.class));
    }

    private Fixture fixture(int orderShopId,
                            int configShopId,
                            int paymentStatus,
                            Transaction.TradeStateEnum tradeState) {
        Order order = new Order();
        order.setId(11);
        order.setOrderNo("202607300001");
        order.setShopId(orderShopId);
        order.setActualPrice(new BigDecimal("68.00"));
        order.setStatus(Order.STATUS_OF_WAIT_PAYMENT);
        order.setIsPayment(false);
        when(orderMapper.selectByOrderNo(order.getOrderNo())).thenReturn(order);

        ShopWechatConfig config = new ShopWechatConfig();
        config.setShopId(configShopId);
        config.setAppid("wx-app-a");
        config.setMchid("mch-a");

        WechatPaymentRecord record = new WechatPaymentRecord();
        record.setId(21L);
        record.setOrderId(order.getId());
        record.setOrderNo(order.getOrderNo());
        record.setShopId(orderShopId);
        record.setAppid(config.getAppid());
        record.setMchid(config.getMchid());
        record.setAmountCent(6800L);
        record.setStatus(paymentStatus);
        if (paymentStatus == WechatPaymentRecord.STATUS_SUCCESS) {
            record.setTransactionId("wx-transaction-1");
        }
        when(paymentRecordMapper.selectByOrderId(order.getId())).thenReturn(record);

        TransactionAmount amount = new TransactionAmount();
        amount.setTotal(6800);
        amount.setCurrency("CNY");

        Transaction transaction = new Transaction();
        transaction.setOutTradeNo(order.getOrderNo());
        transaction.setAppid(config.getAppid());
        transaction.setMchid(config.getMchid());
        transaction.setAttach("shop:" + orderShopId + ":order:" + order.getId());
        transaction.setAmount(amount);
        transaction.setTransactionId("wx-transaction-1");
        transaction.setTradeState(tradeState);
        transaction.setSuccessTime("2026-07-30T01:00:00+08:00");
        return new Fixture(new WechatPayV3Service.VerifiedNotification(config, transaction));
    }

    private void expectRejected(WechatPayV3Service.VerifiedNotification verified) {
        try {
            service.applySuccessfulNotification(verified);
            throw new AssertionError("Notification should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        }
    }

    private static class Fixture {
        private final WechatPayV3Service.VerifiedNotification verified;

        private Fixture(WechatPayV3Service.VerifiedNotification verified) {
            this.verified = verified;
        }
    }
}
