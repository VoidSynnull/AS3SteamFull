<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:app="http://ns.adobe.com/air/application/32.0">

	<xsl:output method="xml"
		omit-xml-declaration="no"
		standalone="no" encoding="utf-8"
		cdata-section-elements="app:InfoAdditions app:Entitlements app:manifestAdditions"/>

	<xsl:param name="appId"/>
	<xsl:param name="packageFilename"/>
	<xsl:param name="packageName"/>
	<xsl:param name="versionNumber"/>
	<xsl:param name="buildNumber"/>
	<xsl:param name="initialWindowContent"/>
	<xsl:param name="targetPrefix"/>
	<xsl:param name="iconDir"/>
	<xsl:param name="config.isAdsActive"/>

	<xsl:template match="app:initialWindow/app:content">
		<xsl:copy>
			<xsl:value-of select="$initialWindowContent"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:id">
		<xsl:copy>
			<xsl:value-of select="$appId"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:filename">
		<xsl:copy>
			<xsl:value-of select="$packageFilename"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:name">
		<xsl:copy>
			<xsl:value-of select="$packageName"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:versionNumber">
		<xsl:copy>
			<xsl:value-of select="$versionNumber"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:versionLabel">
		<xsl:copy>
			<xsl:value-of select="$versionNumber"/>
			<xsl:if test="$buildNumber &gt; 0">
				<xsl:text> #</xsl:text>
				<xsl:value-of select="$buildNumber"/>
			</xsl:if>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:icon">
		<xsl:copy>
			<xsl:for-each select="node()">
				<xsl:copy>
					<xsl:value-of select="$iconDir"/>
					<xsl:text>/</xsl:text>
					<xsl:apply-templates/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:manifestAdditions">
		<manifestAdditions>
			<xsl:text disable-output-escaping="yes">
&lt;![CDATA[
</xsl:text>
			<xsl:copy-of select="document(concat('../src/', $targetPrefix, '.manifest.xml'))"/>
			<xsl:text disable-output-escaping="yes">
]]&gt;
</xsl:text>
		</manifestAdditions>
	</xsl:template>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>

	<xsl:template match="app:extensionID">
		<xsl:if test="$config.isAdsActive='true' or not(starts-with(., 'com.supersonic.') or starts-with(., 'com.fiksu.'))">
			<xsl:copy>
				<xsl:apply-templates/>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
