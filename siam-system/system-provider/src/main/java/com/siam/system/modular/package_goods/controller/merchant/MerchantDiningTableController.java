package com.siam.system.modular.package_goods.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.siam.package_common.entity.BasicResult;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.service.DiningTableService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping(value = "/rest/merchant/diningTable")
@Transactional(rollbackFor = Exception.class)
public class MerchantDiningTableController {

    @Autowired
    private DiningTableService diningTableService;

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    @PostMapping(value = "/list")
    public BasicResult list(@RequestBody @Validated(value = {}) DiningTable param) {
        Merchant merchant = getLoginMerchant();
        Page<DiningTable> page = diningTableService.getListByMerchant(param, merchant.getShopId());
        return BasicResult.success(page);
    }

    @PostMapping(value = "/insert")
    public BasicResult insert(@RequestBody @Validated(value = {}) DiningTable param) {
        Merchant merchant = getLoginMerchant();
        String tableNo = normalizeTableNo(param.getTableNo());
        ensureTableNoAvailable(merchant.getShopId(), tableNo, null);

        DiningTable table = new DiningTable();
        table.setShopId(merchant.getShopId());
        table.setTableNo(tableNo);
        table.setTableName(StringUtils.hasText(param.getTableName()) ? param.getTableName().trim() : tableNo + "桌");
        table.setSceneToken(newSceneToken());
        Integer status = param.getStatus() == null ? DiningTable.STATUS_ENABLED : param.getStatus();
        if (!DiningTable.STATUS_ENABLED.equals(status) && !DiningTable.STATUS_DISABLED.equals(status)) {
            throw new StoneCustomerException("餐桌状态不正确");
        }
        table.setStatus(status);
        table.setCreateTime(new Date());
        table.setUpdateTime(new Date());
        diningTableService.save(table);
        return BasicResult.success(table);
    }

    @PostMapping(value = "/update")
    public BasicResult update(@RequestBody @Validated(value = {}) DiningTable param) {
        Merchant merchant = getLoginMerchant();
        DiningTable table = getOwnedTable(param.getId(), merchant.getShopId());

        if (StringUtils.hasText(param.getTableNo())) {
            String tableNo = normalizeTableNo(param.getTableNo());
            ensureTableNoAvailable(merchant.getShopId(), tableNo, table.getId());
            table.setTableNo(tableNo);
        }
        if (StringUtils.hasText(param.getTableName())) {
            table.setTableName(param.getTableName().trim());
        }
        if (param.getStatus() != null) {
            if (!DiningTable.STATUS_ENABLED.equals(param.getStatus())
                    && !DiningTable.STATUS_DISABLED.equals(param.getStatus())) {
                throw new StoneCustomerException("餐桌状态不正确");
            }
            table.setStatus(param.getStatus());
        }
        table.setUpdateTime(new Date());
        diningTableService.updateById(table);
        return BasicResult.success(table);
    }

    @PostMapping(value = "/generateQr")
    public BasicResult generateQr(@RequestBody @Validated(value = {}) DiningTable param) {
        Merchant merchant = getLoginMerchant();
        DiningTable table = getOwnedTable(param.getId(), merchant.getShopId());
        if (!DiningTable.STATUS_ENABLED.equals(table.getStatus())) {
            throw new StoneCustomerException("请先启用餐桌再生成桌码");
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("tableId", table.getId());
        result.put("tableNo", table.getTableNo());
        result.put("tableName", table.getTableName());
        result.put("sceneToken", table.getSceneToken());
        result.put("pagePath", "pages/menu/index/index?scene=" + table.getSceneToken());
        result.put("qrCodeUrl", table.getQrCodeUrl());
        return BasicResult.success(result);
    }

    @PostMapping(value = "/regenerateScene")
    public BasicResult regenerateScene(@RequestBody @Validated(value = {}) DiningTable param) {
        Merchant merchant = getLoginMerchant();
        DiningTable table = getOwnedTable(param.getId(), merchant.getShopId());
        table.setSceneToken(newSceneToken());
        table.setQrCodeUrl(null);
        table.setUpdateTime(new Date());
        diningTableService.updateById(table);
        return generateQr(table);
    }

    private Merchant getLoginMerchant() {
        Merchant merchant = merchantSessionManager.getSession(TokenUtil.getToken());
        if (merchant == null || merchant.getShopId() == null) {
            throw new StoneCustomerException("当前商家未绑定门店");
        }
        return merchant;
    }

    private DiningTable getOwnedTable(Long id, Integer shopId) {
        if (id == null) {
            throw new StoneCustomerException("餐桌id不能为空");
        }
        DiningTable table = diningTableService.getById(id);
        if (table == null) {
            throw new StoneCustomerException("餐桌不存在");
        }
        if (!shopId.equals(table.getShopId())) {
            throw new StoneCustomerException("您没有权限操作该餐桌");
        }
        return table;
    }

    private void ensureTableNoAvailable(Integer shopId, String tableNo, Long excludeId) {
        LambdaQueryWrapper<DiningTable> wrapper = new LambdaQueryWrapper<DiningTable>()
                .eq(DiningTable::getShopId, shopId)
                .eq(DiningTable::getTableNo, tableNo)
                .ne(excludeId != null, DiningTable::getId, excludeId);
        if (diningTableService.count(wrapper) > 0) {
            throw new StoneCustomerException("当前门店已存在该桌号");
        }
    }

    private String normalizeTableNo(String tableNo) {
        if (!StringUtils.hasText(tableNo)) {
            throw new StoneCustomerException("餐桌编号不能为空");
        }
        String normalized = tableNo.trim().toUpperCase();
        if (normalized.length() > 50) {
            throw new StoneCustomerException("餐桌编号不能超过50个字符");
        }
        return normalized;
    }

    private String newSceneToken() {
        return UUID.randomUUID().toString().replace("-", "");
    }
}
