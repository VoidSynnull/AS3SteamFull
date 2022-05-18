<?xml version="1.0" encoding="UTF-8"?>
<!--
Create zip files of assets used in mobile ad delivery

Based on XML files of the form

<manifest>
  <data|assets>+ @type @path? @prefix? @ext?
    <asset>+
 -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="text" omit-xml-declaration="yes"
		standalone="no" encoding="utf-8" indent="no" />

	<xsl:template match="/">
		<xsl:apply-templates select="manifest" />
	</xsl:template>

	<xsl:template match="manifest">
		<xsl:apply-templates select="data|assets" />
	</xsl:template>

	<xsl:template match="data|assets">
		<xsl:apply-templates select="asset">
			<xsl:with-param name="path">
				<xsl:value-of select="@path"/>
			</xsl:with-param>
			<xsl:with-param name="prefix">
				<xsl:value-of select="@prefix"/>
			</xsl:with-param>
			<xsl:with-param name="ext">
				<xsl:value-of select="@ext"/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="asset">
		<xsl:param name="path"/>
		<xsl:param name="prefix"/>
		<xsl:param name="ext"/>

		<xsl:variable name="pathLength" select="string-length($path)"/>

		<xsl:value-of select="$path"/>
		<xsl:if test="substring($path,$pathLength) != '/'">
			<xsl:text>/</xsl:text>
		</xsl:if>
		<xsl:value-of select="$prefix"/>
		<xsl:apply-templates select="child::node()"/>
		<xsl:if test="$ext">
			<xsl_text>.</xsl_text>
			<xsl:value-of select="$ext"/>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="child::node()">
		<xsl:value-of select="." />
	</xsl:template>
</xsl:stylesheet>