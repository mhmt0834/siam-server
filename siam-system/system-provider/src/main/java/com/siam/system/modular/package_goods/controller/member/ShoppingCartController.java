package com.siam.system.modular.package_goods.controller.member;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.siam.package_common.constant.BasicResultCode;
import com.siam.package_common.constant.Quantity;
import com.siam.package_common.entity.BasicResult;
import com.siam.package_common.exception.StoneCustomerException;
import com.siam.package_common.util.GsonUtils;
import com.siam.system.modular.package_goods.entity.DiningTable;
import com.siam.system.modular.package_goods.entity.Goods;
import com.siam.system.modular.package_goods.entity.ShoppingCart;
import com.siam.system.modular.package_goods.service.DiningTableService;
import com.siam.system.modular.package_goods.service.GoodsService;
import com.siam.system.modular.package_goods.service.GoodsSpecificationOptionService;
import com.siam.system.modular.package_goods.service.ShoppingCartService;
import com.siam.system.modular.package_user.auth.cache.MemberSessionManager;
import com.siam.system.modular.package_user.entity.Member;
import com.siam.system.util.TokenUtil;
import io.swagger.annotations.Api;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Slf4j
@RestController
@RequestMapping(value = "/rest/member/shoppingCart")
@Transactional(rollbackFor = Exception.class)
@Api(tags = "购物车模块相关接口", description = "ShoppingCartController")
public class ShoppingCartController {

    @Autowired
    private ShoppingCartService shoppingCartService;

    @Autowired
    private GoodsSpecificationOptionService goodsSpecificationOptionService;

    @Autowired
    private MemberSessionManager memberSessionManager;

    @Autowired
    private DiningTableService diningTableService;

    @Autowired
    private GoodsService goodsService;

    @PostMapping(value = "/list")
    public BasicResult list(@RequestBody @Validated ShoppingCart shoppingCart, HttpServletRequest request){
        Member loginMember = memberSessionManager.getSession(TokenUtil.getToken());
        DiningTable diningTable = requireDiningTable(shoppingCart);
        applyDiningContext(shoppingCart, diningTable);
        shoppingCart.setMemberId(loginMember.getId());
        shoppingCart.setIsGoodsExists(true);

        Page<Map<String, Object>> page = shoppingCartService.getListByPageJoinGoods(
                shoppingCart.getPageNo(), shoppingCart.getPageSize(), shoppingCart);
        page.getRecords().forEach(shoppingCartMap -> {
            List<String> nameList = new ArrayList<>();
            Map<String, Object> specMap = GsonUtils.toMap((String) shoppingCartMap.get("specList"));
            if(specMap != null){
                for(String key : specMap.keySet()){
                    nameList.add((String) specMap.get(key));
                }
            }

            BigDecimal specOptionPrice = BigDecimal.ZERO;
            if(!nameList.isEmpty()){
                specOptionPrice = goodsSpecificationOptionService.selectSumPriceByGoodsIdAndName(
                        (int) shoppingCartMap.get("goodsId"), nameList);
            }
            BigDecimal price = ((BigDecimal) shoppingCartMap.get("goodsPrice")).add(specOptionPrice);
            shoppingCartMap.put("price", price);
        });
        return BasicResult.success(page);
    }

    @PostMapping(value = "/insert")
    public BasicResult insert(@RequestBody @Validated ShoppingCart shoppingCart, HttpServletRequest request){
        Member loginMember = memberSessionManager.getSession(TokenUtil.getToken());
        DiningTable diningTable = requireDiningTable(shoppingCart);
        applyDiningContext(shoppingCart, diningTable);

        Goods goods = goodsService.getById(shoppingCart.getGoodsId());
        if(goods == null || !Objects.equals(goods.getShopId(), diningTable.getShopId())
                || !Objects.equals(goods.getStatus(), Goods.STATUS_ON_SHELF)){
            throw new StoneCustomerException("商品不存在、已下架或不属于当前门店");
        }

        ShoppingCart dbShoppingCart = shoppingCartService.selectSameItem(loginMember.getId(),
                diningTable.getShopId(), diningTable.getId(), shoppingCart.getGoodsId(), shoppingCart.getSpecList());
        Date now = new Date();
        int requestedNumber = shoppingCart.getNumber() == null ? Quantity.INT_1 : shoppingCart.getNumber();
        if(requestedNumber <= 0 || requestedNumber > 99){
            throw new StoneCustomerException("加入数量必须在1到99之间");
        }
        if(dbShoppingCart != null){
            int actualNumber = dbShoppingCart.getNumber() + requestedNumber;
            if(actualNumber > 99){
                throw new StoneCustomerException("购物车单项数量不能超过99");
            }
            ShoppingCart updateShoppingCart = new ShoppingCart();
            updateShoppingCart.setId(dbShoppingCart.getId());
            updateShoppingCart.setNumber(actualNumber);
            updateShoppingCart.setUpdateTime(now);
            shoppingCartService.updateByPrimaryKeySelective(updateShoppingCart);
        }else{
            shoppingCart.setMemberId(loginMember.getId());
            shoppingCart.setNumber(requestedNumber);
            shoppingCart.setIsGoodsExists(true);
            shoppingCart.setCreateTime(now);
            shoppingCart.setUpdateTime(now);
            shoppingCartService.insertSelective(shoppingCart);
        }
        return success("新增成功");
    }

    @PostMapping(value = "/updateNumber")
    public BasicResult updateNumber(@RequestBody @Validated ShoppingCart shoppingCart, HttpServletRequest request){
        Member loginMember = memberSessionManager.getSession(TokenUtil.getToken());
        DiningTable diningTable = requireDiningTable(shoppingCart);
        ShoppingCart dbShoppingCart = shoppingCartService.selectByPrimaryKey(shoppingCart.getId());
        verifyOwnership(dbShoppingCart, loginMember, diningTable);

        if(shoppingCart.getType() == null
                || (shoppingCart.getType() != Quantity.INT_0 && shoppingCart.getType() != Quantity.INT_1)){
            throw new StoneCustomerException("操作类型不正确");
        }
        if(shoppingCart.getNumber() == null || shoppingCart.getNumber() <= Quantity.INT_0){
            throw new StoneCustomerException("加减数量必须大于0");
        }

        int actualNumber = shoppingCart.getType() == Quantity.INT_0
                ? dbShoppingCart.getNumber() - shoppingCart.getNumber()
                : dbShoppingCart.getNumber() + shoppingCart.getNumber();
        if(actualNumber < Quantity.INT_0){
            throw new StoneCustomerException("修改后的购买数量不能小于0");
        }
        if(actualNumber > 99){
            throw new StoneCustomerException("购物车单项数量不能超过99");
        }
        if(actualNumber == Quantity.INT_0){
            shoppingCartService.deleteByPrimaryKey(dbShoppingCart.getId());
        }else{
            ShoppingCart updateShoppingCart = new ShoppingCart();
            updateShoppingCart.setId(dbShoppingCart.getId());
            updateShoppingCart.setNumber(actualNumber);
            updateShoppingCart.setUpdateTime(new Date());
            shoppingCartService.updateByPrimaryKeySelective(updateShoppingCart);
        }
        return success("修改成功");
    }

    @PostMapping(value = "/delete")
    public BasicResult delete(@RequestBody @Validated ShoppingCart param, HttpServletRequest request){
        Member loginMember = memberSessionManager.getSession(TokenUtil.getToken());
        DiningTable diningTable = requireDiningTable(param);
        ShoppingCart dbShoppingCart = shoppingCartService.selectByPrimaryKey(param.getId());
        verifyOwnership(dbShoppingCart, loginMember, diningTable);
        shoppingCartService.deleteByPrimaryKey(param.getId());
        return success("删除成功");
    }

    private DiningTable requireDiningTable(ShoppingCart shoppingCart){
        DiningTable diningTable = diningTableService.resolveActiveTable(shoppingCart.getSceneToken());
        if(diningTable == null){
            throw new StoneCustomerException("桌码无效或餐桌已停用，请重新扫码");
        }
        return diningTable;
    }

    private void applyDiningContext(ShoppingCart shoppingCart, DiningTable diningTable){
        shoppingCart.setShopId(diningTable.getShopId());
        shoppingCart.setDiningTableId(diningTable.getId());
    }

    private void verifyOwnership(ShoppingCart shoppingCart, Member member, DiningTable diningTable){
        if(shoppingCart == null || !Objects.equals(shoppingCart.getMemberId(), member.getId())
                || !Objects.equals(shoppingCart.getShopId(), diningTable.getShopId())
                || !Objects.equals(shoppingCart.getDiningTableId(), diningTable.getId())){
            throw new StoneCustomerException("购物车商品不属于当前用户或餐桌");
        }
    }

    private BasicResult success(String message){
        BasicResult result = new BasicResult();
        result.setSuccess(true);
        result.setCode(BasicResultCode.SUCCESS);
        result.setMessage(message);
        return result;
    }
}
