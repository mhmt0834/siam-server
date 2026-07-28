<template>
	<view class="page">
		<!-- 品牌信息 -->
		<view class="brand-header">
			<view class="brand-mark">玉</view>
			<view class="brand-copy">
				<view class="brand-name">{{ brand.restaurantName }}</view>
				<view class="brand-slogan">{{ brand.slogan }}</view>
			</view>
		</view>

		<!-- 问候语 -->
		<view class="greeting-section">
			<view class="greeting-title">您好，欢迎光临 👋</view>
			<view class="greeting-subtitle">新鲜食材 · 精心烹饪 · 用心服务</view>
		</view>

		<view class="start-order-button" hover-class="start-order-button--pressed" @tap="businessTap" data-index="0">
			<text>开始点餐</text>
			<text class="start-order-arrow">›</text>
		</view>

		<!-- 四个快捷入口 -->
		<view class="quick-entries">
			<view class="quick-entry" hover-class="hover-class-public" @tap="businessTap" data-index="0">
				<view class="quick-entry-icon">
					<text class="quick-entry-symbol">⌂</text>
				</view>
				<text class="quick-entry-text">店内点餐</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="businessTap" data-index="1">
				<view class="quick-entry-icon">
					<text class="quick-entry-symbol">↗</text>
				</view>
				<text class="quick-entry-text">外卖配送</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="bindOrderInfo">
				<view class="quick-entry-icon">
					<text class="quick-entry-symbol">▤</text>
				</view>
				<text class="quick-entry-text">订单记录</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="isPromotionTap">
				<view class="quick-entry-icon">
					<text class="quick-entry-symbol">◇</text>
				</view>
				<text class="quick-entry-text">优惠活动</text>
			</view>
		</view>

		<!-- 推荐菜品 -->
		<view class="section-header" v-if="recommendGoodsList && recommendGoodsList.length">
			<view class="section-title">推荐菜品</view>
			<view class="section-more" @tap="businessTap" data-index="0">
				<text>查看更多</text>
				<text class="section-arrow">›</text>
			</view>
		</view>
		<view class="recommend-grid" v-if="recommendGoodsList && recommendGoodsList.length">
			<view class="recommend-item" v-for="(item, index) in recommendGoodsList" :key="index"
				hover-class="hover-class-public" @tap="commodityDetailTap" :data-id="item.goodsId"
				:data-shopid="item.shopId">
				<image :src="item.mainImage || '/static/assets/common/load-image.png'" mode="aspectFill"
					class="recommend-image" />
				<view class="recommend-info">
					<view class="recommend-name out_of_range one_row">{{ item.goodsName }}</view>
					<view class="recommend-bottom">
						<text class="price-accent">¥{{ item.goodsPrice }}</text>
						<view class="btn-add-circle" @tap.stop="openSpecifications" :data-goodsId="item.goodsId">＋</view>
					</view>
				</view>
			</view>
		</view>

		<!-- 优惠活动 -->
		<view class="section-header" v-if="promotionList && promotionList.length">
			<view class="section-title">优惠活动</view>
		</view>
		<view class="promotion-card" v-for="(rule, index) in promotionList" :key="index"
			v-if="promotionList && promotionList.length" @tap="businessTap" data-index="0">
			<view class="promotion-info">
				<view class="promotion-title">{{ rule.name }}</view>
				<view class="promotion-desc" v-if="rule.validityPeriod">有效期至 {{ rule.validityPeriod }}</view>
			</view>
			<view class="promotion-btn">去使用</view>
		</view>

		<!-- 活动弹窗 -->
		<van-action-sheet :show="isActivityDialog" @close="closeActivity" @cancel="closeActivity" title="优惠活动">
			<view slot="desc">
				<scroll-view style="height: 55vh" scroll-y>
					<view class="dialog-title">优惠：</view>
					<view class="business-discount-info">
						<view class="business-discount" @tap="isPromotionTap">
							<view class="theme-color-border business-discount-list" v-for="(rule, idx) in promotionList"
								:key="idx">
								{{ rule.name }}
							</view>
						</view>
					</view>
				</scroll-view>
			</view>
		</van-action-sheet>

		<!-- 规格弹窗 -->
		<van-action-sheet :show="specificationsDialog" @close="closeSpecifications" @cancel="closeSpecifications"
			title="选择规格">
			<view class="content">
				<view class="goods-info-view">
					<image :src="goodsInfo.mainImage" mode="aspectFill" class="commodity-image"></image>
					<view>
						<view class="goods-info-name">{{ goodsInfo.name }}</view>
						<view class="goods-info-specListString">已选：{{ specListString }}</view>
						<view class="goods-info-price price-accent">¥{{ priceAfter }}</view>
					</view>
				</view>
				<scroll-view scroll-y style="height: 50vh">
					<view class="commdity-name-type-view">
						<view class="commdity-type-item" v-for="(item, key) in specList" :key="key">
							<view class="commdity-type-name">{{ key }}</view>
							<radio-group class="radio-group" @change="radioChange" :data-firstIndex="key">
								<label :class="
									'group-label theme-border ' +
									(!item.stock ? 'disabled-group-label' : '') +
									' ' +
									(item.checked ? 'active theme-bg' : 'theme-color-border') +
									' out_of_range one_row'
								" v-for="(item, index) in item" :key="index">
									<radio :value="index" :checked="item.checked" :disabled="!item.stock" class="radio" />
									{{ item.name }}
								</label>
							</radio-group>
						</view>
						<view class="loading_box" v-if="specLoading&&specList.length==0">
							<van-loading custom-class="loading_box_class" vertical>加载中...</van-loading>
						</view>
						<van-empty v-if="!specLoading&&specList.length <= 0" description="暂无规格"></van-empty>
					</view>
				</scroll-view>
				<view slot="footer" class="position-sticky-bottom">
					<view class="good-choice-btn theme-bg" @tap="insertShoppingCart">我选好了</view>
				</view>
			</view>
		</van-action-sheet>

		<!-- 底部安全区 -->
		<view class="safe-area-bottom"></view>
	</view>
</template>

<script>
	import GlobalConfig from '../../utils/global-config';
	import BrandConfig from '../../utils/brand-config';
	import https from '../../utils/http';
	import authService from '../../utils/auth';
	import toastService from '../../utils/toast.service';
	let app = null;
	export default {
		data() {
			return {
				brand: BrandConfig,
				recommendGoodsList: [],
				promotionList: [],
				isActivityDialog: false,
				isLoading: true,
				// 规格弹窗相关
				specificationsDialog: false,
				specLoading: false,
				goodsId: '',
				goodsInfo: { mainImage: '', name: '' },
				specList: [],
				specListString: '',
				priceAfter: '',
			};
		},
		onLoad: function () {
			app = getApp();
			this.getRecommendGoods();
			this.getPromotionList();
		},
		onShow: function () {
			this.getRegeoInit();
		},
		onPullDownRefresh() {
			this.getRecommendGoods();
			this.getPromotionList();
			setTimeout(() => {
				uni.stopPullDownRefresh();
				uni.hideNavigationBarLoading();
			}, 1000);
		},
		methods: {
			getRegeoInit() {
				var addressInfo = app.globalData.deliveryAndSelfTaking.initRegeoInfo;
				app.globalData.deliveryAndSelfTaking.regeoInfo = addressInfo;
				app.globalData.deliveryAndSelfTaking.location = addressInfo.location;
			},

			businessTap(e) {
				var index = e.currentTarget.dataset.index;
				app.globalData.deliveryAndSelfTaking.selfOutActiveIndex = index;
				app.globalData.deliveryAndSelfTaking.ifIndexSwitchTab = true;
				app.globalData.deliveryAndSelfTaking.ifChooseBack = false;
				app.globalData.deliveryAndSelfTaking.ifChoosePayBack = false;
				uni.switchTab({
					url: `/pages/menu/index/index`
				});
			},

			searchBusinessTap() {
				uni.navigateTo({
					url: '../menu/search/search?location=' + app.globalData.deliveryAndSelfTaking.location
				});
			},

			commodityDetailTap(e) {
				uni.navigateTo({
					url: '../menu/detail/detail?id=' + e.currentTarget.dataset.id + '&shopId=' + e.currentTarget.dataset.shopid
				});
			},

			bindOrderInfo() {
				uni.navigateTo({
					url: '../order/index/index?currentTab=0&modeType=all&currentOrderTab=0'
				});
			},

			isPromotionTap() {
				this.isActivityDialog = !this.isActivityDialog;
			},

			closeActivity() {
				this.isActivityDialog = false;
			},

			getRecommendGoods() {
				https.request('/rest/goods/list', {
					pageNo: 1,
					pageSize: 3,
					isRecommend: 1
				}).then((result) => {
					if (result.success && result.data) {
						result.data.records.forEach((item) => {
							item.mainImage = item.mainImage ? GlobalConfig.ossUrl + item.mainImage : '';
						});
						this.recommendGoodsList = result.data.records;
					}
				});
			},

			getPromotionList() {
				https.request('/rest/fullReductionRule/list', {
					pageNo: -1,
					pageSize: 5
				}).then((result) => {
					if (result.success) {
						this.promotionList = result.data.records || [];
					}
				});
			},

			// 规格相关
			openSpecifications(e) {
				this.specificationsDialog = true;
				this.specLoading = true;
				this.goodsId = e.currentTarget.dataset.goodsid;
				this.getCommodityDetails(e.currentTarget.dataset.goodsid);
			},

			closeSpecifications() {
				this.specificationsDialog = false;
				this.specList = [];
				this.specLoading = false;
			},

			getCommodityDetails(id) {
				https.request('/rest/goods/selectById', {
					id: id,
					position: app.globalData.deliveryAndSelfTaking.location
				}).then((result) => {
					if (result.success && result.data) {
						result.data.mainImage = GlobalConfig.ossUrl + result.data.mainImage;
						this.goodsInfo = result.data;
						this.priceAfter = result.data.price;
						this.selectByGoodsId(id);
					}
				});
			},

			selectByGoodsId(goodsId) {
				https.request('/rest/goodsSpecificationOption/selectByGoodsId', {
					goodsId: goodsId
				}).then((result) => {
					if (result.success && result.data) {
						let specList = result.data;
						let price = this.goodsInfo.price;
						let specListString = '';
						for (let key in specList) {
							let isChecked = true;
							for (let keyof in specList[key]) {
								specList[key][keyof].checked = false;
								if (specList[key][keyof].stock == 1 && isChecked) {
									specList[key][keyof].checked = true;
									price = price + specList[key][keyof].price;
									specListString = (specListString ? specListString + '/' : specListString) + specList[key][keyof].name;
									isChecked = false;
								}
							}
						}
						this.specListString = specListString;
						this.specList = JSON.stringify(specList) == '{}' ? [] : specList;
						this.specLoading = false;
					}
				});
			},

			radioChange(e) {
				var checkValue = e.detail.value;
				let firstIndex = e.currentTarget.dataset.firstindex;
				let specList = this.specList;
				for (var j in specList[firstIndex]) {
					specList[firstIndex][j].checked = false;
				}
				specList[firstIndex][checkValue].checked = true;
				let price = this.goodsInfo.price;
				let specListString = '';
				for (let key in specList) {
					for (let keyof in specList[key]) {
						if (specList[key][keyof].checked) {
							price = price + specList[key][keyof].price;
							specListString = (specListString ? specListString + '/' : specListString) + specList[key][keyof].name;
						}
					}
				}
				this.specList = specList;
				this.specListString = specListString;
				this.priceAfter = price;
			},

			insertShoppingCart() {
				var _this = this;
				authService.checkIsLogin().then((result) => {
					toastService.showLoading();
					if (result) {
						let goodsSpecs = {};
						let specList = _this.specList;
						for (let key in specList) {
							for (let keyof in specList[key]) {
								if (specList[key][keyof].checked) {
									goodsSpecs[key] = specList[key][keyof].name;
								}
							}
						}
						toastService.hideLoading();
						https.request('/rest/member/shoppingCart/insert', {
							goodsId: _this.goodsId,
							specList: JSON.stringify(goodsSpecs),
							shopId: _this.recommendGoodsList[0] ? _this.recommendGoodsList[0].shopId : ''
						}).then((result) => {
							if (result.success) {
								_this.specificationsDialog = false;
								_this.specList = [];
								_this.specLoading = true;
								toastService.showSuccess('已加入购物车', false);
							}
						});
						return;
					}
					_this.specificationsDialog = false;
					toastService.hideLoading();
					app.globalData.checkIsAuth('scope.userInfo');
				});
			},
		}
	};
</script>
<style>
	page {
		width: 100%;
		background: #fff;
	}

	.page {
		min-height: 100vh;
		padding: calc(44rpx + env(safe-area-inset-top)) 40rpx 120rpx;
		box-sizing: border-box;
	}

	/* 品牌信息 */
	.brand-header {
		display: flex;
		align-items: center;
		padding: 10rpx 0 74rpx;
	}

	.brand-mark {
		width: 64rpx;
		height: 64rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: 50%;
		background: #050505;
		color: #fff;
		font-size: 30rpx;
		font-weight: 700;
	}

	.brand-copy {
		margin-left: 18rpx;
	}

	.brand-name {
		color: #0a0a0a;
		font-size: 30rpx;
		font-weight: 700;
		line-height: 1.25;
	}

	.brand-slogan {
		margin-top: 4rpx;
		color: #8a8a8a;
		font-size: 21rpx;
	}

	/* 问候语 */
	.greeting-section {
		padding: 0 0 52rpx;
	}

	.greeting-title {
		font-size: 42rpx;
		font-weight: 700;
		color: #090909;
		letter-spacing: -1rpx;
	}

	.greeting-subtitle {
		margin-top: 14rpx;
		font-size: 24rpx;
		color: #8c8c8c;
		letter-spacing: 1rpx;
	}

	.start-order-button {
		display: flex;
		justify-content: center;
		align-items: center;
		position: relative;
		height: 96rpx;
		margin-bottom: 58rpx;
		border-radius: 18rpx;
		background: #050505;
		color: #fff;
		font-size: 28rpx;
		font-weight: 700;
		box-shadow: 0 12rpx 30rpx rgba(0, 0, 0, 0.12);
	}

	.start-order-button--pressed {
		opacity: 0.82;
	}

	.start-order-arrow {
		position: absolute;
		right: 28rpx;
		top: 50%;
		transform: translateY(-54%);
		font-size: 42rpx;
		font-weight: 300;
	}

	/* 快捷入口 */
	.quick-entries {
		display: flex;
		justify-content: space-between;
		margin-bottom: 70rpx;
	}

	.quick-entry {
		display: flex;
		flex-direction: column;
		align-items: center;
		width: 22%;
	}

	.quick-entry-icon {
		width: 70rpx;
		height: 70rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 14rpx;
	}

	.quick-entry-symbol {
		font-size: 44rpx;
		color: #0a0a0a;
		font-weight: 500;
	}

	.quick-entry-text {
		font-size: 23rpx;
		color: #171717;
		font-weight: 500;
	}

	/* 分区标题 */
	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 20rpx;
		padding: 0 6rpx;
	}

	.section-title {
		font-size: 32rpx;
		font-weight: 700;
		color: #111;
	}

	.section-more {
		font-size: 24rpx;
		color: #858585;
		display: flex;
		align-items: center;
	}

	.section-arrow {
		font-size: 30rpx;
		margin-left: 4rpx;
	}

	/* 推荐菜品 grid */
	.recommend-grid {
		display: grid;
		grid-template-columns: 1fr 1fr 1fr;
		grid-column-gap: 14rpx;
		margin-bottom: 32rpx;
	}

	.recommend-item {
		background: #fff;
		border-radius: 14rpx;
		overflow: hidden;
		box-shadow: 0 4rpx 18rpx rgba(0, 0, 0, 0.06);
	}

	.recommend-image {
		width: 100%;
		height: 190rpx;
		display: block;
	}

	.recommend-info {
		padding: 14rpx 12rpx 18rpx;
	}

	.recommend-name {
		font-size: 24rpx;
		font-weight: 600;
		color: #111;
		margin-bottom: 12rpx;
	}

	.recommend-bottom {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.recommend-bottom .price-accent {
		font-size: 26rpx;
		color: #111;
	}

	.recommend-bottom .btn-add-circle {
		width: 40rpx;
		height: 40rpx;
		font-size: 26rpx;
		background: #050505;
	}

	/* 优惠卡片 */
	.promotion-card {
		display: flex;
		justify-content: space-between;
		align-items: center;
		background: #fff;
		border-radius: 16rpx;
		padding: 26rpx 24rpx;
		margin-bottom: 16rpx;
		box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.04);
	}

	.promotion-info {}

	.promotion-title {
		font-size: 28rpx;
		font-weight: 700;
		color: #111;
		margin-bottom: 6rpx;
	}

	.promotion-desc {
		font-size: 22rpx;
		color: #858585;
	}

	.promotion-btn {
		padding: 12rpx 24rpx;
		background: #050505;
		color: #fff;
		font-size: 24rpx;
		font-weight: 600;
		border-radius: 50rpx;
	}

	/* 活动弹窗 */
	.dialog-title {
		font-size: 28rpx;
		font-weight: 700;
		padding: 20rpx;
	}

	.business-discount-info {
		padding: 0 20rpx;
	}

	.business-discount {
		display: flex;
		flex-wrap: wrap;
		gap: 10rpx;
	}

	.business-discount-list {
		padding: 4rpx 12rpx;
		font-size: 22rpx;
		font-weight: 600;
		border-radius: 8rpx;
	}

	/* 规格弹窗 */
	.content {
		padding: 0 16px 16px 16px;
	}

	.goods-info-view {
		display: flex;
		padding: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.goods-info-view .commodity-image {
		width: 160rpx;
		height: 160rpx;
		border-radius: 12rpx;
		margin-right: 20rpx;
	}

	.goods-info-name {
		font-size: 30rpx;
		font-weight: 700;
		color: #111;
		margin-bottom: 8rpx;
	}

	.goods-info-specListString {
		font-size: 24rpx;
		color: #858585;
		margin-bottom: 10rpx;
	}

	.goods-info-price {
		font-size: 32rpx;
	}

	.commdity-name-type-view {
		padding: 20rpx;
	}

	.commdity-type-item {
		margin-bottom: 20rpx;
	}

	.commdity-type-name {
		font-size: 26rpx;
		font-weight: 600;
		color: #111;
		margin-bottom: 14rpx;
	}

	.radio-group {
		display: flex;
		flex-wrap: wrap;
		gap: 12rpx;
	}

	.group-label {
		padding: 10rpx 18rpx;
		font-size: 24rpx;
		border-radius: 8rpx;
	}

	.good-choice-btn {
		width: 100%;
		padding: 26rpx 0;
		text-align: center;
		font-size: 30rpx;
		font-weight: 700;
		border-radius: 50rpx;
		margin: 16rpx;
		width: calc(100% - 32rpx);
	}

	.safe-area-bottom {
		height: calc(100rpx + env(safe-area-inset-bottom));
	}
</style>
