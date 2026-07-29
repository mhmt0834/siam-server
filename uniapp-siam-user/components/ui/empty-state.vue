<template>
	<view class="empty-state">
		<view class="empty-state__title">{{ title }}</view>
		<view v-if="desc" class="empty-state__desc">{{ desc }}</view>
		<view v-if="actionText" class="empty-state__action" @tap="$emit('action')">
			{{ actionText }}
		</view>
	</view>
</template>

<script>
export default {
	name: 'EmptyState',
	props: {
		title: {
			type: String,
			default: '暂无内容'
		},
		desc: {
			type: String,
			default: ''
		},
		actionText: {
			type: String,
			default: ''
		}
	}
};
</script>

<style scoped>
.empty-state {
	padding: 64rpx 32rpx;
	text-align: center;
	background: #fff;
	border-radius: 16rpx;
	border: 1rpx solid #eaeaea;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
}

.empty-state__title {
	font-size: 30rpx;
	font-weight: 600;
	color: #000;
}

.empty-state__desc {
	margin-top: 10rpx;
	font-size: 24rpx;
	color: #666;
}

.empty-state__action {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	height: 44px;
	padding: 0 22px;
	margin-top: 24rpx;
	border-radius: 999px;
	background: #000;
	color: #fff;
	font-size: 26rpx;
	font-weight: 600;
}
</style>
