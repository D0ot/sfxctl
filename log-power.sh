#!/bin/env sh

while [ true ]; do
	sleep 0.5
	/home/doot/programs/swiftx-fn/getwatt.sh | tee $1
done

