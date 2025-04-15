# 8. Web Crawling Architectural Decisions 🏗️

[<- Back to Scrapy](./07-scrapy.md) | [Back to Main](./README.md)

## Table of Contents
- [Data Storage Strategies](#data-storage-strategies)
- [Deployment Approaches](#deployment-approaches)
- [Distributed Crawling](#distributed-crawling)
- [Scheduling and Automation](#scheduling-and-automation)
- [Error Handling and Resilience](#error-handling-and-resilience)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Data Storage Strategies

When designing a web crawling system, how you handle data storage is a critical architectural decision that impacts system performance, scalability, and reliability.

### Immediate Upload Approach

**Flow**: Scraper extracts data → Immediately uploads to the database

```
Web Page → Scraper → Database
```

**Advantages**:
- Real-time data availability
- Simplicity in implementation
- No local storage requirements

**Disadvantages**:
- Increased server load during scraping
- More vulnerable to network issues
- Requires constant database connection
- Can be slower overall due to per-record database operations

**Best for**:
- Small-scale scraping
- Time-sensitive data requirements
- Systems with reliable network connections

### Local Cache with Batch Upload

**Flow**: Scraper extracts data → Stores locally → Periodically uploads batches

```
Web Page → Scraper → Local Storage → Batch Processor → Database
```

**Advantages**:
- Reduced server/database load
- More resilient to network interruptions
- Better performance for large-scale scraping
- Reduced database connection overhead

**Disadvantages**:
- Delayed data availability
- Additional complexity in batch management
- Requires local storage solution

### Implementation Options

#### Option 1: Post-Scraping Upload Script

```python
# Scrape and store locally
def scrape_websites():
    results = []
    for url in urls_to_scrape:
        data = scrape_url(url)
        results.append(data)
    
    # Save to local file
    with open('scraped_data.json', 'w') as f:
        json.dump(results, f)

# Upload in batches
def upload_to_database():
    with open('scraped_data.json', 'r') as f:
        data = json.load(f)
    
    # Split into batches
    batch_size = 100
    for i in range(0, len(data), batch_size):
        batch = data[i:i+batch_size]
        db.insert_many('products', batch)
```

#### Option 2: SQLite as Intermediate Storage

```python
# Scrape into SQLite database
def scrape_to_sqlite():
    conn = sqlite3.connect('scraped_data.db')
    cursor = conn.cursor()
    
    for url in urls_to_scrape:
        data = scrape_url(url)
        cursor.execute(
            "INSERT INTO products (name, price, url) VALUES (?, ?, ?)",
            (data['name'], data['price'], data['url'])
        )
    
    conn.commit()
    conn.close()

# Transfer entire SQLite database
def transfer_database():
    # Option 1: Use database migration tools
    # Option 2: Direct SQL transfer
    # Option 3: Simply transfer the .db file
```

## Deployment Approaches

Where and how to run your web scraping system is another key architectural decision that affects reliability, scalability, and maintenance.

### Local Development Environment

**Approach**: Run scripts on developer machines during development or for ad-hoc scraping.

**Advantages**:
- Simple setup
- Direct access to results
- Immediate feedback and debugging

**Disadvantages**:
- Not suitable for production use
- Limited resources
- No automatic recovery
- Requires machine to remain active

### Scheduled Server Jobs

**Approach**: Deploy scrapers on dedicated servers with scheduled execution.

**Advantages**:
- More reliable than local execution
- Better resource allocation
- Centralized logging and monitoring
- Can run on more powerful hardware

**Disadvantages**:
- Requires server maintenance
- Single point of failure
- Limited horizontal scaling

### Containerized Solutions

**Approach**: Package scrapers in containers (Docker) and run them on orchestration platforms (Kubernetes, ECS).

**Advantages**:
- Consistent environment
- Easy scaling
- Isolation from other services
- Better resource utilization

**Disadvantages**:
- Added complexity
- Learning curve for container orchestration
- Potentially higher costs

### Serverless Functions

**Approach**: Run scrapers as serverless functions (AWS Lambda, Google Cloud Functions).

**Advantages**:
- No server management
- Pay-per-execution
- Automatic scaling
- High availability

**Disadvantages**:
- Execution time limits
- Cold start delays
- Memory limitations
- Complexity in handling state

## Distributed Crawling

For large-scale web crawling, distributing the workload across multiple machines or processes can significantly improve performance and reliability.

### Centralized Queue Architecture

**Flow**: Central queue → Multiple scraper instances → Central database

```
                     ┌─→ Scraper 1 ─→┐
Central Queue of URLs ├─→ Scraper 2 ─→├─→ Central Database
                     └─→ Scraper 3 ─→┘
```

**Implementation Options**:
1. **Message Queues**: RabbitMQ, Kafka, SQS
2. **Distributed Task Queues**: Celery, Redis-based queues

**Example with Redis and Celery**:

```python
# tasks.py
from celery import Celery

app = Celery('crawler', broker='redis://localhost:6379/0')

@app.task
def scrape_url(url):
    data = fetch_and_parse(url)
    store_data(data)
    
    # Add new discovered URLs to the queue
    for new_url in extract_links(data):
        if should_visit(new_url):
            scrape_url.delay(new_url)

# crawler.py
def start_crawl(start_urls):
    for url in start_urls:
        scrape_url.delay(url)
```

### Horizontally Partitioned Crawling

**Approach**: Divide the URL space among crawlers based on domain, path patterns, or hashing.

```python
def assign_crawler(url):
    # Simple domain-based partitioning
    domain = extract_domain(url)
    crawler_id = hash(domain) % NUM_CRAWLERS
    return f"crawler-{crawler_id}"

def start_distributed_crawl():
    for url in start_urls:
        crawler = assign_crawler(url)
        send_to_crawler(crawler, url)
```

### Challenges in Distributed Crawling

1. **Coordination**: Ensuring URLs aren't processed multiple times
2. **State Management**: Tracking crawl progress and visited URLs
3. **Failure Handling**: Recovering from crawler or queue failures
4. **Data Consistency**: Ensuring data integrity across distributed components

## Scheduling and Automation

Regular, automated execution is essential for keeping scraped data current and maintaining system reliability.

### Cron Jobs

**Approach**: Use system cron or cron-like schedulers to run scraping tasks.

```bash
# Example crontab entry (run daily at 2 AM)
0 2 * * * cd /path/to/scraper && python run_scraper.py >> /var/log/scraper.log 2>&1
```

**Advantages**:
- Simple, widely understood
- Built into most operating systems
- No additional dependencies

**Disadvantages**:
- Limited monitoring
- Basic scheduling options
- No built-in retry mechanism

### GitHub Actions Scheduled Workflows

**Approach**: Use GitHub Actions to run scrapers on a schedule.

```yaml
# .github/workflows/scrape-daily.yml
name: Run Scrapy Project Daily

on:
  schedule:
    - cron: '0 0 * * *'  # Runs at midnight (UTC) every day

jobs:
  run-scrapy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.8'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run Scrapy Spider
        run: |
          scrapy crawl <spider_name> -o output.json
      
      - name: Upload results to database
        run: |
          python upload_results.py
```

**Advantages**:
- No infrastructure to maintain
- Built-in logging and notifications
- Version controlled alongside code
- Free for public repositories

**Disadvantages**:
- Limited execution time
- Potential rate limiting
- Limited resource allocation
- May pause after inactivity (60 days for public repos)

### Dedicated Scheduling Services

**Options**:
- Airflow: Complex workflow orchestration
- Jenkins: Robust build and job scheduling
- Rundeck: Operations runbook automation
- Kubernetes CronJobs: Container-based scheduling

**Example Airflow DAG**:

```python
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_team',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': True,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'web_scraping_pipeline',
    default_args=default_args,
    description='Web scraping and data processing pipeline',
    schedule_interval='0 2 * * *',
)

t1 = BashOperator(
    task_id='run_scraper',
    bash_command='cd /path/to/scraper && python run_scraper.py',
    dag=dag,
)

t2 = BashOperator(
    task_id='process_data',
    bash_command='cd /path/to/processor && python process_data.py',
    dag=dag,
)

t3 = BashOperator(
    task_id='load_to_database',
    bash_command='cd /path/to/loader && python load_to_db.py',
    dag=dag,
)

t1 >> t2 >> t3
```

## Error Handling and Resilience

Robust error handling is critical for web scraping systems that operate in the unpredictable environment of the internet.

### Common Failure Points

1. **Network Issues**: Connection timeouts, DNS failures
2. **Target Site Changes**: DOM structure changes, rate limiting
3. **Resource Constraints**: Memory limits, CPU constraints
4. **Authentication Failures**: Session expiration, IP blocking

### Resilience Strategies

1. **Exponential Backoff**:
   ```python
   def fetch_with_retry(url, max_retries=5):
       retries = 0
       while retries < max_retries:
           try:
               return requests.get(url, timeout=10)
           except requests.RequestException:
               wait_time = 2 ** retries  # Exponential backoff
               print(f"Retrying in {wait_time} seconds...")
               time.sleep(wait_time)
               retries += 1
       raise Exception(f"Failed to fetch {url} after {max_retries} retries")
   ```

2. **Circuit Breaker Pattern**:
   ```python
   class CircuitBreaker:
       def __init__(self, failure_threshold=5, reset_timeout=60):
           self.failure_count = 0
           self.failure_threshold = failure_threshold
           self.reset_timeout = reset_timeout
           self.state = "CLOSED"  # CLOSED, OPEN, HALF-OPEN
           self.last_failure_time = None
           
       def execute(self, function, *args, **kwargs):
           if self.state == "OPEN":
               if time.time() - self.last_failure_time > self.reset_timeout:
                   self.state = "HALF-OPEN"
               else:
                   raise Exception("Circuit breaker is OPEN")
                   
           try:
               result = function(*args, **kwargs)
               if self.state == "HALF-OPEN":
                   self.failure_count = 0
                   self.state = "CLOSED"
               return result
           except Exception as e:
               self.failure_count += 1
               self.last_failure_time = time.time()
               if self.failure_count >= self.failure_threshold:
                   self.state = "OPEN"
               raise e
   ```

3. **Checkpointing and Resume**:
   ```python
   def crawl_with_checkpointing(start_urls):
       # Load checkpoint if exists
       if os.path.exists('checkpoint.json'):
           with open('checkpoint.json', 'r') as f:
               state = json.load(f)
               urls_to_visit = state['urls_to_visit']
               visited_urls = set(state['visited_urls'])
       else:
           urls_to_visit = start_urls
           visited_urls = set()
       
       try:
           while urls_to_visit:
               current_url = urls_to_visit.pop(0)
               if current_url in visited_urls:
                   continue
                   
               data = scrape_url(current_url)
               process_data(data)
               
               # Update visited and to-visit lists
               visited_urls.add(current_url)
               new_urls = extract_links(data)
               urls_to_visit.extend([u for u in new_urls if u not in visited_urls])
               
               # Save checkpoint periodically
               if len(visited_urls) % 10 == 0:
                   save_checkpoint(urls_to_visit, visited_urls)
       except Exception as e:
           # Save checkpoint on crash
           save_checkpoint(urls_to_visit, visited_urls)
           raise e
   
   def save_checkpoint(urls_to_visit, visited_urls):
       with open('checkpoint.json', 'w') as f:
           json.dump({
               'urls_to_visit': urls_to_visit,
               'visited_urls': list(visited_urls)
           }, f)
   ```

## Monitoring and Maintenance

Long-running web crawling systems require monitoring and maintenance to ensure continued operation and data quality.

### Key Metrics to Monitor

1. **Operational Metrics**:
   - Success/failure rates
   - Crawl completion time
   - Request latency
   - Resource utilization

2. **Data Quality Metrics**:
   - Items extracted per page
   - Schema validation success rates
   - Data completeness
   - Pattern detection for site changes

### Monitoring Implementation

```python
class CrawlMonitor:
    def __init__(self):
        self.start_time = time.time()
        self.pages_crawled = 0
        self.errors = 0
        self.items_extracted = 0
        
    def page_crawled(self, url, success=True):
        self.pages_crawled += 1
        if not success:
            self.errors += 1
        
        # Log progress every 100 pages
        if self.pages_crawled % 100 == 0:
            elapsed = time.time() - self.start_time
            print(f"Crawled {self.pages_crawled} pages in {elapsed:.2f}s")
            print(f"Error rate: {self.errors/self.pages_crawled:.2%}")
            
    def item_extracted(self, count=1):
        self.items_extracted += count
        
    def get_summary(self):
        elapsed = time.time() - self.start_time
        return {
            "pages_crawled": self.pages_crawled,
            "errors": self.errors,
            "error_rate": self.errors/max(1, self.pages_crawled),
            "items_extracted": self.items_extracted,
            "items_per_page": self.items_extracted/max(1, self.pages_crawled),
            "elapsed_seconds": elapsed,
            "pages_per_second": self.pages_crawled/max(1, elapsed)
        }
```

### Alerting and Notifications

Set up notifications for critical issues:

1. **Threshold-based alerts**:
   - Error rate exceeds 10%
   - Zero items extracted from multiple pages
   - Crawl duration exceeds historical average by 50%

2. **Pattern-based detection**:
   - Sudden drop in extracted items
   - Unusual number of HTTP status codes (403, 429)
   - Consistent failure on specific domains

### Maintenance Best Practices

1. **Regular Test Crawls**: Run limited test crawls to verify functionality
2. **Selector Maintenance**: Review and update selectors when site structures change
3. **Version Control**: Track all changes to scraping logic
4. **Documentation**: Maintain clear documentation of site structures and selection patterns
5. **Site Change Monitoring**: Use visual diffing or DOM comparison tools to detect site changes

---

[<- Back to Scrapy](./07-scrapy.md) | [Back to Main](./README.md)