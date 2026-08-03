package com.siam.system.modular.package_goods.service_impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.Goods;
import com.siam.system.modular.package_goods.entity.Menu;
import com.siam.system.modular.package_goods.mapper.MenuMapper;
import com.siam.system.modular.package_goods.model.param.MerchantGoodsBatchItem;
import com.siam.system.modular.package_goods.model.param.MerchantGoodsBatchParam;
import com.siam.system.modular.package_goods.service.GoodsService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.util.TokenUtil;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class MerchantGoodsBatchService {

    private static final int MAX_BATCH_SIZE = 500;

    @Autowired
    private MerchantSessionManager merchantSessionManager;

    @Autowired
    private GoodsService goodsService;

    @Autowired
    private MenuMapper menuMapper;

    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> insert(MerchantGoodsBatchParam param) {
        Merchant merchant = merchantSessionManager.getSession(TokenUtil.getToken());
        if (merchant == null || merchant.getShopId() == null) {
            throw new StoneCustomerException("当前商家未绑定店铺");
        }
        List<MerchantGoodsBatchItem> items = param == null ? null : param.getItems();
        if (items == null || items.isEmpty()) {
            throw new StoneCustomerException("批量菜品不能为空");
        }
        if (items.size() > MAX_BATCH_SIZE) {
            throw new StoneCustomerException("单次最多导入500个菜品");
        }
        validateItems(items);

        Map<String, Integer> categories = new HashMap<>();
        int createdCategoryCount = 0;
        for (MerchantGoodsBatchItem item : items) {
            CategoryResult category = resolveCategory(merchant.getShopId(), item, categories);
            if (category.created) {
                createdCategoryCount++;
            }
            Goods goods = new Goods();
            goods.setName(item.getName().trim());
            goods.setMenuId(category.menuId);
            goods.setMainImage(item.getImage().trim());
            goods.setSubImages(item.getImage().trim());
            goods.setPrice(item.getPrice());
            goods.setPackingCharges(BigDecimal.ZERO);
            goods.setStatus(item.getStatus() == null ? Goods.STATUS_WAIT_ON_SHELF : item.getStatus());
            goods.setDetail(StringUtils.defaultString(item.getDescription()).trim());
            goodsService.insert(goods);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("importedCount", items.size());
        result.put("createdCategoryCount", createdCategoryCount);
        return result;
    }

    private void validateItems(List<MerchantGoodsBatchItem> items) {
        Set<String> names = new HashSet<>();
        for (int index = 0; index < items.size(); index++) {
            MerchantGoodsBatchItem item = items.get(index);
            String prefix = "第" + (index + 1) + "个菜品";
            if (item == null || StringUtils.isBlank(item.getName())) {
                throw new StoneCustomerException(prefix + "名称不能为空");
            }
            String normalizedName = item.getName().trim().toLowerCase();
            if (!names.add(normalizedName)) {
                throw new StoneCustomerException(prefix + "名称在本批次重复");
            }
            if (StringUtils.isBlank(item.getImage())) {
                throw new StoneCustomerException(prefix + "图片不能为空");
            }
            if (item.getMenuId() == null && StringUtils.isBlank(item.getCategoryName())) {
                throw new StoneCustomerException(prefix + "分类不能为空");
            }
            if (item.getPrice() == null || item.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new StoneCustomerException(prefix + "价格必须大于0");
            }
            if (item.getStatus() != null && (item.getStatus() < Goods.STATUS_WAIT_ON_SHELF
                    || item.getStatus() > Goods.STATUS_SELL_OUT)) {
                throw new StoneCustomerException(prefix + "状态不正确");
            }
        }
    }

    private CategoryResult resolveCategory(Integer shopId, MerchantGoodsBatchItem item,
                                           Map<String, Integer> categories) {
        if (item.getMenuId() != null) {
            Menu menu = menuMapper.selectById(item.getMenuId());
            if (menu == null || !Objects.equals(shopId, menu.getShopId())) {
                throw new StoneCustomerException("菜品分类不属于当前店铺");
            }
            return new CategoryResult(menu.getId(), false);
        }

        String categoryName = item.getCategoryName().trim();
        String key = categoryName.toLowerCase();
        if (categories.containsKey(key)) {
            return new CategoryResult(categories.get(key), false);
        }
        List<Menu> existing = menuMapper.selectList(new LambdaQueryWrapper<Menu>()
                .eq(Menu::getShopId, shopId)
                .eq(Menu::getName, categoryName));
        if (existing != null && !existing.isEmpty()) {
            categories.put(key, existing.get(0).getId());
            return new CategoryResult(existing.get(0).getId(), false);
        }

        Menu menu = new Menu();
        menu.setShopId(shopId);
        menu.setName(categoryName);
        menu.setSortNumber(0);
        menu.setCreateTime(new Date());
        menu.setUpdateTime(new Date());
        menuMapper.insert(menu);
        categories.put(key, menu.getId());
        return new CategoryResult(menu.getId(), true);
    }

    private static class CategoryResult {
        private final Integer menuId;
        private final boolean created;

        private CategoryResult(Integer menuId, boolean created) {
            this.menuId = menuId;
            this.created = created;
        }
    }
}
