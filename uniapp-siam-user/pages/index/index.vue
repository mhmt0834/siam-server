<template>
	<view class="page page-bg-warm">
		<!-- 问候语 -->
		<view class="greeting-section">
			<view class="greeting-title">您好，欢迎光临 👋</view>
			<view class="greeting-subtitle">美味佳肴 · 优质服务</view>
		</view>

		<!-- 搜索条 -->
		<view class="search-bar" @tap="searchBusinessTap">
			<view class="search-bar-inner">
				<text class="search-icon">🔍</text>
				<text class="search-placeholder">搜索菜品</text>
			</view>
		</view>

		<!-- Banner轮播 -->
		<swiper v-if="carouselUrls.length" :indicator-dots="true" class="home-banner" :autoplay="autoplay"
			:interval="interval" :duration="duration" indicator-active-color="#4A2605" indicator-color="rgba(255,255,255,0.5)">
			<block v-for="(item, index) in carouselUrls" :key="index">
				<swiper-item class="banner-item">
					<view class="banner-card">
						<view class="banner-text-area">
							<view class="banner-tag">新疆风味 · 串串飘香</view>
							<view class="banner-title">精选羊肉串</view>
							<view class="banner-desc">肉质鲜嫩 · 香味浓郁</view>
							<view class="banner-btn" @tap.stop="businessTap" data-index="0">立即点餐</view>
						</view>
						<image :src="item.imagePath" class="banner-image" mode="aspectFill" />
					</view>
				</swiper-item>
			</block>
		</swiper>

		<!-- 四个快捷入口 -->
		<view class="quick-entries">
			<view class="quick-entry" hover-class="hover-class-public" @tap="businessTap" data-index="0">
				<view class="quick-entry-icon">
					<text class="quick-entry-emoji">🍽️</text>
				</view>
				<text class="quick-entry-text">店内点餐</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="businessTap" data-index="1">
				<view class="quick-entry-icon">
					<text class="quick-entry-emoji">🛵</text>
				</view>
				<text class="quick-entry-text">外卖点餐</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="isPromotionTap">
				<view class="quick-entry-icon">
					<text class="quick-entry-emoji">🎫</text>
				</view>
				<text class="quick-entry-text">优惠活动</text>
			</view>
			<view class="quick-entry" hover-class="hover-class-public" @tap="bindOrderInfo">
				<view class="quick-entry-icon">
					<text class="quick-entry-emoji">📋</text>
				</view>
				<text class="quick-entry-text">我的订单</text>
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
				autoplay: true,
				interval: 5000,
				duration: 1000,
				carouselUrls: [],
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
			this.getCarouselList();
			this.getRecommendGoods();
			this.getPromotionList();
		},
		onShow: function () {
			this.getRegeoInit();
		},
		onPullDownRefresh() {
			this.getCarouselList();
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

			getCarouselList() {
				https.request('/rest/advertisement/list', {
					type: 1,
					pageNo: -1,
					pageSize: 20
				}).then((result) => {
					if (result.success) {
						result.data.records.forEach(function (item) {
							item.imagePath = GlobalConfig.ossUrl + item.imagePath;
						});
						this.carouselUrls = result.data.records;
					}
				});
			},

			getRecommendGoods() {
				https.request('/rest/goods/list', {
					pageNo: 1,
					pageSize: 6,
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
		background: #F8F6F2;
	}

	.page {
		min-height: 100vh;
		padding: 0 24rpx 120rpx;
		box-sizing: border-box;
	}

	/* 问候语 */
	.greeting-section {
		padding: 40rpx 10rpx 20rpx;
	}

	.greeting-title {
		font-size: 40rpx;
		font-weight: 700;
		color: #2D1A08;
	}

	.greeting-subtitle {
		margin-top: 10rpx;
		font-size: 26rpx;
		color: #9A9A8E;
	}

	/* 搜索条 */
	.search-bar {
		margin: 10rpx 0 24rpx;
	}

	.search-bar-inner {
		display: flex;
		align-items: center;
		background: #F0EDE6;
		border-radius: 50rpx;
		padding: 22rpx 28rpx;
	}

	.search-icon {
		font-size: 28rpx;
		margin-right: 14rpx;
	}

	.search-placeholder {
		font-size: 28rpx;
		color: #B5B0A4;
	}

	/* Banner */
	.home-banner {
		height: 340rpx;
		margin-bottom: 28rpx;
		border-radius: 24rpx;
		overflow: hidden;
	}

	.banner-item {
		height: 100%;
	}

	.banner-card {
		display: flex;
		height: 100%;
		background: linear-gradient(135deg, #3D1F08 0%, #5C3414 100%);
		border-radius: 24rpx;
		overflow: hidden;
	}

	.banner-text-area {
		flex: 1;
		padding: 36rpx 30rpx;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}

	.banner-tag {
		font-size: 22rpx;
		color: #F5C89A;
		margin-bottom: 10rpx;
	}

	.banner-title {
		font-size: 38rpx;
		font-weight: 800;
		color: #FFF;
		margin-bottom: 8rpx;
	}

	.banner-desc {
		font-size: 22rpx;
		color: rgba(255, 255, 255, 0.7);
		margin-bottom: 24rpx;
	}

	.banner-btn {
		display: inline-block;
		width: 160rpx;
		padding: 14rpx 0;
		background: #FFF9F2;
		color: #4A2605;
		font-size: 24rpx;
		font-weight: 700;
		border-radius: 50rpx;
		text-align: center;
	}

	.banner-image {
		width: 280rpx;
		height: 100%;
		border-radius: 0 24rpx 24rpx 0;
	}

	/* 快捷入口 */
	.quick-entries {
		display: flex;
		justify-content: space-between;
		margin-bottom: 32rpx;
	}

	.quick-entry {
		display: flex;
		flex-direction: column;
		align-items: center;
		width: 22%;
	}

	.quick-entry-icon {
		width: 100rpx;
		height: 100rpx;
		border-radius: 24rpx;
		background: #F0EBE0;
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 12rpx;
	}

	.quick-entry-emoji {
		font-size: 44rpx;
	}

	.quick-entry-text {
		font-size: 24rpx;
		color: #5C4A3A;
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
		color: #2D1A08;
	}

	.section-more {
		font-size: 24rpx;
		color: #9A9A8E;
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
		border-radius: 16rpx;
		overflow: hidden;
		box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.04);
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
		color: #2D1A08;
		margin-bottom: 12rpx;
	}

	.recommend-bottom {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.recommend-bottom .price-accent {
		font-size: 26rpx;
	}

	.recommend-bottom .btn-add-circle {
		width: 40rpx;
		height: 40rpx;
		font-size: 26rpx;
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
		color: #2D1A08;
		margin-bottom: 6rpx;
	}

	.promotion-desc {
		font-size: 22rpx;
		color: #9A9A8E;
	}

	.promotion-btn {
		padding: 12rpx 24rpx;
		background: #F05A2A;
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
		color: #2D1A08;
		margin-bottom: 8rpx;
	}

	.goods-info-specListString {
		font-size: 24rpx;
		color: #9A9A8E;
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
		color: #2D1A08;
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
