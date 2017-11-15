+++
type = "post"
title = "{{ replace .TranslationBaseName "-" " " | title }}"
description = ""
date = "{{ dateFormat "2006-01-02" .Date }}"
categories = [
    "",
]
tags = [
    "",
]
slug = "{{ replace .TranslationBaseName " " "-" | title }}"
aliases = [
    "",
]
draft = true
+++
