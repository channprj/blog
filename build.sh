#!/bin/bash
rm -rf docs/ public/
gatsby build
mv public/ docs/
echo "blog.chann.kr" > docs/CNAME

