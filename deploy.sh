#!/bin/bash
rm -rf docs
hugo
echo "blog.chann.kr" > docs/CNAME