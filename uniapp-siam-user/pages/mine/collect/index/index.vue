<template>
	<view class="collect-page ui-page">
		<view class="collect-toolbar">
			<view class="search-box">
				<text class="search-icon">⌕</text>
				<input
					v-model="keyword"
					class="search-input"
					placeholder="搜索收藏菜品"
					placeholder-class="search-placeholder"
				/>
				<text v-if="keyword" class="search-clear" @tap="keyword = ''">×</text>
			</view>
		</view>

		<view class="collect-content">
			<view v-if="loading" class="loading-card ui-card">收藏加载中...</view>

			<view v-else-if="visibleList.length" class="collect-list">
				<food-card
					v-for="item in visibleList"
					:key="item.goodsId"
					:item="item"
					layout="row"
					action-symbol="♥"
					class="collect-item"
					@tap="openDetail(item)"
					@add="removeFavorite(item)"
				/>
			</view>

			<empty-state
				v-else
				title="暂无收藏"
				desc="收藏喜欢的菜品，下次点餐更方便"
				action-text="去菜单看看"
				@action="goToMenu"
			/>
		</view>
	</view>
</template>

<script>
import GlobalConfig from '../../../../utils/global-config';
import https from '../../../../utils/http';
import toastService from '../../../../utils/toast.service';
import FoodCard from '../../../../components/ui/food-card.vue';
import EmptyState from '../../../../components/ui/empty-state.vue';

export default {
	components: {
		FoodCard,
		EmptyState
	},
	data() {
		return {
			keyword: '',
			collectList: [],
			loading: true
		};
	},
	computed: {
		visibleList() {
			const keyword = this.keyword.trim().toLowerCase();
			if (!keyword) return this.collectList;
			return this.collectList.filter((item) =>
				String(item.goodsName || '').toLowerCase().includes(keyword)
			);
		}
	},
	onShow() {
		this.loadFavorites();
	},
	onPullDownRefresh() {
		this.loadFavorites().finally(() => {
			uni.stopPullDownRefresh();
		});
	},
	methods: {
		loadFavorites() {
			this.loading = true;
			return https.request('/rest/member/goodsCollect/list', {
				pageNo: -1,
				pageSize: 50,
				isBuy: false,
				goodsName: ''
			}).then((result) => {
				const records = result.success && result.data ? result.data.records || [] : [];
				this.collectList = records.map((item) => Object.assign({}, item, {
					mainImage: this.resolveImage(item.mainImage),
					price: item.isSale ? item.salePrice : item.goodsPrice,
					description: item.restructure || '店内现做'
				}));
			}).finally(() => {
				this.loading = false;
			});
		},
		resolveImage(url) {
			if (!url) return '';
			return /^https?:\/\//.test(url) ? url : GlobalConfig.ossUrl + url;
		},
		openDetail(item) {
			if (!item.isGoodsExists || item.goodsStatus == 3) return;
			uni.navigateTo({
				url: '../../../menu/detail/detail?id=' + item.goodsId + '&shopId=' + item.shopId
			});
		},
		removeFavorite(item) {
			toastService.showModal(null, '确定取消收藏吗？', () => {
				https.request('/rest/member/goodsCollect/batchDelete', {
					goodsIdList: [item.goodsId]
				}).then((result) => {
					if (!result.success) return;
					this.collectList = this.collectList.filter((favorite) => favorite.goodsId !== item.goodsId);
					toastService.showSuccess('已取消收藏');
				});
			});
		},
		goToMenu() {
			uni.switchTab({ url: '/pages/menu/index/index' });
		}
	}
};
</script>

<style scoped>
page {
	background: #f7f7f7;
}

.collect-page {
	min-height: 100vh;
	background: #f7f7f7;
}

.collect-toolbar {
	position: sticky;
	z-index: 10;
	top: 0;
	padding: 20rpx 28rpx;
	border-bottom: 2rpx solid #eeeeee;
	background: rgba(247, 247, 247, 0.98);
}

.search-box {
	height: 82rpx;
	display: flex;
	align-items: center;
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

.search-placeholder,
.search-clear {
	color: #999999;
}

.search-clear {
	width: 48rpx;
	font-size: 34rpx;
	text-align: right;
}

.collect-content {
	padding: 24rpx 28rpx 48rpx;
}

.collect-item {
	display: block;
	margin-bottom: 18rpx;
}

.loading-card {
	padding: 80rpx 24rpx;
	border-radius: 32rpx;
	background: #ffffff;
	color: #666666;
	font-size: 26rpx;
	text-align: center;
}
</style>
