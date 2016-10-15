library(rvest)
library(stringr)
library(curl)
wr_html <- read_html("https://secure.thameswater.co.uk/water-quality-reports/")
wr_links <- html_nodes(wr_html, xpath = "//a/@href")
wr_links <- as.character(wr_links[6:length(wr_links)])
wr_links <- str_split_fixed(string = wr_links,pattern = "\"",n = 3)[,2]

for (i in wr_links) {
  curl_download(paste0("https://secure.thameswater.co.uk/water-quality-reports/",i), destfile = i)
}
