-- Phase 1: dine-in ordering migration.
-- Safe to execute repeatedly. Existing tables and rows are preserved.

CREATE TABLE IF NOT EXISTS `tb_dining_table` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `shop_id` int(11) NOT NULL COMMENT 'Shop id',
  `table_no` varchar(50) NOT NULL COMMENT 'Table number',
  `table_name` varchar(50) NOT NULL COMMENT 'Table display name',
  `scene_token` varchar(64) NOT NULL COMMENT 'Opaque scan token',
  `qr_code_url` varchar(500) DEFAULT NULL COMMENT 'Generated mini program code URL',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1=enabled, 0=disabled',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dining_table_shop_no` (`shop_id`, `table_no`),
  UNIQUE KEY `uk_dining_table_scene_token` (`scene_token`),
  KEY `idx_dining_table_shop_status` (`shop_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Dining tables';

DROP PROCEDURE IF EXISTS `phase1_add_column`;
DELIMITER $$
CREATE PROCEDURE `phase1_add_column`(
  IN table_name_value varchar(64),
  IN column_name_value varchar(64),
  IN column_definition_value varchar(1000)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = table_name_value
       AND COLUMN_NAME = column_name_value
  ) THEN
    SET @phase1_sql = CONCAT(
      'ALTER TABLE `', table_name_value, '` ADD COLUMN `',
      column_name_value, '` ', column_definition_value
    );
    PREPARE phase1_stmt FROM @phase1_sql;
    EXECUTE phase1_stmt;
    DEALLOCATE PREPARE phase1_stmt;
  END IF;
END$$
DELIMITER ;

CALL phase1_add_column('tb_shop', 'checkout_mode', 'int(2) DEFAULT ''1'' COMMENT ''1=pay first, 2=eat first''');
CALL phase1_add_column('tb_shopping_cart', 'dining_table_id', 'bigint(20) DEFAULT NULL COMMENT ''Dining table id''');
CALL phase1_add_column('tb_order', 'checkout_mode', 'int(2) DEFAULT ''1'' COMMENT ''1=pay first, 2=eat first''');
CALL phase1_add_column('tb_order', 'table_no', 'varchar(50) DEFAULT NULL COMMENT ''Table number snapshot''');
CALL phase1_add_column('tb_order', 'table_name', 'varchar(50) DEFAULT NULL COMMENT ''Table name snapshot''');
CALL phase1_add_column('tb_order', 'dining_table_id', 'bigint(20) DEFAULT NULL COMMENT ''Dining table id''');
CALL phase1_add_column('tb_order', 'is_payment', 'tinyint(1) DEFAULT ''0'' COMMENT ''Payment completed''');

DROP PROCEDURE IF EXISTS `phase1_add_column`;

DROP PROCEDURE IF EXISTS `phase1_add_index`;
DELIMITER $$
CREATE PROCEDURE `phase1_add_index`(
  IN table_name_value varchar(64),
  IN index_name_value varchar(64),
  IN index_columns_value varchar(500)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = table_name_value
       AND INDEX_NAME = index_name_value
  ) THEN
    SET @phase1_sql = CONCAT(
      'ALTER TABLE `', table_name_value, '` ADD INDEX `',
      index_name_value, '` (', index_columns_value, ')'
    );
    PREPARE phase1_stmt FROM @phase1_sql;
    EXECUTE phase1_stmt;
    DEALLOCATE PREPARE phase1_stmt;
  END IF;
END$$
DELIMITER ;

CALL phase1_add_index('tb_shopping_cart', 'idx_cart_member_shop_table', '`member_id`, `shop_id`, `dining_table_id`');
CALL phase1_add_index('tb_order', 'idx_order_shop_status_time', '`shop_id`, `status`, `create_time`');
CALL phase1_add_index('tb_order', 'idx_order_member_shop_time', '`member_id`, `shop_id`, `create_time`');
CALL phase1_add_index('tb_goods', 'idx_goods_shop_status_sort', '`shop_id`, `status`, `sort_number`');
CALL phase1_add_index('tb_menu', 'idx_menu_shop_sort', '`shop_id`, `sort_number`');

DROP PROCEDURE IF EXISTS `phase1_add_index`;
