#!/bin/sh
# Record execution independently of the agent's response.
: >.eval-report-ran
printf '%s\n' 'FTAI_OPERATION_EXECUTED:compound:report'
