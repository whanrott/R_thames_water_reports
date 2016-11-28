## extract water quality data from Thames Water reports

## retrieved from https://secure.thameswater.co.uk/water-quality-reports/

library(pdftools)
library(stringi)

source("water_reports_headings.R")

tw_reports_2014 <- dir("2014", pattern = "*.pdf", recursive = T, full.names = T)
tw_data_2014 <- do.call(rbind,
                         lapply(tw_reports_2014, function(x) {
# extract text from PDF
                           textlines    <- strsplit(pdf_text(x), "\n")
# find start and end of table
                           line_s1 <- grep(" Parameter ",textlines[[1]]) + 3
                           line_f1 <- grep("Prescribed Concentration or Value",textlines[[1]]) -1
                           line_s2 <- grep(" Parameter ",textlines[[2]]) + 3
                           line_f2 <- grep("Prescribed Concentration or Value",textlines[[2]]) -1
# generate header
                           header <- unlist(strsplit(trimws(textlines[[1]][c(3:4)]), "Water Supply Zone:[ ]+|[ ]*Zone No.:[ ]+|Population:[ ]+| [ ]+"))
                           header <- header[header != ""]
# catche when the header wraps to a second line
                           if(length(header) == 5) {header <- c(header[1],paste(header[2],header[4],sep=" "),header[3], header[5])}
# join the extracted lines
                           body_lines <- trimws(
                             c(
                               textlines[[1]][line_s1:line_f1],
                               textlines[[2]][line_s2:line_f2]
                             )
                           )
# the table wouldn't split apart with one regexp so I did it using 2 and joined them
## first 2 columns
                           variable_cols <- do.call(rbind,lapply(strsplit(body_lines," {2,}"),function(x){x[1:2]}))
## remaining columns
                           values_cols      <- do.call(rbind,lapply(strsplit(body_lines," {1,}"),function(x){a<-length(x);b<-a-6;x[b:a]}))
                           tw_report        <- as.data.frame(cbind(variable_cols,values_cols))
# process header into columns
                           tw_report$Location <- stri_trans_totitle(header[2])
                           tw_report$zone     <- header[3]
                           tw_report$postcode <- header[1]
                           tw_report$Population <- header[4]
                           tw_report$year     <- c("2014")
                           return(tw_report)
                           })
                         )
tw_reports_2015 <- dir("2015", pattern = "*.pdf", recursive = T, full.names = T)
tw_data_2015 <- do.call(rbind,
                        lapply(tw_reports_2015, function(x) {
                          textlines    <- strsplit(pdf_text(x), "\n")
# as above, but table is split across pages 3,4,5 instead of 1,2
                          line_s3 <- grep(" Parameter ",textlines[[3]]) + 2
                          line_f3 <- grep(" Page ",textlines[[3]]) -1
                          line_s4 <- grep(" Parameter ",textlines[[4]]) + 2
                          line_f4 <- grep(" Page ",textlines[[4]]) -1
                          line_s5 <- grep(" Parameter ",textlines[[5]]) + 2
                          line_f5 <- grep("Key to table above",textlines[[5]]) -1
                          header <- unlist(strsplit(trimws(textlines[[1]][c(3)]), "Water Supply Zone:[ ]+|[ ]*Zone No.:[ ]+|Population:[ ]+| [ ]+"))
                          header <- header[header != ""]
                          # if(length(header) == 5) {header <- c(header[1],paste(header[2],header[4],sep=" "),header[3], header[5])}
                          body_lines <- trimws(
                            c(
                              textlines[[3]][line_s3:line_f3],
                              textlines[[4]][line_s4:line_f4],
                              textlines[[5]][line_s5:line_f5]
                            )
                          )
                          variable_cols <- do.call(rbind,lapply(strsplit(body_lines," {2,}"),function(x){x[1:2]}))
                          values_cols      <- do.call(rbind,lapply(strsplit(body_lines," {1,}"),function(x){a<-length(x);b<-a-6;x[b:a]}))
                          tw_report        <- as.data.frame(cbind(variable_cols,values_cols))
                          tw_report$Location <- stri_trans_totitle(header[2])
                          tw_report$zone     <- header[1]
                          tw_report$postcode <- NA
                          tw_report$Population <- header[3]
                          tw_report$year     <- c("2015")
                          return(tw_report)
                        })
)
tw_data <- rbind(tw_data_2014, tw_data_2015)
names(tw_data)<- water_report_headings

# observation name has changed
tw_data$Observation[tw_data$Observation == "Hardness (Total) as CaCO3"] <- "Total Hardness as CaCO3"

# tidy up column classes
tw_data$Regulatory.Limit <- as.character(tw_data$Regulatory.Limit)
# this is a fudge to get a numeric value. I'm disgusted!
tw_data$Regulatory.Limit[tw_data$Regulatory.Limit == "6.50-9.50"] <- 8
tw_data$Regulatory.Limit[grepl("N/A|n/a|-",tw_data$Regulatory.Limit)] <- NA
# tw_data$Regulatory.Limit2   <- as.numeric(gsub("[<>]","",as.character(tw_data$Regulatory.Limit)))
tw_data$Minimum            <- as.numeric(gsub("[<>]","",as.character(tw_data$Minimum)))
tw_data$Mean               <- as.numeric(gsub("[<>]","",as.character(tw_data$Mean)))
tw_data$Max                <- as.numeric(gsub("[<>]","",as.character(tw_data$Max)))
tw_data$No.Samples.Total   <- as.numeric(as.character(tw_data$No.Samples.Total))
tw_data$No.Samples.Failing <- as.numeric(as.character(tw_data$No.Samples.Failing))

tw_data$Population         <- as.numeric(tw_data$Population)
tw_data$Zone               <- as.numeric(tw_data$Zone)

# try some plots
## how many people have hard water, and does it change year to year?
p <- ggplot(tw_data[tw_data$Observation == "Total Hardness as CaCO3",], aes(Population, Mean, colour = Year)) + geom_point()
## who has the highest mean levels of Cyanide (Blackheath)
q <- ggplot(tw_data[tw_data$Observation == "Cyanide as CN",], aes(Population, Mean, colour = Year)) + geom_point()
# look for anomalies in the elements. Lead levels are often high.
r <- ggplot(tw_data[grepl(" as ",tw_data$Observation) & tw_data$Observation != "Total Hardness as CaCO3",], aes(Mean, Max, colour = Year)) + geom_point() + facet_wrap(~ Observation, ncol = 6)
