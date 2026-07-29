<template>
	<view class="order-card" @tap="$emit('tap')">
		<view class="order-card__head">
			<view class="order-card__meta">
				<text class="order-card__no">订单号 {{ order.orderNo || order.no || '—' }}</text>
				<text class="order-card__time">{{ order.createTime || order.time || '' }}</text>
			</view>
			<view class="order-card__status">{{ order.statusText || statusText || '' }}</view>
		</view>
		<text class="order-card__title">{{ order.shopName || order.title || '' }}</text>
		<text class="order-card__desc">{{ order.description || desc || '' }}</text>
		<view class="order-card__footer">
			<text class="order-card__amount">¥{{ order.actualPrice || order.amount || '0.00' }}</text>
			<view v-if="actionText" class="order-card__action" @tap="$emit('action')">
				{{ actionText }}
			</view>
		</view>
	</view>
</template>

<script>
export default {
	name: 'OrderCard',
	props: {
		order: {
			type: Object,
			default: () => ({})
		},
		statusText: {
			type: String,
			default: ''
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
.order-card {
	padding: 22rpx;
	background: #fff;
	border: 1rpx solid #eaeaea;
	border-radius: 16rpx;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
}

.order-card__head,
.order-card__footer {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 18rpx;
}

.order-card__meta {
	display: flex;
	flex-direction: column;
	min-width: 0;
}

.order-card__no {
	font-size: 26rpx;
	font-weight: 600;
	color: #000;
}

.order-card__time,
.order-card__desc {
	margin-top: 6rpx;
	font-size: 22rpx;
	color: #666;
}

.order-card__status {
	font-size: 22rpx;
	font-weight: 600;
	color: #000;
}

.order-card__title {
	display: block;
	margin-top: 16rpx;
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.order-card__desc {
	display: block;
}

.order-card__footer {
	margin-top: 18rpx;
}

.order-card__amount {
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.order-card__action {
	min-height: 42px;
	padding: 0 18px;
	border-radius: 999px;
	border: 1rpx solid #000;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 24rpx;
	font-weight: 600;
	color: #000;
}
</style>
