<template>
	<view class="menu-page ui-page">
		<view class="menu-shell">
			<app-header
				title="菜单点餐"
				:subtitle="diningContext.tableName ? '桌号：' + diningContext.tableName : '新疆风味 · 现点现做'"
				:status-text="shopInfo.shop && shopInfo.shop.isOperating ? '营业中' : '休息中'"
				:logo="shopInfo.shop && shopInfo.shop.logoImg ? shopInfo.shop.logoImg : ''"
				mark="M"
			/>

			<navigator url="../search/search" class="menu-search ui-surface">
				<text class="menu-search__icon">⌕</text>
				<text class="menu-search__text">搜索菜品、口味、套餐</text>
			</navigator>

			<view class="menu-layout">
				<category-menu :items="menuList" :active-index="activeLeftTab" @select="leftTap" />

				<scroll-view
					class="menu-content"
					scroll-y
					:scroll-with-animation="true"
					:scroll-into-view="'into' + activeTab"
					@scroll="mainScroll"
					@touchstart="mainTouch"
				>
					<view v-if="menuList.length > 0" class="menu-content__inner">
						<view v-for="(menu, menuIndex) in menuList" :id="'into' + menuIndex" :key="menuIndex" class="menu-section">
							<view class="menu-section__title">{{ menu.name }}</view>
							<view class="menu-section__list">
								<food-card
									v-for="goods in menu.goodsList"
									:key="goods.goodsId"
									:item="goods"
									layout="row"
									:show-add="goods.goodsStatus != 4"
									@tap="commodityDetailTap(goods.goodsId)"
									@add="openSpecifications(goods.goodsId)"
								/>
							</view>
						</view>
						<view class="menu-content__end">没有更多啦~</view>
					</view>

					<empty-state
						v-else
						class="menu-empty"
						title="暂无菜品"
						desc="请稍后再来看看，或联系门店更新菜单"
						action-text="刷新"
						@action="getShopList"
					/>
				</scroll-view>
			</view>
		</view>

		<view class="menu-cart" :class="{ 'menu-cart--disabled': !isCartEnabled }">
			<view class="menu-cart__left" @tap="openShoppingCart">
				<view class="menu-cart__bag">
					<text class="menu-cart__bag-text">购</text>
					<view v-if="totalNum > 0" class="menu-cart__badge">{{ totalNum }}</view>
				</view>
				<view class="menu-cart__info">
					<text class="menu-cart__price" v-if="shoppingCartList.length > 0">¥{{ totalPrice }}</text>
					<text class="menu-cart__hint" v-else>暂未选购商品</text>
					<text class="menu-cart__sub" v-if="shoppingCartList.length > 0">另需包装费 ¥{{ packingCharges }}</text>
				</view>
			</view>
			<view class="menu-cart__right" @tap="goToPay">
				<text>{{ isStartDeliveryPrice ? '去结算' : '还差 ¥' + priceDifference + ' 起送' }}</text>
			</view>
		</view>

		<view v-if="shoppingCartDialog" class="ui-overlay" @tap="closeShoppingCart">
			<view class="ui-sheet ui-sheet--cart" @tap.stop>
				<view class="ui-sheet__head">
					<text class="ui-sheet__title">已选商品</text>
					<text class="ui-sheet__sub">共 {{ totalNum }} 件</text>
				</view>

				<scroll-view class="ui-sheet__body" scroll-y>
					<view v-if="shoppingCartList.length > 0" class="cart-list">
						<view v-for="(item, index) in shoppingCartList" :key="index" class="cart-item">
							<view class="cart-item__meta">
								<text class="cart-item__name">{{ item.goodsName }}</text>
								<text class="cart-item__spec" v-if="item.restructure">{{ item.restructure }}</text>
							</view>
							<view class="cart-item__right">
								<text class="cart-item__price">¥{{ item.price }}</text>
								<view class="cart-stepper">
									<view class="cart-stepper__btn" @tap.stop="bindMinus" :data-cartid="item.id" :data-number="item.number">−</view>
									<text class="cart-stepper__num">{{ item.number }}</text>
									<view class="cart-stepper__btn" @tap.stop="bindPlus" :data-num="index + ',' + item.number">+</view>
								</view>
							</view>
						</view>
					</view>
					<empty-state v-else title="购物车空空的" desc="先去选几道菜吧" />
				</scroll-view>

				<view class="cart-summary">
					<view class="cart-summary__row">
						<text>商品金额</text>
						<text>¥{{ totalPrice }}</text>
					</view>
					<view class="cart-summary__row">
						<text>包装费</text>
						<text>¥{{ packingCharges }}</text>
					</view>
					<view class="cart-summary__row cart-summary__row--total">
						<text>合计</text>
						<text>¥{{ totalPrice }}</text>
					</view>
					<primary-button text="去结算" :disabled="!isStartDeliveryPrice" @tap="goToPay" />
				</view>
			</view>
		</view>

		<view v-if="specificationsDialog" class="ui-overlay" @tap="closeSpecifications">
			<view class="ui-sheet ui-sheet--spec" @tap.stop>
				<view class="ui-sheet__head">
					<text class="ui-sheet__title">选择规格</text>
					<text class="ui-sheet__sub">{{ specListString ? '已选：' + specListString : '请选择口味规格' }}</text>
				</view>

				<view class="spec-head">
					<image class="spec-head__image" :src="goodsInfo.mainImage || '/static/assets/common/load-image.png'" mode="aspectFill" />
					<view class="spec-head__body">
						<text class="spec-head__name">{{ goodsInfo.name }}</text>
						<text class="spec-head__price">¥{{ priceAfter }}</text>
						<text class="spec-head__tips">精选食材 · 现做现卖</text>
					</view>
				</view>

				<scroll-view class="ui-sheet__body" scroll-y>
					<view class="spec-list">
						<view class="spec-group" v-for="(options, key) in specList" :key="key">
							<text class="spec-group__title">{{ key }}</text>
							<radio-group class="spec-group__options" @change="radioChange" :data-firstIndex="key">
								<label
									v-for="(option, index) in options"
									:key="index"
									class="spec-option"
									:class="{ 'spec-option--active': option.checked, 'spec-option--disabled': !option.stock }"
								>
									<radio :value="index" :checked="option.checked" :disabled="!option.stock" class="spec-option__radio" />
									<text>{{ option.name }}</text>
								</label>
							</radio-group>
						</view>

						<view v-if="specLoading && specList.length == 0" class="spec-loading">加载中...</view>
						<empty-state v-if="!specLoading && specList.length <= 0" title="暂无规格" />
					</view>
				</scroll-view>

				<primary-button text="加入购物车" @tap="insertShoppingCart" />
			</view>
		</view>
	</view>
</template>

<script>
import AppHeader from '../../../components/ui/app-header.vue';
import CategoryMenu from '../../../components/ui/category-menu.vue';
import FoodCard from '../../../components/ui/food-card.vue';
import PrimaryButton from '../../../components/ui/primary-button.vue';
import EmptyState from '../../../components/ui/empty-state.vue';
import GlobalConfig from '../../../utils/global-config';
import https from '../../../utils/http';
import authService from '../../../utils/auth';
import toastService from '../../../utils/toast.service';
import utilHelper from '../../../utils/util';
import DiningContext from '../../../utils/dining-context';

let app = null;

export default {
	components: {
		AppHeader,
		CategoryMenu,
		FoodCard,
		PrimaryButton,
		EmptyState
	},
	data() {
		return {
			menuList: [],
			shopInfo: {
				shop: {
					id: '',
					name: '',
					logoImg: '',
					startDeliveryPrice: 0,
					startTime: '',
					endTime: '',
					isOperating: true
				},
				isOutofDeliveryRange: false,
				isOperatingOfShop: true,
				promotionList: []
			},
			initShopInfo: { id: '', shopAdditionalVo: {} },
			activeTab: 0,
			activeLeftTab: 0,
			shoppingCartDialog: false,
			specificationsDialog: false,
			shoppingCartList: [],
			totalNum: 0,
			totalPrice: 0,
			packingCharges: 0,
			isStartDeliveryPrice: false,
			priceDifference: 0,
			isMainScroll: false,
			topArr: [],
			winHeight: 0,
			topHeight: 0,
			carHeight: 70,
			ifScroll: true,
			isLoading: true,
			selfOutActiveIndex: 0,
			deliveryAndSelfTaking: { deliveryAddress: {} },
			memberInfo: {},
			specLoading: false,
			goodsId: '',
			goodsInfo: { mainImage: '', name: '' },
			specList: [],
			specListString: '',
			priceAfter: '',
			staticImg: '',
			diningContext: {},
			pendingScene: ''
		};
	},
	computed: {
		isCartEnabled() {
			return !this.shopInfo.isOutofDeliveryRange && this.shopInfo.isOperatingOfShop && this.shopInfo.shop.isOperating;
		}
	},
	onLoad(options) {
		app = getApp();
		this.pendingScene = DiningContext.normalizeScene(options && options.scene);
	},
	onShow() {
		let selfOutActiveIndex = 0;
		if ('selfOutActiveIndex' in app.globalData.deliveryAndSelfTaking) {
			selfOutActiveIndex = app.globalData.deliveryAndSelfTaking.selfOutActiveIndex;
		}
		app.globalData.deliveryAndSelfTaking.ifIndexSwitchTab = false;
		app.globalData.deliveryAndSelfTaking.selfOutActiveIndex = selfOutActiveIndex;
		app.globalData.deliveryAndSelfTaking.chooseIndex = selfOutActiveIndex;

		this.activeLeftTab = 0;
		this.activeTab = 0;
		this.topArr = [];
		this.isMainScroll = false;
		this.selfOutActiveIndex = selfOutActiveIndex;
		this.deliveryAndSelfTaking.deliveryAddress = app.globalData.deliveryAndSelfTaking.deliveryAddress;
		this.staticImg = app.globalData.staticImg;

		this.isLoading = true;
		this.menuList = [];
		this.getShopList();
		this.selfAdaption();

		this.$nextTick(() => {
			setTimeout(() => {
				this.getElementTop();
			}, 500);
			setTimeout(() => {
				this.isLoading = false;
			}, 2000);
		});
	},
	onHide() {
		this.shoppingCartDialog = false;
	},
	onPullDownRefresh() {
		uni.showNavigationBarLoading();
		this.getShopList();
		uni.hideNavigationBarLoading();
		uni.stopPullDownRefresh();
	},
	methods: {
		selfAdaption() {
			const _this = this;
			uni.getSystemInfo({
				success(res) {
					_this.winHeight = res.windowHeight;
					setTimeout(() => {
						uni.createSelectorQuery()
							.in(_this)
							.selectAll('#shopping-cart-detail')
							.boundingClientRect(function(rects) {
								if (rects && rects.length > 0) {
									_this.carHeight = rects[0].height;
								}
							})
							.exec();
					}, 800);
				}
			});
		},
		getShopList() {
			const pendingScene = this.pendingScene;
			const cachedContext = DiningContext.get();
			if (pendingScene) {
				this.pendingScene = '';
				this.resolveDiningScene(pendingScene);
				return;
			}
			if (cachedContext.sceneToken && cachedContext.shopId) {
				this.diningContext = cachedContext;
				this.getShopInfo({ id: cachedContext.shopId, shopAdditionalVo: { deliveryDistanceText: '' } });
				return;
			}
			if (GlobalConfig.defaultShopId) {
				this.getShopInfo({ id: GlobalConfig.defaultShopId, shopAdditionalVo: { deliveryDistanceText: '' } });
				return;
			}
			if (app.globalData.deliveryAndSelfTaking.location) {
				https.request('/rest/shop/list', {
					pageNo: -1,
					pageSize: 1,
					position: app.globalData.deliveryAndSelfTaking.location
				}).then((result) => {
					if (result.success && result.data.records.length > 0) {
						this.getShopInfo(result.data.records[0]);
					} else {
						this.isLoading = false;
					}
				});
			}
		},
		resolveDiningScene(sceneToken) {
			https.request('/rest/scan/resolve', { sceneToken }).then((result) => {
				if (!result.success || !result.data) {
					DiningContext.clear();
					this.isLoading = false;
					return;
				}
				this.diningContext = DiningContext.set(result.data);
				this.getShopInfo({ id: result.data.shopId, shopAdditionalVo: { deliveryDistanceText: '' } });
			}).catch(() => {
				DiningContext.clear();
				this.isLoading = false;
			});
		},
		getShopInfo(initShopInfo) {
			const shopId = initShopInfo.id;
			const requestData = { id: shopId };
			if (!GlobalConfig.defaultShopId && app.globalData.deliveryAndSelfTaking.location) {
				requestData.position = app.globalData.deliveryAndSelfTaking.location;
			}
			https.request('/rest/shop/detail', requestData).then((result) => {
				if (result.success && result.data) {
					this.shopInfo = result.data;
					this.initShopInfo = initShopInfo;
					this.getMenuList(shopId);
				}
			});
		},
		getMenuList(shopId) {
			https.request('/rest/menu/listWithGoods', { shopId }).then((result) => {
				if (result.success && result.data) {
					const goodsList = [];
					result.data.forEach((item) => {
						if (item.goodsList && item.goodsList.length > 0) {
							item.goodsList.forEach((goods) => {
								goods.mainImage = goods.mainImage ? GlobalConfig.ossUrl + goods.mainImage : '';
								goods.number = 0;
								goods.cartId = '';
							});
							goodsList.push(item);
						}
					});
					this.menuList = goodsList;
					this.$nextTick(() => {
						this.getElementTop();
						this.getShoppingCartList(shopId);
					});
					this.isLoading = false;
				}
			});
		},
		getShoppingCartList(shopId) {
			if (!this.diningContext.sceneToken) {
				this.shoppingCartList = [];
				this.totalNum = 0;
				this.totalPrice = 0;
				this.isStartDeliveryPrice = true;
				return;
			}
			https.request('/rest/member/shoppingCart/list', {
				sceneToken: this.diningContext.sceneToken,
				pageNo: -1,
				pageSize: 20
			}).then((result) => {
				if (result.success && result.data) {
					let packingCharges = 0;
					let totalNum = 0;
					let totalPrice = 0;

					this.menuList.forEach((menu, menuIndex) => {
						menu.goodsList.forEach((goods, goodsIndex) => {
							let number = 0;
							this.menuList[menuIndex].goodsList[goodsIndex].number = number;
							result.data.records.forEach((record) => {
								if (goods.goodsId == record.goodsId) {
									number = number + record.number;
									this.menuList[menuIndex].goodsList[goodsIndex].number = number;
									this.menuList[menuIndex].goodsList[goodsIndex].cartId = record.id;
								}
							});
						});
					});

					result.data.records.forEach((record) => {
						let specList = '';
						try {
							for (const key in JSON.parse(record.specList)) {
								specList = (specList ? specList + '/' : specList) + JSON.parse(record.specList)[key];
							}
						} catch (e) {
							specList = '';
						}
						record.restructure = specList;
						totalNum += record.number;
						totalPrice += record.price * record.number;
						if (!(record.goodsStatus == 1 || record.goodsStatus == 3 || record.goodsStatus == 4)) {
							packingCharges += record.packingCharges * record.number;
						}
					});

					totalPrice = utilHelper.toFixed(totalPrice, 2);
					this.isStartDeliveryPrice = true;
					this.priceDifference = 0;
					this.totalNum = totalNum;
					this.shoppingCartList = result.data.records;
					this.packingCharges = packingCharges;
					this.totalPrice = utilHelper.toFixed(totalPrice + packingCharges, 2);
				}
			});
		},
		commodityDetailTap(eOrId) {
			const goodsId = typeof eOrId === 'object' ? eOrId.currentTarget?.dataset?.id : eOrId;
			if (!goodsId) return;
			uni.navigateTo({
				url:
					'../detail/detail?id=' +
					goodsId +
					'&shopId=' +
					this.shopInfo.shop.id +
					'&initShopInfo=' +
					JSON.stringify(this.initShopInfo)
			});
		},
		openShoppingCart() {
			authService.checkIsLogin().then((result) => {
				if (result) {
					if (this.shoppingCartList.length > 0) {
						this.shoppingCartDialog = !this.shoppingCartDialog;
					}
					return;
				}
				app.globalData.checkIsAuth('scope.userInfo');
			});
		},
		closeShoppingCart() {
			this.shoppingCartDialog = false;
		},
		openSpecifications(eOrId) {
			const goodsId = typeof eOrId === 'object' ? eOrId.currentTarget?.dataset?.goodsid : eOrId;
			if (!goodsId) return;
			this.specificationsDialog = true;
			this.specLoading = true;
			this.goodsId = goodsId;
			this.getCommodityDetails(goodsId);
		},
		closeSpecifications() {
			if (this.shopInfo.shop.id) {
				this.getShoppingCartList(this.shopInfo.shop.id);
			}
			this.specificationsDialog = false;
			this.specList = [];
			this.specLoading = false;
		},
		getCommodityDetails(id) {
			https.request('/rest/goods/selectById', {
				id,
				position: app.globalData.deliveryAndSelfTaking.location
			}).then((result) => {
				if (result.success && result.data) {
					result.data.mainImage = result.data.mainImage ? GlobalConfig.ossUrl + result.data.mainImage : '';
					this.goodsInfo = result.data;
					this.priceAfter = result.data.price;
					this.selectByGoodsId(id);
				}
			});
		},
		selectByGoodsId(goodsId) {
			https.request('/rest/goodsSpecificationOption/selectByGoodsId', { goodsId }).then((result) => {
				if (result.success && result.data) {
					const specList = result.data;
					let price = this.goodsInfo.price;
					let specListString = '';
					for (const key in specList) {
						let isChecked = true;
						for (const keyof in specList[key]) {
							specList[key][keyof].checked = false;
							if (specList[key][keyof].stock == 1 && isChecked) {
								specList[key][keyof].checked = true;
								price = price + specList[key][keyof].price;
								specListString = (specListString ? specListString + '/' : specListString) + specList[key][keyof].name;
								isChecked = false;
							}
						}
					}
					this.specListString = specListString;
					this.specList = JSON.stringify(specList) == '{}' ? [] : specList;
					this.priceAfter = price;
					this.specLoading = false;
				}
			});
		},
		radioChange(e) {
			const checkValue = e.detail.value;
			const firstIndex = e.currentTarget.dataset.firstindex;
			const specList = this.specList;
			for (const j in specList[firstIndex]) {
				specList[firstIndex][j].checked = false;
			}
			specList[firstIndex][checkValue].checked = true;
			let price = this.goodsInfo.price;
			let specListString = '';
			for (const key in specList) {
				for (const keyof in specList[key]) {
					if (specList[key][keyof].checked) {
						price = price + specList[key][keyof].price;
						specListString = (specListString ? specListString + '/' : specListString) + specList[key][keyof].name;
					}
				}
			}
			this.specList = specList;
			this.specListString = specListString;
			this.priceAfter = price;
		},
		insertShoppingCart() {
			if (!this.diningContext.sceneToken) {
				toastService.showError('请先扫描餐桌二维码');
				return;
			}
			authService.checkIsLogin().then((result) => {
				toastService.showLoading();
				if (result) {
					const goodsSpecs = {};
					const specList = this.specList;
					for (const key in specList) {
						for (const keyof in specList[key]) {
							if (specList[key][keyof].checked) {
								goodsSpecs[key] = specList[key][keyof].name;
							}
						}
					}
					toastService.hideLoading();
					https.request('/rest/member/shoppingCart/insert', {
						goodsId: this.goodsId,
						specList: JSON.stringify(goodsSpecs),
						sceneToken: this.diningContext.sceneToken
					}).then((result) => {
						if (result.success) {
							this.specificationsDialog = false;
							this.specList = [];
							this.specLoading = true;
							this.getShoppingCartList(this.shopInfo.shop.id);
						}
					});
					return;
				}
				this.specificationsDialog = false;
				toastService.hideLoading();
				app.globalData.checkIsAuth('scope.userInfo');
			});
		},
		bindMinus(e) {
			toastService.showLoading();
			const cartId = e.currentTarget.dataset.cartid || e.currentTarget.dataset.cartId;
			const number = e.currentTarget.dataset.number;
			if (number == 1) {
				toastService.hideLoading();
				toastService.showModal(null, '确定不要这个了吗？', () => {
					toastService.showLoading();
					this.updateNumber(cartId, 1, 0, () => {
						if (this.shoppingCartList.length == 1) {
							this.shoppingCartDialog = false;
						}
						toastService.hideLoading();
						this.getShoppingCartList(this.shopInfo.shop.id);
					});
				});
				return;
			}
			this.updateNumber(cartId, 1, 0, () => {
				this.getShoppingCartList(this.shopInfo.shop.id);
			});
		},
		bindPlus(e) {
			toastService.showLoading();
			const numList = e.currentTarget.dataset.num.split(',');
			const items = this.shoppingCartList;
			items[numList[0]].number = Number(numList[1]) + 1;
			if (items[numList[0]].disable) {
				toastService.hideLoading();
				return;
			}
			this.updateNumber(items[numList[0]].id, 1, 1, () => {
				toastService.hideLoading();
				this.getShoppingCartList(this.shopInfo.shop.id);
			});
		},
		updateNumber(id, number, type, callback) {
			authService.checkIsLogin().then((result) => {
				if (!result) {
					app.globalData.checkIsAuth('scope.userInfo');
					return;
				}
				https.request('/rest/member/shoppingCart/updateNumber', {
					id,
					number,
					type,
					sceneToken: this.diningContext.sceneToken
				}).then((result) => {
					if (result.success) callback();
				});
			});
		},
		goToPay() {
			if (!this.isCartEnabled || !this.isStartDeliveryPrice || this.shoppingCartList.length <= 0) return;
			authService.checkIsLogin().then((result) => {
				if (!result) {
					app.globalData.checkIsAuth('scope.userInfo');
					return;
				}
				const startTime = this.shopInfo.shop.startTime;
				const endTime = this.shopInfo.shop.endTime;
				const isOperating = this.shopInfo.shop.isOperating;
				app.globalData.getIsBusiness(startTime, endTime, isOperating).then((result) => {
					if (!result) return;
					this.toPay();
				});
			});
		},
		toPay() {
			const list = this.shoppingCartList;
			const orderDetail = {
				actualPrice: this.totalPrice,
				fullPriceReduction: this.totalPrice,
				reducedPrice: 0,
				shopId: this.shopInfo.shop.id,
				diningTableId: this.diningContext.tableId,
				tableNo: this.diningContext.tableNo,
				tableName: this.diningContext.tableName,
				sceneToken: this.diningContext.sceneToken,
				initShopInfo: this.initShopInfo,
				selfOutActiveIndex: this.selfOutActiveIndex,
				orderDetailList: [],
				packingCharges: 0
			};
			for (const key in list) {
				orderDetail.packingCharges += list[key].packingCharges;
				orderDetail.orderDetailList.push({
					goodsId: list[key].goodsId,
					specList: list[key].specList,
					number: list[key].number,
					goodsName: list[key].goodsName,
					restructure: list[key].restructure,
					price: list[key].price,
					id: list[key].id,
					packingCharges: list[key].packingCharges,
					totalPrice: list[key].price * list[key].number
				});
			}
			setTimeout(() => {
				app.globalData.deliveryAndSelfTaking.selfOutActiveIndex = this.selfOutActiveIndex;
				app.globalData.deliveryAndSelfTaking.payType = 'car';
				app.globalData.deliveryAndSelfTaking.orderDetail = orderDetail;
				uni.navigateTo({ url: '../pay/pay' });
			}, 100);
		},
		getScrollTop(selector) {
			return new Promise((resolve) => {
				uni.createSelectorQuery()
					.in(this)
					.select(selector)
					.boundingClientRect((data) => {
						if (data && 'top' in data) resolve(data.top);
					})
					.exec();
			});
		},
		async getElementTop() {
			const p_arr = [];
			for (let i = 0; i < this.menuList.length; i++) {
				const resu = await this.getScrollTop('#into' + i);
				p_arr.push(resu - this.topHeight);
			}
			this.topArr = p_arr;
		},
		mainScroll(e) {
			if (!this.isMainScroll || this.topArr.length == 0) return;
			const top = e.detail.scrollTop;
			let index = -1;
			if (top >= this.topArr[this.topArr.length - 1]) {
				index = this.topArr.length - 1;
			} else {
				index = this.topArr.findIndex((item, idx) => this.topArr[idx + 1] >= top);
			}
			this.activeLeftTab = index < 0 ? 0 : index;
			this.activeTab = this.activeLeftTab;
		},
		mainTouch() {
			this.isMainScroll = true;
		},
		leftTap(indexOrEvent) {
			const index = typeof indexOrEvent === 'number' ? indexOrEvent : Number(indexOrEvent.currentTarget?.dataset?.index ?? 0);
			this.isMainScroll = false;
			this.activeLeftTab = index;
			this.activeTab = index;
		},
		close() {
			this.specificationsDialog = false;
			this.shoppingCartDialog = false;
		}
	}
};
</script>

<style>
.menu-page {
	position: relative;
	height: 100vh;
	overflow: hidden;
	background: #f7f7f7;
}

.menu-shell {
	height: 100%;
	padding: 24rpx 24rpx 220rpx;
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.menu-search {
	height: 86rpx;
	padding: 0 24rpx;
	display: flex;
	align-items: center;
	gap: 14rpx;
	border-radius: 16rpx;
	border: 1rpx solid #eaeaea;
	background: #fff;
	color: #666;
}

.menu-search__icon {
	font-size: 32rpx;
	color: #000;
	line-height: 1;
}

.menu-search__text {
	font-size: 24rpx;
	color: #666;
}

.menu-layout {
	flex: 1;
	min-height: 0;
	display: flex;
	border-radius: 16rpx;
	overflow: hidden;
	background: #fff;
	border: 1rpx solid #eaeaea;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.04);
}

.menu-content {
	flex: 1;
	min-width: 0;
	height: 100%;
	background: #fff;
}

.menu-content__inner {
	padding: 20rpx;
}

.menu-section + .menu-section {
	margin-top: 20rpx;
}

.menu-section__title {
	margin-bottom: 16rpx;
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.menu-section__list {
	display: flex;
	flex-direction: column;
	gap: 16rpx;
}

.menu-content__end {
	padding: 8rpx 0 24rpx;
	text-align: center;
	font-size: 22rpx;
	color: #999;
}

.menu-empty {
	margin: 24rpx;
}

.menu-cart {
	position: fixed;
	left: 24rpx;
	right: 24rpx;
	bottom: calc(env(safe-area-inset-bottom) + 24rpx);
	min-height: 108rpx;
	padding: 18rpx;
	display: flex;
	align-items: center;
	gap: 18rpx;
	background: #000;
	color: #fff;
	border-radius: 24rpx;
	box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	z-index: 20;
}

.menu-cart--disabled {
	opacity: 0.65;
}

.menu-cart__left {
	flex: 1;
	min-width: 0;
	display: flex;
	align-items: center;
	gap: 16rpx;
}

.menu-cart__bag {
	position: relative;
	width: 64rpx;
	height: 64rpx;
	border-radius: 50%;
	background: #fff;
	color: #000;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
}

.menu-cart__bag-text {
	font-size: 26rpx;
	font-weight: 700;
	line-height: 1;
}

.menu-cart__badge {
	position: absolute;
	top: -10rpx;
	right: -6rpx;
	min-width: 32rpx;
	height: 32rpx;
	padding: 0 8rpx;
	border-radius: 999px;
	background: #fff;
	color: #000;
	font-size: 18rpx;
	font-weight: 600;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2rpx solid #000;
}

.menu-cart__info {
	display: flex;
	flex-direction: column;
	min-width: 0;
}

.menu-cart__price {
	font-size: 30rpx;
	font-weight: 600;
	color: #fff;
}

.menu-cart__hint,
.menu-cart__sub {
	margin-top: 4rpx;
	font-size: 20rpx;
	color: rgba(255, 255, 255, 0.72);
}

.menu-cart__right {
	flex-shrink: 0;
	min-width: 172rpx;
	height: 72rpx;
	padding: 0 22rpx;
	border-radius: 999px;
	background: #fff;
	color: #000;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 26rpx;
	font-weight: 600;
}

.ui-overlay {
	position: fixed;
	inset: 0;
	z-index: 30;
	background: rgba(0, 0, 0, 0.28);
	display: flex;
	align-items: flex-end;
}

.ui-sheet {
	width: 100%;
	background: #fff;
	border-radius: 24rpx 24rpx 0 0;
	padding: 24rpx;
	max-height: 88vh;
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.ui-sheet__head {
	display: flex;
	flex-direction: column;
	gap: 8rpx;
}

.ui-sheet__title {
	font-size: 32rpx;
	font-weight: 600;
	color: #000;
}

.ui-sheet__sub {
	font-size: 22rpx;
	color: #666;
}

.ui-sheet__body {
	flex: 1;
	min-height: 0;
}

.ui-sheet--cart {
	padding-bottom: calc(env(safe-area-inset-bottom) + 24rpx);
}

.cart-list {
	display: flex;
	flex-direction: column;
	gap: 16rpx;
}

.cart-item {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 18rpx;
	padding: 16rpx 0;
	border-bottom: 1rpx solid #f1f1f1;
}

.cart-item__meta {
	flex: 1;
	min-width: 0;
	display: flex;
	flex-direction: column;
	gap: 6rpx;
}

.cart-item__name {
	font-size: 26rpx;
	font-weight: 600;
	color: #000;
}

.cart-item__spec {
	font-size: 20rpx;
	color: #666;
}

.cart-item__right {
	display: flex;
	flex-direction: column;
	align-items: flex-end;
	gap: 10rpx;
	flex-shrink: 0;
}

.cart-item__price {
	font-size: 24rpx;
	font-weight: 600;
	color: #000;
}

.cart-stepper {
	display: flex;
	align-items: center;
	gap: 10rpx;
}

.cart-stepper__btn {
	width: 40rpx;
	height: 40rpx;
	border-radius: 50%;
	border: 1rpx solid #000;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.cart-stepper__num {
	min-width: 28rpx;
	text-align: center;
	font-size: 24rpx;
	font-weight: 600;
	color: #000;
}

.cart-summary {
	display: flex;
	flex-direction: column;
	gap: 14rpx;
}

.cart-summary__row {
	display: flex;
	align-items: center;
	justify-content: space-between;
	font-size: 24rpx;
	color: #666;
}

.cart-summary__row--total {
	margin-top: 4rpx;
	font-size: 26rpx;
	font-weight: 600;
	color: #000;
}

.ui-sheet--spec {
	padding-bottom: calc(env(safe-area-inset-bottom) + 24rpx);
}

.spec-head {
	display: flex;
	gap: 18rpx;
	padding: 14rpx;
	border-radius: 16rpx;
	background: #f7f7f7;
}

.spec-head__image {
	width: 148rpx;
	height: 148rpx;
	border-radius: 12rpx;
	background: #fff;
	flex-shrink: 0;
}

.spec-head__body {
	flex: 1;
	min-width: 0;
	display: flex;
	flex-direction: column;
	gap: 8rpx;
	justify-content: center;
}

.spec-head__name {
	font-size: 28rpx;
	font-weight: 600;
	color: #000;
}

.spec-head__price {
	font-size: 30rpx;
	font-weight: 600;
	color: #000;
}

.spec-head__tips {
	font-size: 20rpx;
	color: #666;
}

.spec-list {
	display: flex;
	flex-direction: column;
	gap: 18rpx;
	padding-top: 12rpx;
}

.spec-group {
	display: flex;
	flex-direction: column;
	gap: 12rpx;
}

.spec-group__title {
	font-size: 24rpx;
	font-weight: 600;
	color: #000;
}

.spec-group__options {
	display: flex;
	flex-wrap: wrap;
	gap: 12rpx;
}

.spec-option {
	display: inline-flex;
	align-items: center;
	gap: 8rpx;
	min-height: 52rpx;
	padding: 0 18rpx;
	border-radius: 999px;
	border: 1rpx solid #eaeaea;
	color: #000;
	font-size: 22rpx;
	background: #fff;
}

.spec-option--active {
	border-color: #000;
	background: #000;
	color: #fff;
}

.spec-option--disabled {
	opacity: 0.35;
}

.spec-option__radio {
	transform: scale(0.8);
}

.spec-loading {
	padding: 24rpx 0 8rpx;
	font-size: 22rpx;
	color: #666;
	text-align: center;
}
</style>
