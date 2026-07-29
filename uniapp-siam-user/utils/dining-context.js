const STORAGE_KEY = 'dining_context';

function normalizeScene(value) {
	if (!value) return '';
	try {
		return decodeURIComponent(String(value)).trim();
	} catch (e) {
		return String(value).trim();
	}
}

function extractScene(scanResult) {
	const raw = typeof scanResult === 'string'
		? scanResult
		: (scanResult && (scanResult.path || scanResult.result)) || '';
	const match = String(raw).match(/[?&]scene=([^&#]+)/);
	return normalizeScene(match ? match[1] : raw);
}

function get() {
	return uni.getStorageSync(STORAGE_KEY) || {};
}

function set(context) {
	const value = Object.assign({}, context);
	uni.setStorageSync(STORAGE_KEY, value);
	return value;
}

function clear() {
	uni.removeStorageSync(STORAGE_KEY);
}

export default {
	normalizeScene,
	extractScene,
	get,
	set,
	clear
};
