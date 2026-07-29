<template>
	<view class="mine-page ui-page">
		<view class="mine-shell">
			<app-header
				:title="brand.restaurantName"
				:subtitle="brand.slogan"
				:logo="headerLogo"
				status-text="我的"
			/>

			<view class="profile-card ui-card" @tap="handleProfileTap">
				<image
					class="avatar"
					:src="profile.headImg || '/static/assets/images/user-head.png'"
					mode="aspectFill"
				/>
				<view class="profile-copy">
					<text class="profile-name">{{ isLoggedIn ? profile.username || '微信用户' : '登录 / 注册' }}</text>
					<text class="profile-meta">
						{{ isLoggedIn ? memberDescription : '登录后查看订单、收藏与优惠' }}
					</text>
				</view>
				<text class="profile-arrow">›</text>
			</view>

			<view class="order-card ui-card" @tap="openOrders">
				<view>
					<text class="order-title">我的订单</text>
					<text class="order-subtitle">查看进行中与历史订单</text>
				</view>
				<view class="order-action">
					<text>查看全部</text>
					<text class="profile-arrow">›</text>
				</view>
			</view>

			<view class="menu-card ui-card">
				<view
					v-for="(item, index) in menuItems"
					:key="item.key"
					class="menu-item"
					:class="{ 'menu-item--last': index === menuItems.length - 1 }"
					@tap="openMenuItem(item)"
				>
					<view class="menu-icon">{{ item.mark }}</view>
					<view class="menu-copy">
						<text class="menu-title">{{ item.title }}</text>
						<text class="menu-subtitle">{{ item.subtitle }}</text>
					</view>
					<text class="menu-arrow">›</text>
				</view>
			</view>

			<view class="brand-footer">
				<text>{{ brand.nameEn }}</text>
				<text class="brand-footer__version">VERSION {{ appVersion }}</text>
			</view>
		</view>
		<view class="ui-safe-bottom"></view>
	</view>
</template>

<script>
import https from '../../../utils/http';
import authService from '../../../utils/auth';
import BrandConfig from '../../../utils/brand-config';
import AppHeader from '../../../components/ui/app-header.vue';

let app = null;

export default {
	components: {
		AppHeader
	},
	data() {
		return {
			brand: BrandConfig,
			headerLogo: '/static/assets/images/logo.png',
			isLoggedIn: false,
			appVersion: '5.28',
			profile: {
				id: '',
				headImg: '',
				username: '',
				vipNo: ''
			},
			menuItems: [
				{ key: 'collect', mark: '♡', title: '我的收藏', subtitle: '收藏的菜品与口味' },
				{ key: 'coupon', mark: '券', title: '优惠活动', subtitle: '查看可用优惠券' },
				{ key: 'feedback', mark: '言', title: '意见反馈', subtitle: '告诉我们您的建议' },
				{ key: 'settings', mark: '设', title: '设置中心', subtitle: '账号、隐私与通知' },
				{ key: 'about', mark: 'i', title: '关于我们', subtitle: '品牌与服务信息' }
			]
		};
	},
	computed: {
		memberDescription() {
			return this.profile.vipNo ? `会员编号 ${this.profile.vipNo}` : '欢迎回来，祝您用餐愉快';
		}
	},
	onLoad() {
		app = getApp();
		this.appVersion = String(app.globalData.appVersion || '5.28');
	},
	onShow() {
		this.refreshProfile();
	},
	methods: {
		refreshProfile() {
			authService.checkIsLogin().then((loggedIn) => {
				this.isLoggedIn = Boolean(loggedIn);
				if (!loggedIn) {
					this.profile = { id: '', headImg: '', username: '', vipNo: '' };
					return;
				}
				https.request('/rest/member/getLoginMemberInfo', {}).then((result) => {
					if (result.success && result.data) {
						this.profile = result.data;
					}
				});
			});
		},
		handleProfileTap() {
			if (this.isLoggedIn) {
				uni.navigateTo({ url: '../userinfo/userinfo' });
				return;
			}
			// #ifdef APP-PLUS||H5
			uni.navigateTo({ url: '../../internal/login/code/code' });
			// #endif
			// #ifdef MP-WEIXIN||MP-ALIPAY
			uni.navigateTo({ url: '../../internal/login/choose/choose' });
			// #endif
		},
		openOrders() {
			uni.switchTab({ url: '/pages/order/index/index' });
		},
		openMenuItem(item) {
			const routes = {
				collect: '../collect/index/index',
				coupon: '../coupons/coupons',
				feedback: '../settings/index?section=feedback',
				settings: '../settings/index',
				about: '../settings/index?section=about'
			};
			if (routes[item.key]) {
				if (!this.isLoggedIn) {
					this.handleProfileTap();
					return;
				}
				uni.navigateTo({ url: routes[item.key] });
				return;
			}
			app.globalData.bindInDevelopment();
		}
	}
};
</script>

<style scoped>
page {
	background: #f7f7f7;
}

.mine-page {
	min-height: 100vh;
	background: #f7f7f7;
}

.mine-shell {
	padding: calc(32rpx + env(safe-area-inset-top)) 32rpx 48rpx;
}

.ui-card {
	border: 2rpx solid #f0f0f0;
	border-radius: 32rpx;
	background: #ffffff;
	box-shadow: 0 8rpx 40rpx rgba(0, 0, 0, 0.04);
}

.profile-card {
	display: flex;
	align-items: center;
	margin-top: 38rpx;
	padding: 34rpx;
}

.avatar {
	width: 118rpx;
	height: 118rpx;
	flex-shrink: 0;
	border: 2rpx solid #eaeaea;
	border-radius: 50%;
	background: #f7f7f7;
}

.profile-copy {
	flex: 1;
	display: flex;
	flex-direction: column;
	min-width: 0;
	margin-left: 24rpx;
}

.profile-name {
	color: #000000;
	font-size: 36rpx;
	font-weight: 600;
	line-height: 1.3;
}

.profile-meta {
	margin-top: 10rpx;
	color: #666666;
	font-size: 24rpx;
}

.profile-arrow,
.menu-arrow {
	flex-shrink: 0;
	color: #999999;
	font-size: 42rpx;
	font-weight: 300;
	line-height: 1;
}

.order-card {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-top: 22rpx;
	padding: 30rpx 34rpx;
}

.order-title {
	display: block;
	color: #000000;
	font-size: 30rpx;
	font-weight: 600;
}

.order-subtitle {
	display: block;
	margin-top: 8rpx;
	color: #666666;
	font-size: 23rpx;
}

.order-action {
	display: flex;
	align-items: center;
	color: #666666;
	font-size: 24rpx;
}

.order-action .profile-arrow {
	margin-left: 8rpx;
}

.menu-card {
	margin-top: 22rpx;
	padding: 0 30rpx;
}

.menu-item {
	display: flex;
	align-items: center;
	min-height: 116rpx;
	border-bottom: 2rpx solid #f2f2f2;
}

.menu-item--last {
	border-bottom: 0;
}

.menu-icon {
	width: 60rpx;
	height: 60rpx;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2rpx solid #eaeaea;
	border-radius: 50%;
	background: #fafafa;
	color: #000000;
	font-size: 25rpx;
	font-weight: 600;
}

.menu-copy {
	flex: 1;
	display: flex;
	flex-direction: column;
	min-width: 0;
	margin-left: 22rpx;
}

.menu-title {
	color: #1c1c1e;
	font-size: 28rpx;
	font-weight: 500;
}

.menu-subtitle {
	margin-top: 5rpx;
	color: #888888;
	font-size: 21rpx;
}

.menu-arrow {
	font-size: 36rpx;
}

.brand-footer {
	display: flex;
	flex-direction: column;
	align-items: center;
	margin-top: 42rpx;
	color: #999999;
	font-size: 20rpx;
	letter-spacing: 2rpx;
}

.brand-footer__version {
	margin-top: 8rpx;
	font-size: 18rpx;
	letter-spacing: 1rpx;
}
</style>
