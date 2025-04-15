# 5. Cheerio 🔍

[<- Back to Web Scraping & Web Crawling](./04-web-scraping-web-crawling.md) | [Next: Beautiful Soup 4 ->](./06-beautiful-soup4.md)

## Table of Contents
- [What is Cheerio?](#what-is-cheerio)
- [Setup and Installation](#setup-and-installation)
- [Basic Usage](#basic-usage)
- [Selectors and Navigation](#selectors-and-navigation)
- [Data Extraction Techniques](#data-extraction-techniques)
- [Practical Example: E-commerce Scraping](#practical-example-e-commerce-scraping)
- [Common Challenges and Solutions](#common-challenges-and-solutions)

## What is Cheerio?

Cheerio is a fast, flexible, and lean implementation of jQuery designed specifically for the server. It provides a familiar API for parsing and manipulating HTML in Node.js applications.

### Key Features

- **Fast and lightweight**: Cheerio doesn't include a DOM or browser environment
- **jQuery-compatible API**: Familiar for web developers who know jQuery
- **Memory-efficient**: Optimized for parsing and manipulating large HTML documents
- **No JavaScript execution**: Cannot handle dynamically rendered content

Cheerio is ideal when you need to extract data from static HTML documents without the overhead of a full browser environment.

## Setup and Installation

Setting up a Node.js project with Cheerio is straightforward:

```bash
# Initialize a new Node.js project
npm init -y

# Install Cheerio
npm install cheerio

# For HTTP requests, you might also want:
npm install node-fetch
```

Update your `package.json` to use ES modules:

```json
{
  "type": "module",
  // ... other configuration
}
```

## Basic Usage

The core workflow with Cheerio involves:
1. Loading HTML content
2. Selecting elements
3. Extracting or manipulating data

### Loading HTML

```javascript
import { load } from 'cheerio';
import fs from 'fs';

// From a string
const html = '<h2 class="title">Hello world</h2>';
const $ = load(html);

// From a file
const htmlFile = fs.readFileSync('page.html').toString();
const $ = load(htmlFile);

// From a remote source (using fetch)
import fetch from 'node-fetch';

async function scrapeWebsite() {
  const response = await fetch('https://example.com');
  const html = await response.text();
  const $ = load(html);
  
  // Now use $ for selections
}
```

### Basic Selections

```javascript
// Select by tag
const headings = $('h1');

// Select by class
const titles = $('.title');

// Select by ID
const header = $('#header');

// Combined selectors
const articleHeadings = $('article h2.title');
```

## Selectors and Navigation

Cheerio supports most CSS selectors and jQuery traversal methods.

### CSS Selectors

```javascript
// Descendant selector
$('div p');

// Child selector
$('ul > li');

// Attribute selector
$('a[href^="https://"]');

// Pseudo-selectors
$('li:first-child');
$('p:contains("keyword")');
```

### Element Traversal

```javascript
// Find descendants
const links = $('nav').find('a');

// Navigate to siblings
const nextItem = $('li.current').next();
const prevItem = $('li.current').prev();

// Navigate to parents
const parent = $('span').parent();
const ancestors = $('span').parents();

// Filter elements
const activeLinks = $('a').filter('.active');
```

## Data Extraction