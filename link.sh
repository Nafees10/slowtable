#!/bin/sh
for f in stparse stfilter stdelab stcomb sthtml; do
	ln -s $PWD/bin/slowtable $HOME/.local/bin/$f;
done
