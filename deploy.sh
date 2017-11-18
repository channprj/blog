#!/bin/bash
rm -rf docs/ public/
hugo
echo "blog.chann.kr" > docs/CNAME
git add -A
git cm "auto: new posts"
git push

