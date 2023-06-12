var utils = require('utils'),
    signs = require('signs'),
    http = require('http')

exports.windturbine_sign = function (player) {
    var cartel = box(blsocks.sign_post);
    var cordx = cartel.x;
    var cordy = cartel.y;
    var cordz = cartel.z;
    let i = 0;
    while (i < 100) {
        task(i);
        i++;
    }
    function task(i) {
        setTimeout(function () {
            http.request('http://localhost:3500/v1.0/invoke/dapr-sensors-average/method/average/1', function (responseCode, responseBody) { setsigntext(cordx, cordy, cordz, JSON.parse(responseBody).temperature, JSON.parse(responseBody).energy); });
        }, 2000 * i);
    }
};