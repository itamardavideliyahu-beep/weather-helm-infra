# Weather Dashboard App - Complete Setup Guide

This guide will walk you through setting up and running the complete Weather Dashboard application, including both the backend and frontend microservices.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Getting OpenWeatherMap API Key](#getting-openweathermap-api-key)
3. [Local Development Setup](#local-development-setup)
4. [Docker Setup](#docker-setup)
5. [Testing the Application](#testing-the-application)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.11+** - For backend service
- **Node.js 18+** - For frontend service
- **Docker** (optional) - For containerized deployment
- **Git** - For version control
- **OpenWeatherMap API Key** - Free API key (see below)

## Getting OpenWeatherMap API Key

### Step-by-Step Instructions

1. **Visit OpenWeatherMap Website**
   - Go to [https://openweathermap.org/api](https://openweathermap.org/api)

2. **Sign Up for Free Account**
   - Click "Sign Up" in the top right corner
   - Fill in your details:
     - Username
     - Email
     - Password
   - Agree to terms and conditions
   - Complete the CAPTCHA
   - Click "Create Account"

3. **Verify Your Email**
   - Check your email inbox
   - Click the verification link sent by OpenWeatherMap
   - This activates your account

4. **Get Your API Key**
   - Log in to your account
   - Navigate to "API keys" tab (or go to [https://home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys))
   - You'll see a default API key already created
   - Copy this key (you'll need it for the backend setup)

5. **Important Notes**
   - New API keys may take 10-15 minutes to activate
   - Free tier allows 60 API calls per minute
   - Keep your API key private and never commit it to Git

## Local Development Setup

### Option 1: Run Without Docker

#### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd weather-backend
   ```

2. **Create virtual environment (recommended)**
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # Edit .env and add your API key
   # OPENWEATHER_API_KEY=your_actual_api_key_here
   ```

5. **Start the backend server**
   ```bash
   python app.py
   ```
   
   The backend will run on `http://localhost:5000`

#### Frontend Setup

1. **Open a new terminal** (keep backend running in the first terminal)

2. **Navigate to frontend directory**
   ```bash
   cd weather-frontend
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Configure environment**
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # The default configuration should work:
   # REACT_APP_BACKEND_URL=http://localhost:5000
   ```

5. **Start the development server**
   ```bash
   npm start
   ```
   
   The frontend will automatically open at `http://localhost:3000`

### Option 2: Run With Docker

#### Backend Container

1. **Navigate to backend directory**
   ```bash
   cd weather-backend
   ```

2. **Build the Docker image**
   ```bash
   docker build -t weather-backend .
   ```

3. **Run the container**
   ```bash
   docker run -d -p 5000:5000 -e OPENWEATHER_API_KEY=your_api_key_here --name weather-backend weather-backend
   ```
   
   Replace `your_api_key_here` with your actual API key.

#### Frontend Container

1. **Navigate to frontend directory**
   ```bash
   cd weather-frontend
   ```

2. **Build the Docker image**
   ```bash
   docker build -t weather-frontend .
   ```

3. **Run the container**
   ```bash
   docker run -d -p 3000:80 --name weather-frontend weather-frontend
   ```

4. **Access the application**
   - Open your browser to `http://localhost:3000`

## Testing the Application

### Manual Testing Checklist

#### 1. Test Backend Health Check

```bash
curl http://localhost:5000/
```

**Expected Response:**
```json
{
  "status": "running",
  "service": "Weather Backend API",
  "available_cities": ["newyork", "sydney", "capetown", "bangkok"]
}
```

#### 2. Test Backend Weather Endpoints

```bash
# Test New York
curl http://localhost:5000/weather/newyork

# Test Sydney
curl http://localhost:5000/weather/sydney

# Test Cape Town
curl http://localhost:5000/weather/capetown

# Test Bangkok
curl http://localhost:5000/weather/bangkok
```

**Expected Response Format:**
```json
{
  "city": "New York",
  "temperature": 22.5,
  "description": "Clear sky",
  "humidity": 65,
  "wind_speed": 3.5
}
```

#### 3. Test Frontend UI

1. **Open Browser**
   - Navigate to `http://localhost:3000`

2. **Verify UI Elements**
   - [ ] Page loads successfully
   - [ ] Header shows "Weather Dashboard"
   - [ ] Dropdown shows 4 cities
   - [ ] "Get Weather" button is visible

3. **Test City Selection**
   - [ ] Select "New York" from dropdown
   - [ ] Click "Get Weather"
   - [ ] Weather card appears with data
   - [ ] Temperature is displayed
   - [ ] Weather description is shown
   - [ ] Humidity percentage is visible
   - [ ] Wind speed is displayed

4. **Test All Cities**
   - [ ] Repeat test for Sydney
   - [ ] Repeat test for Cape Town
   - [ ] Repeat test for Bangkok

5. **Test Error Handling**
   - Stop the backend server
   - Try to fetch weather
   - [ ] Error message is displayed
   - Restart the backend server

#### 4. Test Docker Containers

If using Docker:

```bash
# Check running containers
docker ps

# Check backend logs
docker logs weather-backend

# Check frontend logs
docker logs weather-frontend
```

### Integration Test Script

Create a simple test script to verify everything works:

**test_integration.sh** (Linux/Mac):
```bash
#!/bin/bash

echo "Testing Weather Dashboard Integration..."
echo ""

# Test backend health
echo "1. Testing backend health check..."
curl -s http://localhost:5000/ | grep -q "running" && echo "✓ Backend is running" || echo "✗ Backend failed"
echo ""

# Test each city
echo "2. Testing weather endpoints..."
for city in newyork sydney capetown bangkok; do
    curl -s http://localhost:5000/weather/$city | grep -q "temperature" && echo "✓ $city: OK" || echo "✗ $city: FAILED"
done
echo ""

echo "3. Testing frontend..."
curl -s http://localhost:3000 | grep -q "Weather Dashboard" && echo "✓ Frontend is accessible" || echo "✗ Frontend failed"
echo ""

echo "Integration test complete!"
```

**test_integration.ps1** (Windows PowerShell):
```powershell
Write-Host "Testing Weather Dashboard Integration..." -ForegroundColor Cyan
Write-Host ""

# Test backend health
Write-Host "1. Testing backend health check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/"
    if ($response.status -eq "running") {
        Write-Host "✓ Backend is running" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Backend failed" -ForegroundColor Red
}
Write-Host ""

# Test each city
Write-Host "2. Testing weather endpoints..." -ForegroundColor Yellow
$cities = @("newyork", "sydney", "capetown", "bangkok")
foreach ($city in $cities) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5000/weather/$city"
        if ($response.temperature) {
            Write-Host "✓ $city : OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ $city : FAILED" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "Integration test complete!" -ForegroundColor Cyan
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Configuration error: OpenWeatherMap API key not configured"

**Solution:**
- Check that `.env` file exists in weather-backend directory
- Verify the API key is correctly set: `OPENWEATHER_API_KEY=your_key`
- Ensure there are no extra spaces or quotes
- If using Docker, pass the key with `-e` flag

#### Issue: "API key not activated yet"

**Solution:**
- Wait 10-15 minutes after creating your OpenWeatherMap account
- Try the API key directly: `http://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_KEY`

#### Issue: Frontend shows "Failed to fetch weather data"

**Solution:**
1. Verify backend is running: `curl http://localhost:5000/`
2. Check backend URL in frontend `.env` file
3. Check browser console for CORS errors
4. Verify backend has CORS enabled (it should by default)

#### Issue: Backend returns 502 errors

**Solution:**
- Check internet connection
- Verify API key is valid
- Check OpenWeatherMap API status: [https://status.openweathermap.org/](https://status.openweathermap.org/)

#### Issue: Docker container won't start

**Solution:**
```bash
# Check container logs
docker logs weather-backend
docker logs weather-frontend

# Remove and recreate containers
docker rm -f weather-backend weather-frontend
# Then rebuild and run again
```

#### Issue: Port already in use

**Solution:**
```bash
# For backend (port 5000)
# On Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# On Linux/Mac
lsof -ti:5000 | xargs kill

# For frontend (port 3000)
# On Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# On Linux/Mac
lsof -ti:3000 | xargs kill
```

## Project Structure

```
project/
├── weather-backend/          # Backend microservice
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .env.example
│   ├── .gitignore
│   └── README.md
├── weather-frontend/         # Frontend microservice
│   ├── public/
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   ├── .env.example
│   ├── .gitignore
│   └── README.md
└── SETUP_GUIDE.md           # This file
```

## Next Steps

After successfully running the application:

1. **Create GitHub Repositories**
   - Create two separate repositories: `weather-backend` and `weather-frontend`
   - Push each microservice to its respective repository

2. **Documentation Screenshots**
   - Take screenshots of the working application
   - Add them to the respective README files

3. **Prepare for Deployment**
   - Consider cloud deployment options (AWS, Azure, Google Cloud)
   - Look into Kubernetes for orchestration
   - Set up CI/CD pipelines

## Summary

You now have:

- ✅ Backend API serving weather data from OpenWeatherMap
- ✅ Frontend React app with beautiful UI
- ✅ Both services running locally or in Docker
- ✅ Complete documentation for both services
- ✅ Testing procedures to verify functionality

**Congratulations!** Your Weather Dashboard App is ready for Phase 1 submission!
