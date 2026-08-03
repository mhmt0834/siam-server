<template>
	<view class="pay-page page-bg-warm">
		<!-- 就餐方式 -->
		<view class="pay-card">
			<view class="pay-card-title">就餐方式</view>
			<view class="dining-mode">
				<view class="mode-btn mode-btn--active">
					店内就餐
				</view>
			</view>
			<view class="address-info" v-if="shopInfo && shopInfo.shop.name">
				<text class="address-label">就餐门店：</text>
				<text>{{ shopInfo.shop.name }}</text>
			</view>
			<view class="address-info" v-if="orderDetail.tableName">
				<text class="address-label">桌号：</text>
				<text>{{ orderDetail.tableName }}</text>
			</view>
		</view>

		<!-- 订单内容 -->
		<view class="pay-card">
			<view class="pay-card-title">订单内容</view>
			<view class="order-item" v-for="(item, index) in orderDetail.orderDetailList" :key="index">
				<image v-if="item.goodsImage" :src="item.goodsImage" mode="aspectFill" class="order-item-img" />
				<view class="order-item-info">
					<view class="order-item-name">{{ item.goodsName }}</view>
					<view class="order-item-spec" v-if="item.restructure">{{ item.restructure }}</view>
				</view>
				<view class="order-item-right">
					<text class="price-accent">¥{{ item.price }}</text>
					<text class="order-item-qty">x{{ item.number }}</text>
				</view>
			</view>
			<!-- 包装费 -->
			<view class="order-extra" v-if="orderDetail.packingCharges > 0">
				<text>包装费</text>
				<text>¥{{ orderDetail.packingCharges }}</text>
			</view>
		</view>

		<!-- 备注 -->
		<view class="pay-card pay-card--row" @tap="focusRemarks">
			<text>备注</text>
			<text class="pay-card-hint">口味、忌口等要求 ›</text>
		</view>
		<view class="remarks-area" v-if="showRemarks">
			<textarea class="remarks-textarea" @input="remarksInput" maxlength="30" placeholder="口味、忌口等要求（选填）"
				placeholder-class="textarea-placeholder"></textarea>
			<view class="remarks-count">{{ inputLength }}/30</view>
		</view>

		<!-- 优惠券 -->
		<view class="pay-card pay-card--row" @tap="parseEventDynamicCode($event, afterDiscount ? 'onCoupon' : '')">
			<text>优惠券</text>
			<view class="pay-card-right">
				<text class="pay-card-hint" v-if="!afterDiscount">选择优惠券 ›</text>
				<text class="coupon-used" v-else>{{ afterDiscount.couponsName }} (已优惠¥{{ afterDiscount.price }}) ›</text>
			</view>
		</view>

		<!-- 订单金额 -->
		<view class="pay-card">
			<view class="pay-card-title">订单金额</view>
			<view class="price-row">
				<text>商品金额</text>
				<text>¥{{ orderDetail.actualPrice }}</text>
			</view>
			<view class="price-row price-row--discount" v-if="orderDetail.fullPriceReductionIsHidden">
				<text>优惠金额</text>
				<text>−¥{{ (orderDetail.actualPrice - orderDetail.fullPriceReduction).toFixed(2) }}</text>
			</view>
			<view class="view-line"></view>
			<view class="price-total">
				<text>合计</text>
				<text class="price-accent price-total-num">
					¥{{ orderDetail.fullPriceReductionIsHidden ? orderDetail.fullPriceReduction : orderDetail.actualPrice }}
				</text>
			</view>
		</view>

		<!-- 结算方式 -->
		<view class="pay-card pay-card--row" v-if="!brandConfig.features.onlinePayment">
			<text>结算方式</text>
			<view class="pay-card-right">
				<text class="settle-text">到店付款</text>
				<text class="settle-hint">提交后由门店确认</text>
			</view>
		</view>
		<view class="pay-card margin-border-radius" v-if="brandConfig.features.onlinePayment">
			<view>支付方式</view>
			<view class="choose-pay-mode">
				<radio-group class="radio-group-address" @change="radioChangeAddress">
					<block v-for="(item, index) in paymentModes" :key="index">
						<label :class="'radio-label-payment flex_center ' + (item.checked ? 'payment-checked' : 'payment-not-checked')"
							v-if="item.show">
							<radio :value="index" :checked="item.checked" class="pay_radio" />
							<van-icon :name="item.icon" />
							<text :decode="true">&nbsp;{{ item.text }}</text>
							<text :decode="true" class="actionItem__desc" v-if="item.desc">&nbsp;{{ item.desc }}</text>
						</label>
					</block>
				</radio-group>
			</view>
		</view>

		<!-- 底部提交 -->
		<view class="pay-bottom">
			<view class="pay-bottom-total">
				<text class="pay-bottom-label">{{ brandConfig.features.onlinePayment ? '还需支付' : '订单金额' }}</text>
				<text class="price-accent pay-bottom-price">
					¥{{ orderDetail.fullPriceReductionIsHidden ? orderDetail.fullPriceReduction : orderDetail.actualPrice }}
				</text>
			</view>
			<primary-button class="pay-submit-btn"
				@tap="parseEventDynamicCode($event, isForgetThePassword ? 'showPwdLayer' : 'getRequestSubscribeMessage')">
				{{ brandConfig.features.onlinePayment ? '去支付' : '提交订单' }}
			</primary-button>
			<view class="pay-agreement">提交即同意《用户协议》</view>
		</view>

		<!-- 密码弹窗 -->
		<van-dialog use-slot :show="showPayPwdInput" :showConfirmButton="false" :showCancelButton="false" z-index='1'>
			<view class="flex_between content_box">
				<view></view>
				<view>输入支付密码</view>
				<van-icon name="cross" @tap="balancePayFail" />
			</view>
			// #ifdef APP-PLUS||H5
			<view class="content_box" style="padding: 0 0;">
				<view class="password_dialog_tip" style="padding: 0 16px;">
					<text>使用会员卡余额支付需要验证身份，验证通过后才可进行支付。</text>
				</view>
				<van-password-input :value="pwdVal" :focused="payFocus" @focus="payFocus = true" />
				<view class="theme-color password_dialog_forget_pwd" @tap.stop.prevent="forgetThePassword">忘记密码</view>
			</view>
			// #endif
			// #ifdef MP-WEIXIN||MP-ALIPAY
			<view class="content_box" style="padding: 0 16px;">
				<view class="password_dialog_tip"><text>使用会员卡余额支付需要验证身份，验证通过后才可进行支付。</text></view>
				<view class="password_dialog_row" @tap="getFocus">
					<view class="password_dialog_item_input" v-for="(item, i) in 6" :key="i">
						<text v-if="pwdVal.length > i"></text>
					</view>
				</view>
				<view class="theme-color password_dialog_forget_pwd" @tap.stop.prevent="forgetThePassword">忘记密码</view>
				<input class="password_dialog_input_control" password type="number" :focus="payFocus"
					:hold-keyboard="true" :value="pwdVal" @input="inputPwd" maxlength="6"
					:adjust-position="adjustPosition" cursor-spacing="100" :auto-focus="payFocus" inputmode="numeric" />
			</view>
			// #endif
		</van-dialog>
		// #ifdef APP-PLUS||H5
		<van-number-keyboard :show="payFocus" @blur="payFocus = false" @input="inputPwd" @delete="deletePwd" />
		// #endif

		<!-- 底部安全区 -->
		<view style="height: 200rpx;"></view>
	</view>
</template>

<script>
	import https from '../../../utils/http';
	import authService from '../../../utils/auth';
	import { Base64 } from 'js-base64';
	import toastService from '../../../utils/toast.service';
	import systemStatus from '../../../utils/system-status';
	import dateHelper from '../../../utils/date-helper';
	import utilHelper from '../../../utils/util';
	import BrandConfig from '../../../utils/brand-config';
	import PrimaryButton from '../../../components/ui/primary-button.vue';
	let app = null;
	var wxNotifyTemplates = [];
	export default {
		components: {
			PrimaryButton
		},
		data() {
			return {
				brandConfig: BrandConfig,
				time: '10:00',
				isChoose: false,
				selfOutActiveIndex: 0,
				shopInfo: { shop: {} },
				initShopInfo: {},
				orderDetail: {
					actualPrice: 0,
					fullPriceReduction: 0,
					fullPriceReductionIsHidden: false,
					reducedPrice: 0,
					packingCharges: 0,
					couponsIsHidden: false,
					fullReductionRuleName: '',
					orderDetailList: []
				},
				deliveryAndSelfTaking: {
					deliveryAddress: null,
					isReducedDeliveryPrice: false,
					reducedDeliveryTotalPrice: 0,
					feeData: 0,
					isThereADiscount: false
				},
				afterDiscount: null,
				radioIndex: 0,
				inputLength: 0,
				remarks: '',
				showRemarks: false,
				paymentModeIndex: 0,
				paymentModes: [
					{ text: '微信支付', icon: 'wechat', checked: true, show: true },
					{ text: '平台余额', icon: 'balance-pay', checked: false, show: false }
				],
				showPayPwdInput: false,
				pwdVal: '',
				payFocus: false,
				isForgetThePassword: false,
				isPayJson: {},
				userInfo: {},
				adjustPosition: true,
				isVipDialogShow: false,
				timestamp: ''
			};
		},
		onLoad() {
			app = getApp();
			if (!app.globalData.deliveryAndSelfTaking.orderDetail) {
				uni.navigateBack({ delta: 1 });
				return;
			}
		},
		onShow() {
			app = getApp();
			var deliveryAndSelfTaking = app.globalData.deliveryAndSelfTaking;
			if (deliveryAndSelfTaking.orderDetail) {
				this.orderDetail = deliveryAndSelfTaking.orderDetail;
			}
			this.selfOutActiveIndex = 0;
			app.globalData.deliveryAndSelfTaking.selfOutActiveIndex = 0;
			this.initShopInfo = this.orderDetail.initShopInfo || {};
			this.shopInfo = { shop: { name: this.initShopInfo.name || '' } };
			this.deliveryAndSelfTaking = deliveryAndSelfTaking;
			this.timestamp = dateHelper.getTimestamp();
			this.getUserInfo();
			this.getPaymentMode();
		},
		methods: {
			getUserInfo() {
				https.request('/rest/member/getLoginMemberInfo', {}).then((result) => {
					if (result.success) { this.userInfo = result.data; }
				});
			},
			getPaymentMode() {
				https.request('/rest/systemConfig/selectByKey', { key: 'payment_mode' }).then((result) => {
					if (result.success && result.data) {
						var config = JSON.parse(result.data.value);
						this.paymentModes[1].show = config.balance;
					}
				});
			},
			focusRemarks() { this.showRemarks = !this.showRemarks; },
			remarksInput(e) {
				this.inputLength = e.detail.value.length;
				this.remarks = e.detail.value;
			},
			radioChangeAddress(e) { this.paymentModeIndex = parseInt(e.detail.value); },
			onCoupon() {
				uni.navigateTo({ url: `../../mine/coupons/coupons?prevData=` + JSON.stringify(this.orderDetail) });
			},
			getRequestSubscribeMessage() {
				let self = this;
				if (this.brandConfig.features.onlinePayment && this.paymentModeIndex == 1) {
					if (!this.userInfo.paymentPassword) {
						uni.navigateTo({ url: '../../mine/security/reset/reset' });
						return;
					}
					this.showPayPwdInput = true;
					return;
				}
				this.insertOrder();
			},
			showPwdLayer() { this.showPayPwdInput = true; },
			inputPwd(e) {
				if (this.pwdVal.length >= 6) return;
				this.pwdVal += e;
				if (this.pwdVal.length == 6) { this.balancePay(); }
			},
			deletePwd() { this.pwdVal = this.pwdVal.slice(0, -1); },
			getFocus() { this.payFocus = true; },
			balancePayFail() { this.showPayPwdInput = false; this.pwdVal = ''; this.payFocus = false; },
			forgetThePassword() {
				this.showPayPwdInput = false;
				this.pwdVal = '';
				uni.navigateTo({ url: '../../mine/security/verify/verify' });
			},
			balancePay() {
				var _this = this;
				https.request('/rest/member/validatePayPassword', {
					paymentPassword: this.pwdVal
				}).then((result) => {
					if (result.success) {
						_this.showPayPwdInput = false;
						_this.pwdVal = '';
						_this.insertOrder();
					} else {
						toastService.showToast(result.message || '密码错误');
						_this.pwdVal = '';
					}
				});
			},
			insertOrder() {
				var _this = this;
				toastService.showLoading();
				var data = {
					sceneToken: this.orderDetail.sceneToken,
					shoppingCartIdList: this.orderDetail.orderDetailList.map((item) => item.id),
					orderDetailListStr: JSON.stringify(this.orderDetail.orderDetailList),
					actualPrice: this.orderDetail.actualPrice,
					remark: this.remarks,
					shoppingWay: 1
				};
				if (this.brandConfig.features.onlinePayment) {
					data.paymentMode = this.paymentModeIndex == 1 ? 'balance' : 'wechat';
				}
				https.request('/rest/member/order/insert', data).then((result) => {
					toastService.hideLoading();
					if (result.success) {
						_this.handleOrderCreated(result.data);
					}
				}).catch(() => toastService.hideLoading());
			},
			handleOrderCreated(order) {
				if (this.brandConfig.features.onlinePayment) {
					this.toPay4Applet(order.id, order.orderNo);
					return;
				}
				toastService.showSuccess('订单提交成功', true);
				setTimeout(() => {
					uni.redirectTo({ url: '../../order/detail/detail?id=' + order.id });
				}, 800);
			},
			toPay4Applet(id, orderNo) {
				toastService.showLoading('正在加载...', true);
				var _this = this;
				https.request('/rest/member/wxPay/toPay4Applet', {
					orderNo: orderNo
				}).then((result) => {
					toastService.hideLoading();
					if (result.success) {
						// #ifdef MP-WEIXIN
						uni.requestPayment({
							timeStamp: result.data.timeStamp,
							nonceStr: result.data.nonceStr,
							package: result.data.package,
							signType: result.data.signType,
							paySign: result.data.paySign,
							success() {
								uni.redirectTo({ url: '../../order/detail/detail?id=' + id });
							},
							fail(e) { toastService.showToast('支付取消'); }
						});
						// #endif
						// #ifdef APP-PLUS||H5
						uni.redirectTo({ url: '../../order/detail/detail?id=' + id });
						// #endif
					}
				});
			},
			parseEventDynamicCode(e, method) {
				if (method && this[method]) { this[method](e); }
			},
			close() { this.showPayPwdInput = false; }
		}
	};
</script>
<style>
	.pay-page {
		min-height: 100vh;
		padding: 20rpx 24rpx;
		background: #f7f7f7;
	}

	/* 卡片 */
	.pay-card {
		background: #fff;
		border-radius: 14rpx;
		padding: 24rpx;
		margin-bottom: 16rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.035);
	}

	.pay-card--row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 28rpx;
		color: #111;
		font-weight: 500;
	}

	.pay-card-title {
		font-size: 28rpx;
		font-weight: 700;
		color: #111;
		margin-bottom: 20rpx;
	}

	.pay-card-hint {
		font-size: 26rpx;
		color: #999;
	}

	.pay-card-right {
		display: flex;
		align-items: center;
		gap: 12rpx;
	}

	/* 就餐方式 */
	.dining-mode {
		display: flex;
		gap: 16rpx;
		margin-bottom: 16rpx;
	}

	.mode-btn {
		flex: 1;
		padding: 20rpx 0;
		text-align: center;
		font-size: 28rpx;
		font-weight: 600;
		border-radius: 12rpx;
		background: #f6f6f6;
		color: #555;
		transition: 0.2s;
	}

	.mode-btn--active {
		background: #050505;
		color: #fff;
		border: 2rpx solid #050505;
	}

	.address-info {
		font-size: 24rpx;
		color: #777;
		padding: 12rpx 0;
		border-top: 1rpx solid #F5F2ED;
	}

	.address-label {
		color: #111;
		font-weight: 500;
	}

	/* 订单内容 */
	.order-item {
		display: flex;
		align-items: center;
		padding: 16rpx 0;
		border-bottom: 1rpx solid #F5F2ED;
	}

	.order-item:last-child {
		border-bottom: none;
	}

	.order-item-img {
		width: 100rpx;
		height: 100rpx;
		border-radius: 10rpx;
		flex-shrink: 0;
	}

	.order-item-info {
		flex: 1;
		margin-left: 16rpx;
	}

	.order-item-name {
		font-size: 28rpx;
		font-weight: 600;
		color: #111;
	}

	.order-item-spec {
		font-size: 22rpx;
		color: #888;
		margin-top: 4rpx;
	}

	.order-item-right {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 6rpx;
	}

	.order-item-qty {
		font-size: 24rpx;
		color: #888;
	}

	.order-extra {
		display: flex;
		justify-content: space-between;
		padding: 12rpx 0;
		font-size: 26rpx;
		color: #666;
	}

	/* 备注 */
	.remarks-area {
		background: #fff;
		border-radius: 16rpx;
		padding: 16rpx 24rpx;
		margin-top: -8rpx;
		margin-bottom: 16rpx;
	}

	.remarks-textarea {
		width: 100%;
		height: 120rpx;
		font-size: 26rpx;
		color: #111;
	}

	.remarks-count {
		text-align: right;
		font-size: 22rpx;
		color: #999;
	}

	/* 优惠券 */
	.coupon-used {
		font-size: 26rpx;
		color: #111;
	}

	/* 金额明细 */
	.price-row {
		display: flex;
		justify-content: space-between;
		padding: 10rpx 0;
		font-size: 26rpx;
		color: #555;
	}

	.price-row--discount {
		color: #111;
	}

	.price-total {
		display: flex;
		justify-content: space-between;
		padding-top: 16rpx;
		font-size: 30rpx;
		font-weight: 700;
		color: #111;
	}

	.price-total-num {
		font-size: 36rpx;
	}

	.view-line {
		height: 1rpx;
		background: #F5F2ED;
		margin: 8rpx 0;
	}

	/* 结算方式 */
	.settle-text {
		font-size: 28rpx;
		font-weight: 600;
		color: #111;
	}

	.settle-hint {
		font-size: 22rpx;
		color: #999;
	}

	/* 底部 */
	.pay-bottom {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		background: #FFF;
		padding: 20rpx 24rpx calc(20rpx + env(safe-area-inset-bottom));
		box-shadow: 0 -4rpx 20rpx rgba(0, 0, 0, 0.05);
	}

	.pay-bottom-total {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 16rpx;
		padding: 0 8rpx;
	}

	.pay-bottom-label {
		font-size: 28rpx;
		color: #111;
	}

	.pay-bottom-price {
		font-size: 40rpx;
	}

	.pay-submit-btn {
		width: 100%;
		margin-bottom: 10rpx;
	}

	.pay-agreement {
		text-align: center;
		font-size: 22rpx;
		color: #999;
	}

	/* 支付方式 */
	.choose-pay-mode {
		margin-top: 16rpx;
	}

	.radio-group-address {
		display: flex;
		flex-direction: column;
		gap: 16rpx;
	}

	.radio-label-payment {
		padding: 20rpx;
		border-radius: 12rpx;
		border: 1rpx solid #EDEDED;
		font-size: 28rpx;
	}

	.payment-checked {
		border-color: #111;
		background: #f5f5f5;
	}

	.payment-not-checked {
		background: #FAFAFA;
	}

	.pay_radio {
		display: none;
	}

	.line-through {
		text-decoration: line-through;
		color: #999;
		margin-right: 8rpx;
	}

	.content_box {
		padding: 20rpx;
	}
</style>
