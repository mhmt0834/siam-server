package com.siam.system.modular.package_goods.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.siam.system.modular.package_goods.entity.DiningTable;

public interface DiningTableService extends IService<DiningTable> {

    DiningTable resolveActiveTable(String sceneToken);

    Page<DiningTable> getListByMerchant(DiningTable param, Integer shopId);
}
