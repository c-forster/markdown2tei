<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		exclude-result-prefixes="tei">

  <xsl:output method="xml" version="1.0" indent="yes" encoding="utf-8" omit-xml-declaration="no" />

  <xsl:template match="/">
    <xsl:apply-templates />
  </xsl:template>

  <!-- Identity template. -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- This element matches paragraphs followed by a poem and then a 
       noindent div. -->
  <xsl:template match="tei:p[following-sibling::*[1][self::tei:lg[@type='poetry']] and following-sibling::*[2][self::tei:div[@class='noindent']]]">
    <xsl:copy>
      <xsl:apply-templates />
      <xsl:copy-of select="../tei:lg[following-sibling::*[1][self::tei:div[@class='noindent']]]" />      <xsl:value-of select="../tei:div[@class='noindent']" /> 
    </xsl:copy>
  </xsl:template>

  <!-- These two templates silence the material that gets moved by the template above. 
       Without these rules the material would appear twice. -->
  <xsl:template match="tei:div[@class='noindent'][preceding-sibling::tei:lg[@type='poetry']]"></xsl:template>

  <xsl:template match="tei:lg[@type='poetry'][following-sibling::*[1][self::tei:div[@class='noindent']]]"></xsl:template>


</xsl:stylesheet>
