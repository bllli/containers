#!/bin/sh
# fake sendmail command to print mail body from cronie

awk 'NR==2 {printf("\n%s\n",$0)}' RS=