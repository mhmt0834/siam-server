package com.siam.system.modular.package_order.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("tb_wechat_payment_record")
public class WechatPaymentRecord {

    public static final int STATUS_INIT = 1;
    public static final int STATUS_SUCCESS = 2;

    @TableId(type = IdType.AUTO)
    private Long id;

    private Integer shopId;

    private Integer orderId;

    private String orderNo;

    private String appid;

    private String mchid;

    private Long amountCent;

    private Integer status;

    private String transactionId;

    private String prepayId;

    private Date paidAt;

    private Date createTime;

    private Date updateTime;
}
