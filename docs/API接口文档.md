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
| `POST /rest/merchant/diningTable/list` | 当前商家餐桌 | 商家 Token |
| `POST /rest/merchant/diningTable/insert` | 新增餐桌 | 商家 Token |
| `POST /rest/merchant/diningTable/update` | 修改餐桌 | 商家 Token + 资源归属 |
| `POST /rest/merchant/diningTable/generateQr` | 获取场景和页面路径 | 商家 Token |
| `POST /rest/merchant/diningTable/regenerateScene` | 重置场景码 | 商家 Token |

请求及返回字段详见 [Phase 1 API](phase1-acceptance/API.md)。微信支付接口不属于本版本。
