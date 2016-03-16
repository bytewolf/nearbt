# CC=clang

all: pam_nearbt.so

pam_nearbt.so: pam_nearbt.m 
	${CC} -bundle -flat_namespace -undefined suppress -o $@ $?

install: pam_nearbt.so
	chmod 444 $?
	cp -i $? /usr/lib/pam/

clean:
	rm -rf pam_nearbt.so

