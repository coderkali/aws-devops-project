# Phase 13: Multi-Environment Setup

## Overview

This directory contains environment-specific Terraform variable files for deploying the DevOps project across three environments: **dev**, **staging**, and **prod**.

## Environments

### Development (`dev.tfvars`)
- **Purpose**: Active development, testing, experimentation
- **Cluster**: 1-5 nodes (t3.large)
- **Databases**: Smallest instance types (db.t3.micro)
- **Backups**: 7 days retention
- **Multi-AZ**: Disabled (cost optimization)
- **Budget**: $100/month
- **Data**: Can be destroyed/recreated

### Staging (`staging.tfvars`)
- **Purpose**: Pre-production testing, integration testing
- **Cluster**: 2-10 nodes (t3.xlarge)
- **Databases**: Small instance types (db.t3.small)
- **Backups**: 14 days retention
- **Multi-AZ**: Enabled
- **Budget**: $300/month
- **Data**: Should match production patterns
- **Use case**: Final testing before production deploy

### Production (`prod.tfvars`)
- **Purpose**: Customer-facing, revenue-generating
- **Cluster**: 3-20 nodes (t3.2xlarge)
- **Databases**: Medium instance types (db.t3.medium)
- **Backups**: 30 days retention
- **Multi-AZ**: Enabled (required)
- **Budget**: $1000/month
- **Data**: Real customer data, immutable
- **Use case**: Live traffic, SLA compliance

## How to Use

### Deploy Development Environment

```bash