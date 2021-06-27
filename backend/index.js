
// const { S3Client, ListObjectsCommand } = require("@aws-sdk/client-s3");

exports.handler = async function (event, context, callback) {

  // const client = new S3Client();
  // const command = new ListObjectsCommand({
  //   Bucket: 
  // });
  // const response = await client.send(command);

  var response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: JSON.stringify({ event, context, env: process.env }),
  };

  return response;
}
