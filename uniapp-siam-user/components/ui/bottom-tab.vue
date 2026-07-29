<template>
	<view class="bottom-tab">
		<view
			v-for="(item, index) in tabs"
			:key="index"
			class="bottom-tab__item"
			:class="{ 'bottom-tab__item--active': index === activeIndex }"
			@tap="$emit('select', index)"
		>
			<view class="bottom-tab__icon">{{ item.icon || item.short || (item.text ? item.text.slice(0, 1) : '') }}</view>
			<text class="bottom-tab__text">{{ item.text }}</text>
		</view>
	</view>
</template>

<script>
export default {
	name: 'BottomTab',
	props: {
		tabs: {
			type: Array,
			default: () => []
		},
		activeIndex: {
			type: Number,
			default: 0
		}
	}
};
</script>

<style scoped>
.bottom-tab {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12rpx;
	padding: 14rpx;
	background: #fff;
	border: 1rpx solid #eaeaea;
	border-radius: 20rpx;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
}

.bottom-tab__item {
	flex: 1;
	min-height: 104rpx;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	border-radius: 16rpx;
	color: #666;
}

.bottom-tab__item--active {
	color: #000;
	background: #f7f7f7;
}

.bottom-tab__icon {
	font-size: 26rpx;
	font-weight: 700;
	line-height: 1;
}

.bottom-tab__text {
	margin-top: 8rpx;
	font-size: 22rpx;
	line-height: 1.2;
}
</style>
