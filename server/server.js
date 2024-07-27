const net = require('net');
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
let clientSocket = null;
let latestData = '';

// Use the cors middleware
app.use(cors({ origin: '*' }));

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// REST API to send start command to the emulator
app.post('/start', (req, res) => {
  if (!clientSocket) {
    res.status(400).send('Emulator is not connected');
  } else {
    console.log('Sending start command to emulator...');
    clientSocket.write('start\n'); // Ensure newline to flush the data
    setTimeout(() => {
      res.json({ message: "Running" });
    }, 1000); // Wait for 1 second to allow the data to be sent back
  }
});

// REST API to send stop command to the emulator
app.post('/stop', (req, res) => {
  if (!clientSocket) {
    res.status(400).send('Emulator is not connected');
  } else {
    console.log('Sending stop command to emulator...');
    clientSocket.write('stop\n'); // Ensure newline to flush the data
    setTimeout(() => {
      res.json({ message: "Stopped" });
    }, 1000); // Wait for 1 second to allow the data to be sent back
  }
});

// REST API to fetch the latest data from the emulator
app.get('/fetch_data', (req, res) => {
  if (clientSocket) {
    console.log('Fetching latest data from emulator...');
    clientSocket.write('fetch_data\n'); // Ensure newline to flush the data
    setTimeout(() => {
      try {
        // Add additional logging to see what is being received
        console.log('Received data:', latestData);
        
        // Ensure data is not empty and attempt to parse
        if (latestData && latestData.trim() !== '') {
          const data = JSON.parse(latestData); // Attempt to parse latestData
          res.json(data); // Send parsed data as response
        } else {
          // Handle case where data is empty or not valid JSON
          console.error('No data or invalid data received');
          res.status(204).send('No data available'); // 204 No Content
        }
      } catch (err) {
        console.error('Error parsing latest data:', err);
        res.status(500).send('Failed to parse data from emulator');
      }
    }, 1000); // Wait for 1 second to allow the data to be sent back
  } else {
    res.status(400).json({ message: "Emulator is not connected" });
  }
});

// TCP server logic
const server = net.createServer((sock) => {
  clientSocket = sock;
  console.log('CONNECTED: ' + sock.remoteAddress + ':' + sock.remotePort);

  sock.on('data', (data) => {
    console.log('DATA ' + sock.remoteAddress + ': ' + data);
    latestData = data.toString();
  });

  sock.on('close', () => {
    console.log('CLOSED: ' + sock.remoteAddress + ' ' + sock.remotePort);
    clientSocket = null;
  });

  sock.on('error', (err) => {
    console.error('Error: ' + err);
    clientSocket = null;
  });
});

// Initialize the TCP server to listen for connections
server.listen(3000, '0.0.0.0', () => {
  console.log('TCP server listening on 0.0.0.0:3000');
});

// REST API server listens on port 3001
app.listen(3001, '0.0.0.0', () => {
  console.log('REST API server listening on port 3001');
});
