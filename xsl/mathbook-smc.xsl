<?xml version='1.0'?>

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:math="http://exslt.org/math"
    extension-element-prefixes="exsl date math">

<xsl:import href="./mathbook-html.xsl" />

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<!-- Content as Knowls -->
<!-- Turn off all knowls, as incompatible -->
<xsl:param name="html.knowl.theorem" select="'no'" />
<xsl:param name="html.knowl.proof" select="'no'" />
<xsl:param name="html.knowl.definition" select="'no'" />
<xsl:param name="html.knowl.example" select="'no'" />
<xsl:param name="html.knowl.remark" select="'no'" />
<xsl:param name="html.knowl.figure" select="'no'" />
<xsl:param name="html.knowl.table" select="'no'" />
<xsl:param name="html.knowl.exercise" select="'no'" />

<!-- SageWS files as output -->
<xsl:variable name="file-extension" select="'.sagews'" />

<!-- Do not implement any cross-reference as a knowl -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in   xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<!-- Contrary to HTML production, we do not have a pass through to build the knowls -->
<xsl:template match="mathbook">
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- File wrap -->
<!-- Per file setup, CSS, LaTeX macros, crude nav bars top and bottom -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="url">
        <xsl:apply-templates select="." mode="url" />
    </xsl:variable>
    <exsl:document href="{$url}" method="html">
        <xsl:call-template name="sage-css-setup" />
        <xsl:call-template name="html-css-mathjax-setup" />
        <xsl:apply-templates select="." mode="crude-nav-bar" />
        <!-- the guts -->
        <xsl:copy-of select="$content" />
        <!-- A nav bar at the bottom too -->
        <xsl:apply-templates select="." mode="crude-nav-bar" />
    </exsl:document>
</xsl:template>

<!-- The abstract chunking routines will use a default   -->
<!-- template for a structural subdivision, so we define -->
<!-- that here.  For SMC we write a subdvision header    -->
<!-- (ie section title) as an HTML cell, then deal with  -->
<!-- each direct descendant (children) as HTML or Sage   -->
<!-- cells.  At a minimum this assumes that a Sage cell  -->
<!-- is not buried in some other structure, like a list. -->
<xsl:template match="&STRUCTURAL;">
    <!-- Subdivision heading, as its own HTML cell -->
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <xsl:variable name="ident">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:variable>
            <section class="{local-name(.)}" id="{$ident}">
                <xsl:apply-templates select="." mode="section-header" />
            </section>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- Direct, and interesting, children become cells             -->
    <!-- Further subdivisions (not chunked) come through here again -->
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)]" mode="smc-cell" />
</xsl:template>

<!-- Introductions and Conclusions     -->
<!-- Nearly identical to HTML template -->
<xsl:template match="introduction|conclusion">
    <!-- Cell for introduction header, condition on title! -->
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <xsl:variable name="ident">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:variable>
            <article class="{local-name(.)}" id="{$ident}">
                <h5 class="heading">
                    <xsl:apply-templates select="." mode="title-full" />
                    <span> </span>
                </h5>
            </article>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- Build cells for remaining children -->
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)]" mode="smc-cell" />
</xsl:template>

<!-- Most children of a subdivision will be HTML cells,    -->
<!-- so wrap as such and then call their default templates -->
<xsl:template match="*" mode="smc-cell">
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Handle Sage code with a minimum of interference   -->
<!-- This comes second, so as to overide generic above -->
<xsl:template match="sage" mode="smc-cell">
    <xsl:apply-templates select="." mode="smc-compute-cell">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
            <!-- Sage input always ends with a newline -->
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Most Sage options are implemented in  xsl/mathbook-common.xsl -->
<!-- We just output the input code, with no XHTML protections      -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:value-of select="$in" disable-output-escaping="yes" />
</xsl:template>

<!-- TODO: sage-display-only abstract template needed (?) -->
<!--       Or deprecate type="display"                    -->

<!-- Summary page is links to subsidiary content      -->
<!-- This is functional but will not win style points -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <!-- Heading, div for subdivision that is this page -->
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <xsl:variable name="ident">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:variable>
            <section class="{local-name(.)}" id="{$ident}">
                <xsl:apply-templates select="." mode="section-header" />
            </section>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- Handle structural elements as pointers -->
    <!-- introduction and conclusion as cells   -->
    <xsl:for-each select="*">
        <xsl:choose>
            <xsl:when test="&STRUCTURAL-FILTER;">
                <xsl:apply-templates select="." mode="smc-html-cell">
                    <xsl:with-param name="content">
                        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
                        <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
                        <div style="font-size:150%; padding-bottom:1.5ex">
                            <a href="{$url}">
                                <!-- important not include codenumber span -->
                                <xsl:if test="$num!=''">
                                    <span class="codenumber"><xsl:value-of select="$num" /></span>
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                                <span class="title">
                                    <xsl:apply-templates select="." mode="title-simple" />
                                </span>
                            </a>
                        </div>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
            <!-- introduction, conclusion are included on page -->
            <xsl:otherwise>
                <xsl:apply-templates select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<!-- Mimics depth-first search, into its own HTML cell -->
<!-- This is functional but will not win style points  -->
<xsl:template match="*" mode="crude-nav-bar">
    <xsl:variable name="prev">
        <xsl:apply-templates select="." mode="previous-linear-url" />
    </xsl:variable>
    <xsl:variable name="up">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:variable name="next">
        <xsl:apply-templates select="." mode="next-linear-url" />
    </xsl:variable>
    <!-- HTML cell begins here, holds a table element -->
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <table width="90%" style="font-size: 200%;">
                <tr>
                    <xsl:if test="not($prev = '')">
                        <td align="left">
                            <xsl:element name="a">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$prev" />
                                </xsl:attribute>
                                <xsl:text>Previous</xsl:text>
                            </xsl:element>
                        </td>
                    </xsl:if>
                    <xsl:if test="not($up = '')">
                        <td align="center">
                            <xsl:element name="a">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$up" />
                                </xsl:attribute>
                                <xsl:text>Up</xsl:text>
                            </xsl:element>
                        </td>
                    </xsl:if>
                    <xsl:if test="not($next = '')">
                        <td align="right">
                            <xsl:element name="a">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$next" />
                                </xsl:attribute>
                                <xsl:text>Next</xsl:text>
                            </xsl:element>
                        </td>
                    </xsl:if>
                </tr>
            </table>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- We bypass image creation and just let SMC -->
<!-- do the job with an executable cell        -->
<xsl:template match="image[child::sageplot]">
    <xsl:apply-templates select="sageplot" />
</xsl:template>

<!-- TODO: Not fixed up yet 2016-10-02 -->
<xsl:template match="sageplot">
    <!-- Drop out of HTML mode -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Create a complete Sage cell region -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%hide&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start back in HTML mode -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>

<!-- Override for SVG images                        -->
<!-- SMC treates the object tag badly.  We ignore   -->
<!-- any PNG fallback and so just use an img tag.   -->
<!-- A named template creates the infrastructure    -->
<!-- for an SVG image.  Parameter lists (doc, code) -->
<!-- are identical to those for HTML conversion     -->
<!-- Parameters                                     -->
<!-- svg-filename: required, full relative path     -->
<!-- png-fallback-filename: optional                -->
<!-- image-width: required                          -->
<!-- image-description: optional                    -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="img">
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:value-of select="$image-width" />
            <xsl:text>; margin:0 auto;</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- ##################### -->
<!-- Set-up, per-worksheet -->
<!-- ##################### -->

<!-- Sage code for CSS load -->
<xsl:template name="sage-css-setup">
    <xsl:apply-templates select="." mode="smc-compute-cell">
        <xsl:with-param name="content">
            <xsl:text>%auto&#xa;</xsl:text>
            <xsl:text>%hide&#xa;</xsl:text>
            <xsl:text>load("mathbook-content.css")&#xa;</xsl:text>
            <xsl:text>load("mathbook-add-on.css")&#xa;</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- HTML code for CSS style, MathJax macros -->
<xsl:template name="html-css-mathjax-setup">
    <xsl:apply-templates select="." mode="smc-html-cell">
        <xsl:with-param name="content">
            <!-- Blend background color for MathJax display math       -->
            <!-- Status: https://github.com/sagemathinc/smc/issues/136 -->
            <xsl:element name="style">
                <xsl:text>.MathJax_SVG_Display {background-color: inherit;}</xsl:text>
            </xsl:element>
            <xsl:call-template name="latex-macros" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- ########################### -->
<!-- SageMathCloud Cell Wrappers -->
<!-- ########################### -->

<!-- SMC HTML Cell -->
<!-- Pass in HTML content, after templates applied -->
<!-- USe SMC UUID markers on their own lines       -->
<!-- Wrap in custom CSS class, mathbook-content    -->
<xsl:template match="*" mode="smc-html-cell">
    <xsl:param name="content" />
    <xsl:apply-templates select="." mode="smc-input-marker" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>%auto&#xa;</xsl:text>
    <xsl:text>%html(hide=True)&#xa;</xsl:text>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>mathbook-content</xsl:text>
        </xsl:attribute>
        <xsl:copy-of select="$content" />
    </xsl:element>
    <!-- Be certain output marker is on own line -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="smc-output-marker" />
    <!-- We could parse HTML $content into a JSON-escaped string -->
    <!-- Belongs *immediately* after output marker (?)           -->
    <!-- <xsl:text disable-output-escaping='yes'>{"done":true,"html":"&lt;p&gt;Execute cell above for proper output.&lt;/p&gt;"}&#xa;</xsl:text> -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- SMC Compute Cell -->
<!-- Pass in content, after templates applied -->
<!-- USe SMC UUID markers on their own lines       -->
<!-- Wrap in custom CSS class, mathbook-content    -->
<xsl:template match="*" mode="smc-compute-cell">
    <xsl:param name="content" />
    <xsl:apply-templates select="." mode="smc-input-marker" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$content" />
    <!-- Be certain $content ends with newline -->
    <xsl:apply-templates select="." mode="smc-output-marker" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- ########################## -->
<!-- SageMathCloud Cell Markers -->
<!-- ########################## -->

<!-- SMC uses markers to denote the start of each cell, -->
<!-- differentiating input from output.                 -->
<!-- By default these are Sage compute cells, but       -->
<!-- decorators/magics can make them behave differently -->

<!-- Pair of matched seldom-used Unicode, with a UUID -->
<!-- 'COMBINING LIGATURE LEFT HALF' (U+FE20)          -->
<xsl:template match="*" mode="smc-input-marker">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE20;</xsl:text>
</xsl:template>

<!-- Pair of matched seldom-used Unicode, with a UUID -->
<!-- 'COMBINING LIGATURE RIGHT HALF' (U+FE21)         -->
<xsl:template match="*" mode="smc-output-marker">
    <xsl:text>&#xFE21;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE21;</xsl:text>
</xsl:template>

<!-- Version 4 UUID -->
<!-- Improvements:                     -->
<!-- Use EXSLT random:random-sequence  -->
<!--   (1) Get a random number         -->
<!--   (2) Get content id of object    -->
<!--   (3) Mix to a new seed           -->
<!--   (4) Generate sequence and adorn -->
<!-- idpXXXXXXXX (universal format?)   -->
<!-- <xsl:value-of select="substring(generate-id(.), 4, 8)" /> -->
<xsl:template match="*" mode="uuid">
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 5 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 6 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 7 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 8 -->
    <xsl:text>-</xsl:text>
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:text>4</xsl:text> <!-- Version 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:text>a</xsl:text> <!-- Variant: leading bits 10 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 5 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 6 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 7 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 8 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 9 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 0 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
</xsl:template>

<xsl:template name="random-hex-digit">
    <xsl:variable name="digit" select="floor(16*math:random())" />
    <xsl:choose>
        <xsl:when test="10 > $digit">
            <xsl:value-of select="$digit" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$digit = 10">a</xsl:when>
                <xsl:when test="$digit = 11">b</xsl:when>
                <xsl:when test="$digit = 12">c</xsl:when>
                <xsl:when test="$digit = 13">d</xsl:when>
                <xsl:when test="$digit = 14">e</xsl:when>
                <xsl:when test="$digit = 15">f</xsl:when>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
