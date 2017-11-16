#!/bin/bash
rm -rf docs
rm -rf public
hugo
echo "blog.chann.kr" > docs/CNAME

