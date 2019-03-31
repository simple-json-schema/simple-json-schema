json-schema.txt: json-schema.xml
	xml2rfc --v3 --text json-schema.xml

json-schema.xml: json-schema.md
	mmark ./json-schema.md > json-schema.xml
