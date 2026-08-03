# API 接口文档

统一前缀：`/siam-server`，请求格式为 JSON。

| 接口 | 用途 | 鉴权/隔离 |
| --- | --- | --- |
| `POST /rest/scan/resolve` | 解析 `sceneToken`，返回门店和餐桌 | 有效且启用的场景码 |
| `POST /rest/menu/listWithGoods` | 获取门店分类和菜品 | 使用扫码解析所得门店 |
| `POST /rest/member/shoppingCart/list` | 查询当前桌购物车 | 会员 Token + `sceneToken` |
| `POST /rest/member/shoppingCart/insert` | 加入购物车 | 会员 Token + `sceneToken` |
| `POST /rest/member/shoppingCart/updateNumber` | 修改数量 | 校验商品所属门店和餐桌 |
| `POST /rest/member/shoppingCart/delete` | 删除购物车项 | 校验商品所属门店和餐桌 |
| `POST /rest/member/order/insert` | 创建店内订单，服务端按购物车和商品现价重算金额 | 会员 Token + `sceneToken` |
| `POST /rest/member/order/list` | 查询当前会员订单 | 会员 Token |
| `POST /rest/member/order/selectById` | 查询当前会员订单详情 | 会员 Token + 订单归属 |
| `POST /rest/member/order/cancelOrder` | 取消未支付订单（状态 1→10） | 会员 Token + 订单归属 |
| `POST /rest/merchant/order/list` | 查询当前商家订单 | 商家 Token 推导 `shopId` |
| `POST /rest/merchant/order/updateStatus` | 接单/制作完成（2→3→6） | 商家 Token + 订单归属 + 合法前置状态 |
| `POST /rest/merchant/diningTable/list` | 当前商家餐桌 | 商家 Token |
| `POST /rest/merchant/diningTable/insert` | 新增餐桌 | 商家 Token |
| `POST /rest/merchant/diningTable/update` | 修改餐桌 | 商家 Token + 资源归属 |
| `POST /rest/merchant/diningTable/generateQr` | 获取场景和页面路径 | 商家 Token |
| `POST /rest/merchant/diningTable/regenerateScene` | 重置场景码 | 商家 Token |

创建订单只接收当前桌购物车 ID、`sceneToken` 和备注；`shopId`、桌号、商品、规格、数量、价格和金额均由服务端解析。

## Phase 2.2 微信支付 APIv3

- `POST /rest/member/wxPay/toPay4Applet`：会员只提交 `orderNo`。服务端校验订单归属、待支付状态，并根据订单 `shop_id` 读取商家支付配置及重算金额。
- `POST /rest/member/wxPay/notify/{callbackToken}`：生产支付回调。官方 SDK 验签、AES-GCM 解密并核验 AppID、商户号、订单号和金额；成功后幂等更新为待接单。
- `POST /rest/member/wxPay/notify`：无路由令牌的兼容回调，生产配置优先使用上一接口。
- `POST /rest/merchant/shopWechatConfig/detail`：返回是否配置、启用状态和掩码字段，不返回密钥或私钥。
- `POST /rest/merchant/shopWechatConfig/save`：按登录商家的 `shopId` 保存配置；空白敏感字段表示保留原值。

支付配置不接受前端 `shopId` 决定权限，资金直接进入当前订单所属商家的微信支付商户号。
