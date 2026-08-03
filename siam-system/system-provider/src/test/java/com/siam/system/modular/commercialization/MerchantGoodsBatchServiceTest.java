package com.siam.system.modular.commercialization;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.Goods;
import com.siam.system.modular.package_goods.entity.Menu;
import com.siam.system.modular.package_goods.mapper.MenuMapper;
import com.siam.system.modular.package_goods.model.param.MerchantGoodsBatchItem;
import com.siam.system.modular.package_goods.model.param.MerchantGoodsBatchParam;
import com.siam.system.modular.package_goods.service.GoodsService;
import com.siam.system.modular.package_goods.service_impl.MerchantGoodsBatchService;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Merchant;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantGoodsBatchServiceTest {

    @Mock
    private MerchantSessionManager merchantSessionManager;

    @Mock
    private GoodsService goodsService;

    @Mock
    private MenuMapper menuMapper;

    private MerchantGoodsBatchService service;

    @Before
    public void setUp() {
        service = new MerchantGoodsBatchService();
        ReflectionTestUtils.setField(service, "merchantSessionManager", merchantSessionManager);
        ReflectionTestUtils.setField(service, "goodsService", goodsService);
        ReflectionTestUtils.setField(service, "menuMapper", menuMapper);
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "merchant-token");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        Merchant merchant = new Merchant();
        merchant.setShopId(101);
        when(merchantSessionManager.getSession("merchant-token")).thenReturn(merchant);
    }

    @After
    public void tearDown() {
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void importsBatchAndCreatesCategoryInsideCurrentShop() {
        when(menuMapper.selectList(any())).thenReturn(Collections.emptyList());
        doAnswer(invocation -> {
            ((Menu) invocation.getArgument(0)).setId(77);
            return 1;
        }).when(menuMapper).insert(any(Menu.class));
        MerchantGoodsBatchParam param = new MerchantGoodsBatchParam();
        param.setItems(Arrays.asList(item("大盘鸡"), item("烤羊肉串")));

        Map<String, Object> result = service.insert(param);

        ArgumentCaptor<Menu> menuCaptor = ArgumentCaptor.forClass(Menu.class);
        verify(menuMapper).insert(menuCaptor.capture());
        assertEquals(Integer.valueOf(101), menuCaptor.getValue().getShopId());
        ArgumentCaptor<Goods> goodsCaptor = ArgumentCaptor.forClass(Goods.class);
        verify(goodsService, org.mockito.Mockito.times(2)).insert(goodsCaptor.capture());
        List<Goods> goods = goodsCaptor.getAllValues();
        assertEquals(Integer.valueOf(77), goods.get(0).getMenuId());
        assertEquals(2, result.get("importedCount"));
        assertEquals(1, result.get("createdCategoryCount"));
    }

    @Test(expected = StoneCustomerException.class)
    public void rejectsCategoryOwnedByAnotherShop() {
        MerchantGoodsBatchItem item = item("抓饭");
        item.setCategoryName(null);
        item.setMenuId(9);
        Menu foreignMenu = new Menu();
        foreignMenu.setId(9);
        foreignMenu.setShopId(202);
        when(menuMapper.selectById(9)).thenReturn(foreignMenu);
        MerchantGoodsBatchParam param = new MerchantGoodsBatchParam();
        param.setItems(Collections.singletonList(item));
        try {
            service.insert(param);
        } finally {
            verify(goodsService, never()).insert(any(Goods.class));
        }
    }

    private MerchantGoodsBatchItem item(String name) {
        MerchantGoodsBatchItem item = new MerchantGoodsBatchItem();
        item.setName(name);
        item.setImage("data/images/foods/demo.jpg");
        item.setCategoryName("特色菜");
        item.setPrice(new BigDecimal("68.00"));
        item.setStatus(2);
        return item;
    }
}
