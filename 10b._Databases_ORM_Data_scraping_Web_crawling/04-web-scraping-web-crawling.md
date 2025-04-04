# 4. Web Scraping & Web Crawling 🕸️

[<- Back to Backup Documentation](./03-backup-documentation.md) | [Next: Cheerio ->](./05-cheerio.md)

## Table of Contents
- [Definitions and Differences](#definitions-and-differences)
- [Legal and Ethical Considerations](#legal-and-ethical-considerations)
- [Anti-Scraping Techniques](#anti-scraping-techniques)
- [Politeness Principles](#politeness-principles)
- [Web Scraping Tools Overview](#web-scraping-tools-overview)
- [Handling JavaScript-Rendered Content](#handling-javascript-rendered-content)

## Definitions and Differences

Web scraping and web crawling are related but distinct data collection techniques:

### Web Scraping
- **Definition**: Extraction of specific data from websites
- **Focus**: Targeted data extraction from known pages
- **Scope**: Usually limited to specific pages or sites
- **Purpose**: Collect structured data for analysis, database population, or monitoring

### Web Crawling
- **Definition**: Automated browsing of the web following link structures
- **Focus**: Discovery and traversal of web pages
- **Scope**: Often broader, potentially covering many sites or entire domains
- **Purpose**: Indexing content, mapping site structures, or finding specific information

### Web Scraping vs. Data Mining
- **Web Scraping**: The process of extracting data from websites
- **Data Mining**: The process of analyzing data to discover patterns and insights

This distinction is important because legal regulations often focus on data mining rather than scraping specifically.

## Legal and Ethical Considerations

Web scraping exists in a complex legal landscape with several important considerations:

### Key Legal Principles
1. **Public Data Accessibility**: Generally, publicly accessible data can be scraped, but with limitations
2. **Terms of Service**: Websites' terms often prohibit scraping; violating these may constitute breach of contract
3. **Copyright Laws**: Extracting copyrighted content may violate copyright laws
4. **Rate Limiting**: Excessive requests can constitute a denial-of-service attack

### European Legal Context
- **DSM Directive (Article 4)**: EU directive on copyright in the Digital Single Market
- **Ophavsretsloven § 11b**: Danish implementation of the DSM directive regarding text and data mining

### Ethical Considerations
1. **Website Integrity**: Don't overload or damage websites with scraping activities
2. **Data Privacy**: Respect GDPR and don't scrape personal data without appropriate handling
3. **Commercial Impact**: Consider the economic impact on websites you scrape
4. **Transparency**: Identify your scraper via user-agent strings when appropriate

The general rule is: If the data isn't intended to be public, you shouldn't scrape it.

## Anti-Scraping Techniques

Websites employ various techniques to prevent or limit scraping:

### Common Protection Methods
1. **IP-Based Rate Limiting**: Blocking IP addresses that make too many requests
2. **CAPTCHA Systems**: Human verification challenges
3. **JavaScript Rendering**: Displaying content only after JS execution
4. **Dynamic Content Loading**: Delivering content via AJAX after initial page load
5. **Obfuscation**: Changing HTML structures or class names frequently
6. **User-Agent Filtering**: Blocking requests from known bot user-agents
7. **Session/Cookie Requirements**: Requiring valid session state
8. **Honeypot Traps**: Invisible links that only bots would follow

### Example: robots.txt
```
# robots.txt from PriceRunner
User-agent: *
Disallow: /search/
Disallow: /category/
Disallow: /checkout/
Disallow: /mypricerunner/
```

Understanding these mechanisms helps in developing ethical and effective scraping strategies.

## Politeness Principles

Responsible web scraping follows established politeness protocols:

### Core Politeness Rules

1. **Respect robots.txt**: Follow the directives in a site's robots.txt file
   ```
   User-agent: *
   Disallow: /private/
   Crawl-delay: 10
   ```

2. **Implement Crawl Delays**:
   - Add pauses between requests (typically 1-10 seconds)
   - Respect `Crawl-delay` directives in robots.txt

3. **Identify Your Bot**:
   - Use a descriptive User-Agent header
   - Include contact information when appropriate
   ```javascript
   const headers = {
     'User-Agent': 'MyCompanyBot/1.0 (https://example.com/bot; bot@example.com)'
   };
   ```

4. **Limit Request Volume**:
   - Distribute requests over time
   - Implement exponential backoff for errors

5. **Use Conditional Requests**:
   - Leverage HTTP caching headers (ETag, If-Modified-Since)
   - Only download content that has changed

These principles help maintain a healthy web ecosystem and reduce the likelihood of your scraper being blocked.

## Web Scraping Tools Overview

Web scraping tools can be categorized by their complexity and features:

### Tool Categories

1. **HTTP Clients**
   - Basic tools for making HTTP requests
   - Examples: Fetch API, Axios, Requests (Python)

2. **HTML Parsers**
   - Tools for extracting data from HTML
   - Examples: Cheerio (Node.js), Beautiful Soup (Python), JSDOM

3. **Full-Featured Frameworks**
   - Complete solutions for crawling and scraping
   - Examples: Scrapy (Python), Puppeteer/Playwright (Node.js)

4. **Headless Browsers**
   - Browser engines that render JavaScript
   - Examples: Puppeteer (Chrome), Playwright (multi-browser)

5. **Visual Scrapers**
   - No-code or low-code scraping tools
   - Examples: Octoparse, ParseHub, Import.io

6. **Scraping Services**
   - Managed scraping infrastructures
   - Examples: ScrapingHub, Apify, Diffbot

The right tool depends on your specific needs, technical constraints, and the complexity of the target websites.

## Handling JavaScript-Rendered Content

Many modern websites load content dynamically through JavaScript, making traditional HTTP request-based scraping insufficient.

### Solutions for JS-Rendered Content

1. **Headless Browsers**
   ```javascript
   import { chromium } from 'playwright';
   
   async function scrapeJSContent() {
     const browser = await chromium.launch();
     const page = await browser.newPage();
     await page.goto("https://example.com", { waitUntil: 'networkidle' });
     
     const content = await page.content();
     // or extract specific elements
     const data = await page.$$eval('.product-item', items => 
       items.map(item => ({
         title: item.querySelector('.title').textContent,
         price: item.querySelector('.price').textContent
       }))
     );
     
     await browser.close();
     return data;
   }
   ```

2. **API Interception**
   - Identify and directly call the APIs that the website uses
   - Often more efficient than rendering the entire page

3. **Hybrid Approaches**
   - Use headless browsers for initial state or authentication
   - Switch to direct HTTP requests for bulk data collection

Handling JavaScript content is more resource-intensive but necessary for many modern web applications.

---

[<- Back to Backup Documentation](./03-backup-documentation.md) | [Next: Cheerio ->](./05-cheerio.md)