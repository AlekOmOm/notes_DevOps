# 6. Beautiful Soup 4 🍲

[<- Back to Cheerio](./05-cheerio.md) | [Next: Scrapy ->](./07-scrapy.md)

## Table of Contents
- [What is Beautiful Soup?](#what-is-beautiful-soup)
- [Setup and Installation](#setup-and-installation)
- [Parsing HTML](#parsing-html)
- [Navigating the DOM](#navigating-the-dom)
- [Searching the DOM](#searching-the-dom)
- [Data Extraction](#data-extraction)
- [Practical Example: Wikipedia Scraping](#practical-example-wikipedia-scraping)
- [Web Crawling with Beautiful Soup](#web-crawling-with-beautiful-soup)

## What is Beautiful Soup?

Beautiful Soup is a Python library designed for web scraping purposes, providing a convenient API for extracting data from HTML and XML files. It sits on top of an HTML or XML parser (like lxml, html.parser, or html5lib) and creates a parse tree for parsed pages.

### Key Features

- **Pythonic Idioms**: Intuitive navigation of parse trees
- **Forgiving Parser**: Handles malformed markup effectively
- **Search Methods**: Multiple methods for locating elements
- **Document Transformation**: Capabilities for editing and reconstructing documents

Beautiful Soup is widely used due to its ease of use and robustness when dealing with real-world web pages.

## Setup and Installation

Setting up Beautiful Soup is straightforward with pip or poetry:

### Using virtualenv

```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install required packages
pip install beautifulsoup4 requests lxml
```

### Using Poetry

```bash
# Initialize Poetry project
poetry init -n

# Add dependencies
poetry add beautifulsoup4 requests lxml

# Enter Poetry shell
poetry shell
```

## Parsing HTML

Beautiful Soup supports multiple parsers, with lxml being the recommended one for speed and flexibility:

```python
import requests
from bs4 import BeautifulSoup

# Fetch HTML content
url = "https://en.wikipedia.org/wiki/List_of_Monty_Python_projects"
response = requests.get(url)
html = response.text

# Parse HTML with lxml parser
soup = BeautifulSoup(html, 'lxml')

# Alternative parsers
# soup = BeautifulSoup(html, 'html.parser')  # Python's built-in parser
# soup = BeautifulSoup(html, 'html5lib')     # Lenient HTML5 parser
```

### Parser Comparison

| Parser | Speed | Lenient | Dependencies |
|--------|-------|---------|--------------|
| lxml | Fastest | Yes | External C library |
| html.parser | Medium | Less | Built-in |
| html5lib | Slowest | Most | Pure Python |

lxml is generally recommended unless you have specific needs for lenient parsing (html5lib) or need to avoid external dependencies (html.parser).

## Navigating the DOM

Beautiful Soup provides intuitive ways to navigate the document structure:

### Accessing Elements and Attributes

```python
# Navigate to elements
title = soup.title
first_paragraph = soup.p

# Access text content
title_text = soup.title.string

# Access attributes
link = soup.a
href_value = link.get('href')  # or link['href']

# Navigating down
body = soup.body
first_div = body.div

# Navigating up
parent = soup.a.parent
parents = list(soup.a.parents)

# Navigating sideways
next_sibling = soup.a.next_sibling
previous_sibling = soup.a.previous_sibling

# Content extraction
full_text = soup.get_text()
```

## Searching the DOM

Beautiful Soup offers powerful search capabilities:

### Finding Elements

```python
# Find the first matching element
first_heading = soup.find('h1')
first_link = soup.find('a')

# Find all matching elements
all_headings = soup.find_all('h1')
all_links = soup.find_all('a')

# Find with class (note the underscore to avoid collision with Python's class keyword)
articles = soup.find_all('div', class_='article')

# Find with attributes
images = soup.find_all('img', {'alt': True})
https_links = soup.find_all('a', href=lambda href: href and href.startswith('https://'))

# Find with CSS selectors (requires lxml or html5lib parser)
css_selected = soup.select('div.content > p.intro')
```

### Advanced Filtering

```python
# Find by text content
python_mentions = soup.find_all(text=lambda text: 'python' in text.lower())

# Find by multiple tags
headings = soup.find_all(['h1', 'h2', 'h3'])

# Limit number of results
first_three_links = soup.find_all('a', limit=3)

# Recursive search control
direct_children_only = soup.find_all('p', recursive=False)
```

## Data Extraction

Once you've found elements, extracting data is straightforward:

### Text and Attributes

```python
# Get text from element
heading_text = soup.h1.get_text()

# Strip whitespace
clean_text = soup.p.get_text(strip=True)

# Join text with separator
joined_text = soup.p.get_text(separator=' | ')

# Get attribute
image_url = soup.img['src']
```

### Extracting Structured Data

```python
# Extract table data
table = soup.find('table')
rows = []
for tr in table.find_all('tr'):
    row_data = []
    for td in tr.find_all(['td', 'th']):
        row_data.append(td.get_text(strip=True))
    if row_data:  # Skip empty rows
        rows.append(row_data)

# Extract list data
ul = soup.find('ul')
items = [li.get_text(strip=True) for li in ul.find_all('li')]
```

## Practical Example: Wikipedia Scraping

This example extracts projects from the "List of Monty Python projects" Wikipedia page:

```python
import requests
from bs4 import BeautifulSoup
from pprint import pprint

# Fetch Wikipedia page
url = "https://en.wikipedia.org/wiki/List_of_Monty_Python_projects"
response = requests.get(url)
html = response.text

# Parse HTML
soup = BeautifulSoup(html, 'lxml')

# Get the main content
content_div = soup.find("div", {"class": "mw-parser-output"})

# Dictionary to store projects by category
projects = {}
current_category = None

# Process all elements in the content div
for element in content_div.children:
    # Check if element is a heading
    if element.name == "h2" or element.name == "h3":
        current_category = element.get_text().replace("[edit]", "").strip()
        projects[current_category] = []
    
    # Check if element is a list under the current category
    elif element.name == "ul" and current_category:
        for li in element.find_all("li", recursive=False):
            projects[current_category].append(li.get_text().strip())

# Clean up categories we don't want
categories_to_remove = ["References", "Notes", "Further reading", "External links"]
for category in categories_to_remove:
    if category in projects:
        del projects[category]

# Print results
pprint(projects)
```

## Web Crawling with Beautiful Soup

Beautiful Soup can be combined with requests to create a simple web crawler:

```python
import requests
from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin

class WikiCrawler:
    def __init__(self, start_url, max_pages=100):
        self.start_url = start_url
        self.base_url = "https://en.wikipedia.org"
        self.visited_urls = set()
        self.urls_to_visit = [start_url]
        self.max_pages = max_pages
    
    def get_page_content(self, url):
        try:
            full_url = urljoin(self.base_url, url)
            response = requests.get(full_url)
            return BeautifulSoup(response.text, 'lxml')
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None
    
    def get_internal_links(self, soup):
        # Find all internal wiki links (content links only)
        if not soup or not soup.find('div', {'id': 'bodyContent'}):
            return []
            
        content_div = soup.find('div', {'id': 'bodyContent'})
        internal_links = []
        
        # Get links matching wiki pattern that don't contain colons
        link_pattern = re.compile('^(/wiki/)((?!:).)*$')
        for a_tag in content_div.find_all('a', href=link_pattern):
            if 'href' in a_tag.attrs:
                internal_links.append(a_tag.attrs['href'])
                
        return internal_links
    
    def crawl(self):
        count = 0
        
        while self.urls_to_visit and count < self.max_pages:
            # Get URL to process
            current_url = self.urls_to_visit.pop(0)
            
            # Skip if already visited
            if current_url in self.visited_urls:
                continue
                
            print(f"Crawling: {current_url}")
            
            # Mark as visited
            self.visited_urls.add(current_url)
            count += 1
            
            # Get links from page
            soup = self.get_page_content(current_url)
            new_links = self.get_internal_links(soup)
            
            # Add new links to visit
            for link in new_links:
                if link not in self.visited_urls and link not in self.urls_to_visit:
                    self.urls_to_visit.append(link)
                    
        print(f"Crawling complete. Visited {len(self.visited_urls)} pages.")
        return self.visited_urls

# Usage
crawler = WikiCrawler("/wiki/Monty_Python", max_pages=20)
visited_pages = crawler.crawl()
```

This simple crawler follows internal Wikipedia links starting from the Monty Python page, respecting a maximum page limit to avoid endless crawling.

---

[<- Back to Cheerio](./05-cheerio.md) | [Next: Scrapy ->](./07-scrapy.md)