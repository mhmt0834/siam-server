package com.siam.system.modular.package_user.controller.admin;

import com.siam.package_common.annoation.AdminPermission;
import com.siam.package_common.entity.BasicResult;
import com.siam.system.modular.package_user.model.param.MerchantInitializationParam;
import com.siam.system.modular.package_user.service.MerchantService;
import com.siam.system.modular.package_user.service_impl.MerchantInitializationService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "/rest/admin/merchant")
@Transactional(rollbackFor = Exception.class)
@Api(tags = "后台商家账号模块相关接口", description = "AdminMerchantController")
public class AdminMerchantController {

    @Autowired
    private MerchantService merchantService;

    @Autowired
    private MerchantInitializationService merchantInitializationService;

    @AdminPermission
    @ApiOperation(value = "创建商家并初始化店铺")
    @PostMapping(value = "/initialize")
    public BasicResult initialize(@RequestBody MerchantInitializationParam param) {
        return BasicResult.success(merchantInitializationService.initialize(param));
    }
}
