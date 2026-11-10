#!/bin/sh
# Accept exactly one greeting line, with or without its final newline.
test "$(cat greeting.txt)" = 'hello world' && test "$(wc -l <greeting.txt | tr -d ' ')" -le 1
