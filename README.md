# Scrape Thames Water reports

an R script to scrape and collate information which was supplied in PDF format.

The 2014 reports were generated to PDF directly from a spreadsheet. I tried using 
pdftools package. After some false starts I converted the PDF back into XLSX and use
the openxlsx package to read them. 

The 2015 data will require a different approach.

Reports are available at https://secure.thameswater.co.uk/water-quality-reports/

These reports are intended for collation into a data set for the fermentR package
