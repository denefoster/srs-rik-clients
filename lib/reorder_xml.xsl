<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--

This xslt takes an SRS XML Request, and re-orders the elements to the order required by the SRS protocol.dtd. This is
primarily needed when converting requests from JSON to XML, as the order of elements is not preserved when creating a
JSON data structure.

-->

<!-- Top level - copy attributes, and apply any templates based on xpath match expressions -->
<xsl:template match="NZSRSRequest">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<!-- Contact Elements -->
<xsl:template match="RegistrantContact|AdminContact|TechnicalContact|RegistrarPublicContact|RegistrarSRSContact|DefaultTechnicalContact">
   <xsl:copy>
     <xsl:call-template name="ContactSubelements"/>
  </xsl:copy>
</xsl:template>


<!-- Named template that defines order of a contact's sub-elements -->
<xsl:template name="ContactSubelements">
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="PostalAddress"/>
     <xsl:copy-of select="Phone"/>
     <xsl:copy-of select="Fax"/>
</xsl:template>


<!-- Date Ranges -->
<xsl:template match="ResultDateRange|SearchDateRange|ChangedInDateRange|RegisteredDateRange|LockedDateRange|CancelledDateRange|BilledUntilDateRange|TransDateRange|InvoiceDateRange">
   <xsl:copy>
     <xsl:copy-of select="From"/>
     <xsl:copy-of select="To"/>          
  </xsl:copy>
</xsl:template>

<!-- Contact filters (differ to normal contacts with the PostalAddressFilter element) -->
<xsl:template match="RegistrantContactFilter|AdminContactFilter|TechnicalContactFilter|ContactFilter">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="PostalAddressFilter"/>
     <xsl:copy-of select="Phone"/>
     <xsl:copy-of select="Fax"/>
  </xsl:copy>
</xsl:template>

<!-- Transaction definitions -->

<xsl:template match="DomainCreate">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="RegistrantContact"/>
     <xsl:apply-templates select="AdminContact"/>
     <xsl:apply-templates select="TechnicalContact"/>
     <xsl:copy-of select="NameServers"/>
     <xsl:copy-of select="DNSSEC"/>
     <xsl:copy-of select="AuditText"/>
  </xsl:copy>

</xsl:template>

<xsl:template match="DomainUpdate">

   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="DomainNameFilter"/>
     <xsl:apply-templates select="RegistrantContact"/>
     <xsl:apply-templates select="AdminContact"/>
     <xsl:apply-templates select="TechnicalContact"/>
     <xsl:copy-of select="NameServers"/>
     <xsl:copy-of select="DNSSEC"/>
     <xsl:copy-of select="AuditText"/>
  </xsl:copy>

</xsl:template>

<xsl:template match="DomainDetailsQry">

   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="DomainNameFilter"/>
     <xsl:copy-of select="NameServerFilter"/>
     <xsl:copy-of select="DNSSECFilter"/>
     <xsl:apply-templates select="RegistrantContactFilter"/>
     <xsl:apply-templates select="AdminContactFilter"/>
     <xsl:apply-templates select="TechnicalContactFilter"/>
     <xsl:apply-templates select="ResultDateRange"/>
     <xsl:apply-templates select="SearchDateRange"/>
     <xsl:apply-templates select="ChangedInDateRange"/>
     <xsl:apply-templates select="RegisteredDateRange"/>
     <xsl:apply-templates select="LockedDateRange"/>
     <xsl:apply-templates select="CancelledDateRange"/>
     <xsl:apply-templates select="BilledUntilDateRange"/>
     <xsl:copy-of select="AuditTextFilter"/>
     <xsl:copy-of select="ActionIdFilter"/>
     <xsl:copy-of select="FieldList"/>
  </xsl:copy>

</xsl:template>

<xsl:template match="GetMessages">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="TransDateRange"/>
     <xsl:copy-of select="AuditTextFilter"/>
     <xsl:copy-of select="TypeFilter"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="RegistrarDetailsQry">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="ResultDateRange"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="RegistrarUpdate">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="RegistrarPublicContact"/>
     <xsl:apply-templates select="RegistrarSRSContact"/>
     <xsl:apply-templates select="DefaultTechnicalContact"/>
     <xsl:copy-of select="EncryptKeys"/>
     <xsl:copy-of select="EPPAuth"/>
     <xsl:copy-of select="Allowed2LDs"/>
     <xsl:copy-of select="Roles"/>
     <xsl:copy-of select="AuditText"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="RegistrarAccountQry">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="TransDateRange"/>
     <xsl:apply-templates select="InvoiceDateRange"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="HandleCreate|HandleUpdate">
   <xsl:copy>
	  <xsl:call-template name="ContactSubelements"/>
      <xsl:copy-of select="AuditText"/>
   </xsl:copy>   
</xsl:template>

<xsl:template match="HandleDetailsQry">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="HandleIdFilter"/>
     <xsl:apply-templates select="SearchDateRange"/>
     <xsl:apply-templates select="ChangedInDateRange"/>
     <xsl:apply-templates select="ContactFilter"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="Whois|AckMessage|UDAIValidQry|ActionDetailsQry">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
   </xsl:copy>
</xsl:template>

</xsl:stylesheet>

