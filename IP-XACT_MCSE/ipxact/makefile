
# ---------- Local variables -----------------------------------------------------------------------
DIR_ROOT=..
DIR_SRC=src
DIR_SCRIPTS=scripts
DIR_ARTIFACTS=artifacts
DIR_CONFIG=$(DIR_ROOT)/config

FILE_CONFIG_DESIGN_NAME=$(DIR_CONFIG)/design_name
FILE_CONFIG_DESIGN_VENDOR=$(DIR_CONFIG)/design_vendor
FILE_CONFIG_DESIGN_IPLIB=$(DIR_CONFIG)/design_iplib
FILE_CONFIG_DESIGN_VERSION=$(DIR_CONFIG)/design_version
FILE_COMPILE_MANIFEST=$(DIR_ROOT)/compile_manifest

# ---------- Configuration variables ---------------------------------------------------------------
CONFIG_TARGET_NAME=$(shell head -n 1 $(FILE_CONFIG_DESIGN_NAME))
CONFIG_TARGET_VENDOR=$(shell head -n 1 $(FILE_CONFIG_DESIGN_NAME))
CONFIG_TARGET_IPLIB=$(shell head -n 1 $(FILE_CONFIG_DESIGN_NAME))
CONFIG_TARGET_VERSION=$(shell head -n 1 $(FILE_CONFIG_DESIGN_NAME))

# ---------- Script variables ----------------------------------------------------------------------
IPXACT_TIMESTAMP=$(shell date +"%F_%H%M%S")
IPXACT_CHECKSUM=$(shell sha256sum $(TARGET_IPXACT) | cut -d ' ' -f 1)

TARGET=$(CONFIG_TARGET_NAME)
TARGET_IPXACT=$(TARGET).xml
TARGET_MODULE=$(DIR_ROOT)/$(DIR_SRC)/$(TARGET).v

FILE_TMP_DEFINES_DICT=tmp_defines_dictionary
FILE_TMP_INCLUDE_DIRECTIVES=tmp_include_directives
FILE_TMP_FILESETS=tmp_filesets

# ---------- IP-XACT keywords and values -----------------------------------------------------------
IPXACT_DESIGN_VENDOR=$(CONFIG_TARGET_VENDOR)
IPXACT_DESIGN_LIBRARY=$(CONFIG_TARGET_IPLIB)
IPXACT_DESIGN_NAME=$(CONFIG_TARGET_NAME)
IPXACT_DESIGN_VERSION=$(CONFIG_TARGET_VERSION)

# ---------- IP-XACT files and sections ------------------------------------------------------------
IPXACT_FILE_PREAMBLE=$(DIR_ARTIFACTS)/ipxact_preamble.xml

# ---------- IP-XACT target specific files and sections --------------------------------------------
IPXACT_TARGET_PREAMBLE=$(TARGET)_preamble.xml
IPXACT_TARGET_BUS_INTERFACES=$(TARGET)_bus_interfaces.xml
IPXACT_TARGET_ADDRESS_SPACES=$(TARGET)_address_spaces.xml
IPXACT_TARGET_MEMORYMAPS=$(TARGET)_memorymaps.xml
IPXACT_TARGET_MODEL=$(TARGET)_model.xml
IPXACT_TARGET_FILESETS=$(TARGET)_filesets.xml
IPXACT_TARGET_DESCRIPTION=$(TARGET)_description.xml
IPXACT_TARGET_PARAMETERS=$(TARGET)_parameters.xml
IPXACT_TARGET_VENDOR_EXTENSIONS=$(TARGET)_vendor.xml
IPXACT_TARGET_EPILOG=$(TARGET)_epilog.xml

# The IP-XACT file is constructed from sections in this order
IPXACT_SECTIONS=$(IPXACT_TARGET_PREAMBLE)\
				$(IPXACT_TARGET_BUS_INTERFACES)\
				$(IPXACT_TARGET_ADDRESS_SPACES)\
				$(IPXACT_TARGET_MEMORY)\
				$(IPXACT_TARGET_MODEL)\
				$(IPXACT_TARGET_FILESETS)\
				$(IPXACT_TARGET_DESCRIPTION)\
				$(IPXACT_TARGET_PARAMETERS)\
				$(IPXACT_TARGET_VENDOR_EXTENSIONS)\
				$(IPXACT_TARGET_EPILOG)



# --------------------------------------------------------------------------------------------------
.DEFAULT_GOAL := ipxact



# ---------- Make rules for IP-XACT sections -------------------------------------------------------
$(IPXACT_TARGET_PREAMBLE): $(DIR_ARTIFACTS)/ipxact_preamble.xml
	@echo "Creating $@"
	@echo "<!-- $(TARGET) IP-XACT created on $(IPXACT_TIMESTAMP) -->"
	@echo "<!-- $(TARGET) IP-XACT created on $(IPXACT_TIMESTAMP) -->"           >  $@
	@cat $(DIR_ARTIFACTS)/ipxact_preamble.xml                                   >> $@
	@echo "    <ipxact:vendor>$(IPXACT_DESIGN_VENDOR)</ipxact:vendor>"          >> $@
	@echo "    <ipxact:library>$(IPXACT_DESIGN_LIBRARY)</ipxact:library>"       >> $@
	@echo "    <ipxact:name>$(IPXACT_DESIGN_NAME)</ipxact:name>"                >> $@
	@echo "    <ipxact:version>$(IPXACT_DESIGN_VERSION)</ipxact:version>"       >> $@
#	@cat $@                                                                     >> $(TARGET_IPXACT)

$(IPXACT_TARGET_BUS_INTERFACES):
	@echo "Creating $@"

$(IPXACT_TARGET_ADDRESS_SPACES):
	@echo "Creating $@"

$(IPXACT_TARGET_MEMORYMAPS):
	@echo "Creating $@"

$(IPXACT_TARGET_MODEL): $(DIR_ARTIFACTS)/$(TARGET)_model_preamble.xml
	@echo "Creating $@"
# Create define dictionary
	@$(DIR_SCRIPTS)/create_defines_dictionary.sh
# Create IP-XACT ports section
	@cat $(DIR_ARTIFACTS)/$(TARGET)_model_preamble.xml                          >  $@
	@awk -f $(DIR_SCRIPTS)/ports.awk $(FILE_TMP_DEFINES_DICT) $(TARGET_MODULE)  >> $@
	@cat $(DIR_ARTIFACTS)/$(TARGET)_model_epilog.xml                            >> $@

$(IPXACT_TARGET_FILESETS): $(FILE_COMPILE_MANIFEST)
	@echo "Creating $@"
	@awk '$$1 !~ /^$(DIR_TESTBENCH)\// {print $1}' $(FILE_COMPILE_MANIFEST) > $(FILE_TMP_FILESETS)
	@awk -f $(DIR_SCRIPTS)/filesets.awk $(FILE_TMP_FILESETS)                    >  $@

$(IPXACT_TARGET_DESCRIPTION):
	@echo "Creating $@"

$(IPXACT_TARGET_PARAMETERS):
	@echo "Creating $@"

$(IPXACT_TARGET_VENDOR_EXTENSIONS):
	@echo "Creating $@"

$(IPXACT_TARGET_EPILOG): $(DIR_ARTIFACTS)/ipxact_epilog.xml
	@echo "Creating $@"
	@cat $(DIR_ARTIFACTS)/ipxact_epilog.xml                                     >  $@
	@echo "<!-- sha256sum $(TARGET_IPXACT) : $(IPXACT_CHECKSUM) -->"            >> $@
	@echo "<!-- sha256sum $(TARGET_IPXACT) : $(IPXACT_CHECKSUM) -->"

$(TARGET_IPXACT):
	@echo "" > $@



# ---------- Make rules for final IP-XACT file -----------------------------------------------------
ipxact: $(TARGET_IPXACT) $(IPXACT_SECTIONS)
	@for ipxact_section in $(IPXACT_SECTIONS) ; do \
		echo "...$$ipxact_section" ; \
		cat $$ipxact_section >> $(TARGET_IPXACT) ; \
	done ;

all:
	@echo $(CONFIG_TARGET_NAME)


# ---------- Make rules for cleaning ---------------------------------------------------------------
clean:
	rm -f $(TARGET_IPXACT)
	rm -f $(IPXACT_TARGET_FILESETS) $(FILE_TMP_FILESETS)
	rm -f $(IPXACT_TARGET_MODEL) $(FILE_TMP_DEFINES_DICT) $(FILE_TMP_INCLUDE_DIRECTIVES)
	rm -f $(IPXACT_TARGET_PREAMBLE) $(IPXACT_TARGET_EPILOG)

distclean: clean

# Phony targets
.PHONY: clean distclean ipxact
