package com.siam.system.modular.package_goods.mapper;

import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;
import java.util.Map;

public interface MerchantBusinessStatisticsMapper {

    @Select("SELECT IFNULL(SUM(actual_price), 0) AS todayRevenue, COUNT(*) AS todayOrderCount " +
            "FROM tb_order WHERE shop_id = #{shopId} AND status = 6 " +
            "AND order_completion_time >= #{startTime} AND order_completion_time < #{endTime}")
    Map<String, Object> selectCompletedOrderAggregate(@Param("shopId") Integer shopId,
                                                       @Param("startTime") Date startTime,
                                                       @Param("endTime") Date endTime);

    @Select("SELECT is_operating FROM tb_shop WHERE id = #{shopId} LIMIT 1")
    Boolean selectShopOperating(@Param("shopId") Integer shopId);

    @Select("SELECT DATE_FORMAT(order_completion_time, '%Y-%m-%d') AS statisticDate, " +
            "IFNULL(SUM(actual_price), 0) AS revenue, COUNT(*) AS orderCount " +
            "FROM tb_order WHERE shop_id = #{shopId} AND status = 6 " +
            "AND order_completion_time >= #{startTime} AND order_completion_time < #{endTime} " +
            "GROUP BY DATE_FORMAT(order_completion_time, '%Y-%m-%d') ORDER BY statisticDate")
    List<Map<String, Object>> selectTrend(@Param("shopId") Integer shopId,
                                          @Param("startTime") Date startTime,
                                          @Param("endTime") Date endTime);

    @Select("SELECT od.goods_id AS goodsId, od.goods_name AS goodsName, " +
            "SUM(od.number) AS salesQuantity, IFNULL(SUM(od.subtotal), 0) AS salesAmount " +
            "FROM tb_order_detail od INNER JOIN tb_order o ON o.id = od.order_id " +
            "WHERE o.shop_id = #{shopId} AND o.status = 6 " +
            "AND o.order_completion_time >= #{startTime} AND o.order_completion_time < #{endTime} " +
            "AND (od.is_deleted = 0 OR od.is_deleted IS NULL) " +
            "GROUP BY od.goods_id, od.goods_name " +
            "ORDER BY salesQuantity DESC, salesAmount DESC LIMIT 10")
    List<Map<String, Object>> selectHotGoods(@Param("shopId") Integer shopId,
                                             @Param("startTime") Date startTime,
                                             @Param("endTime") Date endTime);

    @Select("SELECT g.id AS goodsId, g.name AS goodsName, g.status AS goodsStatus, " +
            "IFNULL(s.salesQuantity, 0) AS salesQuantity, IFNULL(s.salesAmount, 0) AS salesAmount " +
            "FROM tb_goods g LEFT JOIN (" +
            "SELECT od.goods_id, SUM(od.number) AS salesQuantity, IFNULL(SUM(od.subtotal), 0) AS salesAmount " +
            "FROM tb_order_detail od INNER JOIN tb_order o ON o.id = od.order_id " +
            "WHERE o.shop_id = #{shopId} AND o.status = 6 " +
            "AND o.order_completion_time >= #{startTime} AND o.order_completion_time < #{endTime} " +
            "AND (od.is_deleted = 0 OR od.is_deleted IS NULL) GROUP BY od.goods_id" +
            ") s ON s.goods_id = g.id WHERE g.shop_id = #{shopId} " +
            "ORDER BY salesQuantity DESC, salesAmount DESC, g.id")
    List<Map<String, Object>> selectGoodsSales(@Param("shopId") Integer shopId,
                                               @Param("startTime") Date startTime,
                                               @Param("endTime") Date endTime);
}
