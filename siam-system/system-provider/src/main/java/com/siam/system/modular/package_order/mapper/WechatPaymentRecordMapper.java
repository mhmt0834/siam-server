package com.siam.system.modular.package_order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.siam.system.modular.package_order.entity.WechatPaymentRecord;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.Date;

public interface WechatPaymentRecordMapper extends BaseMapper<WechatPaymentRecord> {

    @Select("select * from tb_wechat_payment_record where order_id = #{orderId} limit 1")
    WechatPaymentRecord selectByOrderId(@Param("orderId") Integer orderId);

    @Update("update tb_wechat_payment_record set status = 2, transaction_id = #{transactionId}, " +
            "paid_at = #{paidAt}, update_time = #{paidAt} " +
            "where id = #{id} and shop_id = #{shopId} and status = 1")
    int markSuccess(@Param("id") Long id,
                    @Param("shopId") Integer shopId,
                    @Param("transactionId") String transactionId,
                    @Param("paidAt") Date paidAt);

    @Update("update tb_wechat_payment_record set prepay_id = #{prepayId}, update_time = #{updateTime} " +
            "where id = #{id} and status = 1")
    int savePrepayId(@Param("id") Long id,
                     @Param("prepayId") String prepayId,
                     @Param("updateTime") Date updateTime);
}
