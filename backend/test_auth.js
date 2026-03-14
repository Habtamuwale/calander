const { GoogleAuth } = require('google-auth-library');
const path = require('path');

async function test() {
  try {
    const auth = new GoogleAuth({
      keyFile: path.join(__dirname, 'serviceAccountKey.json'),
      scopes: 'https://www.googleapis.com/auth/cloud-platform',
    });
    const client = await auth.getClient();
    const token = await client.getAccessToken();
    console.log('Token fetched successfully!');
  } catch (e) {
    console.error('Manual Token Fetch Error:', e);
  }
}

test();
