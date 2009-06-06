#!/bin/sh

verbose=false

if [ "x$1" = "x-v" ]
then
	verbose=true
	out=/dev/stdout
	err=/dev/stderr
else
	out=/dev/null
	err=/dev/null
fi

pts=5
timeout=30
preservefs=n

echo_n () {
	# suns can't echo -n, and Mac OS X can't echo "x\c"
	# assume argument has no doublequotes
	awk 'BEGIN { printf("'"$*"'"); }' </dev/null
}

runbochs () {
	# Find the address of the kernel readline function,
	# which the kernel monitor uses to read commands interactively.
	brkaddr=`grep 'readline$' obj/kern/kernel.sym | sed -e's/ .*$//g'`
	#echo "brkaddr $brkaddr"

	# Run Bochs, setting a breakpoint at readline(),
	# and feeding in appropriate commands to run, then quit.
	(
		echo vbreak 0x8:0x$brkaddr
		echo c
		echo die
		echo quit
	) | (
		ulimit -t $timeout
		bochs -q 'display_library: nogui' \
			'parport1: enabled=1, file="bochs.out"'
	) >$out 2>$err
}



make
runbochs

score=0

# echo -n "Printf: "
	awk 'BEGIN{printf("Printf: ");}' </dev/null
	if grep "240 decimal is 360 octal!" bochs.out >/dev/null
	then
		score=`expr 10+$score | bc`
		echo OK
	else
		echo WRONG
	fi

# echo -n "Printf: "
	awk 'BEGIN{printf("Backtrace: ");}' </dev/null
	cnt=`grep "ebp f0109...  eip f0100...  args" bochs.out|wc -w`
	if [ $cnt -eq 80 ]
	then
		score=`expr 20+$score | bc`
		echo OK
	else
		echo WRONG
	fi

echo_n "Page directory: "
 if grep "check_boot_pgdir() succeeded!" bochs.out >/dev/null
 then
	score=`expr 20 + $score`
	echo OK
 else
	echo WRONG
 fi

echo_n "Page management: "
 if grep "page_check() succeeded!" bochs.out >/dev/null
 then
	score=`expr 30 + $score`
	echo OK
 else
	echo WRONG
 fi

echo "Score: $score/80"

if [ $score -lt 80 ]; then
    exit 1
fi


