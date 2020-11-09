const AWS = require("aws-sdk");

exports.handler = (event, context, callback) => {

    const generator  = (function *() {

        try {

            const siteUrl = process.env['URL'];
            const result  = yield checkUrl(siteUrl, generator);

            // メトリクスをput
            yield putMetricData(siteUrl, result, generator);

            callback(null, 'success');

        } catch (e) {

            callback(e.message);

        }
    })();

    /* 処理開始 */
    generator.next();
};

function checkUrl(siteUrl, generator) {
    const request = require('request');

    request(siteUrl, function(error, response, body) {
        if(!error && response.statusCode === 200) {
            // 正常の場合は1
            generator.next(1);
        } else {
            // 異常の場合は0
            generator.next(0);
        }
    });
}

function putMetricData(siteUrl, result, generator) {
    const cloudwatch = new AWS.CloudWatch();

    const params = {
        MetricData: [
            {
                MetricName: 'urlHealth',
                Dimensions: [
                    {
                        Name: 'url',
                        Value: siteUrl
                    }
                ],
                Timestamp: new Date(),
                Unit: 'None',
                Value: result
            }
        ],
        Namespace: 'urlHealth'
    };

    cloudwatch.putMetricData(params, function(err, data) {
        if(err) {
            console.log(err, err.stack);
            generator.throw(new Error('put metric data error'));
            return;
        }
        generator.next();
    });
}