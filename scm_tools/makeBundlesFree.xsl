<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml"
		omit-xml-declaration="no"
		standalone="no" encoding="utf-8"/>


	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>

	<xsl:template match="bundle">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="@free">
		<xsl:attribute name="free">true</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>
