package com.siam.system.modular.package_goods.service_impl;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.mapper.MerchantBusinessStatisticsMapper;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MerchantBusinessStatisticsService {

    private static final String RANGE_TODAY = "today";
    private static final String RANGE_SEVEN_DAYS = "7d";
    private static final String RANGE_THIRTY_DAYS = "30d";

    @Autowired
    private MerchantBusinessStatisticsMapper statisticsMapper;

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    public Map<String, Object> today() {
        Integer shopId = currentShopId();
        DateRange range = range(RANGE_TODAY);
        Map<String, Object> aggregate = statisticsMapper.selectCompletedOrderAggregate(
                shopId, range.startTime, range.endTime);
        BigDecimal revenue = decimalValue(aggregate == null ? null : aggregate.get("todayRevenue"));
        int orderCount = intValue(aggregate == null ? null : aggregate.get("todayOrderCount"));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("todayRevenue", revenue);
        result.put("todayOrderCount", orderCount);
        result.put("averageOrderAmount", orderCount == 0
                ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
                : revenue.divide(BigDecimal.valueOf(orderCount), 2, RoundingMode.HALF_UP));
        result.put("isOperating", Boolean.TRUE.equals(statisticsMapper.selectShopOperating(shopId)));
        return result;
    }

    public List<Map<String, Object>> trend(String rangeValue) {
        Integer shopId = currentShopId();
        DateRange range = range(rangeValue);
        List<Map<String, Object>> rows = statisticsMapper.selectTrend(shopId, range.startTime, range.endTime);
        Map<String, Map<String, Object>> rowsByDate = new HashMap<>();
        if (rows != null) {
            for (Map<String, Object> row : rows) {
                rowsByDate.put(String.valueOf(row.get("statisticDate")), row);
            }
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (int index = 0; index < range.days; index++) {
            String date = range.startDate.plusDays(index).format(DateTimeFormatter.ISO_LOCAL_DATE);
            Map<String, Object> row = rowsByDate.get(date);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("date", date);
            item.put("revenue", decimalValue(row == null ? null : row.get("revenue")));
            item.put("orderCount", intValue(row == null ? null : row.get("orderCount")));
            result.add(item);
        }
        return result;
    }

    public List<Map<String, Object>> hotGoods(String rangeValue) {
        Integer shopId = currentShopId();
        DateRange range = range(rangeValue);
        List<Map<String, Object>> rows = statisticsMapper.selectHotGoods(shopId, range.startTime, range.endTime);
        List<Map<String, Object>> result = new ArrayList<>();
        if (rows == null) {
            return result;
        }
        for (int index = 0; index < rows.size(); index++) {
            Map<String, Object> item = new LinkedHashMap<>(rows.get(index));
            item.put("rank", index + 1);
            item.put("salesQuantity", intValue(item.get("salesQuantity")));
            item.put("salesAmount", decimalValue(item.get("salesAmount")));
            result.add(item);
        }
        return result;
    }

    public Map<String, Object> goodsAnalysis(String rangeValue) {
        Integer shopId = currentShopId();
        DateRange range = range(rangeValue);
        List<Map<String, Object>> rows = statisticsMapper.selectGoodsSales(shopId, range.startTime, range.endTime);
        List<Map<String, Object>> goods = new ArrayList<>();
        int totalQuantity = 0;
        if (rows != null) {
            for (Map<String, Object> row : rows) {
                totalQuantity += intValue(row.get("salesQuantity"));
            }
        }
        BigDecimal averageQuantity = rows == null || rows.isEmpty()
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(totalQuantity).divide(BigDecimal.valueOf(rows.size()), 2, RoundingMode.HALF_UP);
        int hotCount = 0;
        int regularCount = 0;
        int lowCount = 0;
        if (rows != null) {
            for (Map<String, Object> row : rows) {
                Map<String, Object> item = new LinkedHashMap<>(row);
                int quantity = intValue(item.get("salesQuantity"));
                String category;
                String categoryName;
                if (quantity == 0) {
                    category = "LOW";
                    categoryName = "低销量商品";
                    lowCount++;
                } else if (BigDecimal.valueOf(quantity).compareTo(averageQuantity) >= 0) {
                    category = "HOT";
                    categoryName = "热销商品";
                    hotCount++;
                } else {
                    category = "REGULAR";
                    categoryName = "普通商品";
                    regularCount++;
                }
                item.put("salesQuantity", quantity);
                item.put("salesAmount", decimalValue(item.get("salesAmount")));
                item.put("category", category);
                item.put("categoryName", categoryName);
                goods.add(item);
            }
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("averageSalesQuantity", averageQuantity);
        result.put("hotGoodsCount", hotCount);
        result.put("regularGoodsCount", regularCount);
        result.put("lowSalesGoodsCount", lowCount);
        result.put("goods", goods);
        return result;
    }

    private Integer currentShopId() {
        Merchant merchant = merchantSessionManager.getSession(TokenUtil.getToken());
        if (merchant == null || merchant.getShopId() == null) {
            throw new StoneCustomerException("当前商家未绑定店铺");
        }
        return merchant.getShopId();
    }

    private DateRange range(String rangeValue) {
        String normalized = rangeValue == null || rangeValue.trim().isEmpty()
                ? RANGE_SEVEN_DAYS : rangeValue.trim().toLowerCase();
        int days;
        if (RANGE_TODAY.equals(normalized)) {
            days = 1;
        } else if (RANGE_SEVEN_DAYS.equals(normalized)) {
            days = 7;
        } else if (RANGE_THIRTY_DAYS.equals(normalized)) {
            days = 30;
        } else {
            throw new StoneCustomerException("统计时间范围仅支持 today、7d、30d");
        }
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1L);
        ZoneId zoneId = ZoneId.systemDefault();
        return new DateRange(startDate,
                Date.from(startDate.atStartOfDay(zoneId).toInstant()),
                Date.from(endDate.plusDays(1).atStartOfDay(zoneId).toInstant()), days);
    }

    private BigDecimal decimalValue(Object value) {
        if (value == null) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        BigDecimal decimal = value instanceof BigDecimal
                ? (BigDecimal) value : new BigDecimal(String.valueOf(value));
        return decimal.setScale(2, RoundingMode.HALF_UP);
    }

    private int intValue(Object value) {
        return value == null ? 0 : new BigDecimal(String.valueOf(value)).intValue();
    }

    private static class DateRange {
        private final LocalDate startDate;
        private final Date startTime;
        private final Date endTime;
        private final int days;

        private DateRange(LocalDate startDate, Date startTime, Date endTime, int days) {
            this.startDate = startDate;
            this.startTime = startTime;
            this.endTime = endTime;
            this.days = days;
        }
    }
}
