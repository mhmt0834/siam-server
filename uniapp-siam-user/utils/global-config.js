export default class GlabalConfig {
    // static baseUrl = 'https://api.test.siamit.cn/siam-server';
	// #ifdef H5
	static baseUrl = 'siam-server';
	// #endif
	// #ifdef APP-PLUS||MP-WEIXIN||MP-ALIPAY
	static baseUrl = 'http://192.168.1.4:9200/siam-server';
	// #endif
	static defaultShopId = 13;
    
    // static baseUrl = 'http://localhost:9020';
    static ossUrl = 'https://siam-hangzhou.oss-cn-hangzhou.aliyuncs.com/';
}
