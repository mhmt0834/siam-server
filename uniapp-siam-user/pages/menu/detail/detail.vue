<template>
	<view class="ui-page detail-page">
		<view class="hero">
			<swiper
				v-if="carouselUrls.length"
				class="hero-swiper"
				:indicator-dots="carouselUrls.length > 1"
				indicator-color="rgba(255,255,255,.45)"
				indicator-active-color="#ffffff"
			>
				<swiper-item v-for="(item, index) in carouselUrls" :key="index">
					<image class="hero-image" :src="item" mode="aspectFill" />
				</swiper-item>
			</swiper>
			<view v-else class="hero-placeholder">暂无图片</view>

			<view class="hero-action back" @tap="goBack">←</view>
			<view class="hero-action favorite" :class="{ active: isCollect }" @tap="toggleCollect">
				{{ isCollect ? '♥' : '♡' }}
			</view>
		</view>

		<view class="content">
			<view class="heading">
				<view class="title-group">
					<text class="title">{{ goods.name || '菜品详情' }}</text>
					<text class="subtitle">精选食材 · 现做现卖</text>
				</view>
				<text class="price">¥{{ displayPrice }}</text>
			</view>

			<view class="ui-card description-card">
				<text class="section-title">菜品介绍</text>
				<text class="description">{{ goods.detail || '严选新鲜食材，用心烹制每一道菜。' }}</text>
			</view>

			<view v-if="specGroups.length" class="ui-card specification-card">
				<view v-for="group in specGroups" :key="group.name" class="spec-group">
					<text class="section-title">{{ group.name }}</text>
					<view class="spec-options">
						<view
							v-for="(option, index) in group.options"
							:key="option.name"
							class="spec-option"
							:class="{ active: option.checked, disabled: !option.stock }"
							@tap="selectSpecification(group.name, index)"
						>
							{{ option.name }}
						</view>
					</view>
				</view>
			</view>

			<view class="ui-card quantity-card">
				<view>
					<text class="section-title">数量</text>
					<text class="quantity-hint">按实际用餐人数选择</text>
				</view>
				<view class="stepper">
					<view class="step-button" :class="{ disabled: quantity <= 1 }" @tap="changeQuantity(-1)">−</view>
					<text class="quantity">{{ quantity }}</text>
					<view class="step-button dark" @tap="changeQuantity(1)">＋</view>
				</view>
			</view>
		</view>

		<view class="bottom-action ui-safe-bottom">
			<view class="total">
				<text class="total-label">合计</text>
				<text class="total-price">¥{{ totalPrice }}</text>
			</view>
			<primary-button class="add-button" :disabled="submitting || goods.goodsStatus == 4" @tap="addToCart">
				{{ goods.goodsStatus == 4 ? '已售罄' : submitting ? '加入中…' : '加入购物车' }}
			</primary-button>
		</view>
	</view>
</template>

<script>
import GlobalConfig from '../../../utils/global-config';
import https from '../../../utils/http';
import authService from '../../../utils/auth';
import toastService from '../../../utils/toast.service';
import utilHelper from '../../../utils/util';
import PrimaryButton from '../../../components/ui/primary-button.vue';

let app = null;

export default {
	components: {
		PrimaryButton
	},
	data() {
		return {
			goodsId: '',
			shopId: '',
			carouselUrls: [],
			goods: {
				id: '',
				name: '',
				price: 0,
				detail: '',
				mainImage: '',
				goodsStatus: 1
			},
			specList: {},
			quantity: 1,
			selectedPrice: 0,
			isCollect: false,
			collectInfo: null,
			submitting: false
		};
	},
	computed: {
		specGroups() {
			return Object.keys(this.specList || {}).map((name) => ({
				name,
				options: this.specList[name]
			}));
		},
		displayPrice() {
			return utilHelper.toFixed(Number(this.selectedPrice || this.goods.price || 0), 2);
		},
		totalPrice() {
			return utilHelper.toFixed(Number(this.displayPrice) * this.quantity, 2);
		}
	},
	onLoad(options) {
		app = getApp();
		this.goodsId = options.id || '';
		this.shopId = options.shopId || '';
		if (!this.goodsId) {
			toastService.showError('商品信息不存在');
			return;
		}
		this.getCommodityDetails();
		this.getGoodsCollect();
	},
	methods: {
		goBack() {
			uni.navigateBack();
		},
		getCommodityDetails() {
			const delivery = app.globalData.deliveryAndSelfTaking || {};
			https.request('/rest/goods/selectById', {
				id: this.goodsId,
				position: delivery.location
			}).then((result) => {
				if (!result.success || !result.data) return;
				const goods = result.data;
				const imageList = goods.subImages ? goods.subImages.split(',').filter(Boolean) : [];
				this.carouselUrls = imageList.map((url) => GlobalConfig.ossUrl + url);
				if (!this.carouselUrls.length && goods.mainImage) {
					this.carouselUrls = [GlobalConfig.ossUrl + goods.mainImage];
				}
				goods.mainImage = goods.mainImage ? GlobalConfig.ossUrl + goods.mainImage : '';
				this.goods = goods;
				this.selectedPrice = Number(goods.price || 0);
				this.getSpecifications();
			});
		},
		getSpecifications() {
			https.request('/rest/goodsSpecificationOption/selectByGoodsId', {
				goodsId: this.goodsId
			}).then((result) => {
				const specList = result.success && result.data ? result.data : {};
				Object.keys(specList).forEach((key) => {
					let selected = false;
					specList[key].forEach((option) => {
						option.checked = !selected && Number(option.stock) > 0;
						if (option.checked) selected = true;
					});
				});
				this.specList = specList;
				this.calculatePrice();
			});
		},
		selectSpecification(groupName, index) {
			const group = this.specList[groupName];
			if (!group || !group[index] || !group[index].stock) return;
			group.forEach((option, optionIndex) => {
				option.checked = optionIndex === index;
			});
			this.specList = Object.assign({}, this.specList);
			this.calculatePrice();
		},
		calculatePrice() {
			let price = Number(this.goods.price || 0);
			Object.keys(this.specList || {}).forEach((key) => {
				this.specList[key].forEach((option) => {
					if (option.checked) price += Number(option.price || 0);
				});
			});
			this.selectedPrice = price;
		},
		changeQuantity(step) {
			this.quantity = Math.max(1, this.quantity + step);
		},
		getSelectedSpecifications() {
			const selected = {};
			Object.keys(this.specList || {}).forEach((key) => {
				const option = this.specList[key].find((item) => item.checked);
				if (option) selected[key] = option.name;
			});
			return selected;
		},
		addToCart() {
			if (this.submitting || this.goods.goodsStatus == 4) return;
			authService.checkIsLogin().then((loggedIn) => {
				if (!loggedIn) {
					app.globalData.checkIsAuth('scope.userInfo');
					return;
				}
				this.submitting = true;
				https.request('/rest/member/shoppingCart/insert', {
					goodsId: this.goodsId,
					specList: JSON.stringify(this.getSelectedSpecifications()),
					shopId: this.shopId,
					number: this.quantity
				}).then((result) => {
					if (result.success) {
						toastService.showSuccess('已加入购物车');
						setTimeout(() => uni.navigateBack(), 500);
					}
				}).finally(() => {
					this.submitting = false;
				});
			});
		},
		toggleCollect() {
			authService.checkIsLogin().then((loggedIn) => {
				if (!loggedIn) {
					app.globalData.checkIsAuth('scope.userInfo');
					return;
				}
				const url = this.isCollect
					? '/rest/member/goodsCollect/delete'
					: '/rest/member/goodsCollect/insert';
				https.request(url, { goodsId: this.goodsId }).then((result) => {
					if (!result.success) return;
					this.isCollect = !this.isCollect;
					toastService.showSuccess(this.isCollect ? '收藏成功' : '已取消收藏');
				});
			});
		},
		getGoodsCollect() {
			https.request('/rest/member/goodsCollect/selectByGoodsId', {
				goodsId: this.goodsId
			}).then((result) => {
				if (result.success) {
					this.collectInfo = result.data;
					this.isCollect = Boolean(result.data);
				}
			});
		}
	}
};
</script>

<style scoped>
.detail-page {
	min-height: 100vh;
	padding-bottom: calc(150rpx + env(safe-area-inset-bottom));
	background: #f7f7f7;
}

.hero {
	position: relative;
	height: 700rpx;
	background: #eeeeee;
}

.hero-swiper,
.hero-image,
.hero-placeholder {
	width: 100%;
	height: 100%;
}

.hero-placeholder {
	display: flex;
	align-items: center;
	justify-content: center;
	color: #999999;
	font-size: 26rpx;
}

.hero-action {
	position: absolute;
	top: calc(30rpx + env(safe-area-inset-top));
	width: 72rpx;
	height: 72rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 50%;
	background: rgba(255, 255, 255, 0.94);
	color: #000000;
	font-size: 38rpx;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.06);
}

.hero-action.back {
	left: 28rpx;
}

.hero-action.favorite {
	right: 28rpx;
}

.hero-action.favorite.active {
	background: #000000;
	color: #ffffff;
}

.content {
	position: relative;
	z-index: 1;
	margin-top: -28rpx;
	padding: 0 28rpx;
}

.heading {
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	padding: 36rpx 34rpx;
	margin-bottom: 20rpx;
	border-radius: 32rpx;
	background: #ffffff;
}

.title-group {
	display: flex;
	flex-direction: column;
	min-width: 0;
	padding-right: 20rpx;
}

.title {
	color: #000000;
	font-size: 42rpx;
	font-weight: 600;
	line-height: 1.35;
}

.subtitle {
	margin-top: 12rpx;
	color: #666666;
	font-size: 24rpx;
}

.price {
	flex-shrink: 0;
	color: #000000;
	font-size: 38rpx;
	font-weight: 700;
}

.ui-card {
	margin-bottom: 20rpx;
	padding: 32rpx;
	border-radius: 32rpx;
	background: #ffffff;
	box-shadow: 0 8rpx 40rpx rgba(0, 0, 0, 0.04);
}

.section-title {
	display: block;
	color: #000000;
	font-size: 30rpx;
	font-weight: 600;
}

.description {
	display: block;
	margin-top: 18rpx;
	color: #666666;
	font-size: 27rpx;
	line-height: 1.75;
}

.spec-group + .spec-group {
	margin-top: 34rpx;
}

.spec-options {
	display: flex;
	flex-wrap: wrap;
	gap: 16rpx;
	margin-top: 22rpx;
}

.spec-option {
	min-width: 120rpx;
	padding: 20rpx 28rpx;
	border: 2rpx solid #eaeaea;
	border-radius: 24rpx;
	background: #ffffff;
	color: #1c1c1e;
	font-size: 26rpx;
	text-align: center;
}

.spec-option.active {
	border-color: #000000;
	background: #000000;
	color: #ffffff;
}

.spec-option.disabled {
	background: #f7f7f7;
	color: #bbbbbb;
}

.quantity-card {
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.quantity-hint {
	display: block;
	margin-top: 10rpx;
	color: #999999;
	font-size: 22rpx;
}

.stepper {
	display: flex;
	align-items: center;
	gap: 22rpx;
}

.step-button {
	width: 64rpx;
	height: 64rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2rpx solid #eaeaea;
	border-radius: 50%;
	background: #ffffff;
	color: #000000;
	font-size: 34rpx;
}

.step-button.dark {
	border-color: #000000;
	background: #000000;
	color: #ffffff;
}

.step-button.disabled {
	color: #cccccc;
}

.quantity {
	min-width: 36rpx;
	color: #000000;
	font-size: 30rpx;
	font-weight: 600;
	text-align: center;
}

.bottom-action {
	position: fixed;
	z-index: 20;
	right: 0;
	bottom: 0;
	left: 0;
	display: flex;
	align-items: center;
	gap: 28rpx;
	padding: 20rpx 28rpx calc(20rpx + env(safe-area-inset-bottom));
	border-top: 2rpx solid #eaeaea;
	background: rgba(255, 255, 255, 0.98);
}

.total {
	flex: 0 0 170rpx;
	display: flex;
	flex-direction: column;
}

.total-label {
	color: #666666;
	font-size: 22rpx;
}

.total-price {
	margin-top: 4rpx;
	color: #000000;
	font-size: 36rpx;
	font-weight: 700;
}

.add-button {
	flex: 1;
}
</style>
