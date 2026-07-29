package com.siam.system.modular.package_goods.service_impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.mapper.DiningTableMapper;
import com.siam.system.modular.package_goods.service.DiningTableService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class DiningTableServiceImpl extends ServiceImpl<DiningTableMapper, DiningTable> implements DiningTableService {

    @Override
    public DiningTable resolveActiveTable(String sceneToken) {
        if (!StringUtils.hasText(sceneToken)) {
            throw new StoneCustomerException("餐桌二维码无效，请重新扫码");
        }
        DiningTable table = getOne(new LambdaQueryWrapper<DiningTable>()
                .eq(DiningTable::getSceneToken, sceneToken.trim())
                .eq(DiningTable::getStatus, DiningTable.STATUS_ENABLED), false);
        if (table == null) {
            throw new StoneCustomerException("餐桌二维码已失效，请联系商家");
        }
        return table;
    }

    @Override
    public Page<DiningTable> getListByMerchant(DiningTable param, Integer shopId) {
        Page<DiningTable> page = new Page<>(param.getPageNo(), param.getPageSize());
        LambdaQueryWrapper<DiningTable> wrapper = new LambdaQueryWrapper<DiningTable>()
                .eq(DiningTable::getShopId, shopId)
                .like(StringUtils.hasText(param.getTableNo()), DiningTable::getTableNo, param.getTableNo())
                .eq(param.getStatus() != null, DiningTable::getStatus, param.getStatus())
                .orderByAsc(DiningTable::getTableNo);
        return page(page, wrapper);
    }
}
