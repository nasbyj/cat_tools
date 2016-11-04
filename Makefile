include pgxntool/base.mk

# TODO: Remove once this is pulled into pgxntool
installcheck: pgtap

B = sql

LT93		 = $(call test, $(MAJORVER), -lt, 93)

$B:
	@mkdir -p $@

installcheck: $B/cat_tools.sql
EXTRA_CLEAN += $B/cat_tools.sql
$B/cat_tools.sql: sql/cat_tools.in.sql Makefile
	(echo @generated@ && cat $< && echo @generated@) | sed -e 's#@generated@#-- GENERATED FILE! DO NOT EDIT! See $<#' > $@
ifeq ($(LT93),yes)
	sed -i'' -e 's/, COLUMN/-- Requires 9.3: &/' $@
endif

