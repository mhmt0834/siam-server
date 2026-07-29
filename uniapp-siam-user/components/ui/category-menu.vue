<template>
	<scroll-view class="category-menu" scroll-y>
		<view
			v-for="(item, index) in items"
			:key="index"
			class="category-menu__item"
			:class="{ 'category-menu__item--active': index === activeIndex }"
			@tap="$emit('select', index)"
		>
			<view v-if="index === activeIndex" class="category-menu__indicator"></view>
			<text class="category-menu__text">{{ item.name || item.title || '' }}</text>
		</view>
	</scroll-view>
</template>

<script>
export default {
	name: 'CategoryMenu',
	props: {
		items: {
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
.category-menu {
	width: 176rpx;
	height: 100%;
	padding: 14rpx 0;
	background: #f7f7f7;
	border-right: 1rpx solid #eaeaea;
}

.category-menu__item {
	position: relative;
	display: flex;
	align-items: center;
	min-height: 92rpx;
	padding: 0 22rpx 0 30rpx;
	color: #666;
	font-size: 24rpx;
	font-weight: 500;
}

.category-menu__item--active {
	color: #000;
	font-weight: 600;
	background: #fff;
}

.category-menu__indicator {
	position: absolute;
	left: 14rpx;
	top: 50%;
	width: 6rpx;
	height: 30rpx;
	border-radius: 999px;
	background: #000;
	transform: translateY(-50%);
}

.category-menu__text {
	line-height: 1.2;
}
</style>
