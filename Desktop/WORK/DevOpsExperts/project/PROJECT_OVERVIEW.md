# Weather Dashboard App - Project Overview

## Project Summary

A full-stack weather dashboard application built with microservices architecture, featuring a Python Flask backend and React frontend. The application displays real-time weather data for 4 major cities worldwide using the OpenWeatherMap API.

## Architecture

```
┌─────────────┐         ┌──────────────┐         ┌─────────────────┐
│   Browser   │ ──────> │    React     │ ──────> │  Flask Backend  │
│   (User)    │ <────── │   Frontend   │ <────── │   (Port 5000)   │
└─────────────┘         │  (Port 3000) │         └─────────────────┘
                        └──────────────┘                  │
                                                          │
                                                          v
                                                ┌──────────────────┐
                                                │  OpenWeatherMap  │
                                                │       API        │
                                                └──────────────────┘
```

## Microservices

### Backend Service (`weather-backend/`)

**Technology Stack:**
- Python 3.11
- Flask web framework
- Flask-CORS for cross-origin requests
- Requests library for API calls
- Python-dotenv for environment management

**Features:**
- RESTful API design
- Fetches real-time weather data from OpenWeatherMap
- Supports 4 cities: New York, Sydney, Cape Town, Bangkok
- Returns JSON with temperature, description, humidity, wind speed
- Comprehensive error handling
- Docker containerization

**Endpoints:**
- `GET /` - Health check
- `GET /weather/<city>` - Get weather for specific city

### Frontend Service (`weather-frontend/`)

**Technology Stack:**
- React 18
- Modern CSS with gradients
- Responsive design
- Multi-stage Docker build with Nginx

**Features:**
- Clean, modern user interface
- Dropdown city selection
- Real-time weather display
- Loading states and error handling
- Mobile-responsive design
- Optimized production build

## Key Features

✅ **Microservices Architecture** - Separate, independently deployable services  
✅ **Containerization** - Both services have Dockerfiles  
✅ **API Integration** - Live data from OpenWeatherMap  
✅ **Modern UI** - Beautiful gradient design with smooth animations  
✅ **Error Handling** - Comprehensive error messages and states  
✅ **Documentation** - Complete README files for both services  
✅ **Environment Configuration** - Secure API key management  
✅ **Version Control Ready** - .gitignore files to prevent sensitive data commits  

## Directory Structure

```
project/
│
├── weather-backend/              # Backend Microservice
│   ├── app.py                   # Flask application
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Backend container config
│   ├── .env.example            # API key template
│   ├── .gitignore             # Git ignore rules
│   └── README.md              # Backend documentation
│
├── weather-frontend/             # Frontend Microservice
│   ├── public/                 # Static files
│   │   └── index.html
│   ├── src/                    # React source code
│   │   ├── App.js             # Main component
│   │   ├── App.css            # Styles
│   │   └── index.js           # Entry point
│   ├── package.json           # Node dependencies
│   ├── Dockerfile            # Frontend container config
│   ├── .env.example          # Backend URL template
│   ├── .gitignore           # Git ignore rules
│   └── README.md            # Frontend documentation
│
├── Final Project Phase1.md     # Project requirements
├── SETUP_GUIDE.md             # Complete setup instructions
└── PROJECT_OVERVIEW.md        # This file
```

## Technical Highlights

### Backend Implementation

1. **API Integration**
   - Connects to OpenWeatherMap API
   - Handles API authentication with environment variables
   - Converts city keys to full city names

2. **Error Handling**
   - Invalid city validation
   - API timeout handling
   - HTTP error responses
   - Network failure handling
   - Malformed data detection

3. **CORS Configuration**
   - Enables cross-origin requests
   - Allows frontend on different port to communicate

### Frontend Implementation

1. **State Management**
   - React hooks (useState) for state
   - Manages loading, error, and data states

2. **API Communication**
   - Fetch API for HTTP requests
   - Environment variable for backend URL
   - Error handling for failed requests

3. **User Experience**
   - Loading indicators
   - Smooth animations
   - Responsive design
   - Clear error messages

### Docker Strategy

**Backend:**
- Single-stage build with Python slim image
- ~150MB final image size
- Port 5000 exposed

**Frontend:**
- Multi-stage build (Node build + Nginx serve)
- ~25MB final image size
- Port 80 exposed (mapped to 3000)

## Running the Application

### Quick Start (Local)

```bash
# Terminal 1 - Backend
cd weather-backend
pip install -r requirements.txt
# Create .env with your API key
python app.py

# Terminal 2 - Frontend
cd weather-frontend
npm install
npm start
```

### Quick Start (Docker)

```bash
# Backend
cd weather-backend
docker build -t weather-backend .
docker run -p 5000:5000 -e OPENWEATHER_API_KEY=your_key weather-backend

# Frontend
cd weather-frontend
docker build -t weather-frontend .
docker run -p 3000:80 weather-frontend
```

## Testing Checklist

- [x] Backend health check responds correctly
- [x] Backend returns weather data for all 4 cities
- [x] Frontend displays UI correctly
- [x] Frontend successfully fetches and displays weather
- [x] Error handling works when backend is down
- [x] Docker containers build successfully
- [x] Docker containers run and communicate correctly

## Phase 1 Deliverables ✅

All requirements met:

1. ✅ **Two GitHub repositories** - Ready to be pushed (backend and frontend)
2. ✅ **Backend microservice** - Flask API fetching live weather data
3. ✅ **Frontend microservice** - React app with dropdown and weather display
4. ✅ **Dockerfiles** - Present in both repositories
5. ✅ **README files** - Comprehensive documentation for both services
6. ✅ **Working integration** - Frontend successfully calls backend

## API Key Setup

1. Sign up at https://openweathermap.org/api
2. Get your free API key from the dashboard
3. Add to backend `.env` file:
   ```
   OPENWEATHER_API_KEY=your_actual_key_here
   ```
4. Wait 10-15 minutes for API key activation

## Cities and Endpoints

| City       | Endpoint                          | Display Name |
|------------|-----------------------------------|--------------|
| New York   | `/weather/newyork`               | New York     |
| Sydney     | `/weather/sydney`                | Sydney       |
| Cape Town  | `/weather/capetown`              | Cape Town    |
| Bangkok    | `/weather/bangkok`               | Bangkok      |

## Response Format

```json
{
  "city": "New York",
  "temperature": 22.5,
  "description": "Clear sky",
  "humidity": 65,
  "wind_speed": 3.5
}
```

## Security Considerations

- API keys stored in `.env` files (not committed to Git)
- `.env` files listed in `.gitignore`
- CORS properly configured for security
- No hardcoded credentials
- Environment variables for configuration

## Future Enhancements

Potential Phase 2 improvements:

- Kubernetes deployment with YAML manifests
- CI/CD pipeline with GitHub Actions
- Docker Compose for easy multi-container deployment
- Monitoring and logging
- Load balancing
- Database for historical weather data
- User authentication
- Additional cities
- Weather forecasts (5-day)
- Weather icons and animations

## Technologies Used

**Backend:**
- Python 3.11
- Flask 3.0.0
- Flask-CORS 4.0.0
- Requests 2.31.0
- Python-dotenv 1.0.0

**Frontend:**
- React 18.2.0
- React Scripts 5.0.1
- Modern CSS3
- Fetch API

**DevOps:**
- Docker
- Multi-stage builds
- Nginx for static file serving

## Resources

- [Backend README](weather-backend/README.md)
- [Frontend README](weather-frontend/README.md)
- [Setup Guide](SETUP_GUIDE.md)
- [OpenWeatherMap API Documentation](https://openweathermap.org/api)

## Contact

This project was created as part of the DevOps Experts training program - Phase 1.

---

**Project Status:** ✅ Complete and ready for submission
