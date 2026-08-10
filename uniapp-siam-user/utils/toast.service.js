import GlobalConfig from './global-config';
let loadingTimer = null;
let loadingVisible = false;

export default {
	showToast: function(title = '', duration) {
		uni.showToast({
			title: title,
			icon: 'none',
			duration: duration ? duration : 3000
		});
	},
	/**
	 * 成功
	 */
	showSuccess: function(title, mask = true, duration = 3000) {
		uni.showToast({
			title: title,
			mask: mask,
			image: '/static/assets/images/success.png',
			duration: duration
		});
	},
	/**
	 * 警告
	 */
	showWarning: function(title, duration = 3000) {
		uni.showToast({
			title: title,
			image: '/static/assets/images/warning.png',
			duration: duration
		});
	},
	/**
	 * 错误
	 */
	showError: function(title, mask = false, duration = 3000) {
		uni.showToast({
			title: title,
			mask: mask,
			image: '/static/assets/images/error.png',
			duration: duration
		});
	},
	/**
	 * 显示加载
	 */
	showLoading: function(title = '正在加载...', mask = true) {
		if (loadingTimer) {
			clearTimeout(loadingTimer);
		}
		if (loadingVisible) {
			uni.hideLoading();
		}
		uni.showLoading({
			title: title,
			mask: mask
		});
		loadingVisible = true;
		loadingTimer = setTimeout(function () {
			uni.hideLoading();
			loadingVisible = false;
			loadingTimer = null;
		}, 3000);
	},
	/**
	 * 隐藏加载
	 */
	hideLoading: function() {
		if (loadingTimer) {
			clearTimeout(loadingTimer);
			loadingTimer = null;
		}
		if (loadingVisible) {
			uni.hideLoading();
			loadingVisible = false;
		}
	},
	/**
	 * 显示模态窗口
	 */
	showModal: function(title = null, content = null, confirm = null, cancel = null, showCancel = true) {
		uni.showModal({
			title: title ? title : '温馨提示',
			content: content || '',
			showCancel: showCancel,
			success(res) {
				if (res.confirm) {
					//console.log('用户点击确定');
					if (confirm) {
						confirm();
					}
				} else if (res.cancel) {
					//console.log('用户点击取消');
					if (cancel) {
						cancel();
					}
				}
			}
		});
	}
};
