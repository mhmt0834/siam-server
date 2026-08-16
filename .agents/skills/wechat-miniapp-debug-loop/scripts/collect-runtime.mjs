const COLLECTOR_KEY = '__wechat_debug_loop_runtime__';

function redactText(value) {
  return String(value ?? '')
    .replace(/(token|authorization|cookie|code|secret|session[_-]?key)(["'\s:=]+)[^\s,"'}]+/gi, '$1$2[REDACTED]')
    .replace(/1\d{10}/g, '1**********');
}

export function sanitize(value, key = '') {
  if (value == null) return value;
  if (/token|authorization|cookie|code|secret|session|openid|phone|mobile/i.test(key)) {
    return value ? '[PRESENT_REDACTED]' : value;
  }
  if (Array.isArray(value)) return value.slice(0, 5).map((item) => sanitize(item));
  if (typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([childKey, childValue]) => [childKey, sanitize(childValue, childKey)]));
  }
  return typeof value === 'string' ? redactText(value) : value;
}

export function attachRuntimeEvents(miniProgram) {
  const consoleRecords = [];
  const exceptions = [];
  miniProgram.on('console', (record) => {
    const normalized = sanitize(record);
    consoleRecords.push(normalized);
  });
  miniProgram.on('exception', (record) => exceptions.push(sanitize(record)));
  return { consoleRecords, exceptions };
}

export async function installRuntimeCapture(miniProgram) {
  await miniProgram.evaluate((collectorKey) => {
    const host = window;
    host[collectorKey] = { requests: [], logins: [] };

    if (!host.__wechatDebugOriginalRequest) host.__wechatDebugOriginalRequest = wx.request;
    if (!host.__wechatDebugOriginalLogin) host.__wechatDebugOriginalLogin = wx.login;

    wx.request = function(options) {
      const originalSuccess = options.success;
      const originalFail = options.fail;
      const request = {
        url: options.url,
        method: options.method || 'GET'
      };
      const next = Object.assign({}, options, {
        success(response) {
          host[collectorKey].requests.push({
            request,
            response: { statusCode: response.statusCode, data: response.data }
          });
          if (originalSuccess) originalSuccess(response);
        },
        fail(error) {
          host[collectorKey].requests.push({
            request,
            response: { error: error && error.errMsg }
          });
          if (originalFail) originalFail(error);
        }
      });
      return host.__wechatDebugOriginalRequest(next);
    };

    wx.login = function(options) {
      const originalSuccess = options && options.success;
      const originalFail = options && options.fail;
      const next = Object.assign({}, options || {}, {
        success(result) {
          host[collectorKey].logins.push({ ok: true, hasCode: Boolean(result && result.code) });
          if (originalSuccess) originalSuccess(result);
        },
        fail(error) {
          host[collectorKey].logins.push({ ok: false, error: error && error.errMsg });
          if (originalFail) originalFail(error);
        }
      });
      return host.__wechatDebugOriginalLogin(next);
    };
  }, COLLECTOR_KEY);
}

export async function readRuntimeCapture(miniProgram) {
  const json = await miniProgram.evaluate((collectorKey) => JSON.stringify(window[collectorKey] || {}), COLLECTOR_KEY);
  return sanitize(json ? JSON.parse(json) : {});
}

export function countApplicationErrors(consoleRecords, exceptions) {
  const consoleErrors = consoleRecords.filter((record) => {
    const text = JSON.stringify(record).toLowerCase();
    return /"level"\s*:\s*"error"|console\.error|unhandled|request:fail|typeerror|referenceerror/.test(text)
      && !/devtools|automation protocol|webviewid.*not found/.test(text);
  });
  return { consoleErrors, exceptions };
}
