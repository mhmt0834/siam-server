<template>
	<view class="primary-button" :class="{ 'primary-button--disabled': disabled }" @tap="handleTap">
		<slot>{{ text }}</slot>
	</view>
</template>

<script>
export default {
	name: 'PrimaryButton',
	props: {
		text: {
			type: String,
			default: ''
		},
		disabled: {
			type: Boolean,
			default: false
		}
	},
	methods: {
		handleTap() {
			if (this.disabled) return;
			this.$emit('tap');
		}
	}
};
</script>

<style scoped>
.primary-button {
	height: 56px;
	border-radius: 18px;
	background: #000;
	color: #fff;
	font-size: 28rpx;
	font-weight: 600;
	display: flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
}

.primary-button--disabled {
	opacity: 0.45;
}
</style>
