package com.siam.system.modular.package_goods.controller.merchant;

import com.siam.package_common.entity.BasicResult;
import com.siam.system.modular.package_goods.model.param.StatisticsParam;
import com.siam.system.modular.package_goods.service.StatisticsService;
import com.siam.system.modular.package_goods.service_impl.MerchantBusinessStatisticsService;
import io.swagger.annotations.Api;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping(value = "/rest/merchant/statistics")
@Transactional(rollbackFor = Exception.class)
@Api(tags = "后台统计模块相关接口", description = "AdminAdvertisementController")
public class MerchantStatisticsController {

    @Autowired
    private StatisticsService statisticsService;

    @Autowired
    private MerchantBusinessStatisticsService businessStatisticsService;

    /**
     * 今日数据实时统计
     *
     * @author 暹罗
     */
    @PostMapping(value = "/todayStatistic")
    public BasicResult todayStatistic(@RequestBody @Validated(value = {}) StatisticsParam param) {
        Map result = statisticsService.todayStatisticByMerchant(param);
        return BasicResult.success(result);
    }

    @PostMapping(value = "/today")
    public BasicResult today() {
        return BasicResult.success(businessStatisticsService.today());
    }

    @PostMapping(value = "/trend")
    public BasicResult trend(@RequestBody(required = false) StatisticsParam param) {
        return BasicResult.success(businessStatisticsService.trend(param == null ? null : param.getRange()));
    }

    @PostMapping(value = "/hotGoods")
    public BasicResult hotGoods(@RequestBody(required = false) StatisticsParam param) {
        return BasicResult.success(businessStatisticsService.hotGoods(param == null ? null : param.getRange()));
    }

    @PostMapping(value = "/goodsAnalysis")
    public BasicResult goodsAnalysis(@RequestBody(required = false) StatisticsParam param) {
        return BasicResult.success(businessStatisticsService.goodsAnalysis(param == null ? null : param.getRange()));
    }
}
