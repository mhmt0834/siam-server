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

创建订单只接收当前桌购物车 ID、`sceneToken` 和备注；`shopId`、桌号、商品、规格、数量、价格和金额均由服务端解析。微信支付接口不属于 Phase 2.1。
