<template>
	<view class="food-card" :class="'food-card--' + layout" @tap="$emit('tap')">
		<image class="food-card__image" :src="imageSrc" mode="aspectFill" />
		<view class="food-card__body">
			<view class="food-card__head">
				<text class="food-card__title">{{ title }}</text>
				<text v-if="badge" class="food-card__badge">{{ badge }}</text>
			</view>
			<text v-if="desc" class="food-card__desc">{{ desc }}</text>
			<view class="food-card__footer">
				<text class="food-card__price">{{ priceText }}</text>
				<view v-if="showAdd" class="food-card__add" @tap.stop="$emit('add')">{{ actionSymbol }}</view>
			</view>
		</view>
	</view>
</template>

<script>
export default {
	name: 'FoodCard',
	props: {
		item: {
			type: Object,
			default: () => ({})
		},
		layout: {
			type: String,
			default: 'stack'
		},
		showAdd: {
			type: Boolean,
			default: true
		},
		actionSymbol: {
			type: String,
			default: '+'
		}
	},
	computed: {
		imageSrc() {
			return this.item.mainImage || this.item.image || '/static/assets/common/load-image.png';
		},
		title() {
			return this.item.goodsName || this.item.name || '';
		},
		desc() {
			return this.item.briefDescription || this.item.description || '';
		},
		priceText() {
			const price = this.item.goodsPrice ?? this.item.price ?? '';
			return `¥${price}`;
		},
		badge() {
			return this.item.badge || (this.item.goodsStatus == 4 ? '售罄' : (this.item.isRecommend ? '招牌' : ''));
		}
	}
};
</script>

<style scoped>
.food-card {
	background: #fff;
	border: 1rpx solid #eaeaea;
	border-radius: 16rpx;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
	overflow: hidden;
}

.food-card--stack {
	width: 220rpx;
	flex-shrink: 0;
}

.food-card--row {
	display: flex;
	align-items: center;
	padding: 16rpx;
}

.food-card__image {
	width: 100%;
	height: 220rpx;
	background: #f7f7f7;
}

.food-card--row .food-card__image {
	width: 138rpx;
	height: 138rpx;
	border-radius: 12rpx;
	flex-shrink: 0;
}

.food-card__body {
	padding: 16rpx 16rpx 18rpx;
}

.food-card--row .food-card__body {
	flex: 1;
	padding: 0 0 0 16rpx;
}

.food-card__head {
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	gap: 12rpx;
}

.food-card__title {
	font-size: 26rpx;
	line-height: 1.3;
	font-weight: 600;
	color: #000;
}

.food-card__badge {
	flex-shrink: 0;
	padding: 2rpx 8rpx;
	border-radius: 999px;
	background: #000;
	color: #fff;
	font-size: 18rpx;
	font-weight: 600;
}

.food-card__desc {
	display: block;
	margin-top: 8rpx;
	font-size: 20rpx;
	line-height: 1.4;
	color: #666;
}

.food-card__footer {
	margin-top: 14rpx;
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.food-card__price {
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.food-card__add {
	width: 40rpx;
	height: 40rpx;
	border-radius: 50%;
	background: #000;
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 30rpx;
	line-height: 1;
}
</style>
