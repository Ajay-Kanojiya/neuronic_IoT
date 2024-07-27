#include <iostream>
#include <cstdlib>
#include <ctime>
#include <thread>
#include <chrono>
#include <boost/asio.hpp>
#include <jsoncpp/json/json.h> // Include JSON library

using boost::asio::ip::tcp;

// Temperature and Humidity Sensor Emulator Class
class SensorEmulator {
public:
    SensorEmulator() {
        // Seed the random number generator
        std::srand(static_cast<unsigned int>(std::time(nullptr)));
    }

    // Method to read the current temperature
    double readTemperature() {
        // Generate a random temperature value between -10.0 and 50.0 degrees Celsius
        double temperature = (static_cast<double>(std::rand()) / RAND_MAX) * 60.0 - 10.0;
        return temperature;
    }

    // Method to read the current humidity
    double readHumidity() {
        // Generate a random humidity value between 0.0 and 100.0 percent
        double humidity = (static_cast<double>(std::rand()) / RAND_MAX) * 100.0;
        return humidity;
    }

    // Method to generate data
    std::string generateData() {
        double temperature = readTemperature();
        double humidity = readHumidity();

        Json::Value jsonData;
        jsonData["temperature"] = temperature;
        jsonData["humidity"] = humidity;

        Json::StreamWriterBuilder writer;
        return Json::writeString(writer, jsonData);
    }
};

void sendData(tcp::socket& socket, const std::string& message) {
    boost::asio::write(socket, boost::asio::buffer(message + "\n"));
}

void receiveData(tcp::socket& socket, SensorEmulator& sensor, bool& running, std::string& latestData) {
    boost::asio::streambuf buffer;
    boost::asio::read_until(socket, buffer, "\n");
    std::istream is(&buffer);
    std::string receivedMessage;
    std::getline(is, receivedMessage);
    std::cout << "Received: " << receivedMessage << std::endl;

    if (receivedMessage == "start") {
        running = true;
    } else if (receivedMessage == "stop") {
        running = false;
    } else if (receivedMessage == "fetch_data") {
        sendData(socket, latestData);
    }
}

int main() {
    try {
        boost::asio::io_context io_context;
        tcp::resolver resolver(io_context);
        tcp::resolver::results_type endpoints = resolver.resolve("127.0.0.1", "3000");
        tcp::socket socket(io_context);
        boost::asio::connect(socket, endpoints);

        SensorEmulator sensor;
        bool running = false;
        std::string latestData;

        std::thread receiveThread([&socket, &sensor, &running, &latestData]() {
            while (true) {
                receiveData(socket, sensor, running, latestData);
            }
        });

        // Main loop: update and send data every 5 seconds if running
        while (true) {
            if (running) {
                latestData = sensor.generateData();
                sendData(socket, latestData); // Send the data to the socket
            }
            std::this_thread::sleep_for(std::chrono::seconds(5)); // Sleep for 5 seconds
        }

        receiveThread.join();
    } catch (std::exception& e) {
        std::cerr << "Exception: " << e.what() << "\n";
    }

    return 0;
}
