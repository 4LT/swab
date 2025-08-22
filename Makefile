MODDIR=$(QUAKEDIR)/swab-dev
PROGS=progs.dat
CSPROGS=csprogs.dat
OUTPUT=$(MODDIR)/$(PROGS)
CSOUTPUT=$(MODDIR)/$(CSPROGS)

.PHONY: all chkdir install package clean

all: $(PROGS) $(CSPROGS)

chkdir: 
	if [ -z "$(QUAKEDIR)" ] ; then\
		echo ;\
		echo "QUAKEDIR must be set!" ;\
		echo ;\
		exit 1;\
	fi

install: chkdir all $(OUTPUT) $(CSOUTPUT)

clean:
	rm -f progs.dat
	rm -f csprogs.dat
	rm -f progs.lno

$(PROGS): *.qc progs.src
	fteqcc

$(CSPROGS): *.qc csprogs.src
	fteqcc csprogs.src

$(OUTPUT): $(PROGS) $(MODDIR)
	cp $(PROGS) "$(OUTPUT)"

$(CSOUTPUT): $(CSPROGS) $(MODDIR)
	cp $(CSPROGS) "$(CSOUTPUT)"

$(MODDIR):
	if [ \! -e "$(MODDIR)" ] ; then\
		mkdir "$(MODDIR)" ;\
   	fi
