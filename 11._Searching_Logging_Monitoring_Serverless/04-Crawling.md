# 04. Web Crawling 🕸️

[<- Back to Searching](./03-Searching.md) | [Next: Serverless Functions ->](./05-Serverless-Functions.md)

## Table of Contents

- [Introduction](#introduction)
- [Web Crawling vs. Web Scraping](#web-crawling-vs-web-scraping)
- [The Crawling Process](#the-crawling-process)
- [Crawling Considerations](#crawling-considerations)
- [Where to Run Crawlers](#where-to-run-crawlers)
- [Implementation Examples](#implementation-examples)
- [Handling JavaScript-Rendered Content](#handling-javascript-rendered-content)
- [Best Practices](#best-practices)

## Introduction

Web crawling is the systematic process of browsing web pages to collect data, usually for indexing and search purposes. A web crawler (also known as a spider or bot) visits web pages, extracts their content, follows links to other pages, and organizes the collected data for further use.

Crawling is an essential technique for building search indices, monitoring websites for changes, gathering data for analysis, and many other applications.

## Web Crawling vs. Web Scraping

These terms are often used interchangeably, but they have different focuses:

- **Web Crawling**: Focuses on navigating through multiple pages, following links, and discovering content
- **Web Scraping**: Focuses on extracting specific data from web pages, often in a structured format

Most implementations involve both aspects: crawling to navigate between pages and scraping to extract data from each page.

## The Crawling Process

The standard web crawling process involves these steps:

1. **Start with seed URLs**: Begin with a list of initial URLs to crawl
2. **Request the page**: Fetch the HTML content from each URL
3. **Parse the content**: Extract data of interest from the HTML
4. **Process data**: Store or index the extracted data
5. **Discover links**: Find URLs to other pages within the HTML
6. **Filter links**: Determine which discovered URLs to crawl next
7. **Queue new URLs**: Add filtered URLs to the crawling queue
8. **Repeat**: Continue the process until completion criteria are met

## Crawling Considerations

When implementing a web crawler, consider these important factors:

### Politeness and Ethics

- **Respect robots.txt**: Follow the rules specified in a site's robots.txt file
- **Rate limiting**: Introduce delays between requests to avoid overloading servers
- **Identify your crawler**: Use a descriptive User-Agent header that includes contact information
- **Terms of service**: Ensure your crawling complies with the website's terms

### Technical Considerations

- **Duplicate detection**: Avoid crawling the same URL multiple times
- **URL normalization**: Handle different URL formats that point to the same content
- **Depth control**: Limit how far the crawler follows links from seed URLs
- **Breadth vs. depth**: Choose between breadth-first or depth-first crawling strategies
- **Error handling**: Properly handle network issues, timeouts, and malformed HTML
- **Resource management**: Control memory usage for large crawls

## Where to Run Crawlers

Deciding where to run your crawler involves considering resources, cost, and frequency:

### On Application Servers

**Not recommended** due to:
- Competing for resources with production applications
- Cost inefficiency if provisioning dedicated servers

### Locally

Create a script that can be run manually:
- Crawl from your development machine
- Upload data to production via an authenticated API
- Good for infrequent, ad-hoc crawling needs

### GitHub Actions (Scheduled)

```yaml
name: Run Web Crawler Daily

on:
  schedule:
    - cron: '0 0 * * *'  # Runs at midnight UTC every day

jobs:
  crawl:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run crawler
        run: node crawler.js
        
      - name: Upload data to API
        run: node upload.js
```

**Limitations**:
- Jobs may be dropped during high load times
- In public repositories, scheduled workflows are disabled after 60 days of inactivity

### Serverless Functions

**Optimal solution** for modern applications:
- Pay only for execution time
- Simplified environment management
- Can be scheduled to run at regular intervals
- Scalable for larger crawling operations
- See [Serverless Functions](./05-Serverless-Functions.md) for more details

## Implementation Examples

### Simple Sequential Crawler

A basic crawler that processes URLs one at a time:

```javascript
import { JSDOM } from 'jsdom';
import { URL } from 'url';

// Track visited URLs to avoid duplicates
const visitedUrls = new Set();

// Polite delay between requests
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function crawlPage(pageUrl) {
    // Normalize URL and check if already visited
    const cleanUrl = new URL(pageUrl);
    cleanUrl.hash = ''; // Remove fragment identifier

    if (visitedUrls.has(cleanUrl.href)) {
        return;
    }

    visitedUrls.add(cleanUrl.href);

    try {
        // Fetch the page
        const response = await fetch(cleanUrl.href);
        if (!response.ok) {
            console.error(`Failed to fetch ${cleanUrl.href}: ${response.statusText}`);
            return;
        }

        const html = await response.text();
        const { window } = new JSDOM(html);
        const document = window.document;

        // Extract the main content
        const mainContent = Array.from(document.querySelectorAll('.mw-parser-output p, .mw-parser-output h1, .mw-parser-output h2, .mw-parser-output h3'))
            .map(element => element.textContent.trim())
            .join(' ')
            .replace(/[\t\n\r]+/g, ' ')
            .trim();

        console.log('Indexing:', cleanUrl.href);
        // Store the URL and content in a database or index

        // Extract links and follow them
        const links = Array.from(document.querySelectorAll('a')).map(link => link.getAttribute('href'));
        for (let href of links) {
            if (href && href.startsWith('/wiki/') && !href.includes(':')) {
                const resolvedUrl = new URL(href, cleanUrl.origin).href;
                const normalizedUrl = resolvedUrl.split('#')[0];
                
                if (!visitedUrls.has(normalizedUrl)) {
                    await delay(1000); // Be polite - wait 1 second between requests
                    await crawlPage(normalizedUrl);
                }
            }
        }
    } catch (error) {
        console.error(`Error crawling ${cleanUrl.href}:`, error);
    }
}

// Start crawling from a seed URL
crawlPage('https://en.wikipedia.org/wiki/Web_crawler');
```

### Queue-Based Crawler

A more sophisticated approach using a priority queue for better control:

```javascript
import { JSDOM } from 'jsdom';
import { URL } from 'url';

class Crawler {
    constructor(options = {}) {
        this.delay = options.delay || 1000;
        this.maxDepth = options.maxDepth || 3;
        this.maxPages = options.maxPages || 100;
        this.allowedDomains = options.allowedDomains || [];
        
        this.visitedUrls = new Set();
        this.queue = [];
        this.pageCount = 0;
    }
    
    isAllowedDomain(url) {
        if (this.allowedDomains.length === 0) return true;
        
        const hostname = new URL(url).hostname;
        return this.allowedDomains.some(domain => hostname === domain || hostname.endsWith('.' + domain));
    }
    
    async crawl(seedUrl) {
        // Add the seed URL to the queue
        this.queue.push({ url: seedUrl, depth: 0 });
        
        while (this.queue.length > 0 && this.pageCount < this.maxPages) {
            // Sort queue by depth (breadth-first approach)
            this.queue.sort((a, b) => a.depth - b.depth);
            
            const { url, depth } = this.queue.shift();
            
            // Skip if already visited or max depth reached
            if (this.visitedUrls.has(url) || depth > this.maxDepth) {
                continue;
            }
            
            // Mark as visited
            this.visitedUrls.add(url);
            this.pageCount++;
            
            try {
                console.log(`Crawling (${this.pageCount}/${this.maxPages}): ${url}`);
                
                // Fetch the page
                const response = await fetch(url);
                if (!response.ok) {
                    console.error(`Failed to fetch ${url}: ${response.statusText}`);
                    continue;
                }
                
                const html = await response.text();
                const { window } = new JSDOM(html);
                const document = window.document;
                
                // Extract content
                const title = document.querySelector('title')?.textContent || '';
                const content = Array.from(document.querySelectorAll('p'))
                    .map(p => p.textContent.trim())
                    .join(' ');
                
                // Process the content (e.g., store in database)
                this.processContent(url, title, content);
                
                // Extract and queue links if not at max depth
                if (depth < this.maxDepth) {
                    this.queueLinks(document, url, depth);
                }
                
                // Be polite - wait before next request
                await this.sleep(this.delay);
            } catch (error) {
                console.error(`Error crawling ${url}:`, error);
            }
        }
        
        console.log(`Crawling completed. Visited ${this.pageCount} pages.`);
    }
    
    processContent(url, title, content) {
        // Store or index the content
        console.log(`Indexed: ${url} - ${title}`);
        // In a real implementation, you would store this in a database or search index
    }
    
    queueLinks(document, baseUrl, currentDepth) {
        const links = Array.from(document.querySelectorAll('a'))
            .map(link => link.getAttribute('href'))
            .filter(Boolean);
        
        for (const href of links) {
            try {
                // Resolve relative URLs
                const resolvedUrl = new URL(href, baseUrl).href;
                
                // Normalize URL (remove fragments, etc.)
                const normalizedUrl = resolvedUrl.split('#')[0];
                
                // Check if URL should be crawled
                if (!this.visitedUrls.has(normalizedUrl) && 
                    this.isAllowedDomain(normalizedUrl)) {
                    
                    // Add to queue with incremented depth
                    this.queue.push({
                        url: normalizedUrl,
                        depth: currentDepth + 1
                    });
                }
            } catch (error) {
                // Skip invalid URLs
                console.error(`Invalid URL: ${href}`, error);
            }
        }
    }
    
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Usage example
const crawler = new Crawler({
    delay: 2000,         // 2 seconds between requests
    maxDepth: 2,         // Only follow links 2 levels deep
    maxPages: 20,        // Crawl at most 20 pages
    allowedDomains: ['example.com', 'wikipedia.org']
});

crawler.crawl('https://en.wikipedia.org/wiki/Web_crawler');
```

## Handling JavaScript-Rendered Content

Many modern websites load content dynamically using JavaScript, which simple HTML parsers can't handle.

### Using Puppeteer

```javascript
import puppeteer from 'puppeteer';

async function crawlJSPage(url) {
    // Launch a headless browser
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    
    try {
        // Navigate to page and wait for content to load
        await page.goto(url, { waitUntil: 'networkidle2' });
        
        // Wait for specific elements to be present
        await page.waitForSelector('.content', { timeout: 5000 });
        
        // Extract content after JavaScript execution
        const content = await page.evaluate(() => {
            const title = document.querySelector('h1')?.textContent || '';
            const paragraphs = Array.from(document.querySelectorAll('.content p'))
                .map(p => p.textContent.trim())
                .join(' ');
            
            return { title, content: paragraphs };
        });
        
        console.log(`Crawled JS-rendered page: ${url}`);
        console.log(`Title: ${content.title}`);
        
        // Extract all links
        const links = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('a'))
                .map(a => a.href);
        });
        
        console.log(`Found ${links.length} links`);
        
        // Process content and links as needed
        return { content, links };
    } catch (error) {
        console.error(`Error crawling ${url}:`, error);
    } finally {
        // Always close the browser
        await browser.close();
    }
}

// Usage
crawlJSPage('https://example.com/javascript-heavy-page');
```

## Best Practices

1. **Respect the sites you crawl**:
   - Follow robots.txt rules
   - Implement polite delays between requests
   - Identify your crawler with an appropriate User-Agent
   - Consider contacting site owners for high-volume crawling

2. **Optimize performance**:
   - Use asynchronous code for better throughput
   - Implement intelligent prioritization of URLs
   - Consider parallel crawling with rate limiting
   - Cache DNS lookups for performance

3. **Handle errors gracefully**:
   - Implement exponential backoff for failed requests
   - Log and monitor error rates
   - Have strategies for handling different HTTP status codes

4. **Ensure data quality**:
   - Normalize and clean extracted data
   - Implement validation for extracted content
   - Track data provenance (source URL, timestamp, etc.)

5. **Maintain the crawler**:
   - Monitor for changes in site structure
   - Update selectors when sites are redesigned
   - Regularly review and update crawling rules

For more detailed implementation specifics, see:
- [04a. Advanced Crawling Techniques](./04a-Advanced-Crawling-Techniques.md)
- [04b. Crawling with Scrapy](./04b-Crawling-with-Scrapy.md)

---

[<- Back to Searching](./03-Searching.md) | [Next: Serverless Functions ->](./05-Serverless-Functions.md)