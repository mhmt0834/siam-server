package com.siam.system.modular.commercialization;

import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.model.param.ShopBasicConfigParam;
import com.siam.system.modular.package_goods.service.ShopService;
import com.siam.system.modular.package_goods.service_impl.MerchantShopBasicConfigService;
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

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantShopBasicConfigServiceTest {

    @Mock
    private MerchantSessionManager merchantSessionManager;

    @Mock
    private ShopService shopService;

    private MerchantShopBasicConfigService service;

    @Before
    public void setUp() {
        service = new MerchantShopBasicConfigService();
        ReflectionTestUtils.setField(service, "merchantSessionManager", merchantSessionManager);
        ReflectionTestUtils.setField(service, "shopService", shopService);
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "merchant-token");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        Merchant merchant = new Merchant();
        merchant.setShopId(101);
        when(merchantSessionManager.getSession("merchant-token")).thenReturn(merchant);
        when(shopService.getById(101)).thenReturn(shop(101));
    }

    @After
    public void tearDown() {
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void updateAlwaysTargetsAuthenticatedShop() {
        ShopBasicConfigParam param = new ShopBasicConfigParam();
        param.setName("新店名");
        param.setContactPhone("13800000001");
        param.setStartTime("08:30");
        param.setEndTime("21:30");
        param.setIsOperating(true);

        service.update(param);

        ArgumentCaptor<Shop> captor = ArgumentCaptor.forClass(Shop.class);
        verify(shopService).updateById(captor.capture());
        assertEquals(Integer.valueOf(101), captor.getValue().getId());
        assertEquals("新店名", captor.getValue().getName());
    }

    private Shop shop(int id) {
        Shop shop = new Shop();
        shop.setId(id);
        shop.setName("原店名");
        shop.setContactPhone("13800000001");
        shop.setStartTime("09:00");
        shop.setEndTime("22:00");
        shop.setIsOperating(false);
        return shop;
    }
}
