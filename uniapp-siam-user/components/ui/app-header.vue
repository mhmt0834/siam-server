<template>
	<view class="app-header">
		<view class="app-header__brand">
			<view v-if="logo" class="app-header__logo-wrap">
				<image class="app-header__logo" :src="logo" mode="aspectFill" />
			</view>
			<view v-else class="app-header__logo-wrap app-header__logo-wrap--text">
				{{ mark }}
			</view>
			<view class="app-header__copy">
				<text class="app-header__title">{{ title }}</text>
				<text v-if="subtitle" class="app-header__subtitle">{{ subtitle }}</text>
			</view>
		</view>
		<view v-if="statusText" class="app-header__status">{{ statusText }}</view>
		<view v-else-if="showBack" class="app-header__back" @tap="$emit('back')">
			<text class="app-header__back-icon">←</text>
		</view>
	</view>
</template>

<script>
export default {
	name: 'AppHeader',
	props: {
		title: {
			type: String,
			default: ''
		},
		subtitle: {
			type: String,
			default: ''
		},
		logo: {
			type: String,
			default: ''
		},
		mark: {
			type: String,
			default: 'A'
		},
		statusText: {
			type: String,
			default: ''
		},
		showBack: {
			type: Boolean,
			default: false
		}
	}
};
</script>

<style scoped>
.app-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 24rpx;
}

.app-header__brand {
	display: flex;
	align-items: center;
	min-width: 0;
}

.app-header__logo-wrap {
	width: 64rpx;
	height: 64rpx;
	flex-shrink: 0;
	overflow: hidden;
	border-radius: 50%;
	background: #000;
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 30rpx;
	font-weight: 700;
}

.app-header__logo {
	width: 100%;
	height: 100%;
}

.app-header__logo-wrap--text {
	background: #000;
}

.app-header__copy {
	display: flex;
	flex-direction: column;
	margin-left: 18rpx;
	min-width: 0;
}

.app-header__title {
	font-size: 30rpx;
	line-height: 1.2;
	font-weight: 600;
	color: #000;
}

.app-header__subtitle {
	margin-top: 6rpx;
	font-size: 22rpx;
	line-height: 1.3;
	color: #666;
}

.app-header__status,
.app-header__back {
	flex-shrink: 0;
	min-height: 58rpx;
	padding: 0 18rpx;
	border-radius: 999px;
	border: 1rpx solid #eaeaea;
	background: #fff;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	color: #000;
	font-size: 22rpx;
	font-weight: 600;
}

.app-header__back-icon {
	font-size: 34rpx;
	line-height: 1;
	transform: translateY(-1rpx);
}
</style>
