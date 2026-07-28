<template>
	<view class="menu-page page-bg-warm">
		<!-- 左右分栏主体 -->
		<view class="menu-body" :style="'height:' + (winHeight - (carHeight || 70) - 5) + 'px;'">
			<!-- 左侧分类栏 -->
			<scroll-view :scroll-y="true" :enable-flex="true" class="menu-left"
				:scroll-into-view="'left' + activeLeftTab" :scroll-with-animation="true">
				<block v-for="(menu, menuIndex) in menuList">
					<view :id="'left' + menuIndex" v-if="menu.goodsList.length > 0" @tap="leftTap"
						:data-index="menuIndex"
						:class="(menuIndex == activeLeftTab) ? 'left-item left-item--active' : 'left-item'">
						<view class="left-indicator" v-if="menuIndex == activeLeftTab"></view>
						<text class="left-text">{{ menu.name }}</text>
					</view>
				</block>
			</scroll-view>

			<!-- 右侧商品列表 -->
			<scroll-view :scroll-y="true" :enable-flex="true" class="menu-right"
				@scroll="mainScroll" @touchstart="mainTouch"
				:scroll-into-view="'into' + activeTab" :scroll-with-animation="true" id="scroll_right">
				<view class="menu-right-inner">
					<view v-for="(menu, menuIndex) in menuList" :id="'into' + menuIndex" :key="menuIndex">
						<view class="category-title" v-if="menu.goodsList.length > 0">
							<text>{{ menu.name }}</text>
						</view>
						<block v-for="(goods, goodsIndex) in menu.goodsList" :key="goodsIndex">
							<view :class="'goods-card ' + (goods.goodsStatus == 4 ? 'goods-card--soldout' : '')"
								hover-class="hover-class-public"
								@tap="parseEventDynamicCode($event, goods.goodsStatus == 4 ? '' : 'commodityDetailTap')"
								:data-id="goods.goodsId">
								<image
									:src="goods.mainImage ? goods.mainImage : '/static/assets/common/load-image.png'"
									mode="aspectFill" class="goods-image" />
								<view class="sell-out-mark" v-if="goods.goodsStatus == 4">售罄</view>
								<view class="goods-info">
									<view class="goods-name">
										<text>{{ goods.goodsName }}</text>
										<text class="goods-tag" v-if="goods.isRecommend">招牌</text>
									</view>
									<view class="goods-desc out_of_range one_row" v-if="goods.briefDescription">
										{{ goods.briefDescription }}
									</view>
									<view class="goods-bottom">
										<text class="price-accent">¥{{ goods.goodsPrice }}</text>
										<view class="goods-action"
											v-if="!shopInfo.isOutofDeliveryRange && shopInfo.isOperatingOfShop && shopInfo.shop.isOperating">
											<block v-if="goods.number > 0">
												<view class="stepper">
													<view class="step-btn reduce-btn" @click.stop="bindMinus"
														:data-cartId="goods.cartId" :data-number="goods.number">−</view>
													<input disabled type="number" :value="goods.number"
														class="step-input" />
													<view class="step-btn add-btn"
														@click.stop="parseEventDynamicCode($event, goods.goodsStatus != 4 ? 'openSpecifications' : '')"
														:data-goodsId="goods.goodsId">＋</view>
												</view>
											</block>
											<block v-else>
												<view :class="'btn-add-circle ' + (goods.goodsStatus == 4 ? 'isEnd' : '')"
													:data-goodsId="goods.goodsId"
													@click.stop="parseEventDynamicCode($event, goods.goodsStatus != 4 ? 'openSpecifications' : '')">＋</view>
											</block>
										</view>
									</view>
								</view>
							</view>
						</block>
						<view v-if="(menuList.length - 1) == menuIndex" class="more_box">没有更多啦~</view>
					</view>
				</view>
			</scroll-view>
		</view>

		<!-- 底部购物车栏 -->
		<view class="cart-bar" id="shopping-cart-detail">
			<view class="cart-bar-inner"
				:class="shopInfo.isOutofDeliveryRange || !shopInfo.isOperatingOfShop || !shopInfo.shop.isOperating ? 'cart-bar--disabled' : ''">
				<view class="cart-left" @tap="
					parseEventDynamicCode($event, !shopInfo.isOutofDeliveryRange && shopInfo.isOperatingOfShop && shopInfo.shop.isOperating ? 'openShoppingCart' : '')
				">
					<view class="cart-icon-wrap">
						<text class="cart-icon">🛒</text>
						<view class="cart-badge" v-if="totalNum > 0">{{ totalNum }}</view>
					</view>
					<view class="cart-price-info">
						<view class="cart-price" v-if="shoppingCartList.length > 0">¥{{ totalPrice }}</view>
						<view class="cart-price-hint" v-else>暂未选购商品</view>
						<view class="cart-fee-hint" v-if="shoppingCartList.length > 0">
							另需配送费 ¥{{ shopInfo.shop.startDeliveryPrice || 0 }}
						</view>
					</view>
				</view>
				<view :class="(isStartDeliveryPrice ? 'cart-submit cart-submit--ready' : 'cart-submit cart-submit--pending')"
					@tap="
						parseEventDynamicCode($event,
							shoppingCartList.length <= 0 || !isStartDeliveryPrice ||
							shopInfo.isOutofDeliveryRange || !shopInfo.isOperatingOfShop ||
							!shopInfo.shop.isOperating ? '' : 'goToPay')
				">
					{{ isStartDeliveryPrice ? '去结算' : '差 ¥' + priceDifference + ' 起送' }}
				</view>
			</view>
		</view>

		<!-- 购物车弹窗 -->
		<van-action-sheet v-model:show="shoppingCartDialog" :show="shoppingCartDialog" title="已选商品"
			@close="closeShoppingCart" @cancel="closeShoppingCart" z-index="2">
			<view class="content">
				<scroll-view style="height: 55vh" scroll-y>
					<view class="cart-pop-item" v-for="(item, index) in shoppingCartList" :key="index">
						<view class="cart-pop-name-wrap">
							<view class="cart-pop-name out_of_range one_row">{{ item.goodsName }}</view>
							<view class="cart-pop-spec out_of_range one_row">{{ item.restructure }}</view>
						</view>
						<view class="cart-pop-right">
							<view class="price-accent">¥{{ item.price }}</view>
							<view class="stepper">
								<view class="step-btn reduce-btn" @tap="bindMinus" :data-cartid="item.id"
									:data-number="item.number">−</view>
								<input disabled type="number" :value="item.number" class="step-input" />
								<view class="step-btn add-btn" @tap="bindPlus"
									:data-num="index + ',' + item.number">＋</view>
							</view>
						</view>
					</view>
					<view class="cart-pop-packing">
						<text>包装费</text>
						<text>¥{{ packingCharges }}</text>
					</view>
				</scroll-view>
			</view>
		</van-action-sheet>

		<!-- 规格弹窗 -->
		<van-action-sheet :show="specificationsDialog" @close="closeSpecifications" @cancel="closeSpecifications"
			title="选择规格">
			<view class="content">
				<view class="goods-info-view">
					<image :src="goodsInfo.mainImage" mode="aspectFill" class="commodity-image"></image>
					<view>
						<view class="goods-info-name">{{ goodsInfo.name }}</view>
						<view class="goods-info-specListString">已选：{{ specListString }}</view>
						<view class="goods-info-price price-accent">¥{{ priceAfter }}</view>
					</view>
				</view>
				<scroll-view scroll-y style="height: 50vh">
					<view class="commdity-name-type-view">
						<view class="commdity-type-item" v-for="(item, key) in specList" :key="key">
							<view class="commdity-type-name">{{ key }}</view>
							<radio-group class="radio-group" @change="radioChange" :data-firstIndex="key">
								<label :class="
									'group-label theme-border ' +
									(!item.stock ? 'disabled-group-label' : '') +
									' ' +
									(item.checked ? 'active theme-bg' : 'theme-color-border') +
									' out_of_range one_row'
								" v-for="(item, index) in item" :key="index">
									<radio :value="index" :checked="item.checked" :disabled="!item.stock" class="radio" />
									{{ item.name }}
								</label>
							</radio-group>
						</view>
						<view class="loading_box" v-if="specLoading&&specList.length==0">
							<van-loading custom-class="loading_box_class" vertical>加载中...</van-loading>
						</view>
						<van-empty v-if="!specLoading&&specList.length <= 0" description="暂无规格"></van-empty>
					</view>
				</scroll-view>
				<view slot="footer" class="position-sticky-bottom">
					<view class="good-choice-btn theme-bg" @tap="insertShoppingCart">我选好了</view>
				</view>
			</view>
		</van-action-sheet>
	</view>
</template>

<script>
	import GlobalConfig from '../../../utils/global-config';
	import https from '../../../utils/http';
	import authService from '../../../utils/auth';
	import toastService from '../../../utils/toast.service';
	import utilHelper from '../../../utils/util';

	let app = null;
	export default {
		data() {
			return {
				menuList: [],
				shopInfo: {
					shop: {
						id: '',
						name: '',
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
				staticImg: ''
			};
		},
		onLoad(options) {
			app = getApp();
		},
		onShow() {
			var selfOutActiveIndex = 0;
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

			if (this.shopInfo.shop.id) {
				this.getShoppingCartList(this.shopInfo.shop.id);
			}

			this.isLoading = true;
			this.menuList = [];
			this.getShopList();

			this.selfAdaption();
			var _this = this;
			this.$nextTick(() => {
				setTimeout(() => { _this.getElementTop(); }, 500);
				setTimeout(() => { _this.isLoading = false; }, 2000);
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
				var _this = this;
				uni.getSystemInfo({
					success(res) {
						_this.winHeight = res.windowHeight;
						setTimeout(() => {
							uni.createSelectorQuery().in(_this).selectAll('#shopping-cart-detail')
								.boundingClientRect(function (rects) {
									if (rects && rects.length > 0) {
										_this.carHeight = rects[0].height;
									}
								}).exec();
						}, 800);
					}
				});
			},
			getShopList() {
				if (GlobalConfig.defaultShopId) {
					this.getShopInfo({ id: GlobalConfig.defaultShopId, shopAdditionalVo: { deliveryDistanceText: '' } });
					return;
				}
				if (app.globalData.deliveryAndSelfTaking.location) {
					var _this = this;
					https.request('/rest/shop/list', {
						pageNo: -1, pageSize: 1, position: app.globalData.deliveryAndSelfTaking.location
					}).then((result) => {
						if (result.success && result.data.records.length > 0) {
							_this.getShopInfo(result.data.records[0]);
						} else {
							setTimeout(() => { _this.isLoading = false; }, 1000);
						}
					});
				}
			},
			getShopInfo(initShopInfo) {
				var shopId = initShopInfo.id;
				var requestData = { id: shopId };
				if (!GlobalConfig.defaultShopId && app.globalData.deliveryAndSelfTaking.location) {
					requestData.position = app.globalData.deliveryAndSelfTaking.location;
				}
				https.request('/rest/shop/detail', requestData).then((result) => {
					if (result.success && result.data) {
						this.shopInfo = result.data;
						this.initShopInfo = initShopInfo;
						this.getMenuList(shopId);
						this.getShoppingCartList(shopId);
					}
				});
			},
			getMenuList(shopId) {
				var _this = this;
				https.request('/rest/menu/listWithGoods', { shopId: shopId }).then((result) => {
					if (result.success && result.data) {
						var goodsList = [];
						result.data.forEach((aitem) => {
							if (aitem.goodsList.length > 0) {
								aitem.goodsList.forEach((bitem) => {
									bitem.mainImage = bitem.mainImage ? GlobalConfig.ossUrl + bitem.mainImage : '';
									bitem.number = 0;
									bitem.cartId = '';
								});
								goodsList.push(aitem);
							}
						});
						this.menuList = goodsList;
						setTimeout(() => { _this.isLoading = false; }, 0);
					}
				});
			},
			getShoppingCartList(shopId) {
				var _this = this;
				https.request('/rest/member/shoppingCart/list', {
					shopId: shopId, pageNo: -1, pageSize: 20
				}).then((result) => {
					if (result.success && result.data) {
						var packingCharges = 0;
						var totalNum = 0;
						var totalPrice = 0;
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
								for (var key in JSON.parse(record.specList)) {
									specList = (specList ? specList + '/' : specList) + JSON.parse(record.specList)[key];
								}
							} catch (e) { }
							record.restructure = specList;
							totalNum = totalNum + record.number;
							totalPrice += record.price * record.number;
							if (!(record.goodsStatus == 1 || record.goodsStatus == 3 || record.goodsStatus == 4)) {
								packingCharges += record.packingCharges * record.number;
							}
						});
						totalPrice = utilHelper.toFixed(totalPrice, 2);
						var isStartDeliveryPrice = false;
						var priceDifference = 0;
						var startDeliveryPrice = this.shopInfo.shop.startDeliveryPrice || 0;
						if (totalPrice + packingCharges >= startDeliveryPrice) {
							isStartDeliveryPrice = true;
						}
						priceDifference = startDeliveryPrice - (totalPrice + packingCharges);
						this.totalNum = totalNum;
						this.priceDifference = utilHelper.toFixed(priceDifference, 2);
						this.isStartDeliveryPrice = isStartDeliveryPrice;
						this.shoppingCartList = result.data.records;
						this.packingCharges = packingCharges;
						this.totalPrice = utilHelper.toFixed(totalPrice + packingCharges, 2);
					}
				});
			},
			commodityDetailTap(e) {
				uni.navigateTo({
					url: '../detail/detail?id=' + e.currentTarget.dataset.id + '&shopId=' + this.shopInfo.shop.id +
						'&initShopInfo=' + JSON.stringify(this.initShopInfo)
				});
			},
			openShoppingCart() {
				var _this = this;
				authService.checkIsLogin().then((result) => {
					if (result) {
						if (_this.shoppingCartList.length > 0) {
							_this.shoppingCartDialog = !_this.shoppingCartDialog;
						}
						return;
					}
					app.globalData.checkIsAuth('scope.userInfo');
				});
			},
			closeShoppingCart() { this.shoppingCartDialog = false; },
			openSpecifications(e) {
				this.specificationsDialog = true;
				this.specLoading = true;
				this.goodsId = e.currentTarget.dataset.goodsid;
				this.getCommodityDetails(e.currentTarget.dataset.goodsid);
			},
			closeSpecifications() {
				this.getShoppingCartList(this.shopInfo.shop.id);
				this.specificationsDialog = false;
				this.specList = [];
				this.specLoading = false;
			},
			getCommodityDetails(id) {
				https.request('/rest/goods/selectById', {
					id: id, position: app.globalData.deliveryAndSelfTaking.location
				}).then((result) => {
					if (result.success && result.data) {
						result.data.mainImage = GlobalConfig.ossUrl + result.data.mainImage;
						this.goodsInfo = result.data;
						this.priceAfter = result.data.price;
						this.selectByGoodsId(id);
					}
				});
			},
			selectByGoodsId(goodsId) {
				https.request('/rest/goodsSpecificationOption/selectByGoodsId', { goodsId: goodsId }).then((result) => {
					if (result.success && result.data) {
						let specList = result.data;
						let price = this.goodsInfo.price;
						let specListString = '';
						for (let key in specList) {
							let isChecked = true;
							for (let keyof in specList[key]) {
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
						this.specLoading = false;
					}
				});
			},
			radioChange(e) {
				var checkValue = e.detail.value;
				let firstIndex = e.currentTarget.dataset.firstindex;
				let specList = this.specList;
				for (var j in specList[firstIndex]) { specList[firstIndex][j].checked = false; }
				specList[firstIndex][checkValue].checked = true;
				let price = this.goodsInfo.price;
				let specListString = '';
				for (let key in specList) {
					for (let keyof in specList[key]) {
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
				var _this = this;
				authService.checkIsLogin().then((result) => {
					toastService.showLoading();
					if (result) {
						let goodsSpecs = {};
						let specList = _this.specList;
						for (let key in specList) {
							for (let keyof in specList[key]) {
								if (specList[key][keyof].checked) {
									goodsSpecs[key] = specList[key][keyof].name;
								}
							}
						}
						toastService.hideLoading();
						https.request('/rest/member/shoppingCart/insert', {
							goodsId: _this.goodsId, specList: JSON.stringify(goodsSpecs), shopId: _this.shopInfo.shop.id
						}).then((result) => {
							if (result.success) {
								_this.specificationsDialog = false;
								_this.specList = [];
								_this.specLoading = true;
								_this.getShoppingCartList(_this.shopInfo.shop.id);
							}
						});
						return;
					}
					_this.specificationsDialog = false;
					toastService.hideLoading();
					app.globalData.checkIsAuth('scope.userInfo');
				});
			},
			bindMinus(e) {
				toastService.showLoading();
				var _this = this;
				let cartId = e.currentTarget.dataset.cartid || e.currentTarget.dataset.cartId;
				let number = e.currentTarget.dataset.number;
				if (number == 1) {
					toastService.hideLoading();
					toastService.showModal(null, '确定不要这个了吗？', function confirm() {
						toastService.showLoading();
						_this.updateNumber(cartId, 1, 0, function () {
							if (_this.shoppingCartList.length == 1) { _this.shoppingCartDialog = false; }
							toastService.hideLoading();
							_this.getShoppingCartList(_this.shopInfo.shop.id);
						});
					});
					return;
				}
				this.updateNumber(cartId, 1, 0, function () {
					_this.getShoppingCartList(_this.shopInfo.shop.id);
				});
			},
			bindPlus(e) {
				toastService.showLoading();
				var _this = this;
				let numList = e.currentTarget.dataset.num.split(',');
				let items = this.shoppingCartList;
				items[numList[0]].number = Number(numList[1]) + 1;
				if (items[numList[0]].disable) { toastService.hideLoading(); return; }
				this.updateNumber(items[numList[0]].id, 1, 1, function () {
					toastService.hideLoading();
					_this.getShoppingCartList(_this.shopInfo.shop.id);
				});
			},
			updateNumber(id, number, type, callback) {
				authService.checkIsLogin().then((result) => {
					if (!result) { app.globalData.checkIsAuth('scope.userInfo'); return; }
					https.request('/rest/member/shoppingCart/updateNumber', {
						id: id, number: number, type: type
					}).then((result) => { if (result.success) callback(); });
				});
			},
			goToPay() {
				authService.checkIsLogin().then((result) => {
					if (!result) { app.globalData.checkIsAuth('scope.userInfo'); return; }
					let startTime = this.shopInfo.shop.startTime;
					let endTime = this.shopInfo.shop.endTime;
					let isOperating = this.shopInfo.shop.isOperating;
					app.globalData.getIsBusiness(startTime, endTime, isOperating).then((result) => {
						if (!result) return;
						this.toPay();
					});
				});
			},
			toPay() {
				var list = this.shoppingCartList;
				var orderDetail = {};
				orderDetail.actualPrice = this.totalPrice;
				orderDetail.fullPriceReduction = this.totalPrice;
				orderDetail.reducedPrice = 0;
				orderDetail.shopId = this.shopInfo.shop.id;
				orderDetail.initShopInfo = this.initShopInfo;
				orderDetail.selfOutActiveIndex = this.selfOutActiveIndex;
				orderDetail.orderDetailList = [];
				orderDetail.packingCharges = 0;
				for (var key in list) {
					orderDetail.packingCharges = orderDetail.packingCharges + list[key].packingCharges;
					orderDetail.orderDetailList.push({
						goodsId: list[key].goodsId, specList: list[key].specList,
						number: list[key].number, goodsName: list[key].goodsName,
						restructure: list[key].restructure, price: list[key].price,
						id: list[key].id, packingCharges: list[key].packingCharges,
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
				var _this = this;
				return new Promise((resolve) => {
					uni.createSelectorQuery().in(_this).select(selector).boundingClientRect(data => {
						if (data && 'top' in data) resolve(data.top);
					}).exec();
				});
			},
			async getElementTop() {
				let p_arr = [];
				for (let i = 0; i < this.menuList.length; i++) {
					const resu = await this.getScrollTop('#into' + i);
					p_arr.push(resu - this.topHeight);
				}
				this.topArr = p_arr;
			},
			mainScroll(e) {
				if (!this.isMainScroll || this.topArr.length == 0) return;
				let top = e.detail.scrollTop;
				let index = -1;
				if (top >= this.topArr[this.topArr.length - 1]) {
					index = this.topArr.length - 1;
				} else {
					index = this.topArr.findIndex((item, idx) => this.topArr[idx + 1] >= top);
				}
				this.activeLeftTab = (index < 0 ? 0 : index);
			},
			mainTouch() { this.isMainScroll = true; },
			leftTap(e) {
				let index = e.currentTarget.dataset.index;
				this.isMainScroll = false;
				this.activeLeftTab = Number(index);
				this.activeTab = Number(index);
			},
			parseEventDynamicCode(e, method) {
				if (method && this[method]) { this[method](e); }
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
		width: 100%;
		display: flex;
		flex-direction: column;
		height: 100vh;
		overflow: hidden;
	}

	.menu-body {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	/* 左侧分类 */
	.menu-left {
		width: 170rpx;
		background: #F8F6F2;
		flex-shrink: 0;
	}

	.left-item {
		position: relative;
		display: flex;
		align-items: center;
		padding: 28rpx 16rpx 28rpx 20rpx;
		font-size: 26rpx;
		color: #8C8C88;
	}

	.left-item--active {
		background: #FFF;
		font-weight: 700;
		color: #4A2605;
		border-radius: 0 16rpx 16rpx 0;
	}

	.left-indicator {
		position: absolute;
		left: 0;
		top: 50%;
		transform: translateY(-50%);
		width: 6rpx;
		height: 32rpx;
		background: #4A2605;
		border-radius: 3rpx;
	}

	.left-text {
		margin-left: 8rpx;
	}

	/* 右侧列表 */
	.menu-right {
		flex: 1;
		background: #FFF;
		border-radius: 16rpx 0 0 0;
	}

	.menu-right-inner {
		padding: 0 20rpx;
	}

	.category-title {
		padding: 24rpx 8rpx 16rpx;
		font-size: 28rpx;
		font-weight: 700;
		color: #2D1A08;
		background: #FFF;
		position: sticky;
		top: 0;
		z-index: 1;
	}

	/* 商品卡片 */
	.goods-card {
		display: flex;
		padding: 16rpx 0;
		position: relative;
		border-bottom: 1rpx solid #F5F2ED;
	}

	.goods-card--soldout {
		opacity: 0.5;
	}

	.goods-image {
		width: 170rpx;
		height: 166rpx;
		border-radius: 12rpx;
		flex-shrink: 0;
	}

	.sell-out-mark {
		position: absolute;
		top: 50%;
		left: 85rpx;
		transform: translate(-50%, -50%);
		background: rgba(0, 0, 0, 0.6);
		color: #fff;
		padding: 8rpx 16rpx;
		border-radius: 8rpx;
		font-size: 24rpx;
	}

	.goods-info {
		flex: 1;
		padding-left: 16rpx;
		display: flex;
		flex-direction: column;
		justify-content: space-between;
	}

	.goods-name {
		font-size: 28rpx;
		font-weight: 600;
		color: #2D1A08;
		display: flex;
		align-items: center;
	}

	.goods-tag {
		margin-left: 10rpx;
		padding: 2rpx 10rpx;
		font-size: 18rpx;
		font-weight: 600;
		background: #F05A2A;
		color: #FFF;
		border-radius: 6rpx;
	}

	.goods-desc {
		font-size: 22rpx;
		color: #B5B0A4;
		margin-top: 4rpx;
	}

	.goods-bottom {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-top: 8rpx;
	}

	.goods-bottom .price-accent {
		font-size: 30rpx;
	}

	/* 步进器 */
	.stepper {
		display: flex;
		align-items: center;
		gap: 6rpx;
	}

	.step-btn {
		width: 44rpx;
		height: 44rpx;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 28rpx;
		font-weight: 600;
	}

	.add-btn {
		background: #4A2605;
		color: #FFF;
	}

	.reduce-btn {
		color: #4A2605;
		border: 1rpx solid #4A2605;
	}

	.step-input {
		width: 40rpx;
		text-align: center;
		font-size: 26rpx;
		font-weight: 600;
		color: #2D1A08;
		background: transparent;
	}

	/* 底部购物车栏 */
	.cart-bar {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 10rpx 24rpx calc(10rpx + env(safe-area-inset-bottom));
		background: transparent;
		z-index: 999;
	}

	.cart-bar-inner {
		display: flex;
		align-items: center;
		background: #4A2605;
		border-radius: 50rpx;
		padding: 8rpx 12rpx 8rpx 20rpx;
		box-shadow: 0 8rpx 28rpx rgba(74, 38, 5, 0.3);
		height: 100rpx;
	}

	.cart-bar--disabled {
		opacity: 0.5;
	}

	.cart-left {
		flex: 1;
		display: flex;
		align-items: center;
	}

	.cart-icon-wrap {
		position: relative;
		margin-right: 16rpx;
	}

	.cart-icon {
		font-size: 44rpx;
	}

	.cart-badge {
		position: absolute;
		top: -8rpx;
		right: -14rpx;
		min-width: 32rpx;
		height: 32rpx;
		line-height: 32rpx;
		text-align: center;
		background: #F05A2A;
		color: #FFF;
		font-size: 20rpx;
		font-weight: 700;
		border-radius: 16rpx;
		padding: 0 6rpx;
	}

	.cart-price-info {
		color: #FFF;
	}

	.cart-price {
		font-size: 34rpx;
		font-weight: 700;
	}

	.cart-price-hint {
		font-size: 26rpx;
		color: rgba(255, 255, 255, 0.6);
	}

	.cart-fee-hint {
		font-size: 20rpx;
		color: rgba(255, 255, 255, 0.5);
		margin-top: 2rpx;
	}

	.cart-submit {
		padding: 20rpx 36rpx;
		border-radius: 50rpx;
		font-size: 28rpx;
		font-weight: 700;
		white-space: nowrap;
	}

	.cart-submit--ready {
		background: #FFF9F2;
		color: #4A2605;
	}

	.cart-submit--pending {
		background: rgba(255, 255, 255, 0.2);
		color: rgba(255, 255, 255, 0.8);
	}

	/* 购物车弹窗 */
	.content {
		padding: 0 16px 16px 16px;
	}

	.cart-pop-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 20rpx 0;
		border-bottom: 1rpx solid #F5F2ED;
	}

	.cart-pop-name-wrap {
		flex: 1;
	}

	.cart-pop-name {
		font-size: 28rpx;
		font-weight: 600;
		color: #2D1A08;
	}

	.cart-pop-spec {
		font-size: 22rpx;
		color: #9A9A8E;
		margin-top: 4rpx;
	}

	.cart-pop-right {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 12rpx;
	}

	.cart-pop-packing {
		display: flex;
		justify-content: space-between;
		padding: 20rpx 0;
		font-size: 26rpx;
		color: #2D1A08;
	}

	/* 规格弹窗 */
	.goods-info-view {
		display: flex;
		padding: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.goods-info-view .commodity-image {
		width: 160rpx;
		height: 160rpx;
		border-radius: 12rpx;
		margin-right: 20rpx;
	}

	.goods-info-name {
		font-size: 30rpx;
		font-weight: 700;
		color: #2D1A08;
		margin-bottom: 8rpx;
	}

	.goods-info-specListString {
		font-size: 24rpx;
		color: #9A9A8E;
		margin-bottom: 10rpx;
	}

	.goods-info-price {
		font-size: 32rpx;
	}

	.commdity-name-type-view {
		padding: 20rpx;
	}

	.commdity-type-item {
		margin-bottom: 20rpx;
	}

	.commdity-type-name {
		font-size: 26rpx;
		font-weight: 600;
		color: #2D1A08;
		margin-bottom: 14rpx;
	}

	.radio-group {
		display: flex;
		flex-wrap: wrap;
		gap: 12rpx;
	}

	.group-label {
		padding: 10rpx 18rpx;
		font-size: 24rpx;
		border-radius: 8rpx;
	}

	.good-choice-btn {
		width: calc(100% - 32rpx);
		padding: 26rpx 0;
		text-align: center;
		font-size: 30rpx;
		font-weight: 700;
		border-radius: 50rpx;
		margin: 16rpx;
	}

	.position-sticky-bottom {
		position: sticky;
		bottom: 0;
		background: #fff;
	}
</style>
