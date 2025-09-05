MODDIR=$(QUAKEDIR)/swab-dev
PROGS=progs.dat
CSPROGS=csprogs.dat
FGD=driller.fgd
OUTPUT=$(MODDIR)/$(PROGS)
CSOUTPUT=$(MODDIR)/$(CSPROGS)
FGDOUTPUT=$(MODDIR)/$(FGD)

.PHONY: all chkdir install package clean

all: $(PROGS) $(CSPROGS) $(FGD)

chkdir: 
	if [ -z "$(QUAKEDIR)" ] ; then\
		echo ;\
		echo "QUAKEDIR must be set!" ;\
		echo ;\
		exit 1;\
	fi

install: chkdir all $(OUTPUT) $(CSOUTPUT) $(FGDOUTPUT)

clean:
	rm -f progs.dat
	rm -f csprogs.dat
	rm -f progs.lno
	rm -f driller.fgd

$(PROGS): *.qc progs.src
	fteqcc

$(CSPROGS): *.qc csprogs.src
	fteqcc csprogs.src

$(FGD): *.qc progs.src
	python qc2fgd.py driller

$(OUTPUT): $(PROGS) $(MODDIR)
	cp $(PROGS) "$(OUTPUT)"

$(CSOUTPUT): $(CSPROGS) $(MODDIR)
	cp $(CSPROGS) "$(CSOUTPUT)"

$(FGDOUTPUT): $(FGD) $(MODDIR)
	cp $(FGD) "$(FGDOUTPUT)"

$(MODDIR):
	if [ \! -e "$(MODDIR)" ] ; then\
		mkdir "$(MODDIR)" ;\
   	fi
