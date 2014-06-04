<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" version="4.0" encoding="utf-8" indent="yes"/>

  <xsl:template match="/">
    <html>
      <head>
        <title></title>
        <style type="text/css">
          .forme{
          color: #E82C0C;
          }
          .lemme{
          color: darkblue;
          }
          .cat{
          color: darkgreen;
          }
        </style>
      </head>
      <bdoy>
        <table>
          <tr>
            <th class="forme">Forme</th>
            <th class="lemme">Lemme</th>
            <th class="cat">Catégorie</th>
          </tr>
          <xsl:apply-templates/>
        </table>
      </bdoy>
    </html>
  </xsl:template>

  <xsl:template match="element">
    <tr>
      <td class="forme">
        <xsl:value-of select="data[@type='string']"/>
      </td>
      <td class="lemme">
        <xsl:value-of select="data[@type='lemma']"/>
      </td>
      <td class="cat">
        <xsl:value-of select="data[@type='type']"/>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>