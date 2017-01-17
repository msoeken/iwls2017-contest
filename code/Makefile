%.c : %.w
	ctangle $<

%.o : %.c
	gcc -c $<

yig2verilog : yig2verilog.o
	gcc -g -o $@ $^

%.tex : %.w
	cweave $<

%.pdf : %.tex
	pdftex $<

doc : yig2verilog.pdf

all : doc yig2verilog
