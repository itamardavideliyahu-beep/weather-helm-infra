**Phase 1 – Weather App: Local Development** 

**Objective** 

Students will create the backend and frontend microservices of a Weather Dashboard App. The backend fetches weather data from a free external API, and the frontend displays it for the user. 

 **Backend Microservice: Weather Service** 

**Task** 

•    
Implement a REST API service that returns current weather for 4 locations: New York, Sydney, Cape Town, Bangkok. 

**Instructions** 

1\.    
Get an API key from OpenWeatherMap: 

2\.    
Go to https://openweathermap.org/api 

3\.    
Sign up for a free account. 

4\.    
Navigate to API keys and copy your key. 

5\.    
Backend API: 

6\.    
Endpoint example: GET /weather/\<location\_key\> 

7\.    
Use OpenWeatherMap API to fetch weather: http://api.openweathermap.org/data/2.5/weather? 

q=\<city\>\&appid=\<YOUR\_API\_KEY\>\&units=metric 

8\.    
Return JSON with temperature, weather description, optional humidity and wind speed. 

**Repository** 

•    
Create a separate GitHub repository for the backend. 

•    
Add a Dockerfile for containerization. 

•    
Write README.md explaining installation, running locally, and API key setup. 

 **Frontend Microservice: Weather Dashboard Task** 

•    
Create a frontend app with a dropdown for 4 cities. 

•    
Submit button calls backend API and displays weather. 

**Instructions** 

1\.  2\.  3\.    
Frontend logic: 

Dropdown list of locations 

Submit button calls backend API 

1  
4\.  5\.  6\.    
Display weather result Repository 

Separate GitHub repository from backend. 

7\.    
Include a Dockerfile. 

8\.    
Write README.md explaining local run, Docker build, backend URL configuration. 

 **Dockerization** 

**Backend Dockerfile** 

•  •    
Base Python image 

Install dependencies (Flask, requests) •    
Copy backend code 

•    
Set environment variable for API key 

•  •    
Expose port 5000 Run server 

**Frontend Dockerfile** 

•    
Base Python or lightweight web server image •    
Install dependencies (Flask if using Python) •    
Copy frontend code 

•  •    
Expose port 5000 Run server 

 **README Guidelines Backend README** 

•    
How to run locally 

•    
How to set OpenWeatherMap API key •    
Endpoint description: /weather/\<location\_key\> •    
Optional curl examples **Frontend README** 

•  •    
How to run locally 

Configure backend URL 

•    
Dropdown options for cities •    
Screenshot of expected UI 

2  
 **Deliverables for Phase 1** 

•    
Two GitHub repositories: backend and frontend 

•    
Dockerfile in each repository •    
README.md in each repository •    
Working frontend calling backend and fetching live weather data 

 Phase 1 Goal: Two containerized microservices working together locally, fetching live weather data from external API. 

3