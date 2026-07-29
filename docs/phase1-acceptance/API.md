# Phase 1 API

统一前缀：`/siam-server`。请求使用 JSON；老板端接口必须携带登录 Token，服务端从 Token 获取商家及 `shopId`，不信任请求体中的 `shopId`。

## 用户端

### `POST /rest/scan/resolve`

请求：

```json
{"sceneToken":"<scene-token>"}
```

成功返回：`shopId`、`shopName`、`shopLogoImg`、`isOperating`、`tableId`、`tableNo`、`tableName`、`sceneToken`。

### `POST /rest/menu/listWithGoods`

请求：`{"shopId":15}`。返回当前门店分类及菜品；扫码后使用解析结果中的 `shopId`。

### 购物车

| 接口 | 用途 | 关键请求字段 |
| --- | --- | --- |
| `POST /rest/member/shoppingCart/list` | 当前桌购物车 | `sceneToken,pageNo,pageSize` |
| `POST /rest/member/shoppingCart/insert` | 加入购物车 | `sceneToken,goodsId,number` |
| `POST /rest/member/shoppingCart/updateNumber` | 修改数量 | `sceneToken,id,number` |
| `POST /rest/member/shoppingCart/delete` | 删除商品 | `sceneToken,id` |

服务端根据会员 Token 和 `sceneToken` 绑定并校验 `member_id + shop_id + dining_table_id`；禁止跨门店、跨桌更新。

## 老板端餐桌

| 接口 | 用途 | 关键请求字段 |
| --- | --- | --- |
| `POST /rest/merchant/diningTable/list` | 当前商家餐桌分页 | `pageNo,pageSize` |
| `POST /rest/merchant/diningTable/insert` | 新增餐桌 | `tableNo,tableName,status` |
| `POST /rest/merchant/diningTable/update` | 修改餐桌 | `id,tableNo,tableName,status` |
| `POST /rest/merchant/diningTable/generateQr` | 获取场景和页面路径 | `id` |
| `POST /rest/merchant/diningTable/regenerateScene` | 重置场景码 | `id` |

`generateQr` 当前返回：`tableId`、`tableNo`、`tableName`、`sceneToken`、`pagePath`、`qrCodeUrl`。生产小程序码图片必须由后端使用对应商家微信配置生成，前端不得接触 AppSecret 或密钥。

## 隔离规则

1. 老板端 `shopId` 只能从登录 Token 对应商家取得。
2. 任何按主键修改操作必须同时校验资源所属 `shop_id`。
3. 用户购物车由会员 Token 和有效餐桌场景共同确定上下文。
4. 停用餐桌不可解析，场景码重置后旧码立即失效。
