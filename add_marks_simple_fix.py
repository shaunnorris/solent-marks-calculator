#!/usr/bin/env python3
"""
Simple script to manually add missing marks to GPX file with proper XML formatting
"""

# Read the original GPX file
with open('2025scra.gpx', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the closing tag
content = content.replace('</ns0:gpx>', '')

# Add the missing marks with proper formatting
new_marks = '''

<ns0:wpt lat="50.707833" lon="-1.507167">
<ns0:name>23</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Harbour</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.712000" lon="-1.495000">
<ns0:name>29</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>R Sol YC ODM</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.710667" lon="-1.498000">
<ns0:name>2HE</ns0:name>
<ns0:sym>R</ns0:sym>
<ns0:desc>East Fairway Bouy</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.710500" lon="-1.487667">
<ns0:name>2#</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Towers</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.733167" lon="-1.516500">
<ns0:name>2♠</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Spade</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.738000" lon="-1.511000">
<ns0:name>2🌰</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Acorn/Oakhaven</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.741833" lon="-1.500000">
<ns0:name>2S</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>East Mark</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.738500" lon="-1.513500">
<ns0:name>2Y</ns0:name>
<ns0:sym>B</ns0:sym>
<ns0:desc>Black &amp; Orange</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.741833" lon="-1.509333">
<ns0:name>2Z</ns0:name>
<ns0:sym>B</ns0:sym>
<ns0:desc>Black &amp; White</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.748667" lon="-1.495000">
<ns0:name>2π</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Pylewell Inner</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.729667" lon="-1.525500">
<ns0:name>2+</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Plus Mark</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.743167" lon="-1.515333">
<ns0:name>2@</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>West Reach</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.722000" lon="-1.535500">
<ns0:name>2V1</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Inshore of Mark L</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.722167" lon="-1.512500">
<ns0:name>2V2</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>between Marks C &amp; T</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.734333" lon="-1.506667">
<ns0:name>2V3</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>South of Jack in Basket</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.747833" lon="-1.487667">
<ns0:name>2V4</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>North of Mark E</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.744833" lon="-1.482500">
<ns0:name>2V5</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Between Marks E &amp; G</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.740167" lon="-1.477500">
<ns0:name>2V6</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Between Marks F &amp; G</ns0:desc>
</ns0:wpt>

<ns0:wpt lat="50.749667" lon="-1.465500">
<ns0:name>2V7</ns0:name>
<ns0:sym>Y</ns0:sym>
<ns0:desc>Between Marks G &amp; J</ns0:desc>
</ns0:wpt>'''

# Add the new marks and closing tag
content += new_marks + '\n</ns0:gpx>'

# Write back to file
with open('2025scra.gpx', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added 19 new marks to 2025scra.gpx with proper XML formatting") 