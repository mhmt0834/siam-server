
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `tb_admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_admin` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `username` varchar(50) DEFAULT NULL COMMENT '??????',
  `mobile` varchar(11) NOT NULL COMMENT '???',
  `password` varchar(100) DEFAULT NULL COMMENT '??',
  `password_salt` varchar(100) DEFAULT NULL COMMENT '????',
  `nickname` varchar(100) DEFAULT NULL COMMENT '??',
  `roles` varchar(128) DEFAULT NULL COMMENT '??',
  `is_disabled` int NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `is_deleted` int NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=???',
  `disabled` int NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `last_login_time` datetime DEFAULT NULL COMMENT '??????',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='??????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_admin_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_admin_token` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `admin_id` int NOT NULL COMMENT '???id',
  `username` varchar(50) DEFAULT NULL COMMENT '??????',
  `token` varchar(128) NOT NULL COMMENT 'token',
  `type` varchar(5) DEFAULT NULL COMMENT '???? wap',
  `login_time` datetime NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1226 DEFAULT CHARSET=utf8mb3 COMMENT='?????token?';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_advertisement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_advertisement` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `image_name` varchar(50) DEFAULT NULL COMMENT '?????',
  `image_path` varchar(256) DEFAULT NULL COMMENT '?????',
  `description` varchar(50) DEFAULT NULL COMMENT '??',
  `type` int DEFAULT '1' COMMENT '????? 1=????? 2=?????? 3=????????? 4=????????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `image_link_url` varchar(256) DEFAULT NULL COMMENT '??????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb3 COMMENT='??????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_appraise`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_appraise` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `order_id` int DEFAULT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `appraise_type` int NOT NULL DEFAULT '1' COMMENT '???? 1-?????2-????',
  `content` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL COMMENT '????',
  `images_url` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL COMMENT '?url??????',
  `level` int DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_coupons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_coupons` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(100) DEFAULT NULL COMMENT '?????',
  `preferential_type` int DEFAULT NULL COMMENT '?????1=???2=??',
  `discount_amount` decimal(10,2) DEFAULT '1.00' COMMENT '????',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????????????????',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `description` varchar(500) DEFAULT NULL COMMENT '??????',
  `valid_type` int NOT NULL DEFAULT '2' COMMENT '??:1????????XXX-XXX??????? 2????????N????',
  `valid_start_time` datetime DEFAULT NULL COMMENT '??????',
  `valid_end_time` datetime DEFAULT NULL COMMENT '??????',
  `valid_days` int NOT NULL DEFAULT '0' COMMENT '??????????',
  `is_delete` tinyint(1) DEFAULT '0' COMMENT '??????0-??1-?',
  `source` int DEFAULT NULL COMMENT '??????? 1=???? 2=????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb3 COMMENT='????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_coupons_goods_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_coupons_goods_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `coupons_id` int DEFAULT NULL COMMENT '???id',
  `goods_id` int DEFAULT NULL COMMENT '??id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1458 DEFAULT CHARSET=utf8mb3 COMMENT='???????????????????????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_coupons_member_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_coupons_member_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `coupons_id` int DEFAULT NULL COMMENT '???id',
  `coupons_name` varchar(100) DEFAULT NULL COMMENT '?????',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `start_time` datetime DEFAULT NULL COMMENT '????',
  `end_time` datetime DEFAULT NULL COMMENT '????',
  `is_used` tinyint(1) DEFAULT '0' COMMENT '???????0=????1=???',
  `is_expired` tinyint(1) DEFAULT '0' COMMENT '?????0=????1=???',
  `is_valid` tinyint(1) DEFAULT '1' COMMENT '?????0-??1-?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19598 DEFAULT CHARSET=utf8mb3 COMMENT='????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_coupons_shop_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_coupons_shop_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `coupons_id` int DEFAULT NULL COMMENT '???id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=168 DEFAULT CHARSET=utf8mb3 COMMENT='???????????????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_courier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_courier` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '????',
  `phone` varchar(11) DEFAULT NULL COMMENT '????',
  `sex` int DEFAULT '0' COMMENT '?? 0=? 1=? 2=?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_delivery_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_delivery_address` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '?????',
  `phone` varchar(11) DEFAULT NULL COMMENT '????',
  `province` varchar(20) DEFAULT NULL COMMENT '??',
  `city` varchar(20) DEFAULT NULL COMMENT '??',
  `area` varchar(100) DEFAULT NULL COMMENT '?/?',
  `street` varchar(100) DEFAULT NULL COMMENT '????',
  `is_default` int NOT NULL DEFAULT '0' COMMENT '???????? 0=? 1=?',
  `sex` int DEFAULT '0' COMMENT '????? 0=? 1=?? 2=??',
  `house_number` varchar(100) DEFAULT NULL COMMENT '???',
  `longitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `latitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=612 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_dining_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_dining_table` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `shop_id` int NOT NULL COMMENT 'Shop id',
  `table_no` varchar(50) NOT NULL COMMENT 'Table number',
  `table_name` varchar(50) NOT NULL COMMENT 'Table display name',
  `scene_token` varchar(64) NOT NULL COMMENT 'Opaque scan token',
  `qr_code_url` varchar(500) DEFAULT NULL COMMENT 'Generated mini program code URL',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1=enabled, 0=disabled',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dining_table_shop_no` (`shop_id`,`table_no`),
  UNIQUE KEY `uk_dining_table_scene_token` (`scene_token`),
  KEY `idx_dining_table_shop_status` (`shop_id`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Dining tables';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_full_reduction_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_full_reduction_rule` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(100) DEFAULT NULL COMMENT '????',
  `status` int DEFAULT NULL COMMENT '?????1=???2=??',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????????????????',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_give_like`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_give_like` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `appraise_id` int DEFAULT NULL COMMENT '??id',
  `reply_id` int DEFAULT NULL COMMENT '??id',
  `type` int NOT NULL DEFAULT '1' COMMENT '???? 1-?????2-????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_goods` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) DEFAULT NULL COMMENT '????',
  `sub_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `detail` varchar(1024) DEFAULT NULL COMMENT '????',
  `detail_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `stock` int DEFAULT '0' COMMENT '??',
  `is_hot` tinyint(1) DEFAULT '0' COMMENT '????',
  `is_new` tinyint(1) DEFAULT '0' COMMENT '????',
  `status` int DEFAULT '1' COMMENT '?? 1=??? 2=??? 3=??? 4=??',
  `is_sale` tinyint unsigned DEFAULT '0' COMMENT '?????? 0-? 1-?',
  `sale_price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `monthly_sales` int DEFAULT '0' COMMENT '???',
  `total_sales` int DEFAULT '0' COMMENT '????',
  `total_comments` int DEFAULT '0' COMMENT '????',
  `preferential_name` varchar(20) DEFAULT NULL COMMENT '????',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `product_time` decimal(10,2) DEFAULT '0.00' COMMENT '????(??)',
  `exchange_points` int DEFAULT NULL COMMENT '??????????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `printer_id` varchar(255) DEFAULT NULL COMMENT 'Bound printer ids',
  `print_num` int DEFAULT '1' COMMENT 'Print copies',
  PRIMARY KEY (`id`),
  KEY `idx_goods_shop_status_sort` (`shop_id`,`status`,`sort_number`)
) ENGINE=InnoDB AUTO_INCREMENT=281 DEFAULT CHARSET=utf8mb3 COMMENT='???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_goods_rawmaterial_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_goods_rawmaterial_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `rawmaterial_id` int DEFAULT NULL COMMENT '??id',
  `consumed_quantity` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb3 COMMENT='?????/???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_goods_specification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_goods_specification` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `name` varchar(10) NOT NULL COMMENT '??????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1678 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_goods_specification_option`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_goods_specification_option` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_specification_id` int NOT NULL COMMENT '????id',
  `name` varchar(10) NOT NULL COMMENT '????????',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??/????',
  `stock` int DEFAULT '1' COMMENT '?? 1=?? 2=??',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5274 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '???',
  `mobile` varchar(11) NOT NULL COMMENT '???',
  `password` varchar(100) DEFAULT NULL COMMENT '??',
  `password_salt` varchar(100) DEFAULT NULL COMMENT '????',
  `nickname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '??(????)',
  `balance` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `login_count` int NOT NULL DEFAULT '0' COMMENT '????',
  `invite_code` varchar(10) DEFAULT NULL COMMENT '???',
  `head_img` varchar(256) DEFAULT NULL COMMENT '??',
  `roles` varchar(128) DEFAULT NULL COMMENT '??',
  `sex` int DEFAULT '0' COMMENT '?? 0=? 1=? 2=?',
  `email` varchar(50) DEFAULT NULL COMMENT '????',
  `is_disabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `open_id` varchar(50) DEFAULT NULL COMMENT '?????openId',
  `is_bind_wx` tinyint(1) DEFAULT '0' COMMENT '?????? 0=? 1=?',
  `points` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `vip_status` int DEFAULT '0' COMMENT '???? 0=?/??? 1=?? 2=?? 3=???(????)',
  `vip_type` int DEFAULT '0' COMMENT '???? 0=? 1=???? 2=???? 3=????(????)',
  `vip_start_time` datetime DEFAULT NULL COMMENT '??????(????)',
  `vip_end_time` datetime DEFAULT NULL COMMENT '??????(????)',
  `type` int DEFAULT '1' COMMENT '???? 1=???? 2=VIP??',
  `vip_no` varchar(50) DEFAULT NULL COMMENT '????',
  `is_new_people` tinyint(1) DEFAULT '1' COMMENT '?????? 0=? 1=?',
  `is_remind_new_people` tinyint(1) DEFAULT '1' COMMENT '???????????? 0=? 1=?',
  `last_use_time` datetime DEFAULT NULL COMMENT '????/????????',
  `last_use_address` varchar(200) DEFAULT NULL COMMENT '????/??????????',
  `register_way` int DEFAULT NULL COMMENT '???? 1=?????? 2=????? 3=????',
  `wx_public_platform_open_id` varchar(50) DEFAULT NULL COMMENT '?????openId',
  `is_request_wx_notify` tinyint(1) DEFAULT '1' COMMENT '???????????? 0=? 1=?',
  `last_request_wx_notify_time` datetime DEFAULT NULL COMMENT '?????????????',
  `invite_reward_amount` decimal(10,2) DEFAULT '0.00' COMMENT '???????????',
  `real_name` varchar(50) DEFAULT NULL COMMENT '????',
  `total_balance` decimal(10,2) DEFAULT '0.00' COMMENT '????',
  `total_consume_balance` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `total_points` decimal(10,2) DEFAULT '0.00' COMMENT '????',
  `total_consume_points` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `total_withdraw_invite_reward_amount` decimal(10,2) DEFAULT '0.00' COMMENT '???????????????',
  `payment_password` varchar(100) DEFAULT NULL COMMENT '????',
  `payment_password_salt` varchar(100) DEFAULT NULL COMMENT '??????',
  `invite_suncode` varchar(256) DEFAULT NULL COMMENT '????-????????',
  `unreceived_points` decimal(10,2) DEFAULT '0.00' COMMENT '???-??',
  `unreceived_invite_reward_amount` decimal(10,2) DEFAULT '0.00' COMMENT '???-???????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `last_login_time` datetime DEFAULT NULL COMMENT '??????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb3 COMMENT='???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_billing_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_billing_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `type` int NOT NULL COMMENT '???? 1=?????? 2=?????? 3=????????? 4=???????? 5=????????????? 6=????????????? 7=????????????????? 8=????????? 9=????????? 10=???????? 11=??????????? 12=???????? 13=????????-???? 14=??????-???? 15=???????????? 16=?????????-???? 17=?????????-???? 18=?????????????? 19=????-???????? 20=????-??????????? 21=????-??????????? 22=????-??????????',
  `operate_type` int NOT NULL COMMENT '???? 1=? 2=?',
  `coin_type` int NOT NULL COMMENT '???? 1=?? 2=?? 3=??????????? 4=???-?? 5=???-???????????',
  `number` decimal(10,2) NOT NULL COMMENT '?????',
  `service_fee` decimal(10,2) DEFAULT NULL COMMENT '???',
  `message` varchar(200) DEFAULT NULL COMMENT '????',
  `order_id` int DEFAULT NULL COMMENT '??????id',
  `points_mall_order_id` int DEFAULT NULL COMMENT '??????id',
  `is_return` tinyint(1) DEFAULT '0' COMMENT '?????????',
  `is_settled` tinyint(1) DEFAULT '0' COMMENT '?????????/???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=179 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_goods_collect`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_goods_collect` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `goods_id` int DEFAULT NULL COMMENT '??id',
  `is_goods_exists` tinyint(1) DEFAULT '1' COMMENT '?????? 0=?? 1=??',
  `is_buy` tinyint(1) DEFAULT '0' COMMENT '?????? 0=??? 1=???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_invite_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_invite_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '?????id',
  `inviter_id` int DEFAULT NULL COMMENT '???id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=236 DEFAULT CHARSET=utf8mb3 COMMENT='????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_token` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '???',
  `token` varchar(128) NOT NULL COMMENT '????',
  `type` varchar(5) DEFAULT NULL COMMENT '???? wap',
  `create_time` datetime NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2552 DEFAULT CHARSET=utf8mb3 COMMENT='????token???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_trade_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_trade_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `merchant_id` int DEFAULT NULL COMMENT '????id',
  `out_trade_no` varchar(50) DEFAULT NULL COMMENT '????(????????)',
  `trade_no` varchar(50) DEFAULT NULL COMMENT '????(????????)',
  `type` int DEFAULT '1' COMMENT '???? 1=?????? 2=?????? 3=?????????? 4=?????? 5=????????????? 6=??????????',
  `payment_mode` int DEFAULT NULL COMMENT '???? 1=?? 2=??? 3=???? 4=????',
  `amount` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `status` int DEFAULT '1' COMMENT '???? 1=??? 2=???? 3=???? 4=????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3246 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_member_withdraw_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_member_withdraw_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `order_no` varchar(50) NOT NULL COMMENT '??????????',
  `coin_type` int NOT NULL COMMENT '???? 1=???????????',
  `withdraw_amount` decimal(10,2) NOT NULL COMMENT '????',
  `platform_fee` decimal(10,2) NOT NULL COMMENT '?????/???',
  `actual_amount` decimal(10,2) DEFAULT NULL COMMENT '??????',
  `audit_status` int NOT NULL DEFAULT '1' COMMENT '???? 1=????? 2=???? 3=?????',
  `audit_reason` varchar(50) DEFAULT NULL COMMENT '???????',
  `audit_time` datetime DEFAULT NULL COMMENT '????',
  `payment_mode` int DEFAULT NULL COMMENT '????/???? 1=?? 2=??? 3=??',
  `opening_bank_address` varchar(50) DEFAULT NULL COMMENT '???',
  `opening_bank_name` varchar(50) DEFAULT NULL COMMENT '??????',
  `bank_card` varchar(50) DEFAULT NULL COMMENT '????',
  `alipay_account` varchar(50) DEFAULT NULL COMMENT '?????',
  `wechat_account` varchar(50) DEFAULT NULL COMMENT '????',
  `trade_id` int DEFAULT NULL COMMENT '????id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_menu` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '??????',
  `description` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL COMMENT '??????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`),
  KEY `idx_menu_shop_sort` (`shop_id`,`sort_number`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_menu_goods_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_menu_goods_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `menu_id` int NOT NULL COMMENT '????id',
  `goods_id` int NOT NULL COMMENT '??id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=288 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='?????????(???)';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '????id',
  `username` varchar(50) DEFAULT NULL COMMENT '????',
  `mobile` varchar(11) NOT NULL COMMENT '????',
  `PASSWORD` varchar(100) DEFAULT NULL COMMENT '????',
  `password_salt` varchar(100) DEFAULT NULL COMMENT '????',
  `nickname` varchar(100) DEFAULT NULL COMMENT '??',
  `roles` varchar(100) DEFAULT NULL COMMENT '??',
  `head_img` varchar(256) DEFAULT NULL COMMENT '??',
  `sex` int DEFAULT NULL COMMENT '??',
  `email` varchar(50) DEFAULT NULL COMMENT '??',
  `certificate_type` varchar(50) DEFAULT '???' COMMENT '????',
  `certificate_img` varchar(50) DEFAULT NULL COMMENT '????',
  `is_disabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `audit_status` int DEFAULT '1' COMMENT '?????1=????2=?????3=?????',
  `real_name` varchar(50) DEFAULT NULL COMMENT '????',
  `id_card` varchar(50) DEFAULT NULL COMMENT '?????',
  `opening_bank_address` varchar(50) DEFAULT NULL COMMENT '???',
  `opening_bank_name` varchar(50) DEFAULT NULL COMMENT '??????',
  `bank_card` varchar(50) DEFAULT NULL COMMENT '????',
  `alipay_account` varchar(50) DEFAULT NULL COMMENT '?????',
  `wechat_account` varchar(50) DEFAULT NULL COMMENT '????',
  `balance` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `withdrawable_balance` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `frozen_balance` decimal(10,2) DEFAULT '0.00' COMMENT '????',
  `order_frozen_balance` decimal(10,2) DEFAULT '0.00' COMMENT '????????',
  `member_id` int DEFAULT NULL COMMENT '????????id(?????????????????????)',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant_billing_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant_billing_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `merchant_id` int NOT NULL COMMENT '????id',
  `type` int NOT NULL COMMENT '???? 1=???? 2=???? 3=???????? 4=????????????? 5=????????????? 6=?????-????? 7=?????????? 8=??????????-????? 9=?????? 10-??????-?????',
  `operate_type` int NOT NULL COMMENT '???? 1=? 2=?',
  `coin_type` int NOT NULL COMMENT '???? 1=??',
  `number` decimal(10,2) NOT NULL COMMENT '?????',
  `service_fee` decimal(10,2) DEFAULT NULL COMMENT '???',
  `message` varchar(200) DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=205 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant_recommend_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant_recommend_goods` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `goods_id` int DEFAULT NULL COMMENT '??id',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant_token` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `merchant_id` int NOT NULL COMMENT '??id',
  `username` varchar(50) DEFAULT NULL COMMENT '?????',
  `token` varchar(128) NOT NULL COMMENT '????',
  `type` varchar(5) DEFAULT NULL COMMENT '???? wap',
  `create_time` datetime NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=174 DEFAULT CHARSET=utf8mb3 COMMENT='????token???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant_trade_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant_trade_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `merchant_id` int NOT NULL COMMENT '????id',
  `trade_no` varchar(50) DEFAULT NULL COMMENT '????(????????)',
  `out_trade_no` varchar(50) DEFAULT NULL COMMENT '????(????????)',
  `type` int DEFAULT '1' COMMENT '???? 1=????',
  `payment_mode` int DEFAULT NULL COMMENT '???? 1=?? 2=??? 3=???? 4=?? 5=????',
  `amount` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `status` int DEFAULT '1' COMMENT '???? 1=??? 2=???? 3=???? 3=????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='(???)???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_merchant_withdraw_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_merchant_withdraw_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `merchant_id` int NOT NULL COMMENT '????id',
  `order_no` varchar(50) NOT NULL COMMENT '??????????',
  `withdraw_amount` decimal(10,2) NOT NULL COMMENT '????',
  `platform_fee` decimal(10,2) NOT NULL COMMENT '?????/???',
  `actual_amount` decimal(10,2) DEFAULT NULL COMMENT '??????',
  `audit_status` int DEFAULT '1' COMMENT '???? 1=????? 2=???? 3=?????',
  `audit_reason` varchar(50) DEFAULT NULL COMMENT '???????',
  `audit_time` datetime DEFAULT NULL COMMENT '????',
  `payment_mode` int DEFAULT NULL COMMENT '????/???? 1=?? 2=??? 3=??',
  `opening_bank_address` varchar(50) DEFAULT NULL COMMENT '???',
  `opening_bank_name` varchar(50) DEFAULT NULL COMMENT '??????',
  `bank_card` varchar(50) DEFAULT NULL COMMENT '????',
  `alipay_account` varchar(50) DEFAULT NULL COMMENT '?????',
  `wechat_account` varchar(50) DEFAULT NULL COMMENT '????',
  `merchant_trade_record_id` int DEFAULT NULL COMMENT '??????id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_message` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `user_id` int DEFAULT NULL COMMENT '??id',
  `user_type` int NOT NULL COMMENT '?????? 1=?? 2=?? 3=???',
  `title` varchar(255) DEFAULT NULL COMMENT '??',
  `content` text COMMENT '??',
  `is_read` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3690 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_order` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `order_no` varchar(50) NOT NULL COMMENT '??????????',
  `goods_total_quantity` int DEFAULT '0' COMMENT '?????',
  `goods_total_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `packing_charges` decimal(10,2) DEFAULT NULL COMMENT '???',
  `delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '??/???',
  `actual_price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `shopping_way` int NOT NULL COMMENT '???? 1=?? 2=??',
  `delivery_address_id` int DEFAULT NULL COMMENT '????id',
  `contact_realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '?????',
  `contact_phone` varchar(11) DEFAULT NULL COMMENT '????',
  `contact_province` varchar(20) DEFAULT NULL COMMENT '??',
  `contact_city` varchar(20) DEFAULT NULL COMMENT '??',
  `contact_area` varchar(100) DEFAULT NULL COMMENT '?/?',
  `contact_street` varchar(100) DEFAULT NULL COMMENT '????(????????)',
  `contact_sex` int DEFAULT '0' COMMENT '????? 0=? 1=?? 2=??',
  `remark` varchar(1024) DEFAULT NULL COMMENT '??',
  `description` varchar(2048) DEFAULT NULL COMMENT '????',
  `status` int DEFAULT '1' COMMENT '???? 1=??? 2=??? 3=???(???) 4=???(???) 5=??? 6=??? 7=????? 8=???(????) 9=?????? 10=???(???) 11=???(???)',
  `trade_id` int DEFAULT NULL COMMENT '????id',
  `order_logistics_id` int DEFAULT NULL COMMENT '??id',
  `is_invoice` tinyint(1) DEFAULT '0' COMMENT '????',
  `invoice_id` int DEFAULT NULL COMMENT '??id',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `shop_id` int NOT NULL COMMENT '????id',
  `shop_name` varchar(100) NOT NULL COMMENT '??????',
  `shop_address` varchar(200) DEFAULT NULL COMMENT '????',
  `cancel_reason` int DEFAULT NULL COMMENT '(???)?????? 1=????? 2=??????? 3=????',
  `payment_deadline` datetime DEFAULT NULL COMMENT '??????(????????????????)',
  `is_printed` tinyint(1) DEFAULT '0' COMMENT '?????',
  `queue_no` int DEFAULT NULL COMMENT '???',
  `full_reduction_rule_id` int DEFAULT NULL COMMENT '?????id',
  `full_reduction_rule_description` varchar(100) DEFAULT NULL COMMENT '?????????',
  `coupons_id` int DEFAULT NULL COMMENT '??????id',
  `coupons_description` varchar(100) DEFAULT NULL COMMENT '????????',
  `coupons_member_relation_id` int DEFAULT NULL COMMENT '???????id',
  `is_change_to_delivery` tinyint(1) DEFAULT '0' COMMENT '??????????? 0=? 1=?',
  `change_to_delivery_out_trade_no` varchar(50) DEFAULT NULL COMMENT '?????????????',
  `change_to_delivery_trade_id` int DEFAULT NULL COMMENT '?????????????id',
  `platform_extract_ratio` decimal(10,2) DEFAULT '0.00' COMMENT '??????(%)',
  `platform_extract_price` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `platform_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `platform_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `merchant_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `courier_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `merchant_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `payment_success_time` datetime DEFAULT NULL COMMENT '??????',
  `order_completion_time` datetime DEFAULT NULL COMMENT '??????',
  `paid_order_cancel_reason` int DEFAULT NULL COMMENT '(????)(???)?????? 1=?????? 2=??????? 3=???/??? 4=???? 5=??????? 6=???? 7=??????? 8=?????',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????/???????',
  `delivery_way` int DEFAULT NULL COMMENT '???? 1=?????',
  `is_pay_to_merchant` tinyint(1) DEFAULT '0' COMMENT '??????????????? 0=? 1=?',
  `before_reduced_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????????/???',
  `payment_mode` int DEFAULT NULL COMMENT '???? 1=???? 2=????',
  `contact_house_number` varchar(100) DEFAULT NULL COMMENT '???',
  `contact_longitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `contact_latitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `shop_logo_img` varchar(128) DEFAULT NULL COMMENT '????logo',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `checkout_mode` int DEFAULT '1' COMMENT '1=pay first, 2=eat first',
  `table_no` varchar(50) DEFAULT NULL COMMENT 'Table number snapshot',
  `table_name` varchar(50) DEFAULT NULL COMMENT 'Table name snapshot',
  `dining_table_id` bigint DEFAULT NULL COMMENT 'Dining table id',
  `is_payment` tinyint(1) DEFAULT '0' COMMENT 'Payment completed',
  PRIMARY KEY (`id`),
  KEY `idx_order_shop_status_time` (`shop_id`,`status`,`create_time`),
  KEY `idx_order_member_shop_time` (`member_id`,`shop_id`,`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=3556 DEFAULT CHARSET=utf8mb3 COMMENT='???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_order_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_order_detail` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_id` int NOT NULL COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) NOT NULL COMMENT '????',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `number` int DEFAULT '0' COMMENT '????',
  `subtotal` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '????????',
  `is_used_coupons` tinyint(1) DEFAULT '0' COMMENT '??????????? 0=? 1=?',
  `coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????/???????',
  `after_coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '????????????',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4531 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_order_refund`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_order_refund` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_id` int NOT NULL COMMENT '??id',
  `type` int DEFAULT '1' COMMENT '???? 1=?????1?????? 2=?????24???????',
  `refund_way` int DEFAULT '1' COMMENT '???? 1=???? 2=????',
  `refund_reason` int DEFAULT NULL COMMENT '???? 1=?????? 2=??????? 3=???/??? 4=???? 5=??????? 6=???? 7=??????? 8=????? 9=???????? 10=??????? 11=??????? 12=????????? 13=????/???? 14=?????? 15=?????? 16=????/?????? 17=?????? 18=????????? 19=????/??? 20=??',
  `refund_reason_description` varchar(1024) DEFAULT NULL COMMENT '????????',
  `evidence_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `refund_amount` decimal(10,2) DEFAULT '0.00' COMMENT '????',
  `refund_account` int DEFAULT NULL COMMENT '???? 1=?? 2=??? 3=????',
  `status` int DEFAULT '1' COMMENT '???? 1=??????? 2=?????? 3=?????? 4=?????? 5=???????????? 6=????? 7=????',
  `goods_total_quantity` int DEFAULT '0' COMMENT '???????',
  `goods_total_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `is_refund_delivery_fee` tinyint(1) DEFAULT '0' COMMENT '???????? 0=? 1=?',
  `delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '????/???',
  `is_used_coupons` tinyint(1) DEFAULT '0' COMMENT '????????????? 0=? 1=?',
  `is_used_full_reduction_rule` tinyint(1) DEFAULT '0' COMMENT '?????????????? 0=? 1=?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb3 COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_order_refund_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_order_refund_goods` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_refund_id` int NOT NULL COMMENT '????id',
  `order_detail_id` int NOT NULL COMMENT '??????id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) NOT NULL COMMENT '????',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `number` int DEFAULT '0' COMMENT '????',
  `subtotal` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb3 COMMENT='????-?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_order_refund_process`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_order_refund_process` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_refund_id` int NOT NULL COMMENT '????id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `description` varchar(200) DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=81 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_paperwork_push`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_paperwork_push` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `content` text COMMENT '????',
  `pushed_number` int DEFAULT '0' COMMENT '?????',
  `last_pushed_time` datetime DEFAULT NULL COMMENT '??????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_picture_upload_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_picture_upload_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `url` varchar(128) DEFAULT NULL COMMENT '????(????)',
  `module` int DEFAULT NULL COMMENT '???? 1=????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=84 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_coupons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_coupons` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(100) DEFAULT NULL COMMENT '?????',
  `preferential_type` int DEFAULT NULL COMMENT '?????1=???2=??',
  `discount_amount` decimal(10,2) DEFAULT '1.00' COMMENT '????',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????????????????',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `description` varchar(500) DEFAULT NULL COMMENT '??????',
  `valid_type` int NOT NULL DEFAULT '2' COMMENT '??:1????????XXX-XXX??????? 2????????N????',
  `valid_start_time` datetime DEFAULT NULL COMMENT '??????',
  `valid_end_time` datetime DEFAULT NULL COMMENT '??????',
  `valid_days` int NOT NULL DEFAULT '0' COMMENT '??????????',
  `is_delete` tinyint(1) DEFAULT '0' COMMENT '??????0-??1-?',
  `source` int DEFAULT NULL COMMENT '??????? 1=???? 2=????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_coupons_goods_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_coupons_goods_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `coupons_id` int DEFAULT NULL COMMENT '???id',
  `goods_id` int DEFAULT NULL COMMENT '??id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_coupons_member_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_coupons_member_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `coupons_id` int DEFAULT NULL COMMENT '???id',
  `coupons_name` varchar(100) DEFAULT NULL COMMENT '?????',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `start_time` datetime DEFAULT NULL COMMENT '????',
  `end_time` datetime DEFAULT NULL COMMENT '????',
  `is_used` tinyint(1) DEFAULT '0' COMMENT '???????0=????1=???',
  `is_expired` tinyint(1) DEFAULT '0' COMMENT '?????0=????1=???',
  `is_valid` tinyint(1) DEFAULT '1' COMMENT '?????0-??1-?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1318 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_full_reduction_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_full_reduction_rule` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(100) DEFAULT NULL COMMENT '????',
  `status` int DEFAULT NULL COMMENT '?????1=???2=??',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????????????????',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_goods` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) DEFAULT NULL COMMENT '????',
  `sub_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `detail` varchar(1024) DEFAULT NULL COMMENT '????',
  `detail_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `stock` int DEFAULT '0' COMMENT '??',
  `is_hot` tinyint(1) DEFAULT '0' COMMENT '????',
  `is_new` tinyint(1) DEFAULT '0' COMMENT '????',
  `status` int DEFAULT '1' COMMENT '?? 1=??? 2=??? 3=??? 4=??',
  `is_sale` tinyint unsigned DEFAULT '0' COMMENT '?????? 0-? 1-?',
  `sale_price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `monthly_sales` int DEFAULT '0' COMMENT '???',
  `total_sales` int DEFAULT '0' COMMENT '????',
  `total_comments` int DEFAULT '0' COMMENT '????',
  `preferential_name` varchar(20) DEFAULT NULL COMMENT '????',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `product_time` decimal(10,2) DEFAULT '0.00' COMMENT '????(??)',
  `exchange_points` int DEFAULT NULL COMMENT '??????????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_goods_specification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_goods_specification` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `name` varchar(10) NOT NULL COMMENT '??????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_goods_specification_option`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_goods_specification_option` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_specification_id` int NOT NULL COMMENT '????id',
  `name` varchar(10) NOT NULL COMMENT '????????',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??/????',
  `stock` int DEFAULT '1' COMMENT '?? 1=?? 2=??',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_member_goods_collect`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_member_goods_collect` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `goods_id` int DEFAULT NULL COMMENT '??id',
  `is_goods_exists` tinyint(1) DEFAULT '1' COMMENT '?????? 0=?? 1=??',
  `is_buy` tinyint(1) DEFAULT '0' COMMENT '?????? 0=??? 1=???',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_menu` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '??????',
  `description` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL COMMENT '??????',
  `sort_number` int DEFAULT NULL COMMENT '???',
  `icon` varchar(128) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_menu_goods_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_menu_goods_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `menu_id` int NOT NULL COMMENT '????id',
  `goods_id` int NOT NULL COMMENT '??id',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `order_no` varchar(50) NOT NULL COMMENT '??????????',
  `goods_total_quantity` int DEFAULT '0' COMMENT '?????',
  `goods_total_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `packing_charges` decimal(10,2) DEFAULT NULL COMMENT '???',
  `delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '??/???',
  `actual_price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `shopping_way` int DEFAULT NULL COMMENT '???? 1=?? 2=??',
  `delivery_address_id` int DEFAULT NULL COMMENT '????id',
  `contact_realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '?????',
  `contact_phone` varchar(11) DEFAULT NULL COMMENT '????',
  `contact_province` varchar(20) DEFAULT NULL COMMENT '??',
  `contact_city` varchar(20) DEFAULT NULL COMMENT '??',
  `contact_area` varchar(100) DEFAULT NULL COMMENT '?/?',
  `contact_street` varchar(100) DEFAULT NULL COMMENT '????(????????)',
  `contact_sex` int DEFAULT '0' COMMENT '????? 0=? 1=?? 2=??',
  `remark` varchar(1024) DEFAULT NULL COMMENT '??',
  `description` varchar(2048) DEFAULT NULL COMMENT '????',
  `status` int DEFAULT '1' COMMENT '???? 1=??? 4=???(???) 5=??? 6=??? 7=????? 8=???(????) 9=?????? 10=???(???)',
  `trade_id` int DEFAULT NULL COMMENT '????id',
  `order_logistics_id` int DEFAULT NULL COMMENT '??id',
  `is_invoice` tinyint(1) DEFAULT '0' COMMENT '????',
  `invoice_id` int DEFAULT NULL COMMENT '??id',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  `shop_id` int DEFAULT NULL COMMENT '????id',
  `shop_name` varchar(100) DEFAULT NULL COMMENT '??????',
  `shop_address` varchar(200) DEFAULT NULL COMMENT '????',
  `cancel_reason` int DEFAULT NULL COMMENT '(???)?????? 1=????? 2=??????? 3=????',
  `payment_deadline` datetime DEFAULT NULL COMMENT '??????(????????????????)',
  `is_printed` tinyint(1) DEFAULT '0' COMMENT '?????',
  `queue_no` int DEFAULT NULL COMMENT '???',
  `full_reduction_rule_id` int DEFAULT NULL COMMENT '?????id',
  `full_reduction_rule_description` varchar(100) DEFAULT NULL COMMENT '?????????',
  `coupons_id` int DEFAULT NULL COMMENT '??????id',
  `coupons_description` varchar(100) DEFAULT NULL COMMENT '????????',
  `coupons_member_relation_id` int DEFAULT NULL COMMENT '???????id',
  `is_change_to_delivery` tinyint(1) DEFAULT '0' COMMENT '??????????? 0=? 1=?',
  `change_to_delivery_out_trade_no` varchar(50) DEFAULT NULL COMMENT '?????????????',
  `change_to_delivery_trade_id` int DEFAULT NULL COMMENT '?????????????id',
  `platform_extract_ratio` decimal(10,2) DEFAULT '0.00' COMMENT '??????(%)',
  `platform_extract_price` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `platform_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `platform_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `merchant_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `courier_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `merchant_income` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `payment_success_time` datetime DEFAULT NULL COMMENT '??????',
  `order_completion_time` datetime DEFAULT NULL COMMENT '??????',
  `paid_order_cancel_reason` int DEFAULT NULL COMMENT '(????)(???)?????? 1=?????? 2=??????? 3=???/??? 4=???? 5=??????? 6=???? 7=??????? 8=?????',
  `limited_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `reduced_price` decimal(10,2) DEFAULT '0.00' COMMENT '????(?)',
  `coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????/???????',
  `delivery_way` int DEFAULT NULL COMMENT '???? 1=?????',
  `is_pay_to_merchant` tinyint(1) DEFAULT '0' COMMENT '??????????????? 0=? 1=?',
  `before_reduced_delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '???????????/???',
  `payment_mode` int DEFAULT NULL COMMENT '???? 1=???? (2=????) 3=????',
  `logistics_way` varchar(50) DEFAULT NULL COMMENT '????/??????',
  `logistics_no` varchar(50) DEFAULT NULL COMMENT '????/????',
  `courier_name` varchar(50) DEFAULT NULL COMMENT '???/?????',
  `courier_phone` varchar(11) DEFAULT NULL COMMENT '?????',
  `delivery_status` int DEFAULT NULL COMMENT '???? 0=????(??) 1=??? 2=???? 3=??? 4=???? 5=??? 6=????',
  `is_sign` tinyint(1) DEFAULT NULL COMMENT '????',
  `delivery_last_update_time` datetime DEFAULT NULL COMMENT '??????????',
  `take_time` varchar(50) DEFAULT NULL COMMENT '????????? (??????)',
  `contact_house_number` varchar(100) DEFAULT NULL COMMENT '???',
  `contact_longitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `contact_latitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `first_goods_main_image` varchar(128) DEFAULT NULL COMMENT '????????',
  `goods_source` int DEFAULT NULL COMMENT '??? 1=??? 2=?? 3=??',
  `goods_source_order_no` varchar(50) DEFAULT NULL COMMENT '???????',
  `platform_remark` varchar(1024) DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order_detail` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_id` bigint NOT NULL COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) NOT NULL COMMENT '????',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `number` int DEFAULT '0' COMMENT '????',
  `subtotal` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '????????',
  `is_used_coupons` tinyint(1) DEFAULT '0' COMMENT '??????????? 0=? 1=?',
  `coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????/???????',
  `after_coupons_discount_price` decimal(10,2) DEFAULT '0.00' COMMENT '????????????',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???? 0=?? 1=??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=227 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order_logistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order_logistics` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_id` bigint NOT NULL COMMENT '??id',
  `description` varchar(200) DEFAULT NULL COMMENT '??????',
  `description_time` datetime DEFAULT NULL COMMENT '???????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order_refund`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order_refund` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_id` bigint NOT NULL COMMENT '??id',
  `type` int DEFAULT '1' COMMENT '???? 1=????????? 2=?????????-??? 3=?????????-????',
  `refund_way` int DEFAULT '1' COMMENT '???? 1=???? 2=????',
  `refund_reason` int DEFAULT NULL COMMENT '???? 1=?????????/??/???? 2=????? 3=??/???????? 4=??/???? 5=?? 31=?? 32=?????? 33=???????? 34=??/??/??? 35=?? 61=????/??? 62=???? 63=???? 64=???? 65=??/????????? 66=???? 67=????? 68=????/?? 69=???? 70=??',
  `refund_reason_description` varchar(1024) DEFAULT NULL COMMENT '????????',
  `evidence_images` varchar(1024) DEFAULT NULL COMMENT '????',
  `refund_amount` decimal(10,2) DEFAULT '0.00' COMMENT '????',
  `refund_account` int DEFAULT NULL COMMENT '???? 1=?? 2=??? 3=???? 4=????',
  `status` int DEFAULT '1' COMMENT '???? 1=??????? 4=?????? 5=???????????? 7=????',
  `goods_total_quantity` int DEFAULT '0' COMMENT '???????',
  `goods_total_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `packing_charges` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `is_refund_delivery_fee` tinyint(1) DEFAULT '0' COMMENT '???????? 0=? 1=?',
  `delivery_fee` decimal(10,2) DEFAULT '0.00' COMMENT '????/???',
  `is_used_coupons` tinyint(1) DEFAULT '0' COMMENT '????????????? 0=? 1=?',
  `is_used_full_reduction_rule` tinyint(1) DEFAULT '0' COMMENT '?????????????? 0=? 1=?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order_refund_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order_refund_goods` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_refund_id` int NOT NULL COMMENT '????id',
  `order_detail_id` int NOT NULL COMMENT '??????id',
  `goods_id` int NOT NULL COMMENT '??id',
  `goods_name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) NOT NULL COMMENT '????',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `number` int DEFAULT '0' COMMENT '????',
  `subtotal` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_order_refund_process`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_order_refund_process` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `order_refund_id` int NOT NULL COMMENT '????id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `description` varchar(200) DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_points_mall_shopping_cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_points_mall_shopping_cart` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `number` int DEFAULT '1' COMMENT '????',
  `is_goods_exists` tinyint(1) DEFAULT '1' COMMENT '?????? 0=?? 1=??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_printer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_printer` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `name` varchar(50) DEFAULT NULL COMMENT '?????',
  `number` varchar(50) DEFAULT NULL COMMENT '?????',
  `identifying_code` varchar(50) DEFAULT NULL COMMENT '?????/???',
  `is_auto_print` tinyint(1) NOT NULL DEFAULT '0' COMMENT '???????????/?? 0=? 1=?',
  `mobile_card_number` varchar(50) DEFAULT NULL COMMENT '(????)????',
  `cloud_registration_status` varchar(50) DEFAULT NULL COMMENT '(????)??????',
  `type` int DEFAULT NULL COMMENT '????? 1=????? 2=?????',
  `brand` int DEFAULT NULL COMMENT '????? 1=????? 2=??????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_rawmaterial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_rawmaterial` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `main_image` varchar(128) DEFAULT NULL COMMENT '????',
  `description` varchar(512) DEFAULT NULL COMMENT '????',
  `unit` varchar(50) NOT NULL COMMENT '????',
  `price` decimal(20,10) DEFAULT '0.0000000000' COMMENT '????',
  `stock` decimal(20,10) DEFAULT '0.0000000000' COMMENT '??',
  `stock_lower_limit` decimal(20,10) DEFAULT '0.0000000000' COMMENT '?????/????',
  `stock_upper_limit` decimal(20,10) DEFAULT '0.0000000000' COMMENT '?????/????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb3 COMMENT='???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_reply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_reply` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `merchant_id` int DEFAULT NULL COMMENT '??id',
  `appraise_id` int DEFAULT NULL COMMENT '??id??????id?',
  `reply_id` int DEFAULT NULL COMMENT '??id??????id?',
  `reply_type` int NOT NULL DEFAULT '1' COMMENT '???? 1-?????2-????????',
  `replier_type` int NOT NULL DEFAULT '1' COMMENT '????? 1-?????2-????',
  `content` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL COMMENT '????',
  `images_url` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL COMMENT '?url??????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_scheduled_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_scheduled_task` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(50) NOT NULL COMMENT '????',
  `code` varchar(256) NOT NULL COMMENT '????',
  `frequency` varchar(50) NOT NULL COMMENT '????',
  `state` int DEFAULT '1' COMMENT '???? 1=??? 2=????',
  `last_start_time` datetime DEFAULT NULL COMMENT '????????',
  `last_end_time` datetime DEFAULT NULL COMMENT '????????',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_scheduled_task_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_scheduled_task_log` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `scheduled_task_code` varchar(256) NOT NULL COMMENT '????',
  `state` int NOT NULL DEFAULT '1' COMMENT '???? 1=???? 2=????',
  `error` varchar(1024) DEFAULT NULL COMMENT '????',
  `host_name` varchar(50) NOT NULL COMMENT '??????',
  `host_ip_address` varchar(50) NOT NULL COMMENT '????ip??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1722 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='?????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_setting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_setting` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `purchase_reward_points` decimal(10,2) DEFAULT '0.00' COMMENT '????????????',
  `registration_reward_points` decimal(10,2) DEFAULT '0.00' COMMENT '???????????',
  `new_member_coupons_id` int DEFAULT NULL COMMENT '(????)?????id',
  `default_shop_id` int DEFAULT NULL COMMENT '(????)????id',
  `merchant_withdraw_fee` decimal(10,2) NOT NULL COMMENT '???????(%)',
  `start_delivery_price` decimal(10,2) DEFAULT '0.00' COMMENT '????????',
  `delivery_starting_distance` decimal(10,2) DEFAULT '0.00' COMMENT '??????(KM)',
  `delivery_starting_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????',
  `delivery_kilometer_price` decimal(10,2) DEFAULT '0.00' COMMENT '?????(?/KM)',
  `delivery_distance_limit` decimal(10,2) DEFAULT '0.00' COMMENT '??????(KM)',
  `order_system_extraction_ratio` decimal(10,2) DEFAULT NULL COMMENT '??????????(%)',
  `merchant_meal_preparation_time` decimal(10,2) DEFAULT NULL COMMENT '??????(??)',
  `member_withdraw_fee` decimal(10,2) NOT NULL COMMENT '???????(%)',
  `registration_reward_invite_reward_amount` decimal(10,2) NOT NULL COMMENT '???????-???????????',
  `member_withdraw_meet_amount` decimal(10,2) NOT NULL COMMENT '??????(?)XX?????/??????????????????????',
  `member_withdraw_audit_threshold` decimal(10,2) NOT NULL COMMENT '????????(?)XX???????/???????????/???????????????????????(??????)',
  `customer_service_phone` varchar(11) DEFAULT NULL COMMENT '????',
  `customer_service_wechat` varchar(50) DEFAULT NULL COMMENT '????',
  `customer_service_wechat_qrcode` varchar(1024) DEFAULT NULL COMMENT '???????',
  `freight_insurance_paid_amount` decimal(10,2) DEFAULT NULL COMMENT '(????)???????',
  `invitee_consume_commission` decimal(10,2) NOT NULL COMMENT '???????????????????????????(%)--?????????????????????',
  `caseone_own_commission` decimal(10,2) NOT NULL COMMENT '????????????????(%)',
  `casetwo_own_commission` decimal(10,2) NOT NULL COMMENT '?1????????????????(%)',
  `casetwo_first_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '?1?????????????????(%)',
  `casethree_own_commission` decimal(10,2) NOT NULL COMMENT '?2???????????????(%)',
  `casethree_first_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '?2????????????????(%)',
  `casethree_second_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '?2????????????????(%)',
  `points_mall_invitee_consume_commission` decimal(10,2) NOT NULL COMMENT '????--???????????????????????????(%)--?????????????????????',
  `points_mall_caseone_own_commission` decimal(10,2) NOT NULL COMMENT '????--????????????????(%)',
  `points_mall_casetwo_own_commission` decimal(10,2) NOT NULL COMMENT '????--?1????????????????(%)',
  `points_mall_casetwo_first_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '????--?1?????????????????(%)',
  `points_mall_casethree_own_commission` decimal(10,2) NOT NULL COMMENT '????--?2???????????????(%)',
  `points_mall_casethree_first_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '????--?2????????????????(%)',
  `points_mall_casethree_second_level_inviter_commission` decimal(10,2) NOT NULL COMMENT '????--?2????????????????(%)',
  `invite_friends_activity_rule` text COMMENT '??????-????',
  `commission_rule` text COMMENT '??????',
  `vip_rule` text COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_shop`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_shop` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `merchant_id` int NOT NULL COMMENT '??id',
  `name` varchar(100) DEFAULT NULL COMMENT '????',
  `code` varchar(50) DEFAULT NULL COMMENT '????',
  `province` varchar(20) DEFAULT NULL COMMENT '??',
  `city` varchar(20) DEFAULT NULL COMMENT '??',
  `area` varchar(100) DEFAULT NULL COMMENT '?/?',
  `street` varchar(50) DEFAULT NULL COMMENT '????',
  `is_operating` tinyint(1) DEFAULT '1' COMMENT '??????',
  `start_time` varchar(50) DEFAULT NULL COMMENT '????????',
  `end_time` varchar(50) DEFAULT NULL COMMENT '????????',
  `manage_primary` varchar(50) DEFAULT NULL COMMENT '??????',
  `manage_minor` varchar(50) DEFAULT NULL COMMENT '??????',
  `shop_img` varchar(128) DEFAULT NULL COMMENT '????',
  `shop_within_img` varchar(1024) DEFAULT NULL COMMENT '????',
  `shop_logo_img` varchar(128) DEFAULT NULL COMMENT '??LOGO',
  `certificate_type1` varchar(50) DEFAULT NULL COMMENT '????1?1=?????2=????????3=????????????4=???????????5=???????',
  `certificate_img1` varchar(128) DEFAULT NULL COMMENT '????1',
  `certificate_type2` varchar(50) DEFAULT NULL COMMENT '????2(1=????????2=????????3=???????4=???????)',
  `certificate_img2` varchar(128) DEFAULT NULL COMMENT '????2',
  `special_type` varchar(50) DEFAULT NULL COMMENT '?????????1=???????2=????????',
  `special_img` varchar(128) DEFAULT NULL COMMENT '????????',
  `audit_status` int DEFAULT '1' COMMENT '?????1=????2=?????3=?????',
  `audit_reason` varchar(50) DEFAULT NULL COMMENT '??????',
  `audit_time` datetime DEFAULT NULL COMMENT '????',
  `take_out_phone` varchar(20) DEFAULT NULL COMMENT '(????)????',
  `contact_realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '?????',
  `contact_phone` varchar(11) DEFAULT NULL COMMENT '????',
  `announcement` varchar(100) DEFAULT NULL COMMENT '????',
  `brief_introduction` text COMMENT '????',
  `start_delivery_price` decimal(10,2) DEFAULT '0.00' COMMENT '(????)????',
  `delivery_starting_price` decimal(10,2) DEFAULT '0.00' COMMENT '(????)?????(0~1KM)',
  `delivery_kilometer_price` decimal(10,2) DEFAULT '0.00' COMMENT '(????)?????(?/KM)',
  `delivery_distance_limit` decimal(10,2) DEFAULT '0.00' COMMENT '(????)??????',
  `service_rating` decimal(10,1) DEFAULT '0.0' COMMENT '????',
  `business_license` varchar(50) DEFAULT NULL COMMENT '????',
  `id_card_front_side` varchar(50) DEFAULT NULL COMMENT '?????',
  `id_card_back_side` varchar(50) DEFAULT NULL COMMENT '?????',
  `status` int DEFAULT '1' COMMENT '?? 1=??? 2=??? 3=???',
  `reduced_delivery_price` decimal(10,2) DEFAULT '0.00' COMMENT '???????',
  `is_open_order_audio` tinyint(1) DEFAULT '1' COMMENT '??????????',
  `is_open_local_print` tinyint(1) DEFAULT '1' COMMENT '??????????',
  `is_open_cloud_print` tinyint(1) DEFAULT '1' COMMENT '???????',
  `first_poster` varchar(128) DEFAULT NULL COMMENT '??????????',
  `house_number` varchar(100) DEFAULT NULL COMMENT '???',
  `longitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `latitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `checkout_mode` int DEFAULT '1' COMMENT '1=pay first, 2=eat first',
  `kitchen_total_order_printer_id` int DEFAULT NULL COMMENT 'Kitchen total-order printer id',
  `checkout_printer_id` int DEFAULT NULL COMMENT 'Checkout printer id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb3 COMMENT='???';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_shop_change_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_shop_change_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '????id',
  `name` varchar(100) DEFAULT NULL COMMENT '????',
  `province` varchar(20) DEFAULT NULL COMMENT '??',
  `city` varchar(20) DEFAULT NULL COMMENT '??',
  `area` varchar(100) DEFAULT NULL COMMENT '?/?',
  `street` varchar(50) DEFAULT NULL COMMENT '????(????????)',
  `manage_primary` varchar(50) DEFAULT NULL COMMENT '??????',
  `manage_minor` varchar(50) DEFAULT NULL COMMENT '??????',
  `shop_img` varchar(50) DEFAULT NULL COMMENT '????',
  `shop_within_img` varchar(1024) DEFAULT NULL COMMENT '????',
  `shop_logo_img` varchar(50) DEFAULT NULL COMMENT '??LOGO',
  `certificate_type1` varchar(50) DEFAULT NULL COMMENT '????1?1=?????2=????????3=????????????4=???????????5=???????',
  `certificate_img1` varchar(50) DEFAULT NULL COMMENT '????1',
  `certificate_type2` varchar(50) DEFAULT NULL COMMENT '????2(1=????????2=????????3=???????4=???????)',
  `certificate_img2` varchar(50) DEFAULT NULL COMMENT '????2',
  `special_type` varchar(50) DEFAULT NULL COMMENT '?????????1=???????2=????????',
  `special_img` varchar(50) DEFAULT NULL COMMENT '????????',
  `take_out_phone` varchar(20) DEFAULT NULL COMMENT '(????)????',
  `contact_realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '?????',
  `contact_phone` varchar(11) DEFAULT NULL COMMENT '????',
  `announcement` varchar(100) DEFAULT NULL COMMENT '????',
  `brief_introduction` text COMMENT '????',
  `business_license` varchar(50) DEFAULT NULL COMMENT '????',
  `id_card_front_side` varchar(50) DEFAULT NULL COMMENT '?????',
  `id_card_back_side` varchar(50) DEFAULT NULL COMMENT '?????',
  `house_number` varchar(100) DEFAULT NULL COMMENT '???',
  `longitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `latitude` decimal(18,6) DEFAULT NULL COMMENT '??',
  `apply_change_content` varchar(500) DEFAULT NULL COMMENT '??????/???????????',
  `audit_status` int DEFAULT '1' COMMENT '?????1=????2=?????3=?????',
  `audit_reason` varchar(50) DEFAULT NULL COMMENT '??????',
  `audit_time` datetime DEFAULT NULL COMMENT '????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb3 COMMENT='???????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_shopping_cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_shopping_cart` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int NOT NULL COMMENT '??id',
  `goods_id` int NOT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `spec_list` varchar(1024) DEFAULT NULL COMMENT '???? JSON??',
  `number` int DEFAULT '1' COMMENT '????',
  `is_goods_exists` tinyint(1) DEFAULT '1' COMMENT '?????? 0=?? 1=??',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  `dining_table_id` bigint DEFAULT NULL COMMENT 'Dining table id',
  PRIMARY KEY (`id`),
  KEY `idx_cart_member_shop_table` (`member_id`,`shop_id`,`dining_table_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3780 DEFAULT CHARSET=utf8mb3 COMMENT='????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_sms_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_sms_log` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `mobile` varchar(11) NOT NULL COMMENT '???',
  `type` varchar(20) DEFAULT NULL COMMENT '???? ??=register ??=login ?????=verification ????=findpwd ????=extractRemind',
  `verify_code` varchar(10) DEFAULT NULL COMMENT '?????',
  `ip` varchar(15) NOT NULL COMMENT '??ip',
  `state` int NOT NULL DEFAULT '1' COMMENT '???? 1=???? 2=????',
  `description` varchar(50) DEFAULT NULL COMMENT 'API??????',
  `create_time` datetime NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb3 COMMENT='????????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_system_usage_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_system_usage_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `shop_id` int DEFAULT NULL COMMENT '??id',
  `type` varchar(20) DEFAULT NULL COMMENT '?? intoShop=???? intoPointsMall=??????',
  `ip` varchar(15) DEFAULT NULL COMMENT '??ip',
  `imei` varchar(100) DEFAULT NULL COMMENT '????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2379 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_vip_recharge_denomination`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_vip_recharge_denomination` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `name` varchar(50) DEFAULT NULL COMMENT '??????(????)',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `is_sale` tinyint unsigned DEFAULT '0' COMMENT '?????? 0=? 1=?(????)',
  `sale_price` decimal(10,2) DEFAULT '0.00' COMMENT '???(????)',
  `brief_description` varchar(50) DEFAULT NULL COMMENT '??????/??????(????)',
  `description` varchar(500) DEFAULT NULL COMMENT '??????/????????????',
  `is_give_balance` tinyint unsigned DEFAULT '0' COMMENT '????????? 0=? 1=?',
  `give_balance` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `is_give_coupons` tinyint unsigned DEFAULT '0' COMMENT '?????????? 0=? 1=?',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_vip_recharge_denomination_coupons_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_vip_recharge_denomination_coupons_relation` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `vip_recharge_denomination_id` int DEFAULT NULL COMMENT '??????id',
  `coupons_id` int DEFAULT NULL COMMENT '?????id',
  `give_quantity` int DEFAULT '1' COMMENT '???????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_vip_recharge_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_vip_recharge_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `member_id` int DEFAULT NULL COMMENT '??id',
  `order_no` varchar(50) DEFAULT NULL COMMENT '??????????',
  `channel` int DEFAULT NULL COMMENT '???? 1=??? 2=??? 3=????',
  `denomination_id` int DEFAULT NULL COMMENT '??????id',
  `amount` decimal(10,2) DEFAULT NULL COMMENT '????',
  `denomination_name` varchar(50) DEFAULT NULL COMMENT '??????',
  `denomination_price` decimal(10,2) DEFAULT '0.00' COMMENT '??',
  `denomination_is_sale` tinyint unsigned DEFAULT '0' COMMENT '?????? 0=? 1=?',
  `denomination_sale_price` decimal(10,2) DEFAULT '0.00' COMMENT '???',
  `denomination_is_give_balance` tinyint unsigned DEFAULT '0' COMMENT '????????? 0=? 1=?',
  `denomination_give_balance` decimal(10,2) DEFAULT '0.00' COMMENT '??????',
  `denomination_is_give_coupons` tinyint unsigned DEFAULT '0' COMMENT '?????????? 0=? 1=?',
  `denomination_give_coupons_description` varchar(500) DEFAULT NULL COMMENT '????????',
  `denomination_give_coupons_json` varchar(1024) DEFAULT NULL COMMENT '??????(JSON??)',
  `trade_id` int DEFAULT NULL COMMENT '????id',
  `status` int DEFAULT '1' COMMENT '???? 1=??? 2=???? 3=???? 4=????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb3 COMMENT='???????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tb_wx_public_platform_subscribe_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_wx_public_platform_subscribe_user` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '??id',
  `subscribe` varchar(100) DEFAULT NULL COMMENT '????/??',
  `openid` varchar(100) DEFAULT NULL COMMENT 'openid',
  `nickname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '??',
  `sex` varchar(100) DEFAULT NULL COMMENT '??',
  `language` varchar(100) DEFAULT NULL COMMENT '??',
  `city` varchar(100) DEFAULT NULL COMMENT '??',
  `province` varchar(100) DEFAULT NULL COMMENT '??',
  `country` varchar(100) DEFAULT NULL COMMENT '??',
  `headimgurl` varchar(300) DEFAULT NULL COMMENT '??',
  `subscribe_time` varchar(100) DEFAULT NULL COMMENT '????/????',
  `remark` varchar(100) DEFAULT NULL COMMENT '??',
  `groupid` varchar(100) DEFAULT NULL COMMENT '?id',
  `tagid_list` varchar(100) DEFAULT NULL COMMENT '????',
  `subscribe_scene` varchar(100) DEFAULT NULL COMMENT '??/?????',
  `qr_scene` varchar(100) DEFAULT NULL COMMENT '?????',
  `qr_scene_str` varchar(100) DEFAULT NULL COMMENT '????????',
  `create_time` datetime DEFAULT NULL COMMENT '????',
  `update_time` datetime DEFAULT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=543 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `transaction_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_log` (
  `id` varchar(32) NOT NULL COMMENT '??ID',
  `business` varchar(32) NOT NULL COMMENT '????',
  `foreign_key` varchar(32) NOT NULL COMMENT '?????????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='?????';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `undo_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `undo_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `branch_id` bigint NOT NULL,
  `xid` varchar(100) NOT NULL,
  `context` varchar(128) NOT NULL,
  `rollback_info` longblob NOT NULL,
  `log_status` int NOT NULL,
  `log_created` datetime NOT NULL,
  `log_modified` datetime NOT NULL,
  `ext` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_undo_log` (`xid`,`branch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
