package com.siam.system.modular.package_goods.statistics;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.mapper.MerchantBusinessStatisticsMapper;
import com.siam.system.modular.package_goods.service_impl.MerchantBusinessStatisticsService;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantBusinessStatisticsServiceTest {

    @Mock
    private MerchantBusinessStatisticsMapper statisticsMapper;

    @Mock
    private MerchantSessionManager merchantSessionManager;

    private MerchantBusinessStatisticsService service;

    @Before
    public void setUp() {
        service = new MerchantBusinessStatisticsService();
        ReflectionTestUtils.setField(service, "statisticsMapper", statisticsMapper);
        ReflectionTestUtils.setField(service, "merchantSessionManager", merchantSessionManager);
        login("merchant-a", 101);
    }

    @After
    public void tearDown() {
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void todayUsesOnlyCompletedOrdersFromAuthenticatedShop() {
        when(statisticsMapper.selectCompletedOrderAggregate(eq(101), any(), any()))
                .thenReturn(row("todayRevenue", new BigDecimal("126.00"), "todayOrderCount", 3));
        when(statisticsMapper.selectShopOperating(101)).thenReturn(true);

        Map<String, Object> result = service.today();

        assertEquals(new BigDecimal("126.00"), result.get("todayRevenue"));
        assertEquals(3, result.get("todayOrderCount"));
        assertEquals(new BigDecimal("42.00"), result.get("averageOrderAmount"));
        assertEquals(true, result.get("isOperating"));
    }

    @Test
    public void merchantSessionsKeepStatisticsIsolatedByShop() {
        when(statisticsMapper.selectCompletedOrderAggregate(eq(101), any(), any()))
                .thenReturn(row("todayRevenue", new BigDecimal("68.00"), "todayOrderCount", 1));
        when(statisticsMapper.selectCompletedOrderAggregate(eq(202), any(), any()))
                .thenReturn(row("todayRevenue", new BigDecimal("188.00"), "todayOrderCount", 2));

        Map<String, Object> shopA = service.today();
        login("merchant-b", 202);
        Map<String, Object> shopB = service.today();

        assertEquals(new BigDecimal("68.00"), shopA.get("todayRevenue"));
        assertEquals(new BigDecimal("188.00"), shopB.get("todayRevenue"));
        verify(statisticsMapper).selectCompletedOrderAggregate(eq(101), any(), any());
        verify(statisticsMapper).selectCompletedOrderAggregate(eq(202), any(), any());
    }

    @Test
    public void trendReturnsEveryDayAndFillsDatesWithoutOrders() {
        String today = LocalDate.now().toString();
        when(statisticsMapper.selectTrend(eq(101), any(), any()))
                .thenReturn(Arrays.asList(row("statisticDate", today, "revenue", new BigDecimal("88.00"),
                        "orderCount", 1)));

        List<Map<String, Object>> result = service.trend("7d");

        assertEquals(7, result.size());
        assertEquals(today, result.get(6).get("date"));
        assertEquals(new BigDecimal("88.00"), result.get(6).get("revenue"));
        assertEquals(0, result.get(0).get("orderCount"));
    }

    @Test
    public void hotGoodsRanksRealOrderDetailAggregates() {
        when(statisticsMapper.selectHotGoods(eq(101), any(), any())).thenReturn(Arrays.asList(
                row("goodsId", 1, "goodsName", "新疆大盘鸡", "salesQuantity", 8,
                        "salesAmount", new BigDecimal("544.00")),
                row("goodsId", 2, "goodsName", "烤羊肉串", "salesQuantity", 5,
                        "salesAmount", new BigDecimal("30.00"))));

        List<Map<String, Object>> result = service.hotGoods("30d");

        assertEquals(1, result.get(0).get("rank"));
        assertEquals(2, result.get(1).get("rank"));
        assertEquals(new BigDecimal("544.00"), result.get(0).get("salesAmount"));
    }

    @Test
    public void goodsAnalysisClassifiesHotRegularAndNoSalesGoods() {
        List<Map<String, Object>> goods = new ArrayList<>();
        goods.add(row("goodsId", 1, "goodsName", "A", "salesQuantity", 10, "salesAmount", 100));
        goods.add(row("goodsId", 2, "goodsName", "B", "salesQuantity", 2, "salesAmount", 20));
        goods.add(row("goodsId", 3, "goodsName", "C", "salesQuantity", 0, "salesAmount", 0));
        when(statisticsMapper.selectGoodsSales(eq(101), any(), any())).thenReturn(goods);

        Map<String, Object> result = service.goodsAnalysis("30d");
        List<Map<String, Object>> rows = (List<Map<String, Object>>) result.get("goods");

        assertEquals(1, result.get("hotGoodsCount"));
        assertEquals(1, result.get("regularGoodsCount"));
        assertEquals(1, result.get("lowSalesGoodsCount"));
        assertEquals("HOT", rows.get(0).get("category"));
        assertEquals("REGULAR", rows.get(1).get("category"));
        assertEquals("LOW", rows.get(2).get("category"));
    }

    @Test
    public void unsupportedRangeIsRejectedBeforeQuery() {
        try {
            service.trend("90d");
            throw new AssertionError("Unsupported range should be rejected");
        } catch (StoneCustomerException expected) {
            assertTrue(expected.getMessage().contains("today"));
        }
        verify(statisticsMapper, times(0)).selectTrend(any(), any(), any());
    }

    private void login(String token, int shopId) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", token);
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        Merchant merchant = new Merchant();
        merchant.setShopId(shopId);
        when(merchantSessionManager.getSession(token)).thenReturn(merchant);
    }

    private Map<String, Object> row(Object... values) {
        Map<String, Object> result = new HashMap<>();
        for (int index = 0; index < values.length; index += 2) {
            result.put(String.valueOf(values[index]), values[index + 1]);
        }
        return result;
    }
}
