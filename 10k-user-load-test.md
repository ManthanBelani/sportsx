# 10K User Load Test Script for Laravel Backend

This guide shows how to create a load test script to test your Laravel backend (SportX API) with 10k concurrent users using **Locust**, a popular open-source load testing tool.

## Prerequisites

- Python 3.8+
- pip (Python package manager)
- Your Laravel backend running locally or on a test server
- API base URL (e.g., `http://localhost:8000` or your server IP)

## Install Locust

```bash
pip install locust
```

## Create the Load Test Script

Create a file named `locustfile.py` in your project root:

```python
from locust import HttpUser, task, between, events
import random
import string


# Base URL will be set via -H flag or LOCUST_HOST env var
# Example: locust -f locustfile.py --host=http://localhost:8000

# Sample user data for 10k simulation
FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "David", "Elizabeth", "William", "Barbara", "Richard", "Susan", "Joseph", "Jessica"
]
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Taylor"
]
CITIES = ["New York", "London", "Paris", "Tokyo", "Sydney", "Berlin", "Toronto"]
SPORTS = ["football", "basketball", "tennis", "swimming", "running", "cycling"]


def generate_user_data():
    """Generate realistic user data for load testing."""
    return {
        "name": f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
        "email": f"{''.join(random.choices(string.ascii_lowercase, k=8))}@example.com",
        "city": random.choice(CITIES),
        "sport": random.choice(SPORTS),
    }


class SportXUser(HttpUser):
    """Simulates a real user interacting with the SportX backend."""
    
    wait_time = between(1, 5)  # Wait 1-5 seconds between tasks
    
    @task(10)
    def health_check(self):
        """Test the health endpoint - high frequency."""
        self.client.get("/api/v1/health")
    
    @task(5)
    def system_health(self):
        """Test system health endpoint."""
        self.client.get("/api/v1/system/health")
    
    @task(3)
    def register(self):
        """Test user registration."""
        data = generate_user_data()
        self.client.post("/api/v1/auth/register", json=data)
    
    @task(8)
    def login(self):
        """Test user login."""
        # First register if not already done
        data = {
            "email": f"test{self.environment.runner.user_count}@example.com",
            "password": "testpassword123"
        }
        self.client.post("/api/v1/auth/login", json=data)
    
    @task(4)
    def get_meta(self):
        """Test meta endpoints - read-only, high traffic."""
        self.client.get("/api/v1/meta/sports")
        self.client.get("/api/v1/meta/cities")
        self.client.get("/api/v1/meta/age-groups")
    
    @task(3)
    def search(self):
        """Test search functionality."""
        self.client.get("/api/v1/search?q=football")
    
    @task(2)
    def get_profile(self):
        """Test authenticated profile endpoint."""
        # Login first if not authenticated
        headers = {"Authorization": "Bearer test-token-12345"}
        self.client.get("/api/v1/me/profile", headers=headers)
    
    @task(2)
    def get_leaderboard(self):
        """Test leaderboard endpoint."""
        self.client.get("/api/v1/leaderboard")
    
    @task(1)
    def create_post(self):
        """Test post creation (authenticated)."""
        headers = {"Authorization": "Bearer test-token-12345"}
        data = {"content": "Load test post from Locust"}
        self.client.post("/api/v1/posts", json=data, headers=headers)
    
    @task(1)
    def upload_media(self):
        """Test media upload (authenticated)."""
        headers = {"Authorization": "Bearer test-token-12345"}
        # Simulate file upload
        files = {"file": ("test.jpg", b"fake image content", "image/jpeg")}
        self.client.post("/api/v1/media/upload", files=files, headers=headers)
    
    @task(1)
    def send_message(self):
        """Test chat/message endpoint."""
        headers = {"Authorization": "Bearer test-token-12345"}
        data = {"content": "Load test message"}
        self.client.post("/api/v1/conversations/messages", json=data, headers=headers)
    
    @task(1)
    def create_tournament(self):
        """Test tournament registration."""
        headers = {"Authorization": "Bearer test-token-12345"}
        data = {
            "name": "Load Test Tournament",
            "sport": "football",
            "max_participants": 16
        }
        self.client.post("/api/v1/tournaments", json=data, headers=headers)
```

## Run the Load Test

### Basic Command

```bash
locust -f locustfile.py --host=http://localhost:8000 --users 10000 --spawn-rate 100
```

### Explanation of flags:
- `--users 10000`: Total number of simulated users (10k)
- `--spawn-rate 100`: Spawn 100 users per second (will take 100 seconds to reach 10k)
- `--host=http://localhost:8000`: Your API base URL

### Alternative: Run without specifying user count (configure in UI)
```bash
locust -f locustfile.py --host=http://localhost:8000
```
Then open `http://localhost:8089` in your browser, set the number of users to 10k, and start the test.

## Monitor Results

Locust provides a real-time web UI at `http://localhost:8089` showing:
- Current RPS (requests per second)
- Median/avg response time
- Error rates
- Requests per endpoint
- Concurrent user count

## Backend Reliability Testing Tips

### 1. Monitor Server Resources
Keep an eye on:
- CPU usage: `top` or `htop`
- Memory: `free -m`
- Database connections: `mysqladmin processlist`
- Nginx/Apache logs

### 2. Check for Memory Leaks
Run the test for an extended period (15-30 minutes) and watch for:
- Increasing memory usage without corresponding request growth
- Growing database connection pool

### 3. Test Error Handling
Monitor the Locust dashboard for:
- HTTP 5xx errors
- Connection timeouts
- SSL errors

### 4. Scale Gradually
Start with 100 users, then 500, 1000, 5000, and finally 10k. This helps identify the breaking point.

### 5. Enable Keep-Alive
Ensure your Laravel app supports HTTP keep-alive. In `config/http.php`:
```php
'keep_alive' => env('APP_DEBUG') !== true, // or true in production
```

### 6. Database Optimization
- Run `php artisan optimize` before testing
- Ensure proper indexing on frequently queried columns
- Consider using database connection pooling

### 7. Common Issues at Scale
- **Database connection exhaustion**: Increase `max_connections` or use connection pooling
- **Redis memory**: Monitor Redis memory usage if using queues/cache
- **File storage**: Ensure storage permissions are correct for concurrent writes
- **Session storage**: Use Redis or database for session sharing across workers

### 8. Post-Test Analysis
After the test, check:
- Average response time per endpoint
- Error rate percentage
- Throughput (requests/sec)
- Peak concurrent users supported

### 9. Stress Test Configuration
For extreme testing, you can also use `k6` instead of Locust:

```bash
# Install k6
brew install k6  # macOS
# or: apt-get install k6  # Debian/Ubuntu

# Create k6 script (test.js)
export const options = {
  scenarios: {
    classic: {
      executor: 'constant-vus',
      vus: 10000,
      duration: '5m'
    }
  }
};

export default function() {
  http.get('http://localhost:8000/api/v1/health');
}
```

Run with: `k6 run test.js`

### 10. Recovery Testing
After the 10k load test:
- Restart PHP-FPM: `systemctl restart php8.3-fpm`
- Clear opcache: `php artisan opcache:clear`
- Check for any crashed processes or zombie connections

## Sample Output Analysis

If you see these issues, consider the following fixes:

| Issue | Possible Cause | Fix |
|-------|---------------|-----|
| Response time > 5s at 2k users | DB queries without indexes | Add indexes, optimize queries |
| 502 Bad Gateway at 5k users | PHP-FPM pool exhausted | Increase `pm.max_children` |
| 504 Gateway Timeout | Slow queries | Add caching, optimize queries |
| Memory growth over time | PHP memory leak | Restart workers periodically, enable opcache |
| High error rate at 10k | Rate limiting throttling | Adjust throttle rates in routes |