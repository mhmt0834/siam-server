package com.siam.system.modular.package_order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.siam.system.modular.package_order.entity.ShopWechatConfig;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

public interface ShopWechatConfigMapper extends BaseMapper<ShopWechatConfig> {

    @Select("select * from tb_shop_wechat_config where shop_id = #{shopId} limit 1")
    ShopWechatConfig selectByShopId(@Param("shopId") Integer shopId);

    @Select("select * from tb_shop_wechat_config where callback_token = #{callbackToken} and enabled = 1 limit 1")
    ShopWechatConfig selectByCallbackToken(@Param("callbackToken") String callbackToken);

    @Select("select * from tb_shop_wechat_config where enabled = 1")
    List<ShopWechatConfig> selectEnabled();
}
