<template>
	<view class="settings-page ui-page">
		<view class="settings-section ui-card">
			<view class="setting-row" @tap="openSecurity">
				<view>
					<text class="setting-title">账号安全</text>
					<text class="setting-desc">登录与支付安全</text>
				</view>
				<text class="setting-arrow">›</text>
			</view>

			<view class="setting-row">
				<view>
					<text class="setting-title">隐私设置</text>
					<text class="setting-desc">减少非必要信息展示</text>
				</view>
				<switch :checked="privacyEnabled" color="#000000" @change="changePrivacy" />
			</view>

			<view class="setting-row">
				<view>
					<text class="setting-title">消息通知</text>
					<text class="setting-desc">接收订单状态提醒</text>
				</view>
				<switch :checked="noticeEnabled" color="#000000" @change="changeNotice" />
			</view>
		</view>

		<view class="settings-section ui-card">
			<view class="setting-row" @tap="clearCache">
				<view>
					<text class="setting-title">清理缓存</text>
					<text class="setting-desc">保留账号登录信息</text>
				</view>
				<text class="setting-value">{{ cacheText }}</text>
			</view>

			<view class="setting-row" @tap="openFeedback">
				<view>
					<text class="setting-title">意见反馈</text>
					<text class="setting-desc">记录您的建议与问题</text>
				</view>
				<text class="setting-arrow">›</text>
			</view>

			<view class="setting-row setting-row--last" @tap="showAbout">
				<view>
					<text class="setting-title">关于我们</text>
					<text class="setting-desc">{{ brand.name }}</text>
				</view>
				<text class="setting-arrow">›</text>
			</view>
		</view>

		<view v-if="isLoggedIn" class="logout-button" @tap="logout">退出登录</view>

		<view v-if="feedbackVisible" class="feedback-overlay" @tap="closeFeedback">
			<view class="feedback-sheet" @tap.stop>
				<view class="feedback-head">
					<text class="feedback-title">意见反馈</text>
					<text class="feedback-close" @tap="closeFeedback">×</text>
				</view>
				<textarea
					v-model="feedback"
					class="feedback-input"
					maxlength="300"
					placeholder="请描述遇到的问题或建议"
					placeholder-class="feedback-placeholder"
				/>
				<text class="feedback-count">{{ feedback.length }}/300</text>
				<primary-button text="保存反馈" :disabled="!feedback.trim()" @tap="saveFeedback" />
			</view>
		</view>
	</view>
</template>

<script>
import https from '../../../utils/http';
import authService from '../../../utils/auth';
import toastService from '../../../utils/toast.service';
import BrandConfig from '../../../utils/brand-config';
import PrimaryButton from '../../../components/ui/primary-button.vue';

export default {
	components: {
		PrimaryButton
	},
	data() {
		return {
			brand: BrandConfig,
			privacyEnabled: true,
			noticeEnabled: true,
			cacheText: '0 KB',
			isLoggedIn: false,
			feedbackVisible: false,
			feedback: ''
		};
	},
	onLoad(options) {
		this.privacyEnabled = uni.getStorageSync('ui.privacyProtection') !== false;
		this.noticeEnabled = uni.getStorageSync('ui.orderNotifications') !== false;
		this.updateCacheSize();
		authService.checkIsLogin().then((loggedIn) => {
			this.isLoggedIn = Boolean(loggedIn);
		});
		if (options && options.section === 'feedback') {
			this.feedbackVisible = true;
		}
		if (options && options.section === 'about') {
			setTimeout(() => this.showAbout(), 250);
		}
	},
	methods: {
		changePrivacy(e) {
			this.privacyEnabled = e.detail.value;
			uni.setStorageSync('ui.privacyProtection', this.privacyEnabled);
		},
		changeNotice(e) {
			this.noticeEnabled = e.detail.value;
			uni.setStorageSync('ui.orderNotifications', this.noticeEnabled);
		},
		updateCacheSize() {
			const info = uni.getStorageInfoSync();
			const currentSize = Number(info.currentSize || 0);
			this.cacheText = currentSize >= 1024
				? `${(currentSize / 1024).toFixed(1)} MB`
				: `${currentSize} KB`;
		},
		clearCache() {
			toastService.showModal(null, '确定清理非账号缓存吗？', () => {
				const info = uni.getStorageInfoSync();
				(info.keys || []).forEach((key) => {
					if (!String(key).startsWith('security.')) {
						uni.removeStorageSync(key);
					}
				});
				this.updateCacheSize();
				toastService.showSuccess('缓存已清理');
			});
		},
		openSecurity() {
			if (!this.isLoggedIn) {
				toastService.showToast('请先登录');
				return;
			}
			uni.navigateTo({ url: '../security/index/index' });
		},
		openFeedback() {
			this.feedback = uni.getStorageSync('ui.feedbackDraft') || '';
			this.feedbackVisible = true;
		},
		closeFeedback() {
			this.feedbackVisible = false;
		},
		saveFeedback() {
			const value = this.feedback.trim();
			if (!value) return;
			uni.setStorageSync('ui.feedbackDraft', value);
			this.feedbackVisible = false;
			toastService.showSuccess('反馈已保存');
		},
		showAbout() {
			toastService.showModal(
				this.brand.name,
				`${this.brand.slogan}\n版本 5.28`,
				null,
				null,
				false
			);
		},
		logout() {
			toastService.showModal(null, '确定退出登录吗？', () => {
				https.request('/rest/member/logout', {}).then((result) => {
					if (!result.success) return;
					Promise.all([
						authService.deleteToken(),
						authService.deleteOpenId(),
						authService.deletePhoneNumber()
					]).then(() => {
						toastService.showSuccess('已退出登录');
						setTimeout(() => uni.switchTab({ url: '/pages/mine/index/index' }), 400);
					});
				});
			});
		}
	}
};
</script>

<style scoped>
page {
	background: #f7f7f7;
}

.settings-page {
	min-height: 100vh;
	padding: 24rpx 28rpx 80rpx;
	background: #f7f7f7;
	box-sizing: border-box;
}

.settings-section {
	margin-bottom: 22rpx;
	padding: 0 30rpx;
	border: 2rpx solid #f0f0f0;
	border-radius: 32rpx;
	background: #ffffff;
}

.setting-row {
	min-height: 120rpx;
	display: flex;
	align-items: center;
	justify-content: space-between;
	border-bottom: 2rpx solid #f2f2f2;
}

.setting-row--last {
	border-bottom: 0;
}

.setting-title,
.setting-desc {
	display: block;
}

.setting-title {
	color: #1c1c1e;
	font-size: 29rpx;
	font-weight: 500;
}

.setting-desc {
	margin-top: 7rpx;
	color: #888888;
	font-size: 22rpx;
}

.setting-arrow {
	color: #999999;
	font-size: 40rpx;
	font-weight: 300;
}

.setting-value {
	color: #666666;
	font-size: 24rpx;
}

.logout-button {
	height: 96rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2rpx solid #000000;
	border-radius: 28rpx;
	background: #ffffff;
	color: #000000;
	font-size: 28rpx;
	font-weight: 600;
}

.feedback-overlay {
	position: fixed;
	z-index: 40;
	inset: 0;
	display: flex;
	align-items: flex-end;
	background: rgba(0, 0, 0, 0.42);
}

.feedback-sheet {
	width: 100%;
	padding: 30rpx 28rpx calc(30rpx + env(safe-area-inset-bottom));
	border-radius: 32rpx 32rpx 0 0;
	background: #ffffff;
	box-sizing: border-box;
}

.feedback-head {
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.feedback-title {
	color: #000000;
	font-size: 32rpx;
	font-weight: 600;
}

.feedback-close {
	color: #666666;
	font-size: 40rpx;
}

.feedback-input {
	width: 100%;
	height: 240rpx;
	margin-top: 24rpx;
	padding: 24rpx;
	border: 2rpx solid #eaeaea;
	border-radius: 24rpx;
	background: #f7f7f7;
	color: #000000;
	font-size: 26rpx;
	box-sizing: border-box;
}

.feedback-placeholder {
	color: #999999;
}

.feedback-count {
	display: block;
	margin: 12rpx 0 22rpx;
	color: #999999;
	font-size: 22rpx;
	text-align: right;
}
</style>
