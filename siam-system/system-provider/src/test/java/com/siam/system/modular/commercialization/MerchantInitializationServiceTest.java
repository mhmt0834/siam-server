package com.siam.system.modular.commercialization;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.service.ShopService;
import com.siam.system.modular.package_user.entity.Merchant;
import com.siam.system.modular.package_user.model.param.MerchantInitializationParam;
import com.siam.system.modular.package_user.service.MerchantService;
import com.siam.system.modular.package_user.service_impl.MerchantInitializationService;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MerchantInitializationServiceTest {

    @Mock
    private MerchantService merchantService;

    @Mock
    private ShopService shopService;

    private MerchantInitializationService service;

    @Before
    public void setUp() {
        service = new MerchantInitializationService();
        ReflectionTestUtils.setField(service, "merchantService", merchantService);
        ReflectionTestUtils.setField(service, "shopService", shopService);
    }

    @Test
    public void initializesOwnerAndSafeShopWithoutReturningPassword() {
        doAnswer(invocation -> {
            ((Merchant) invocation.getArgument(0)).setId(31);
            return null;
        }).when(merchantService).insertSelective(any(Merchant.class));
        when(shopService.save(any(Shop.class))).thenAnswer(invocation -> {
            ((Shop) invocation.getArgument(0)).setId(88);
            return true;
        });

        MerchantInitializationParam param = validParam();
        Map<String, Object> result = service.initialize(param);

        ArgumentCaptor<Merchant> merchantCaptor = ArgumentCaptor.forClass(Merchant.class);
        verify(merchantService).insertSelective(merchantCaptor.capture());
        Merchant merchant = merchantCaptor.getValue();
        assertNotEquals(param.getInitialPassword(), merchant.getPassword());
        assertEquals(Integer.valueOf(2), merchant.getAuditStatus());

        ArgumentCaptor<Shop> shopCaptor = ArgumentCaptor.forClass(Shop.class);
        verify(shopService).save(shopCaptor.capture());
        Shop shop = shopCaptor.getValue();
        assertFalse(shop.getIsOperating());
        assertEquals(Shop.CHECKOUT_MODE_PAY_FIRST, shop.getCheckoutMode());
        assertEquals(Integer.valueOf(88), result.get("shopId"));
        assertNull(result.get("initialPassword"));
        assertNull(result.get("password"));
    }

    @Test(expected = StoneCustomerException.class)
    public void duplicateOwnerStopsBeforeWritingShop() {
        MerchantInitializationParam param = validParam();
        when(merchantService.selectByUsernameOrMobile(param.getOwnerUsername())).thenReturn(new Merchant());
        try {
            service.initialize(param);
        } finally {
            verify(shopService, never()).save(any(Shop.class));
        }
    }

    private MerchantInitializationParam validParam() {
        MerchantInitializationParam param = new MerchantInitializationParam();
        param.setOwnerUsername("owner-a");
        param.setOwnerMobile("13800000001");
        param.setInitialPassword("safe-pass-123");
        param.setShopName("测试餐厅");
        param.setStartTime("09:00");
        param.setEndTime("22:00");
        param.setContactPhone("13800000001");
        return param;
    }
}
