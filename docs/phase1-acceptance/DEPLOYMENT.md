# Phase 1 部署说明

## 依赖

- JDK 8
- Maven 3.8+
- MySQL 8
- Redis
- MongoDB 4.4（与当前 Spring Data 驱动兼容）
- Node.js 及老板端构建依赖
- HBuilderX、微信开发者工具

## 服务端

1. 从 `application-local.example.yml` 复制实例配置到忽略提交的 `application-local.yml`。
2. 配置 MySQL、Redis、MongoDB；密钥只使用环境变量或实例私有配置。
3. 首次部署先导入 `sql/mysql/siam_db.sql`，再执行 `sql/mysql/update.sql`。
4. 升级部署只执行 `sql/mysql/update.sql`；可重复执行。
5. 构建：

```powershell
mvn -pl siam-system/system-provider -am -DskipTests package
```

6. 启动后检查 `/siam-server/actuator/health`，确认 MySQL、Redis、MongoDB 均正常。

## 客户端

1. 用户端 `utils/global-config.js` 的生产 API 必须替换为商家审核通过的 HTTPS 域名。
2. 使用 HBuilderX 编译 `uniapp-siam-user` 到微信小程序。
3. 老板端按现有 `vue-siam-shop` 构建流程产出静态文件。
4. 微信开发者工具检查场景启动、网络请求和 Console；上传前必须使用正式 AppID 真机扫描实际桌码。

## 模板与商家实例边界

公共模板只保存代码、结构、接口及占位配置。以下内容必须由每个商家独立填写，不同步回模板：

- 正式 AppID/AppSecret
- 微信支付商户号、APIv3 Key、证书和私钥
- HTTPS API 域名及服务器地址
- 地图 Key
- 商家名称、Logo、联系方式和隐私协议确认

平台不代收商家资金；支付配置按订单所属 `shop_id` 在服务端读取，敏感值加密保存且接口仅返回配置状态和掩码。
