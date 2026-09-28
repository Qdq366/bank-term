// 统一封装成功/失败的 JSON 返回结构
function success(res, data = null, message = 'ok') {
  res.json({ code: 200, message, data });
}

function fail(res, message = '请求失败', code = 400, httpStatus = 400) {
  res.status(httpStatus).json({ code, message, data: null });
}

module.exports = { success, fail };
