#!/bin/sh
dub build :stparse -b=release --compiler=ldc
dub build :stdelab -b=release --compiler=ldc
dub build :stfilter -b=release --compiler=ldc
dub build :sthtml -b=release --compiler=ldc
dub build :stcomb -b=release --compiler=ldc
