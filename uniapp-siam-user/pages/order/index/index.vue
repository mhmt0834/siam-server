<template>
	<view class="order-page ui-page">
		<view class="order-toolbar">
			<view class="status-tabs">
				<view
					v-for="item in statusTabs"
					:key="item.key"
					class="status-tab"
					:class="{ active: activeStatus === item.key }"
					@tap="activeStatus = item.key"
				>
					{{ item.title }}
				</view>
			</view>

			<view class="search-box">
				<text class="search-icon">⌕</text>
				<input
					v-model="keyword"
					class="search-input"
					placeholder="搜索订单号或菜品"
					placeholder-class="search-placeholder"
				/>
				<text v-if="keyword" class="search-clear" @tap="keyword = ''">×</text>
			</view>
		</view>

		<view class="order-content">
			<view v-if="loading && !orders.length" class="loading-card ui-card">订单加载中...</view>

			<view v-else-if="visibleOrders.length" class="order-list">
				<order-card
					v-for="item in visibleOrders"
					:key="item.id"
					:order="item"
					class="order-list__item"
					@tap="openOrder(item.id)"
				/>
				<view class="list-state">{{ loading ? '加载中...' : isEnd ? '没有更多订单' : '上拉加载更多' }}</view>
			</view>

			<empty-state
				v-else-if="!isLoggedIn"
				title="登录后查看订单"
				desc="登录后可查看进行中与历史订单"
				action-text="去登录"
				@action="goLogin"
			/>

			<empty-state
				v-else
				:title="emptyTitle"
				desc="当前没有符合条件的订单"
				action-text="去点餐"
				@action="goToMenu"
			/>
		</view>
		<view class="ui-safe-bottom"></view>
	</view>
</template>

<script>
import https from '../../../utils/http';
import authService from '../../../utils/auth';
import dateHelper from '../../../utils/date-helper';
import systemStatus from '../../../utils/system-status';
import OrderCard from '../../../components/ui/order-card.vue';
import EmptyState from '../../../components/ui/empty-state.vue';

let app = null;

export default {
	components: {
		OrderCard,
		EmptyState
	},
	data() {
		return {
			statusTabs: [
				{ key: 'all', title: '全部' },
				{ key: 'ongoing', title: '进行中' },
				{ key: 'completed', title: '已完成' }
			],
			activeStatus: 'all',
			keyword: '',
			orders: [],
			pageNo: 1,
			pageSize: 10,
			loading: false,
			isEnd: false,
			isLoggedIn: false
		};
	},
	computed: {
		visibleOrders() {
			const keyword = this.keyword.trim().toLowerCase();
			return this.orders.filter((order) => {
				const matchesStatus = this.activeStatus === 'all' || order.statusGroup === this.activeStatus;
				if (!matchesStatus) return false;
				if (!keyword) return true;
				return [order.orderNo, order.description, order.shopName]
					.filter(Boolean)
					.some((value) => String(value).toLowerCase().includes(keyword));
			});
		},
		emptyTitle() {
			const tab = this.statusTabs.find((item) => item.key === this.activeStatus);
			return `暂无${tab ? tab.title : ''}订单`;
		}
	},
	onLoad(options) {
		app = getApp();
		if (options && options.modeType === 'all') {
			this.activeStatus = 'all';
		}
	},
	onShow() {
		this.refreshOrders();
	},
	onPullDownRefresh() {
		this.loadOrders(true).finally(() => {
			uni.stopPullDownRefresh();
		});
	},
	onReachBottom() {
		if (!this.loading && !this.isEnd && this.isLoggedIn) {
			this.pageNo += 1;
			this.loadOrders(false);
		}
	},
	methods: {
		refreshOrders() {
			authService.checkIsLogin().then((loggedIn) => {
				this.isLoggedIn = Boolean(loggedIn);
				if (!loggedIn) {
					this.orders = [];
					return;
				}
				this.loadOrders(true);
			});
		},
		loadOrders(reset) {
			if (this.loading) return Promise.resolve();
			if (reset) {
				this.pageNo = 1;
				this.isEnd = false;
			}
			this.loading = true;
			return https.request('/rest/member/order/list', {
				pageNo: this.pageNo,
				pageSize: this.pageSize,
				tabType: 'all',
				keyWords: ''
			}).then((result) => {
				if (!result.success || !result.data) return;
				const records = (result.data.records || []).map((order) => this.formatOrder(order));
				this.orders = reset ? records : this.orders.concat(records);
				this.isEnd = records.length < this.pageSize;
			}).finally(() => {
				this.loading = false;
			});
		},
		formatOrder(order) {
			const rawStatus = systemStatus.statusText(order.status) || '';
			const completed = /完成|关闭|取消|退款成功/.test(rawStatus);
			return Object.assign({}, order, {
				createTime: dateHelper.fmtDate(order.createTime),
				statusText: completed ? '已完成' : '进行中',
				statusGroup: completed ? 'completed' : 'ongoing',
				description: `${order.description || '店内点餐'} · 共${order.goodsTotalQuantity || 0}件`
			});
		},
		openOrder(id) {
			uni.navigateTo({ url: '../detail/detail?id=' + id });
		},
		goToMenu() {
			uni.switchTab({ url: '/pages/menu/index/index' });
		},
		goLogin() {
			// #ifdef APP-PLUS||H5
			uni.navigateTo({ url: '../../internal/login/code/code' });
			// #endif
			// #ifdef MP-WEIXIN||MP-ALIPAY
			uni.navigateTo({ url: '../../internal/login/choose/choose' });
			// #endif
		}
	}
};
</script>

<style scoped>
page {
	background: #f7f7f7;
}

.order-page {
	min-height: 100vh;
	background: #f7f7f7;
}

.order-toolbar {
	position: sticky;
	z-index: 10;
	top: 0;
	padding: 24rpx 28rpx 20rpx;
	border-bottom: 2rpx solid #eeeeee;
	background: rgba(247, 247, 247, 0.98);
}

.status-tabs {
	display: flex;
	align-items: center;
	gap: 14rpx;
}

.status-tab {
	flex: 1;
	height: 72rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2rpx solid #eaeaea;
	border-radius: 24rpx;
	background: #ffffff;
	color: #666666;
	font-size: 26rpx;
	font-weight: 500;
}

.status-tab.active {
	border-color: #000000;
	background: #000000;
	color: #ffffff;
}

.search-box {
	height: 82rpx;
	display: flex;
	align-items: center;
	margin-top: 18rpx;
	padding: 0 24rpx;
	border: 2rpx solid #eaeaea;
	border-radius: 28rpx;
	background: #ffffff;
}

.search-icon {
	color: #666666;
	font-size: 34rpx;
}

.search-input {
	flex: 1;
	height: 100%;
	margin-left: 14rpx;
	color: #000000;
	font-size: 26rpx;
}

.search-placeholder {
	color: #999999;
}

.search-clear {
	width: 48rpx;
	color: #999999;
	font-size: 34rpx;
	text-align: right;
}

.order-content {
	padding: 24rpx 28rpx 48rpx;
}

.order-list__item {
	display: block;
	margin-bottom: 20rpx;
}

.loading-card {
	padding: 80rpx 24rpx;
	border-radius: 32rpx;
	background: #ffffff;
	color: #666666;
	font-size: 26rpx;
	text-align: center;
}

.list-state {
	padding: 24rpx 0;
	color: #999999;
	font-size: 22rpx;
	text-align: center;
}
</style>
