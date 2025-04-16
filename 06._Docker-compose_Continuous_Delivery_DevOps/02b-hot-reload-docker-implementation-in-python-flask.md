# 02b. Hot Reload Docker Implementation in Python Flask 🐍

[<- Back to Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)

## Table of Contents

- [Understanding Python Hot Reload](#understanding-python-hot-reload)
- [Flask's Built-in Development Server](#flasks-built-in-development-server)
- [Using Watchdog for Better File Watching](#using-watchdog-for-better-file-watching)
- [Docker Development Setup for Flask](#docker-development-setup-for-flask)
- [Example Flask Application](#example-flask-application)
- [Advanced Configurations](#advanced-configurations)
- [Production vs Development Setup](#production-vs-development-setup)

## Understanding Python Hot Reload

Python's interpreted nature makes it well-suited for hot reloading:

1. **No compilation step**: Changes to code can be immediately reflected
2. **Dynamic module loading**: Python can reload modules at runtime
3. **Built-in development servers**: Many frameworks include auto-reloading
4. **Lightweight process**: Restarting a Python application is relatively fast

These characteristics make Python ideal for development with hot reload in Docker containers.

## Flask's Built-in Development Server

Flask includes a development server with hot reload capabilities out of the box:

### Basic Flask Development Server

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return {"message": "Hello, World!"}

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
```

The key parameter is `debug=True`, which enables:

1. **Auto-reloading**: Server restarts when code changes
2. **Interactive debugger**: Web-based debugger for exceptions
3. **Detailed error pages**: More information for troubleshooting

### How Flask's Reloader Works

Flask's reloader works by:
1. Spawning a child process to run the actual application
2. The parent process monitors file changes
3. When changes are detected, the child process is restarted

## Using Watchdog for Better File Watching

The default Flask reloader is adequate for most cases, but [Watchdog](https://pypi.org/project/watchdog/) provides improved performance and reliability, especially in Docker:

### Installing Watchdog

```bash
pip install watchdog
```

### Enabling Watchdog in Flask

```python
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=True, reloader_type='watchdog')
```

## Docker Development Setup for Flask

Creating an efficient Docker development environment for Flask requires proper configuration:

### Dockerfile.dev

```Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install development dependencies
RUN pip install --no-cache-dir watchdog

# The source code will be mounted at runtime
# CMD will be provided by docker-compose

EXPOSE 5000

# Command for development with hot reload
CMD ["python", "app.py"]
```

### requirements.txt

```
flask==2.3.3
python-dotenv==1.0.0
requests==2.31.0
```

### Optimized docker-compose.dev.yml

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    volumes:
      # Mount the entire app directory
      - .:/app
    environment:
      - FLASK_ENV=development
      - FLASK_DEBUG=1
      - PYTHONDONTWRITEBYTECODE=1
      - PYTHONUNBUFFERED=1
```

### Key Docker Configuration Elements

1. **Environment variables**:
   - `FLASK_ENV=development`: Enables development mode
   - `FLASK_DEBUG=1`: Enables the debugger
   - `PYTHONDONTWRITEBYTECODE=1`: Prevents Python from writing .pyc files
   - `PYTHONUNBUFFERED=1`: Ensures Python output is sent straight to terminal

2. **Volume configuration**:
   - Mount the entire application directory for immediate updates
   - No need for separate build artifacts like in compiled languages

3. **Port mapping**:
   - Map container port to host for easy access

## Example Flask Application

Let's look at a complete Flask application with hot reload:

### Application Structure

```
project/
  ├── app.py
  ├── templates/
  │    └── index.html
  ├── static/
  │    ├── css/
  │    └── js/
  ├── requirements.txt
  ├── Dockerfile
  ├── Dockerfile.dev
  └── docker-compose.dev.yml
```

### Example Application Code (app.py)

```python
import os
from flask import Flask, render_template, jsonify

app = Flask(__name__)

# Configuration
app.config['DEBUG'] = os.environ.get('FLASK_DEBUG', 'False') == '1'
app.config['API_URL'] = os.environ.get('API_URL', 'http://api:5001')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/health')
def health_check():
    return jsonify({
        "status": "ok",
        "service": "web"
    })

@app.route('/api/data')
def get_data():
    # This is just example data
    return jsonify({
        "items": [
            {"id": 1, "name": "Item 1"},
            {"id": 2, "name": "Item 2"},
            {"id": 3, "name": "Item 3"}
        ]
    })

if __name__ == '__main__':
    # Use watchdog for better file watching in Docker
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,
        use_reloader=True,
        reloader_type='watchdog'
    )
```

### Templates (templates/index.html)

```html
<!DOCTYPE html>
<html>
<head>
    <title>Flask App</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/styles.css') }}">
</head>
<body>
    <h1>Welcome to Flask</h1>
    <p>This is a hot-reloadable Flask application.</p>
    
    <div id="data-container">Loading...</div>
    
    <script src="{{ url_for('static', filename='js/main.js') }}"></script>
</body>
</html>
```

### Static JavaScript (static/js/main.js)

```javascript
document.addEventListener('DOMContentLoaded', function() {
    fetch('/api/data')
        .then(response => response.json())
        .then(data => {
            const container = document.getElementById('data-container');
            container.innerHTML = `
                <h2>Data Items</h2>
                <ul>
                    ${data.items.map(item => `<li>${item.name}</li>`).join('')}
                </ul>
            `;
        })
        .catch(error => {
            console.error('Error fetching data:', error);
            document.getElementById('data-container').textContent = 'Error loading data';
        });
});
```

## Running the Development Environment

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up --build
```

Once running, you can:
1. Edit `app.py` to modify the application logic
2. Modify templates in the `templates` directory
3. Update static files in the `static` directory
4. See changes reflected immediately in the browser

## Advanced Configurations

### Using Flask with gunicorn and watchdog

For a more production-like setup with hot reload:

#### requirements-dev.txt

```
flask==2.3.3
gunicorn==21.2.0
watchdog==3.0.0
python-dotenv==1.0.0
```

#### app.py

```python
# app.py stays mostly the same, but we'll separate the app creation
# from the running code to make it work well with gunicorn

import os
from flask import Flask, render_template, jsonify

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config['DEBUG'] = os.environ.get('FLASK_DEBUG', 'False') == '1'
    app.config['API_URL'] = os.environ.get('API_URL', 'http://api:5001')
    
    @app.route('/')
    def index():
        return render_template('index.html')
    
    @app.route('/api/health')
    def health_check():
        return jsonify({
            "status": "ok",
            "service": "web"
        })
    
    @app.route('/api/data')
    def get_data():
        return jsonify({
            "items": [
                {"id": 1, "name": "Item 1"},
                {"id": 2, "name": "Item 2"},
                {"id": 3, "name": "Item 3"}
            ]
        })
    
    return app

# This allows running with `python app.py` for development
if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
```

#### run-dev.sh

```bash
#!/bin/bash
gunicorn --bind 0.0.0.0:5000 --workers 1 --reload --reload-extra-file ./templates/ --reload-extra-file ./static/ "app:create_app()"
```

#### Dockerfile.dev

```Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1

# Make the run script executable
COPY run-dev.sh .
RUN chmod +x run-dev.sh

EXPOSE 5000

# Run with gunicorn and hot reloading
CMD ["./run-dev.sh"]
```

This configuration uses gunicorn with reload capability, which provides:
- More production-like server behavior
- Better process management
- Still maintains hot reloading for development

### Using docker-compose with Multiple Services

For a more complex application with a database:

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    volumes:
      - .:/app
    environment:
      - FLASK_ENV=development
      - FLASK_DEBUG=1
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/flask_dev
    depends_on:
      - db
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=flask_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## Production vs Development Setup

The development setup differs significantly from production:

### Development Environment

- Uses Flask's built-in server or gunicorn with reload
- Debug mode enabled
- Volume mounts for hot reload
- Direct exposure of ports for easy access
- Environment variables for development mode

### Production Dockerfile (Dockerfile)

```Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install production dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

EXPOSE 5000

# Run with gunicorn in production mode
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:create_app()"]
```

### Production docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/flask_prod
    depends_on:
      - db
    networks:
      - app_network
  
  nginx:
    image: nginx:1.23
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./static:/app/static:ro
    depends_on:
      - web
    networks:
      - app_network
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=flask_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app_network

networks:
  app_network:

volumes:
  postgres_data:
```

This production setup uses:
- Multi-container architecture with web server, application, and database
- No volume mounts for application code
- No debugging enabled
- Proper network isolation
- Production-ready worker configuration

---

[<- Back to Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)
