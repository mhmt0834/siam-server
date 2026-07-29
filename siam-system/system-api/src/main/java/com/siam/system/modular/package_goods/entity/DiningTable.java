package com.siam.system.modular.package_goods.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("tb_dining_table")
public class DiningTable {

    public static final Integer STATUS_DISABLED = 0;
    public static final Integer STATUS_ENABLED = 1;

    @TableId(type = IdType.AUTO)
    private Long id;

    private Integer shopId;

    private String tableNo;

    private String tableName;

    private String sceneToken;

    private String qrCodeUrl;

    private Integer status;

    private Date createTime;

    private Date updateTime;

    @TableField(exist = false)
    private Integer pageNo = 1;

    @TableField(exist = false)
    private Integer pageSize = 20;
}
