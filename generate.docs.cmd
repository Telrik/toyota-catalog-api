@rmdir docs /Q /S
@java -jar c:\work\openapi-generator\modules\openapi-generator-cli\target\openapi-generator-cli.jar generate -i toyota.catalog.json -g html2 -o docs\
@start docs\index.html