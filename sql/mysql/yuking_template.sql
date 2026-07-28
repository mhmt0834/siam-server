-- 玉KING智能点餐模板：审核阶段默认到店付款，避免未配置微信支付时阻塞下单。
UPDATE `tb_shop`
SET `checkout_mode` = 2
WHERE `checkout_mode` <> 2 OR `checkout_mode` IS NULL;
