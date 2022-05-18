<?xml version="1.0" encoding="UTF-8"?>
<!--
Create a list of island manifests that should be scanned for duplicate entries.


 -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:variable name="island.data.dir">bin/data/scenes</xsl:variable>
	<xsl:variable name="manifest.file.name">mobileAssets.txt</xsl:variable>

	<xsl:output method="text" omit-xml-declaration="yes"
		standalone="no" encoding="utf-8" indent="no" />

	<xsl:template match="/">
		<xsl:apply-templates select="project" />
	</xsl:template>

	<xsl:template match="project">
		<xsl:apply-templates select="target" />
	</xsl:template>

	<xsl:template match="target">
		<xsl:apply-templates select="create-island-zip[@packagedFileState != 'remoteCompressed']">
			<xsl:with-param name="directory" select="$island.data.dir"/>
			<xsl:with-param name="filename" select="$manifest.file.name"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="create-island-zip">
		<xsl:param name="directory"/>
		<xsl:param name="filename"/>
		<xsl:value-of select="$directory"/>
		<xsl:text>/</xsl:text>
		<xsl:value-of select="@island"/>
		<xsl:text>/</xsl:text>
		<xsl:value-of select="$filename"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="child::node()">
		<xsl:value-of select="." />
	</xsl:template>
</xsl:stylesheet>