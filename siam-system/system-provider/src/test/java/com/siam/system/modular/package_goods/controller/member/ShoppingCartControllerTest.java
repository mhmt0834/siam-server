package com.siam.system.modular.package_goods.controller.member;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.entity.Goods;
import com.siam.system.modular.package_goods.entity.ShoppingCart;
import com.siam.system.modular.package_goods.service.DiningTableService;
import com.siam.system.modular.package_goods.service.GoodsService;
import com.siam.system.modular.package_goods.service.ShoppingCartService;
import com.siam.system.modular.package_user.auth.cache.MemberSessionManager;
import com.siam.system.modular.package_user.entity.Member;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class ShoppingCartControllerTest {

    @Mock private ShoppingCartService shoppingCartService;
    @Mock private DiningTableService diningTableService;
    @Mock private GoodsService goodsService;
    @Mock private MemberSessionManager memberSessionManager;

    private ShoppingCartController controller;
    private MockHttpServletRequest request;

    @Before
    public void setUp() {
        controller = new ShoppingCartController();
        ReflectionTestUtils.setField(controller, "shoppingCartService", shoppingCartService);
        ReflectionTestUtils.setField(controller, "diningTableService", diningTableService);
        ReflectionTestUtils.setField(controller, "goodsService", goodsService);
        ReflectionTestUtils.setField(controller, "memberSessionManager", memberSessionManager);

        request = new MockHttpServletRequest();
        request.addHeader("Authorization", "phase5-token");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));

        Member member = new Member();
        member.setId(7);
        when(memberSessionManager.getSession("phase5-token")).thenReturn(member);
        when(diningTableService.resolveActiveTable("scene-a01")).thenReturn(table());
    }

    @After
    public void tearDown() {
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void insertRejectsAccumulatedQuantityAbove99() {
        Goods goods = new Goods();
        goods.setId(31);
        goods.setShopId(11);
        goods.setStatus(Goods.STATUS_ON_SHELF);
        when(goodsService.getById(31)).thenReturn(goods);

        ShoppingCart existing = cart(44, 99);
        when(shoppingCartService.selectSameItem(7, 11, 21L, 31, null)).thenReturn(existing);

        ShoppingCart requestCart = cart(null, 1);
        requestCart.setSceneToken("scene-a01");
        expectRejected(() -> controller.insert(requestCart, request));

        verify(shoppingCartService, never()).updateByPrimaryKeySelective(any());
    }

    @Test
    public void updateRejectsQuantityAbove99() {
        ShoppingCart existing = cart(44, 99);
        existing.setMemberId(7);
        existing.setShopId(11);
        existing.setDiningTableId(21L);
        when(shoppingCartService.selectByPrimaryKey(44)).thenReturn(existing);

        ShoppingCart requestCart = new ShoppingCart();
        requestCart.setId(44);
        requestCart.setSceneToken("scene-a01");
        requestCart.setType(1);
        requestCart.setNumber(1);
        expectRejected(() -> controller.updateNumber(requestCart, request));

        verify(shoppingCartService, never()).updateByPrimaryKeySelective(any());
    }

    private DiningTable table() {
        DiningTable table = new DiningTable();
        table.setId(21L);
        table.setShopId(11);
        return table;
    }

    private ShoppingCart cart(Integer id, int number) {
        ShoppingCart cart = new ShoppingCart();
        cart.setId(id);
        cart.setGoodsId(31);
        cart.setNumber(number);
        return cart;
    }

    private void expectRejected(Runnable action) {
        try {
            action.run();
            throw new AssertionError("Operation should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        }
    }
}
