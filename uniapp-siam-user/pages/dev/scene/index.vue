<template>
	<view class="scene-debug-page">
		<text>正在解析餐桌码...</text>
	</view>
</template>

<script>
import https from '../../../utils/http';
import DiningContext from '../../../utils/dining-context';

export default {
	onLoad(options) {
		const sceneToken = DiningContext.normalizeScene(options && options.scene);
		if (!sceneToken || sceneToken === '__SCENE_TOKEN__') {
			this.openMenu({});
			return;
		}
		let settled = false;
		const finish = (context) => {
			if (settled) return;
			settled = true;
			this.openMenu(context);
		};
		setTimeout(() => finish({}), 5000);
		https.request('/rest/scan/resolve', { sceneToken }).then((result) => {
			finish(result.success && result.data ? result.data : {});
		}).catch(() => {
			finish({});
		});
	},
	methods: {
		openMenu(context) {
			if (context.sceneToken) {
				DiningContext.set(context);
			} else {
				DiningContext.clear();
			}
			setTimeout(() => {
				uni.switchTab({ url: '/pages/menu/index/index' });
			}, 300);
		}
	}
};
</script>

<style scoped>
.scene-debug-page {
	min-height: 100vh;
	display: flex;
	align-items: center;
	justify-content: center;
	color: #666666;
	font-size: 14px;
	background: #f7f7f7;
}
</style>
