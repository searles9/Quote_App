#!/usr/bin/env bash

aws dynamodb batch-write-item --request-items file://DATABASE/items.json --region "us-east-1"