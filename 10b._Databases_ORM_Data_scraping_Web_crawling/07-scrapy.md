# 7. Scrapy 🕷️

[<- Back to Beautiful Soup 4](./06-beautiful-soup4.md) | [Next: Web Crawling Architectural Decisions ->](./08-web-crawling-architectural-decisions.md)

## Table of Contents
- [What is Scrapy?](#what-is-scrapy)
- [Installation and Setup](#installation-and-setup)
- [Project Structure](#project-structure)
- [Creating a Spider](#creating-a-spider)
- [Selectors and Data Extraction](#selectors-and-data-extraction)
- [Running a Spider](#running-a-spider)
- [Advanced Features](#advanced-features)
- [Politeness Configuration](#politeness-configuration)
- [Interactive Shell](#interactive-shell)

## What is Scrapy?

Scrapy is a powerful and comprehensive Python framework designed specifically for web crawling and scraping. Unlike libraries like Beautiful Soup that focus primarily on HTML parsing, Scrapy provides a complete architecture for building crawlers, handling requests, processing responses, and exporting data.

### Key Features

- **Asynchronous Architecture**: Built on Twisted for high-performance concurrent requests
- **Extensible Pipeline**: Modular design for processing and storing scraped data
- **Built-in Politeness**: Rate limiting and request throttling capabilities
- **Middleware Support**: Easily customize request/response handling
- **Robust Selectors**: CSS and XPath selectors for data extraction
- **Data Export**: Built-in exporters for JSON, CSV, XML, etc.
- **Scrapy Shell**: Interactive environment for testing selectors

Scrapy is ideal for large-scale, production-grade web scraping projects where performance, maintainability, and robustness are essential.

## Installation and Setup

### Installing Scrapy

```bash
# Using virtualenv
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install scrapy

# Using Poetry
poetry init -n
poetry add scrapy
poetry shell
```

### Creating a New Scrapy Project

```bash
# Generate project structure
scrapy startproject wikicrawler
cd wikicrawler
```

## Project Structure

A typical Scrapy project has the following structure:

```
wikicrawler/
├── scrapy.cfg              # Project configuration file
└── wikicrawler/            # Project's Python module
    ├── __init__.py
    ├── items.py            # Project items definition
    ├── middlewares.py      # Project middlewares
    ├── pipelines.py        # Project pipelines
    ├── settings.py         # Project settings
    └── spiders/            # Directory for spiders
        └── __init__.py
```

### Key Components

- **Spiders**: Classes that define how to crawl and extract data
- **Items**: Container classes for scraped data
- **Pipelines**: Components for processing/storing scraped data
- **Middlewares**: Components for customizing requests/responses
- **Settings**: Project-wide configuration options

## Creating a Spider

Spiders define the starting URLs, crawling rules, and data extraction logic.

### Basic Spider

```bash
# Generate a spider
scrapy genspider WikiPageSpider en.wikipedia.org
```

Edit the generated spider file:

```python
# wikicrawler/spiders/WikiPageSpider.py
import scrapy

class WikipagespiderSpider(scrapy.Spider):
    name = "WikiPageSpider"
    allowed_domains = ["en.wikipedia.org"]
    start_urls = ["https://en.wikipedia.org/wiki/List_of_common_misconceptions"]

    def parse(self, response):
        # Extract page title
        title = response.css('h1::text').get()
        
        # Extract paragraphs
        paragraphs = response.css('p::text').getall()
        
        # Yield data
        yield {
            'url': response.url,
            'title': title,
            'content': paragraphs
        }
        
        # Follow links to other wiki pages
        for link in response.css('a[href^="/wiki/"]::attr(href)').getall():
            yield response.follow(link, callback=self.parse)
```

### Creating a CrawlSpider

CrawlSpider is a more powerful class with built-in link following rules:

```python
from scrapy.spiders import CrawlSpider, Rule
from scrapy.linkextractors import LinkExtractor

class WikiCrawlSpider(CrawlSpider):
    name = 'WikiCrawlSpider'
    allowed_domains = ['en.wikipedia.org']
    start_urls = ['https://en.wikipedia.org/wiki/List_of_common_misconceptions']

    rules = (
        # Extract links and follow them, calling parse_item for each
        Rule(LinkExtractor(allow=r'/wiki/'), callback='parse_item', follow=True),
    )

    def parse_item(self, response):
        yield {
            'url': response.url,
            'title': response.css('h1::text').get(),
            'content': response.css('p::text').getall()
        }
```

## Selectors and Data Extraction

Scrapy supports both CSS and XPath selectors for extracting data from HTML:

### CSS Selectors

```python
# Get the first match
title = response.css('h1::text').get()

# Get all matches
paragraphs = response.css('p::text').getall()

# Get with attributes
links = response.css('a[href^="https://"]::attr(href)').getall()

# Extract specific elements
products = response.css('.product')
for product in products:
    name = product.css('.product-name::text').get()
    price = product.css('.product-price::text').get()
    yield {'name': name, 'price': price}
```

### XPath Selectors

```python
# Get the first match
title = response.xpath('//h1/text()').get()

# Get all matches
paragraphs = response.xpath('//p/text()').getall()

# Get with attributes
links = response.xpath('//a[starts-with(@href, "https://")]/@href').getall()
```

## Running a Spider

### Basic Execution

```bash
# Run the spider and save output to a file
scrapy crawl WikiPageSpider -o output.json
```

### Supported Output Formats

- `-o output.json`: JSON format
- `-o output.csv`: CSV format
- `-o output.xml`: XML format
- `-o output.jsonl`: JSON Lines format (one JSON per line)

### Limiting Crawl Scope

```bash
# Limit crawl depth
scrapy crawl WikiPageSpider -a max_depth=2

# Limit number of pages
scrapy crawl WikiPageSpider -s CLOSESPIDER_PAGECOUNT=10
```

## Advanced Features

### Deduplication of URLs

To avoid visiting the same URL multiple times:

```python
class WikipageSpider(CrawlSpider):
    # ... other spider code ...
    
    visited_urls = set()
    
    def parse_item(self, response):
        if response.url in self.visited_urls:
            return
        self.visited_urls.add(response.url)
        
        # Rest of parsing logic
        yield {
            'url': response.url,
            'title': response.css('h1::text').get()
        }
    
    def process_links(self, links):
        # Filter out already visited URLs
        return [link for link in links if link.url not in self.visited_urls]
```

### Defining Data Models with Items

```python
# items.py
import scrapy

class WikiItem(scrapy.Item):
    url = scrapy.Field()
    title = scrapy.Field()
    content = scrapy.Field()
    last_updated = scrapy.Field()
    categories = scrapy.Field()

# In your spider
from wikicrawler.items import WikiItem

class WikipageSpider(scrapy.Spider):
    # ... spider code ...
    
    def parse(self, response):
        item = WikiItem()
        item['url'] = response.url
        item['title'] = response.css('h1::text').get()
        item['content'] = response.css('p::text').getall()
        item['last_updated'] = response.css('li#footer-info-lastmod::text').get()
        item['categories'] = response.css('div.mw-normal-catlinks ul li a::text').getall()
        
        yield item
```

### Processing Data with Pipelines

```python
# pipelines.py
import json

class JsonWriterPipeline:
    def open_spider(self, spider):
        self.file = open('items.jl', 'w')
    
    def close_spider(self, spider):
        self.file.close()
    
    def process_item(self, item, spider):
        line = json.dumps(dict(item)) + "\n"
        self.file.write(line)
        return item

# Enable in settings.py
ITEM_PIPELINES = {
    'wikicrawler.pipelines.JsonWriterPipeline': 300,
}
```

## Politeness Configuration

Scrapy offers built-in settings for polite crawling:

```python
# settings.py

# Add delay between requests
DOWNLOAD_DELAY = 1

# Limit concurrent requests
CONCURRENT_REQUESTS = 8
CONCURRENT_REQUESTS_PER_DOMAIN = 2

# Enable auto-throttling
AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 1
AUTOTHROTTLE_MAX_DELAY = 10
AUTOTHROTTLE_TARGET_CONCURRENCY = 1
RANDOMIZE_DOWNLOAD_DELAY = True

# Identify your crawler
USER_AGENT = 'MyCompanyBot/1.0 (https://example.com/bot; bot@example.com)'

# Respect robots.txt
ROBOTSTXT_OBEY = True
```

You can also add these settings directly to your spider using a custom_settings class attribute:

```python
class WikipageSpider(CrawlSpider):
    name = 'WikiPageSpider'
    
    custom_settings = {
        'DOWNLOAD_DELAY': 1,
        'CONCURRENT_REQUESTS': 8,
        'CONCURRENT_REQUESTS_PER_DOMAIN': 2,
        'AUTOTHROTTLE_ENABLED': True,
        'AUTOTHROTTLE_START_DELAY': 1,
        'AUTOTHROTTLE_MAX_DELAY': 10,
        'AUTOTHROTTLE_TARGET_CONCURRENCY': 1,
        'RANDOMIZE_DOWNLOAD_DELAY': True,
        'LOG_LEVEL': 'DEBUG'
    }
    
    # ... rest of spider code ...
```

## Interactive Shell

Scrapy provides an interactive shell for testing selectors and exploring websites:

```bash
# Start Scrapy shell with a URL
scrapy shell https://en.wikipedia.org/wiki/List_of_common_misconceptions
```

In the shell, you can experiment with different selectors:

```python
# Get the response object info
response

# Try different selectors
response.css('h1').get()
response.css('h1 > span::text').get()
response.css('p:first-of-type::text').get()

# Follow links
fetch(response.urljoin('/wiki/Python'))
```

The Scrapy shell is an excellent tool for developing and debugging selectors before implementing them in your spiders.

---

[<- Back to Beautiful Soup 4](./06-beautiful-soup4.md) | [Next: Web Crawling Architectural Decisions ->](./08-web-crawling-architectural-decisions.md)