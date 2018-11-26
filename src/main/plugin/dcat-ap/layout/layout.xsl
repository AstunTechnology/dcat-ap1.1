<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (C) 2001-2016 Food and Agriculture Organization of the
  ~ United Nations (FAO-UN), United Nations World Food Programme (WFP)
  ~ and United Nations Environment Programme (UNEP)
  ~
  ~ This program is free software; you can redistribute it and/or modify
  ~ it under the terms of the GNU General Public License as published by
  ~ the Free Software Foundation; either version 2 of the License, or (at
  ~ your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful, but
  ~ WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  ~ General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with this program; if not, write to the Free Software
  ~ Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
  ~
  ~ Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
  ~ Rome - Italy. email: geonetwork@osgeo.org
  -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:spdx="http://spdx.org/rdf/terms#"
		xmlns:skos="http://www.w3.org/2004/02/skos/core#"
		xmlns:adms="http://www.w3.org/ns/adms#" 
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:dcat="http://www.w3.org/ns/dcat#"
		xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
		xmlns:foaf="http://xmlns.com/foaf/0.1/" 
		xmlns:owl="http://www.w3.org/2002/07/owl#"
		xmlns:schema="http://schema.org/"
		xmlns:locn="http://www.w3.org/ns/locn#"
		xmlns:java="java:org.fao.geonet.util.XslUtil" 
		xmlns:gn="http://www.fao.org/geonetwork"
		xmlns:gn-fn-metadata="http://geonetwork-opensource.org/xsl/functions/metadata"
		xmlns:gn-fn-dcat-ap="http://geonetwork-opensource.org/xsl/functions/profiles/dcat-ap"
    xmlns:saxon="http://saxon.sf.net/"
    extension-element-prefixes="saxon"
		exclude-result-prefixes="#all">

  <xsl:include href="utility-fn.xsl"/>
  <xsl:include href="utility-tpl.xsl"/>
  <xsl:include href="layout-custom-fields.xsl"/>
  <xsl:include href="layout-custom-tpl.xsl"/>

  <!-- Ignore all gn element -->
  <xsl:template mode="mode-dcat-ap"
                match="gn:*|@gn:*|@*"
                priority="1000">
  </xsl:template>

  <!-- Template to display non existing element ie. geonet:child element
  of the metadocument. Display in editing mode only and if
  the editor mode is not flat mode. -->
  <xsl:template mode="mode-dcat-ap" match="gn:child" priority="2000">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>


    <xsl:variable name="name" select="concat(@prefix, ':', @name)"/>
    <xsl:variable name="flatModeException"
                  select="gn-fn-metadata:isFieldFlatModeException($viewConfig, $name)"/>

    <!-- TODO: this should be common to all schemas -->
    <xsl:if test="$isEditing and
      (not($isFlatMode) or $flatModeException)">

      <xsl:variable name="directive"
                    select="gn-fn-metadata:getFieldAddDirective($editorConfig, $name)"/>
			<xsl:variable name="labelConfig"
                        select="gn-fn-metadata:getLabel($schema, $name, $labels, name(..), '', concat(gn-fn-metadata:getXPath(..),'/',$name))"/>
      <xsl:call-template name="render-element-to-add">
        <!-- TODO: add xpath and isoType to get label ? -->
        <xsl:with-param name="label" select="$labelConfig/label"/>
        <xsl:with-param name="btnLabel" select="if($name != 'dct:license') then $labelConfig/btnLabel else ''"/>
        <xsl:with-param name="directive" select="$directive"/>
        <xsl:with-param name="childEditInfo" select="."/>
        <xsl:with-param name="parentEditInfo" select="../gn:element"/>
        <xsl:with-param name="isFirst" select="count(preceding-sibling::*[name() = $name]) = 0"/>
        <xsl:with-param name="isForceLabel" select="true()"/>        
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="mode-dcat-ap" priority="200"
                match="*[name() = $editorConfig/editor/fieldsWithFieldset/name]">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>
    <xsl:param name="refToDelete" required="no"/>
    <xsl:variable name="name" select="name(.)"/>
    <xsl:variable name="isSupportingSlideToggle" select="$editorConfig/editor/fieldsWithFieldset/name[.=$name]/@isSupportingSlideToggle='true'"/>
    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="''"/>

    <xsl:variable name="errors">
      <xsl:if test="$showValidationErrors">
        <xsl:call-template name="get-errors"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>
    <xsl:call-template name="render-boxed-element">
      <xsl:with-param name="label" select="$labelConfig/label"/>
      <xsl:with-param name="editInfo" select="if ($refToDelete) then $refToDelete else gn:element"/>
      <xsl:with-param name="errors" select="$errors"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="isSlideToggle" select="if ($isSupportingSlideToggle and $isDisplayingSections = false()) then 'true' else 'false'"/>
      <xsl:with-param name="subTreeSnippet">

        <xsl:if test="$isEditing">
		      <!-- Render attributes as fields and overwrite the normal behavior -->
		      <xsl:apply-templates mode="render-for-field-for-attribute"
		                           select="@*|gn:attribute[not(@name = parent::node()/@*/name())]">
		        <xsl:with-param name="ref" select="gn:element/@ref"/>
		      </xsl:apply-templates>
		    </xsl:if>
        <xsl:apply-templates mode="mode-dcat-ap" select="*">
          <xsl:with-param name="schema" select="$schema"/>
          <xsl:with-param name="labels" select="$labels"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

  <!-- 
    ... but not the one proposing the list of elements to add in DC schema
    
    Template to display non existing element ie. geonet:child element
    of the metadocument. Display in editing mode only and if 
  the editor mode is not flat mode. -->
  <xsl:template mode="mode-dcat-ap" match="gn:child[contains(@name, 'CHOICE_ELEMENT')]"
    priority="3000">
    <xsl:if test="$isEditing and 
      not($isFlatMode)">

      <!-- Create a new configuration to only create
            a add action for non existing node. The add action for 
            the existing one is below the last element. -->
      <xsl:variable name="newElementConfig">
        <xsl:variable name="dcConfig"
          select="ancestor::node()/gn:child[contains(@name, 'CHOICE_ELEMENT')]"/>
        <xsl:variable name="existingElementNames" select="string-join(../descendant::*/name(), ',')"/>

        <gn:child>
          <xsl:copy-of select="$dcConfig/@*"/>
          <xsl:copy-of select="$dcConfig/gn:choose[not(contains($existingElementNames, @name))]"/>
        </gn:child>
      </xsl:variable>

      <xsl:call-template name="render-element-to-add">
        <xsl:with-param name="childEditInfo" select="$newElementConfig/gn:child"/>
        <xsl:with-param name="parentEditInfo" select="../gn:element"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Hide from the editor the dct:references pointing to uploaded files -->
  <xsl:template mode="mode-dcat-ap" priority="101"
                match="*[(name(.) = 'dct:references' or
                          name(.) = 'dc:relation') and
                         (starts-with(., 'http') or
                          contains(. , 'resources.get') or
                          contains(., 'file.disclaimer'))]" />

  <!-- the other elements in DC. -->
  <xsl:template mode="mode-dcat-ap" priority="100" match="dc:*|dct:*|dcat:*|vcard:*|foaf:*|spdx:*|adms:*|owl:*|schema:*|skos:*">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>
    <xsl:param name="overrideLabel" select="''" required="no"/>
    <xsl:param name="refToDelete" required="no"/>
    <xsl:variable name="name" select="name(.)"/>
    <xsl:variable name="ref" select="gn:element/@ref"/>
    <xsl:variable name="labelConfig" as="node()">
      <xsl:choose>
        <xsl:when test="name()='dcat:accessURL' or name()='dcat:downloadURL'">
          <xsl:copy-of select="gn-fn-metadata:getLabel($schema, 'rdf:resource', $labels, name(..), '', concat(gn-fn-metadata:getXPath(.),'/@rdf:resource'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="gn-fn-metadata:getLabel($schema, $name, $labels, name(..), '', gn-fn-metadata:getXPath(.))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="helper" select="gn-fn-metadata:getHelper($labelConfig/helper, .)"/>
    <xsl:variable name="added" select="parent::node()/parent::node()/@gn:addedObj"/>
    <xsl:variable name="container" select="parent::node()/parent::node()"/>

    <!-- Render rdf:about attribute as field for dcat:Dataset -->
    <xsl:if test="not($isFlatMode) and $isEditing and name(..)='dcat:Dataset' and ../@rdf:about and name() = 'dct:title' and count(preceding-sibling::*[name() = 'dct:title']) = 0">
      <xsl:apply-templates mode="render-for-field-for-attribute"
                           select="../@rdf:about">
        <xsl:with-param name="ref" select="../gn:element/@ref"/>
      </xsl:apply-templates>
    </xsl:if>

    <!-- Add view and edit template-->
    <xsl:variable name="fieldNode" select="$editorConfig/editor/fields/for[@name = $name and @templateModeOnly]"/>
    <xsl:choose>
			<xsl:when test="count($fieldNode/*)>0 and $fieldNode/@templateModeOnly">
				<xsl:variable name="name" select="$fieldNode/@name"/>
				<xsl:variable name="label" select="$fieldNode/@label"/>
				<xsl:variable name="del" select="'.'"/>
				<xsl:variable name="template" select="$fieldNode/template"/>
				<xsl:variable name="isForceLabel" select="$fieldNode/@forceLabel"/>
				<xsl:variable name="currentNode" select="." />
				<!-- Check if template field values should be in
				readonly mode in the editor.-->
				<xsl:variable name="readonly">
				  <xsl:choose>
				    <xsl:when test="$template/values/@readonlyIf">
				      <saxon:call-template name="{concat('evaluate-', $schema, '-boolean')}">
				        <xsl:with-param name="base" select="$currentNode"/>
				        <xsl:with-param name="in" select="concat('/', $template/values/@readonlyIf)"/>
				      </saxon:call-template>
				    </xsl:when>
				  </xsl:choose>
				</xsl:variable>
		
				<xsl:variable name="templateCombinedWithNode" as="node()">
				  <template>
				    <xsl:copy-of select="$template/values"/>
				    <snippet>
				      <xsl:apply-templates mode="gn-merge" select="$template/snippet/*">
				        <xsl:with-param name="node-to-merge" select="$currentNode"/>
				      </xsl:apply-templates>
				    </snippet>
				  </template>
				</xsl:variable>
		
				<xsl:variable name="keyValues">
				  <xsl:call-template name="build-key-value-configuration">
				    <xsl:with-param name="template" select="$template"/>
				    <xsl:with-param name="currentNode" select="$currentNode"/>
				    <xsl:with-param name="readonly" select="$readonly"/>
				  </xsl:call-template>
				</xsl:variable>
		
				<xsl:variable name="originalNode"
				              select="gn-fn-metadata:getOriginalNode($metadata, .)"/>
		
				<xsl:variable name="refToDelete">
				  <xsl:call-template name="get-ref-element-to-delete">
				    <xsl:with-param name="node" select="$originalNode"/>
				    <xsl:with-param name="delXpath" select="$del"/>
				  </xsl:call-template>
				</xsl:variable>
		
		
				<!-- If the element exist, use the _X<ref> mode which
				      insert the snippet for the element if not use the
				      XPATH mode which will create the new element at the
				      correct location. -->
				<xsl:variable name="id" select="concat('_X', gn:element/@ref, '_replace')"/>
				<xsl:call-template name="render-element-template-field">
				  <xsl:with-param name="name" select="$labelConfig/label"/>
				  <!--xsl:with-param name="name" select="$strings/*[name() = $name]" /-->
          <xsl:with-param name="btnLabel" select="$labelConfig/btnLabel"/>
				  <xsl:with-param name="id" select="$id"/>
				  <xsl:with-param name="isExisting" select="true()"/>
				  <xsl:with-param name="template" select="$templateCombinedWithNode"/>
				  <xsl:with-param name="keyValues" select="$keyValues"/>
				  <xsl:with-param name="refToDelete" select="$refToDelete/gn:element"/>
				  <xsl:with-param name="isFirst" select="$isForceLabel and count(preceding-sibling::*[name() = $name]) = 0"/>
				</xsl:call-template>
    	</xsl:when>
			<xsl:otherwise>
        <xsl:call-template name="render-element">
			    <xsl:with-param name="label" select="$labelConfig"/>
			    <xsl:with-param name="value" select="."/>
			    <xsl:with-param name="cls" select="local-name()"/>
			    <!--<xsl:with-param name="widget"/>
			          <xsl:with-param name="widgetParams"/>-->
			    <xsl:with-param name="xpath" select="gn-fn-metadata:getXPath(.)"/>
					<!--xsl:with-param name="forceDisplayAttributes" select="gn-fn-dcat-ap:isForceDisplayAttributes(.)"/-->
			    <!--xsl:with-param name="attributesSnippet" select="$attributes"/-->
			    <xsl:with-param name="type" select="gn-fn-metadata:getFieldType($editorConfig, name(), '')"/>
			    <xsl:with-param name="name" select="if ($isEditing) then $ref else ''"/>
			    <xsl:with-param name="editInfo" select="if ($refToDelete) then $refToDelete else gn:element"/>
			    <xsl:with-param name="parentEditInfo"
			                    select="if ($added) then $container/gn:element else element()"/>
			    <xsl:with-param name="listOfValues" select="$helper"/>
			    <!-- When adding an element, the element container contains
			    information about cardinality. -->
			    <xsl:with-param name="isFirst"
			                    select="if ($added) then
			                    (($container/gn:element/@down = 'true' and not($container/gn:element/@up)) or
			                    (not($container/gn:element/@down) and not($container/gn:element/@up)))
			                    else
			                    ((gn:element/@down = 'true' and not(gn:element/@up)) or
			                    (not(gn:element/@down) and not(gn:element/@up)))"/>
          <xsl:with-param name="isForceLabel" select="true()"/>
		      <xsl:with-param name="isDisabled" select="name(.)='dct:identifier' and count(preceding-sibling::*[name(.) = 'dct:identifier'])=0 and name(..)='dcat:Dataset'"/>
          <!-- Boolean that allow to show the mandatory "*" in black instead of red -->
          <xsl:with-param name="subRequired" select="(name() = 'vcard:street-address' and name(..) = 'vcard:Address') or
                                                     (name() = 'vcard:locality' and name(..) = 'vcard:Address') or
                                                     (name() = 'vcard:postal-code' and name(..) = 'vcard:Address') or
                                                     (name() = 'vcard:country-name' and name(..) = 'vcard:Address') or
                                                     (name() = 'foaf:name' and ../../name() = 'dct:publisher') or
                                                     (name() = 'foaf:name' and name(..) = 'foaf:Document') or
                                                     (name() = 'skos:notation' and name(..) = 'adms:Identifier') or
                                                     (name() = 'spdx:algorithm' and name(..) = 'spdx:Checksum') or
                                                     (name() = 'spdx:checksumValue' and name(..) = 'spdx:Checksum')"/>
			  </xsl:call-template>
			
	      <xsl:if test="$isEditing">
	
	        <!-- Render attributes as fields and overwrite the normal behavior -->
	        <xsl:apply-templates mode="render-for-field-for-attribute"
	                             select="@*|gn:attribute[not(@name = parent::node()/@*/name())]">
	          <xsl:with-param name="ref" select="gn:element/@ref"/>
	        </xsl:apply-templates>
	      </xsl:if>
			</xsl:otherwise>
		</xsl:choose>
  </xsl:template>

  <!-- Hide from the editor in default view -->
  <xsl:template mode="mode-dcat-ap" priority="2001"
                match="*[((name(.) = 'dct:type' and name(..)='foaf:Agent') or
                          (name(.) = 'dcat:downloadURL' and name(..)='dcat:Distribution') or
                          (name(.) = 'dct:issued' and name(..)='dcat:Distribution') or
                          (name(.) = 'dct:modified' and name(..)='dcat:Distribution') or
                          (name(.) = 'dct:language' and name(..)='dcat:Distribution') or
                          (name(.) = 'dct:rights' and name(..)='dcat:Distribution') or
                          (name(.) = 'dcat:byteSize' and name(..)='dcat:Distribution') or
                          (name(.) = 'spdx:checksum' and name(..)='dcat:Distribution') or
                          (name(.) = 'foaf:page' and name(..)='dcat:Distribution') or
                          (name(.) = 'dct:conformsTo' and name(..)='dcat:Distribution') or
                          (name(.) = 'adms:status' and name(..)='dcat:Distribution')) and
                          $isFlatMode]" />

  <!-- Ignore the following attributes in flatMode -->
  <xsl:template mode="render-for-field-for-attribute" match="@*[$isFlatMode]|@gn:xsderror|@gn:addedObj" priority="101"/>

  <xsl:template mode="render-for-field-for-attribute" match="@*" priority="100">
    <xsl:variable name="attributeName" select="name(.)"/>
    <xsl:variable name="ref" select="concat(../gn:element/@ref, '_', replace($attributeName, ':', 'COLON'))"/>
    <xsl:variable name="attribute" as="node()">
      <gn:attribute>
        <xsl:attribute name="ref" select="$ref"/>
        <!--xsl:attribute name="del" select="true()"/>
        <xsl:attribute name="parent" select="../gn:element/@ref"/-->
        <xsl:copy-of select="../gn:attribute[@name = local-name()]/@*"/>
      </gn:attribute>
    </xsl:variable>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, $attributeName, $labels, name(..), '', if (name(.)='xml:lang') then '' else gn-fn-metadata:getXPath(.))"/>
    <xsl:variable name="helper" select="gn-fn-metadata:getHelper($labelConfig/helper, .)"/>
    <xsl:variable name="added" select="parent::node()/parent::node()/@gn:addedObj"/>

    <xsl:call-template name="render-element">
      <xsl:with-param name="label" select="$labelConfig"/>
      <xsl:with-param name="value" select="."/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="gn-fn-metadata:getXPath(.)"/>
      <xsl:with-param name="type" select="gn-fn-metadata:getFieldType($editorConfig, $attributeName, '')"/>
      <xsl:with-param name="name" select="$ref"/>
      <xsl:with-param name="editInfo" select="$attribute"/>
      <xsl:with-param name="listOfValues" select="$helper"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template mode="render-for-field-for-attribute"
                match="gn:attribute[@name = ('rdf:nodeID') or (not(@name = ('ref', 'parent', 'id', 'uuid', 'type', 'uuidref',
    'xlink:show', 'xlink:actuate', 'xlink:arcrole', 'xlink:role', 'xlink:title', 'xlink:href')) and $isFlatMode)]"
                priority="101"/>

  <xsl:template mode="render-for-field-for-attribute"
                match="gn:attribute[not(@name = ('ref', 'parent', 'id', 'uuid', 'type', 'uuidref',
    'xlink:show', 'xlink:actuate', 'xlink:arcrole', 'xlink:role', 'xlink:title', 'xlink:href')) and not($isFlatMode)]"
                priority="100">
    <xsl:param name="ref"/>
    <xsl:param name="insertRef" select="''"/>
    <xsl:if test="not(gn-fn-dcat-ap:isNotMultilingualField(.., $editorConfig))">
      <xsl:variable name="attributeLabel" select="gn-fn-metadata:getLabel($schema, @name, $labels, name(..), '', concat(gn-fn-metadata:getXPath(..),'/@',@name))"/>
      <label class="col-sm-2 control-label"/>
      <div class="col-sm-9 btn-group nopadding-in-table">
        <button type="button" class="btn btn-default btn-xs"
                data-gn-click-and-spin="add('{$ref}', '{@name}', '{$ref}', null, true)"
                title="{$attributeLabel/description}">
          <i class="fa fa-plus fa-fw"/>
          <xsl:value-of select="$attributeLabel/label"/>
        </button>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
