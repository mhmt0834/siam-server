<template>
	<view class="home-page ui-page">
		<view class="home-shell">
			<app-header
				:logo="headerLogo"
				:title="brand.restaurantName"
				:subtitle="brand.slogan"
				status-text="营业中"
			/>

			<view class="hero-card ui-card">
				<view class="hero-kicker">纯净 / 克制 / 高级</view>
				<view class="hero-title">您好，欢迎光临 👋</view>
				<view class="hero-desc">精选食材 · 现做现卖 · 用心服务</view>
				<primary-button class="hero-button" text="扫码点餐" @tap="enterMenu" />
			</view>

			<view class="quick-grid">
				<view
					v-for="item in quickEntries"
					:key="item.key"
					class="quick-item ui-card"
					hover-class="quick-item--pressed"
					@tap="handleQuickTap(item.key)"
				>
					<view class="quick-icon">
						<text class="quick-icon__text">{{ item.short }}</text>
					</view>
					<text class="quick-title">{{ item.title }}</text>
				</view>
			</view>

			<view class="section-head">
				<view>
					<view class="ui-section-title">推荐菜品</view>
					<view class="ui-section-subtitle">新疆风味 · 真实摄影 · 产品级呈现</view>
				</view>
				<view class="section-link" @tap="enterMenu">
					<text>查看全部</text>
					<text class="section-link__arrow">›</text>
				</view>
			</view>

			<view v-if="isLoading" class="loading-box ui-card">
				<text class="loading-box__text">加载中...</text>
			</view>

			<scroll-view
				v-else-if="recommendGoodsList.length > 0"
				class="food-scroll"
				scroll-x
				:show-scrollbar="false"
			>
				<view class="food-scroll__inner">
					<food-card
						v-for="item in recommendGoodsList"
						:key="item.goodsId"
						class="food-scroll__item"
						layout="stack"
						:item="item"
						@tap="openGoodsDetail(item)"
						@add="openSpecifications(item)"
					/>
				</view>
			</scroll-view>

			<empty-state
				v-else
				title="暂无推荐菜品"
				desc="请稍后刷新，或者直接进入菜单浏览全部商品"
				action-text="去菜单看看"
				@action="enterMenu"
			/>
		</view>

		<view v-if="specificationsDialog" class="spec-overlay" @tap="closeSpecifications">
			<view class="spec-sheet ui-card" @tap.stop>
				<view class="spec-sheet__head">
					<text class="spec-sheet__title">选择规格</text>
					<text class="spec-sheet__close" @tap="closeSpecifications">×</text>
				</view>

				<view class="spec-preview ui-card">
					<image :src="goodsInfo.mainImage" mode="aspectFill" class="spec-preview__image" />
					<view class="spec-preview__copy">
						<view class="spec-preview__title">{{ goodsInfo.name }}</view>
						<view class="spec-preview__desc">已选：{{ specListString || '默认规格' }}</view>
						<view class="spec-preview__price">¥{{ priceAfter }}</view>
					</view>
				</view>

				<scroll-view scroll-y class="spec-scroll">
					<view class="spec-list">
						<view v-for="(group, key) in specList" :key="key" class="spec-group">
							<view class="spec-group__title">{{ key }}</view>
							<radio-group class="spec-options" @change="radioChange" :data-first-index="key">
								<label
									v-for="(option, index) in group"
									:key="index"
									:class="[
										'spec-option',
										option.checked ? 'spec-option--active' : '',
										!option.stock ? 'spec-option--disabled' : ''
									]"
								>
									<radio :value="index" :checked="option.checked" :disabled="!option.stock" />
									<text class="spec-option__text">{{ option.name }}</text>
								</label>
							</radio-group>
						</view>

						<view v-if="specLoading" class="spec-loading">加载中...</view>
						<empty-state
							v-else-if="!specLoading && specList.length <= 0"
							title="暂无规格"
							desc="当前商品没有可选规格"
						/>
					</view>
				</scroll-view>

				<primary-button text="加入购物车" @tap="insertShoppingCart" />
			</view>
		</view>

		<view class="ui-safe-bottom"></view>
	</view>
</template>

<script>
import GlobalConfig from '../../utils/global-config';
import BrandConfig from '../../utils/brand-config';
import https from '../../utils/http';
import authService from '../../utils/auth';
import toastService from '../../utils/toast.service';
import AppHeader from '../../components/ui/app-header.vue';
import PrimaryButton from '../../components/ui/primary-button.vue';
import FoodCard from '../../components/ui/food-card.vue';
import EmptyState from '../../components/ui/empty-state.vue';

let app = null;

export default {
	components: {
		AppHeader,
		PrimaryButton,
		FoodCard,
		EmptyState
	},
	data() {
		return {
			brand: BrandConfig,
			headerLogo: '/static/assets/images/logo.png',
			quickEntries: [
				{ key: 'scan', title: '扫码点餐', short: '扫' },
				{ key: 'dinein', title: '店内就餐', short: '店' },
				{ key: 'orders', title: '我的订单', short: '订' }
			],
			recommendGoodsList: [],
			isLoading: true,
			specificationsDialog: false,
			specLoading: false,
			goodsId: '',
			goodsInfo: {
				mainImage: '',
				name: '',
				price: 0
			},
			specList: [],
			specListString: '',
			priceAfter: 0
		};
	},
	onLoad() {
		app = getApp();
		this.getRecommendGoods();
	},
	onPullDownRefresh() {
		this.getRecommendGoods();
		setTimeout(() => {
			uni.stopPullDownRefresh();
			uni.hideNavigationBarLoading();
		}, 600);
	},
	methods: {
		enterMenu() {
			app.globalData.deliveryAndSelfTaking.selfOutActiveIndex = 0;
			app.globalData.deliveryAndSelfTaking.ifIndexSwitchTab = true;
			app.globalData.deliveryAndSelfTaking.ifChooseBack = false;
			app.globalData.deliveryAndSelfTaking.ifChoosePayBack = false;
			uni.switchTab({
				url: '/pages/menu/index/index'
			});
		},
		enterOrders() {
			uni.switchTab({
				url: '/pages/order/index/index'
			});
		},
		handleQuickTap(key) {
			if (key === 'orders') {
				this.enterOrders();
				return;
			}
			this.enterMenu();
		},
		openGoodsDetail(item) {
			uni.navigateTo({
				url: `/pages/menu/detail/detail?id=${item.goodsId}&shopId=${item.shopId || GlobalConfig.defaultShopId}`
			});
		},
		getRecommendGoods() {
			this.isLoading = true;
			https.request('/rest/goods/homePage/recommendGoodsList', {
				position: app.globalData.deliveryAndSelfTaking.location || app.globalData.deliveryAndSelfTaking.initRegeoInfo.location
			}).then((result) => {
				this.isLoading = false;
				if (result.success && result.data) {
					this.recommendGoodsList = (result.data || []).map((item) => ({
						...item,
						mainImage: item.mainImage ? GlobalConfig.ossUrl + item.mainImage : ''
					}));
				}
			});
		},
		openSpecifications(item) {
			this.goodsId = item.goodsId;
			this.specificationsDialog = true;
			this.specLoading = true;
			this.getCommodityDetails(item.goodsId);
		},
		closeSpecifications() {
			this.specificationsDialog = false;
			this.specLoading = false;
			this.specList = [];
			this.specListString = '';
		},
		getCommodityDetails(id) {
			https.request('/rest/goods/selectById', {
				id: id,
				position: app.globalData.deliveryAndSelfTaking.location
			}).then((result) => {
				if (result.success && result.data) {
					result.data.mainImage = result.data.mainImage ? GlobalConfig.ossUrl + result.data.mainImage : '';
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
					const specList = result.data;
					let price = this.goodsInfo.price;
					let specListString = '';
					for (const key in specList) {
						let isChecked = true;
						for (const optionKey in specList[key]) {
							specList[key][optionKey].checked = false;
							if (specList[key][optionKey].stock == 1 && isChecked) {
								specList[key][optionKey].checked = true;
								price += specList[key][optionKey].price;
								specListString = (specListString ? `${specListString}/` : '') + specList[key][optionKey].name;
								isChecked = false;
							}
						}
					}
					this.specListString = specListString;
					this.specList = JSON.stringify(specList) === '{}' ? [] : specList;
					this.priceAfter = price;
					this.specLoading = false;
				}
			});
		},
		radioChange(e) {
			const checkValue = e.detail.value;
			const firstIndex = e.currentTarget.dataset.firstIndex;
			const specList = this.specList;
			for (const key in specList[firstIndex]) {
				specList[firstIndex][key].checked = false;
			}
			specList[firstIndex][checkValue].checked = true;

			let price = this.goodsInfo.price;
			let specListString = '';
			for (const groupKey in specList) {
				for (const optionKey in specList[groupKey]) {
					if (specList[groupKey][optionKey].checked) {
						price += specList[groupKey][optionKey].price;
						specListString = (specListString ? `${specListString}/` : '') + specList[groupKey][optionKey].name;
					}
				}
			}
			this.specList = specList;
			this.specListString = specListString;
			this.priceAfter = price;
		},
		insertShoppingCart() {
			authService.checkIsLogin().then((result) => {
				toastService.showLoading();
				if (result) {
					const goodsSpecs = {};
					const specList = this.specList;
					for (const key in specList) {
						for (const optionKey in specList[key]) {
							if (specList[key][optionKey].checked) {
								goodsSpecs[key] = specList[key][optionKey].name;
							}
						}
					}
					toastService.hideLoading();
					https.request('/rest/member/shoppingCart/insert', {
						goodsId: this.goodsId,
						specList: JSON.stringify(goodsSpecs),
						shopId: this.recommendGoodsList[0] ? this.recommendGoodsList[0].shopId : GlobalConfig.defaultShopId
					}).then((result) => {
						if (result.success) {
							this.closeSpecifications();
							toastService.showSuccess('已加入购物车', false);
						}
					});
					return;
				}
				this.closeSpecifications();
				toastService.hideLoading();
				app.globalData.checkIsAuth('scope.userInfo');
			});
		}
	}
};
</script>

<style>
page {
	background: #f7f7f7;
}

.home-page {
	min-height: 100vh;
}

.home-shell {
	padding: calc(32rpx + env(safe-area-inset-top)) 40rpx 24rpx;
}

.hero-card {
	margin-top: 32rpx;
	padding: 32rpx;
}

.hero-kicker {
	font-size: 22rpx;
	color: #666;
	letter-spacing: 2rpx;
}

.hero-title {
	margin-top: 16rpx;
	font-size: 42rpx;
	line-height: 1.2;
	font-weight: 600;
	color: #000;
}

.hero-desc {
	margin-top: 12rpx;
	font-size: 24rpx;
	line-height: 1.4;
	color: #666;
}

.hero-button {
	margin-top: 28rpx;
}

.quick-grid {
	display: flex;
	gap: 16rpx;
	margin-top: 24rpx;
}

.quick-item {
	flex: 1;
	padding: 24rpx 16rpx;
	text-align: center;
}

.quick-item--pressed {
	opacity: 0.72;
}

.quick-icon {
	width: 68rpx;
	height: 68rpx;
	border-radius: 50%;
	border: 1rpx solid #eaeaea;
	display: flex;
	align-items: center;
	justify-content: center;
	margin: 0 auto 14rpx;
	color: #000;
}

.quick-icon__text {
	font-size: 30rpx;
	font-weight: 600;
}

.quick-title {
	display: block;
	font-size: 24rpx;
	line-height: 1.4;
	color: #000;
	font-weight: 500;
}

.section-head {
	display: flex;
	align-items: flex-end;
	justify-content: space-between;
	margin-top: 40rpx;
	margin-bottom: 18rpx;
}

.section-link {
	display: inline-flex;
	align-items: center;
	color: #666;
	font-size: 24rpx;
}

.section-link__arrow {
	margin-left: 8rpx;
	font-size: 30rpx;
	line-height: 1;
}

.food-scroll {
	width: 100%;
	white-space: nowrap;
}

.food-scroll__inner {
	display: inline-flex;
	gap: 16rpx;
	padding-bottom: 8rpx;
}

.food-scroll__item {
	display: inline-flex;
	vertical-align: top;
}

.loading-box {
	padding: 64rpx 24rpx;
	text-align: center;
}

.loading-box__text {
	color: #000;
}

.spec-overlay {
	position: fixed;
	left: 0;
	top: 0;
	right: 0;
	bottom: 0;
	background: rgba(0, 0, 0, 0.42);
	display: flex;
	align-items: flex-end;
	z-index: 999;
}

.spec-sheet {
	width: 100%;
	padding: 24rpx;
	border-radius: 24rpx 24rpx 0 0;
	background: #fff;
	max-height: 86vh;
	box-sizing: border-box;
}

.spec-sheet__head {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 16rpx;
}

.spec-sheet__title {
	font-size: 30rpx;
	font-weight: 600;
	color: #000;
}

.spec-sheet__close {
	width: 48rpx;
	height: 48rpx;
	border-radius: 50%;
	background: #f5f5f5;
	color: #000;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32rpx;
	line-height: 1;
}

.spec-preview {
	display: flex;
	align-items: center;
	padding: 20rpx;
}

.spec-preview__image {
	width: 160rpx;
	height: 160rpx;
	border-radius: 12rpx;
	flex-shrink: 0;
	background: #f7f7f7;
}

.spec-preview__copy {
	margin-left: 20rpx;
	flex: 1;
}

.spec-preview__title {
	font-size: 30rpx;
	line-height: 1.3;
	font-weight: 600;
	color: #000;
}

.spec-preview__desc {
	margin-top: 8rpx;
	font-size: 24rpx;
	color: #666;
}

.spec-preview__price {
	margin-top: 10rpx;
	font-size: 32rpx;
	font-weight: 600;
	color: #000;
}

.spec-scroll {
	max-height: 46vh;
	margin-top: 16rpx;
}

.spec-list {
	padding: 4rpx 0 0;
}

.spec-group {
	margin-bottom: 24rpx;
}

.spec-group__title {
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
	margin-bottom: 14rpx;
}

.spec-options {
	display: flex;
	flex-wrap: wrap;
	gap: 12rpx;
}

.spec-option {
	display: inline-flex;
	align-items: center;
	gap: 8rpx;
	padding: 14rpx 18rpx;
	border-radius: 14rpx;
	border: 1rpx solid #eaeaea;
	background: #fff;
	font-size: 24rpx;
	color: #000;
}

.spec-option--active {
	background: #000;
	border-color: #000;
	color: #fff;
}

.spec-option--disabled {
	opacity: 0.45;
}

.spec-option__text {
	line-height: 1;
}

.spec-loading {
	padding: 36rpx 0;
	text-align: center;
	color: #666;
}
</style>
