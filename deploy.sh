#!/bin/bash
rm -rf docs/ public/
hugo
echo "blog.chann.kr" > docs/CNAME

