const aws = require('aws-sdk');
const request = require('request'); 
const cognito = new aws.CognitoIdentityServiceProvider();
const cloudwatch = new aws.CloudWatch();

const requestHandler = (options) => new Promise((resolve, reject) => {
  request(options, (error, response) => {
    if (error) {
      reject(error);
    } else {
      resolve(response);
    }
  });
});

const putMetricData = async (url, result) => {

    const params = {
        MetricData: [
            {
                MetricName: 'urlHealth',
                Dimensions: [
                    {
                        Name: 'url',
                        Value: url
                    }
                ],
                Timestamp: new Date(),
                Unit: 'None',
                Value: result
            }
        ],
        Namespace: 'urlHealth'
    };

    await cloudwatch.putMetricData(params).promise();
}

exports.handler = async (event,context, callback) => {

  const params = {
    AuthFlow: 'ADMIN_USER_PASSWORD_AUTH',
    UserPoolId: process.env['USER_POOL_ID'],
    ClientId: process.env['CLIENT_ID'],
    AuthParameters: {
      'USERNAME': process.env['USERNAME'],
      'PASSWORD': process.env['PASSWORD'],
    },
  };

  const result = await cognito.adminInitiateAuth(params).promise().catch(error => {
    throw error;
  });

  const url = process.env['URL']
  var options = {
    url: url,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': result.AuthenticationResult.IdToken
    }
  }

  const response =  await requestHandler(options);
  if(response.statusCode === 200) {
    await putMetricData(url, 1)
  } else {
    await putMetricData(url, 0)
  }
  
};