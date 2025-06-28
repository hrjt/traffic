# Advanced Log Analysis Script for Domain Visitor Insights

## Overview

In today’s digital landscape, understanding web traffic patterns is crucial for maintaining optimal website performance, enhancing security, and driving marketing strategies. Managing logs from multiple domains, especially when dealing with high traffic volumes, can be cumbersome and error-prone without the right tools.

Our **Advanced Log Analysis Script** is a powerful, easy-to-use shell script designed to extract and summarize detailed visitor information across all hosted domains. It identifies frequent visitors by IP, provides daily visit counts, and offers flexible sorting and filtering options — helping webmasters, security analysts, and DevOps teams gain actionable insights with minimal effort.

---

## Key Problems Addressed

### 1. Complex Multi-Domain Log Analysis

When hosting numerous websites on a single server, logs are scattered across domain-specific directories and multiple log files (`access_log.processed`, `proxy_access_log`). Aggregating data manually or via generic tools is tedious and inefficient.

**Our script automates this entire process**, iterating through all domains’ logs transparently — or focusing on a specified domain — saving hours of manual work.

### 2. Lack of Day-Wise Visitor Breakdown

Most conventional scripts or tools provide aggregate statistics over a broad time range, lacking granularity.

This script **breaks down visitor IP activity on a day-by-day basis**, allowing precise trend analysis, anomaly detection, and better capacity planning.

### 3. Handling Large Date Ranges and Filtering

Analyzing very large log files without time constraints can be resource-intensive.

Our solution offers an **optional day range parameter**, enabling users to limit analysis to recent periods (e.g., last 7 or 15 days). This improves performance and relevance of insights.

### 4. Difficulty Sorting and Prioritizing Results

Sorting by hits, date, or IP address is a common requirement, yet many scripts don’t support flexible sorting modes.

We’ve integrated a **simple yet powerful sorting option** with parameters:

- `--sort=date` (default): Sort by date ascending
- `--sort=ip`: Sort by IP address ascending
- `--sort=hits`: Sort by visit count descending

This lets users tailor outputs to their needs instantly.

### 5. Reliable Date Parsing & Sorting

Parsing dates from log files in the format `01/Jan/2025` and sorting them correctly is tricky due to textual months and mixed formats.

Our script uses a robust internal date parsing and sorting mechanism that **converts textual dates into sortable keys**, ensuring accurate chronological ordering without relying on external commands inside the processing loop.

---

## Features & Benefits

- **Multi-domain support:** Processes logs for all domains or a specific domain based on parameters.
- **Date range filtering:** Analyze traffic for any specified number of past days.
- **Daily granularity:** Outputs visits per day, per domain, per IP.
- **High hit threshold filtering:** Only shows IPs exceeding a configurable minimum hit count.
- **Flexible sorting:** Sort results by date, IP, or number of hits with simple command-line flags.
- **Efficient and portable:** Uses standard Bash and AWK utilities with no heavy dependencies.
- **Clean output:** Tab-delimited columns for easy reading or further processing.

---

## How to Set up

A. This script looks for all domain at path: /var/www/vhosts
You may need to change it to match your server setup. Open the script and change the line: 

```bsh
LOG_BASE="/var/www/vhosts"
```

B. This report targets frequent visitors. To keep the report this way, it has a HIT_THRESHOLD set to minimun 10 visits. It means, it will check for visitors having atleast 10 visits in given periond of time. 
you can change it to desired value. Edit the script and change value:

```bash
HIT_THRESHOLD=100
```
---

## Example Usage

Analyze the last 7 days of all domains, sorted by date (default):

```bash
./traffic.sh 7
```

Analyze all time for a specific domain example.com, sorted by IP. This example will check last 30 days log for mydomain.org and sort by number oh hits:

```bash
./traffic.sh 30 mydomain.org --sort=hits
```

Sorting options:

- --sort=hits
- --sort=ip
- --sort=date  #default sorting

---

## Upcoming features

- CSV export
- Mail alerts
- HTML5 interface
  
---
