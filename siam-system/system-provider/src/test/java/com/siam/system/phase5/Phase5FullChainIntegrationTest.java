package com.siam.system.phase5;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.package_common.util.Base64Utils;
import com.siam.system.modular.package_goods.controller.member.ScanController;
import com.siam.system.modular.package_goods.controller.member.ShoppingCartController;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.entity.Goods;
import com.siam.system.modular.package_goods.entity.Menu;
import com.siam.system.modular.package_goods.entity.MenuGoodsRelation;
import com.siam.system.modular.package_goods.entity.Shop;
import com.siam.system.modular.package_goods.entity.ShoppingCart;
import com.siam.system.modular.package_goods.service.DiningTableService;
import com.siam.system.modular.package_goods.service.GoodsService;
import com.siam.system.modular.package_goods.service.MenuGoodsRelationService;
import com.siam.system.modular.package_goods.service.MenuService;
import com.siam.system.modular.package_goods.service.ShopService;
import com.siam.system.modular.package_goods.service.ShoppingCartService;
import com.siam.system.modular.package_goods.service_impl.MerchantBusinessStatisticsService;
import com.siam.system.modular.package_order.entity.Order;
import com.siam.system.modular.package_order.entity.ShopWechatConfig;
import com.siam.system.modular.package_order.entity.WechatPaymentRecord;
import com.siam.system.modular.package_order.mapper.WechatPaymentRecordMapper;
import com.siam.system.modular.package_order.model.param.OrderParam;
import com.siam.system.modular.package_order.service.OrderService;
import com.siam.system.modular.package_order.service_impl.MerchantOrderWorkflowService;
import com.siam.system.modular.package_order.service_impl.payment.WechatPayV3Service;
import com.siam.system.modular.package_user.auth.cache.MemberSessionManager;
import com.siam.system.modular.package_user.auth.cache.MerchantSessionManager;
import com.siam.system.modular.package_user.entity.Member;
import com.siam.system.modular.package_user.model.param.MerchantInitializationParam;
import com.siam.system.modular.package_user.model.param.MerchantParam;
import com.siam.system.modular.package_user.model.result.MerchantResult;
import com.siam.system.modular.package_user.service.MemberService;
import com.siam.system.modular.package_user.service.MerchantService;
import com.siam.system.modular.package_user.service_impl.MerchantInitializationService;
import com.wechat.pay.java.service.payments.model.Transaction;
import com.wechat.pay.java.service.payments.model.TransactionAmount;
import org.junit.After;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "springfox.documentation.enabled=false")
@Transactional
public class Phase5FullChainIntegrationTest {

    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private RedisConnectionFactory redisConnectionFactory;
    @Autowired private MerchantInitializationService initializationService;
    @Autowired private MerchantService merchantService;
    @Autowired private MerchantSessionManager merchantSessionManager;
    @Autowired private MemberService memberService;
    @Autowired private MemberSessionManager memberSessionManager;
    @Autowired private ShopService shopService;
    @Autowired private DiningTableService diningTableService;
    @Autowired private GoodsService goodsService;
    @Autowired private MenuService menuService;
    @Autowired private MenuGoodsRelationService menuGoodsRelationService;
    @Autowired private ShoppingCartService shoppingCartService;
    @Autowired private ShoppingCartController shoppingCartController;
    @Autowired private ScanController scanController;
    @Autowired private OrderService orderService;
    @Autowired private WechatPaymentRecordMapper paymentRecordMapper;
    @Autowired private WechatPayV3Service wechatPayV3Service;
    @Autowired private MerchantOrderWorkflowService workflowService;
    @Autowired private MerchantBusinessStatisticsService statisticsService;

    private final List<String> redisTokens = new ArrayList<>();

    @After
    public void cleanup() {
        for (String token : redisTokens) {
            memberSessionManager.removeSession(token);
            merchantSessionManager.removeSession(token);
        }
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    public void realRestaurantFlowAndTenantIsolation() throws Exception {
        assertEquals(Integer.valueOf(1), jdbcTemplate.queryForObject("select 1", Integer.class));
        RedisConnection redis = redisConnectionFactory.getConnection();
        try {
            assertNotNull(redis.ping());
        } finally {
            redis.close();
        }

        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        String mobileDigits = String.format("%08d", Math.abs(suffix.hashCode() % 100000000));
        Tenant tenantA = createTenant("新疆特色烤肉Demo店", "test_shop_001", "qa_a_" + suffix,
                "139" + mobileDigits, "Phase5PassA!");
        Tenant tenantB = createTenant("隔离测试B店", "test_shop_002", "qa_b_" + suffix,
                "138" + mobileDigits, "Phase5PassB!");

        assertMerchantLogin(tenantA);
        assertMerchantLogin(tenantB);

        DiningTable tableA01 = createTable(tenantA.shopId, "A01", "phase5-a01-" + suffix);
        DiningTable tableA02 = createTable(tenantA.shopId, "A02", "phase5-a02-" + suffix);
        createTable(tenantB.shopId, "B01", "phase5-b01-" + suffix);

        List<Goods> goods = createMenuAndGoods(tenantA.shopId);
        assertEquals(4, goods.size());
        Menu menuQuery = new Menu();
        menuQuery.setShopId(tenantA.shopId);
        List<Map<String, Object>> menus = menuService.getListJoinGoods(menuQuery);
        assertEquals(1, menus.size());
        assertEquals(4, ((List<?>) menus.get(0).get("goodsList")).size());

        DiningTable scanParam = new DiningTable();
        scanParam.setSceneToken(tableA01.getSceneToken());
        assertTrue(scanController.resolve(scanParam).getSuccess());
        DiningTable invalid = new DiningTable();
        invalid.setSceneToken("invalid-" + suffix);
        expectRejected(() -> scanController.resolve(invalid));

        Member member = createMember(mobileDigits);
        String memberToken = "phase5-member-" + suffix;
        memberSessionManager.createSession(memberToken, member);
        redisTokens.add(memberToken);
        loginRequest(memberToken);

        ShoppingCart cart = addToCart(tableA01.getSceneToken(), goods.get(0).getId(), 2);
        ShoppingCart decrease = new ShoppingCart();
        decrease.setId(cart.getId());
        decrease.setSceneToken(tableA01.getSceneToken());
        decrease.setType(0);
        decrease.setNumber(1);
        shoppingCartController.updateNumber(decrease, currentRequest());
        assertEquals(Integer.valueOf(1), shoppingCartService.selectByPrimaryKey(cart.getId()).getNumber());

        ShoppingCart deleted = addToCart(tableA01.getSceneToken(), goods.get(1).getId(), 1);
        ShoppingCart deleteParam = new ShoppingCart();
        deleteParam.setId(deleted.getId());
        deleteParam.setSceneToken(tableA01.getSceneToken());
        shoppingCartController.delete(deleteParam, currentRequest());
        assertEquals(null, shoppingCartService.selectByPrimaryKey(deleted.getId()));

        ShoppingCart anotherTableQuery = new ShoppingCart();
        anotherTableQuery.setSceneToken(tableA02.getSceneToken());
        assertTrue(shoppingCartService.getListByPage(1, 20, scopedCart(member.getId(), tenantA.shopId,
                tableA02.getId())).getRecords().isEmpty());

        OrderParam wrongTableOrder = orderParam(tableA02.getSceneToken(), cart.getId());
        expectRejectedChecked(() -> orderService.insert(wrongTableOrder));

        OrderParam orderParam = orderParam(tableA01.getSceneToken(), cart.getId());
        orderParam.setActualPrice(new BigDecimal("0.01"));
        Order order = orderService.insert(orderParam);
        assertEquals(new BigDecimal("68.00"), order.getActualPrice());
        assertEquals(Integer.valueOf(Order.STATUS_OF_WAIT_PAYMENT), order.getStatus());
        assertEquals(tenantA.shopId, order.getShopId());
        assertEquals(tableA01.getId(), order.getDiningTableId());

        WechatPaymentRecord payment = paymentRecord(order, "wx-app-phase5", "mch-phase5");
        paymentRecordMapper.insert(payment);
        WechatPayV3Service.VerifiedNotification notification = notification(order, payment);
        wechatPayV3Service.applySuccessfulNotification(notification);
        assertEquals(Integer.valueOf(Order.STATUS_OF_WAIT_HANDLE), orderService.getById(order.getId()).getStatus());
        wechatPayV3Service.applySuccessfulNotification(notification);
        assertEquals(Integer.valueOf(WechatPaymentRecord.STATUS_SUCCESS),
                paymentRecordMapper.selectByOrderId(order.getId()).getStatus());

        expectRejected(() -> workflowService.accept(order.getId(), tenantB.shopId));
        workflowService.accept(order.getId(), tenantA.shopId);
        assertEquals(Integer.valueOf(Order.STATUS_OF_WAIT_PICKUP), orderService.getById(order.getId()).getStatus());
        expectRejected(() -> workflowService.accept(order.getId(), tenantA.shopId));
        workflowService.complete(order.getId(), tenantA.shopId);
        assertEquals(Integer.valueOf(Order.STATUS_OF_COMPLETED), orderService.getById(order.getId()).getStatus());

        loginRequest(tenantA.loginToken);
        Map<String, Object> statsA = statisticsService.today();
        assertEquals(new BigDecimal("68.00"), statsA.get("todayRevenue"));
        assertEquals(1, statsA.get("todayOrderCount"));
        assertFalse(statisticsService.hotGoods("today").isEmpty());

        loginRequest(tenantB.loginToken);
        Map<String, Object> statsB = statisticsService.today();
        assertEquals(new BigDecimal("0.00"), statsB.get("todayRevenue"));
        assertEquals(0, statsB.get("todayOrderCount"));
        assertTrue(statisticsService.hotGoods("today").isEmpty());
        assertEquals(1L, diningTableService.getListByMerchant(new DiningTable(), tenantB.shopId).getTotal());
    }

    private Tenant createTenant(String shopName, String shopCode, String username,
                                String mobile, String password) {
        MerchantInitializationParam param = new MerchantInitializationParam();
        param.setShopName(shopName);
        param.setOwnerUsername(username);
        param.setOwnerMobile(mobile);
        param.setInitialPassword(password);
        Map<String, Object> initialized = initializationService.initialize(param);
        Integer shopId = (Integer) initialized.get("shopId");

        Shop update = new Shop();
        update.setId(shopId);
        update.setCode(shopCode);
        update.setStatus(2);
        update.setIsOperating(true);
        update.setProvince("");
        update.setCity("");
        update.setArea("");
        update.setStreet("");
        update.setHouseNumber("");
        shopService.updateById(update);
        return new Tenant(shopId, username, password);
    }

    private void assertMerchantLogin(Tenant tenant) {
        loginRequest("login-bootstrap");
        MerchantParam param = new MerchantParam();
        param.setUsername(tenant.username);
        param.setPassword(Base64Utils.encode(tenant.password));
        MerchantResult result = merchantService.login(param);
        assertNotNull(result.getToken());
        assertEquals(tenant.shopId, merchantSessionManager.getSession(result.getToken()).getShopId());
        tenant.loginToken = result.getToken();
        redisTokens.add(result.getToken());
    }

    private DiningTable createTable(Integer shopId, String tableNo, String sceneToken) {
        DiningTable table = new DiningTable();
        table.setShopId(shopId);
        table.setTableNo(tableNo);
        table.setTableName(tableNo + "桌");
        table.setSceneToken(sceneToken);
        table.setStatus(DiningTable.STATUS_ENABLED);
        table.setCreateTime(new Date());
        table.setUpdateTime(new Date());
        diningTableService.save(table);
        return table;
    }

    private List<Goods> createMenuAndGoods(Integer shopId) {
        Menu menu = new Menu();
        menu.setShopId(shopId);
        menu.setName("推荐");
        menu.setSortNumber(1);
        menu.setCreateTime(new Date());
        menu.setUpdateTime(new Date());
        menuService.insert(menu);

        List<String> names = Arrays.asList("新疆大盘鸡", "烤羊肉串", "手抓饭", "饮料");
        List<BigDecimal> prices = Arrays.asList(new BigDecimal("68.00"), new BigDecimal("6.00"),
                new BigDecimal("48.00"), new BigDecimal("5.00"));
        List<Goods> result = new ArrayList<>();
        for (int i = 0; i < names.size(); i++) {
            Goods goods = new Goods();
            goods.setShopId(shopId);
            goods.setName(names.get(i));
            goods.setMainImage("https://example.invalid/phase5/" + i + ".jpg");
            goods.setDetail("Phase 5真实数据验收菜品");
            goods.setPrice(prices.get(i));
            goods.setStock(999);
            goods.setStatus(Goods.STATUS_ON_SHELF);
            goods.setIsHot(i == 0);
            goods.setIsNew(false);
            goods.setIsSale(false);
            goods.setPackingCharges(BigDecimal.ZERO);
            goods.setMonthlySales(0);
            goods.setTotalSales(0);
            goods.setSortNumber(i + 1);
            goods.setCreateTime(new Date());
            goods.setUpdateTime(new Date());
            goodsService.save(goods);

            MenuGoodsRelation relation = new MenuGoodsRelation();
            relation.setMenuId(menu.getId());
            relation.setGoodsId(goods.getId());
            relation.setCreateTime(new Date());
            relation.setUpdateTime(new Date());
            menuGoodsRelationService.insertSelective(relation);
            result.add(goods);
        }
        return result;
    }

    private Member createMember(String mobileDigits) {
        Member member = new Member();
        member.setUsername("Phase5顾客");
        member.setMobile("137" + mobileDigits);
        member.setPassword("phase5-hash");
        member.setPasswordSalt("phase5-salt");
        member.setSex(0);
        member.setIsDisabled(false);
        member.setIsDeleted(false);
        member.setIsNewPeople(false);
        member.setIsRemindNewPeople(false);
        member.setCreateTime(new Date());
        member.setUpdateTime(new Date());
        memberService.insertSelective(member);
        return member;
    }

    private ShoppingCart addToCart(String sceneToken, Integer goodsId, int number) {
        ShoppingCart cart = new ShoppingCart();
        cart.setSceneToken(sceneToken);
        cart.setGoodsId(goodsId);
        cart.setNumber(number);
        shoppingCartController.insert(cart, currentRequest());
        assertNotNull(cart.getId());
        return cart;
    }

    private ShoppingCart scopedCart(Integer memberId, Integer shopId, Long tableId) {
        ShoppingCart cart = new ShoppingCart();
        cart.setMemberId(memberId);
        cart.setShopId(shopId);
        cart.setDiningTableId(tableId);
        return cart;
    }

    private OrderParam orderParam(String sceneToken, Integer cartId) {
        OrderParam param = new OrderParam();
        param.setSceneToken(sceneToken);
        param.setShoppingCartIdList(Arrays.asList(cartId));
        param.setRemark("少盐");
        return param;
    }

    private WechatPaymentRecord paymentRecord(Order order, String appid, String mchid) {
        WechatPaymentRecord record = new WechatPaymentRecord();
        record.setShopId(order.getShopId());
        record.setOrderId(order.getId());
        record.setOrderNo(order.getOrderNo());
        record.setAppid(appid);
        record.setMchid(mchid);
        record.setAmountCent(order.getActualPrice().movePointRight(2).longValueExact());
        record.setStatus(WechatPaymentRecord.STATUS_INIT);
        record.setCreateTime(new Date());
        record.setUpdateTime(new Date());
        return record;
    }

    private WechatPayV3Service.VerifiedNotification notification(Order order, WechatPaymentRecord payment) {
        ShopWechatConfig config = new ShopWechatConfig();
        config.setShopId(order.getShopId());
        config.setAppid(payment.getAppid());
        config.setMchid(payment.getMchid());
        TransactionAmount amount = new TransactionAmount();
        amount.setTotal(payment.getAmountCent().intValue());
        amount.setCurrency("CNY");
        Transaction transaction = new Transaction();
        transaction.setOutTradeNo(order.getOrderNo());
        transaction.setAppid(payment.getAppid());
        transaction.setMchid(payment.getMchid());
        transaction.setAttach("shop:" + order.getShopId() + ":order:" + order.getId());
        transaction.setAmount(amount);
        transaction.setTransactionId("phase5-wx-" + order.getId());
        transaction.setTradeState(Transaction.TradeStateEnum.SUCCESS);
        transaction.setSuccessTime("2026-08-04T09:00:00+08:00");
        return new WechatPayV3Service.VerifiedNotification(config, transaction);
    }

    private void loginRequest(String token) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", token);
        RequestContextHolder.setRequestAttributes(
                new ServletRequestAttributes(request, new MockHttpServletResponse()));
    }

    private MockHttpServletRequest currentRequest() {
        return (MockHttpServletRequest) ((ServletRequestAttributes)
                RequestContextHolder.getRequestAttributes()).getRequest();
    }

    private void expectRejected(Runnable action) {
        try {
            action.run();
            throw new AssertionError("Operation should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        }
    }

    private void expectRejectedChecked(CheckedAction action) {
        try {
            action.run();
            throw new AssertionError("Operation should be rejected");
        } catch (StoneCustomerException expected) {
            // expected
        } catch (Exception unexpected) {
            throw new AssertionError(unexpected);
        }
    }

    private interface CheckedAction {
        void run() throws Exception;
    }

    private static class Tenant {
        private final Integer shopId;
        private final String username;
        private final String password;
        private String loginToken;

        private Tenant(Integer shopId, String username, String password) {
            this.shopId = shopId;
            this.username = username;
            this.password = password;
        }
    }
}
