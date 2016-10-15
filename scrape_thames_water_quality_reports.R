## extract water quality data from Thames Water reports

## retrieved from https://secure.thameswater.co.uk/water-quality-reports/
## 2014 reports uploaded to site on 30th June 2015

library(pdftools)
library(stringi)
library(xlsx)
library(plyr)

tw_reports <- dir(".", pattern = "[.]*xlsx", recursive = T)
# tw_reports <- head(tw_reports, 2)

tw_report_output <- lapply(tw_reports, function(x) {
  print(x)
  tw_report_1_ws_zone <- read.xlsx(x, rowIndex = 3, colIndex = 1, sheetIndex = 1, header = F, colClasses = "character", as.data.frame = F)
  tw_report_1_ws_zone <- stri_split(tw_report_1_ws_zone, regex = "\n|: |to|  ")
  tw_report_1 <- rbind(
      (read.xlsx(x, startRow = 5, endRow = 49, sheetIndex = 1, stringsAsFactors = F, as.data.frame = T)),
      (read.xlsx(x, startRow = 5, endRow = 49, sheetIndex = 2, stringsAsFactors = F, as.data.frame = T))
  )
## routine to extract data in transposed format
#   tmp_parameter <- tw_report_1[,1]
#   tmp_observation <- names(tw_report_1)
#   tw_report_1   <- as.data.frame(t(tw_report_1[,-1]))
#   names(tw_report_1) <- tmp_parameter
#   tw_report_1$observation <- tmp_observation[-1]

  tw_report_1$ws_zone        <- stri_trans_totitle(trimws(tw_report_1_ws_zone[[1]][3]))
  tw_report_1$postcode       <- trimws(tw_report_1_ws_zone[[1]][2])
  tw_report_1$date_from      <- as.Date(tw_report_1_ws_zone[[1]][6], format = "%d/%m/%Y")
  tw_report_1$date_to        <- as.Date(tw_report_1_ws_zone[[1]][7], format = "%d/%m/%Y")
  tw_report_1$date_extracted <- as.Date(tw_report_1_ws_zone[[1]][9], format = "%d/%m/%Y")
  return(tw_report_1)
  }
)

uk_water_chemistry <- ldply(tw_report_output)
# print(names(uk_water_chemistry))
names(uk_water_chemistry) <- c("observation",
                               "units",
                               "pcv",
                               "minimum",
                               "mean",
                               "maximum",
                               "samples",
                               "contravening.pcv",
                               "percentage.contravening.pcv",
                               "area",
                               "postcode",
                               "date.from",
                               "date.to",
                               "date.extracted")
save(uk_water_chemistry, file = "../fermentR/data/uk_water_chemistry.RData")
