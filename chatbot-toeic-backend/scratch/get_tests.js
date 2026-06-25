import axios from 'axios';
import fs from 'fs';

async function run() {
  try {
    console.log('Logging in...');
    const loginRes = await axios.post('http://localhost:8080/api/v1/auth/login', {
      email: 'phamtuanhung9a5@gmail.com',
      password: '123'
    });
    
    const token = loginRes.data.data.accessToken;
    console.log('Login successful. Token acquired.');

    console.log('Fetching tests...');
    const testsRes = await axios.get('http://localhost:8080/api/v1/tests', {
      headers: {
        Authorization: `Bearer ${token}`
      }
    });

    console.log('Tests fetched successfully.');
    fs.writeFileSync('tests_response.json', JSON.stringify(testsRes.data, null, 2));
    console.log('Saved response to tests_response.json');
  } catch (error) {
    console.error('Error fetching tests:', error.response ? error.response.data : error.message);
  }
}

run();
