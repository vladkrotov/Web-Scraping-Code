#Loading the required packages

require(jsonlite)
require(xlsx)
require(rvest)
require(curl)
require(plyr)

#Set the directory where data will be saved
setwd("C:/Users/cob.user/Documents/Research/JAIS/R/Data")


#Forming an initial URL. This URL is used to retrieve scraping parameters, like the number of job descriptions to be retrieved
initial_url <- "http://service.dice.com/api/rest/jobsearch/v1/simple.json?text=%22systems+analyst%22"

#Loading JSON data from the URL. Note that jdata is a list of 6 elements
jdata <- fromJSON(curl(initial_url, handle = curl::new_handle("useragent" = "RStudio")))

#Element 5 from the jdata list is a data frame containing information about jobs. So we save it in a separate data frame 
job_data <- data.frame(jdata[5])

#We also save the total number of job descriptions to be retrieved. This value is element 1 in the jdata list
job_count <- as.numeric(jdata[1])

#Number of total JSON pages is calculated by dividing the number of total jobs by 50, which is the number of jobs listed on each JSON page by default
page_count <- ceiling(job_count/50)

#Creating a data frame where all job descriptions will be stored
job_table <- data.frame()

#Creating a temporary data frame where job descriptions from each page will be temporarily stored until they are appended to the job_table data frame
job_temp_table <- data.frame()

#This outer for loop will load the pages with job listings in JSON format from the first page to the last page as calculated earlier
for (i in 1:page_count){

#A page URL is formed. Page number is supplied as a parameter
page_url <- paste("http://service.dice.com/api/rest/jobsearch/v1/simple.json?text=%22systems+analyst%22&page=",i,sep = "")

#Reading JSON data into a list called jdata
jdata <- fromJSON(page_url)

#If it's not first or last page (where the list returned contains 6 elements), save the 6th element of the data frame into the temporary data frame job_temp_table 
if ((i != 1) && (i != page_count)) {  
    
    job_temp_table <- data.frame(jdata[6])

#The first and the last page are saved into a list of only 5 elements, since previous URL element is absent on the first page and next URL element is absent on the last page. Thus, the 5th element of the jdata list contains the needed job description data      
} else { 
  page_url <-  
paste("http://service.dice.com/api/rest/jobsearch/v1/simple.json?text=%22systems+analyst%22&page=",i,sep = "")
  jdata <- fromJSON(page_url)
  job_temp_table <- data.frame(jdata[5])
}
 #Inserting a new column named Description into the temporary data   
 frame. This is where job descriptions will be added for every job
 job_temp_table["Description"] <- ""
  
 #Calculating the total number of jobs to be loaded for each page   
 using the firstDocument and lastDocument elements in the list. The  
 number of jobs to be downloaded will be the 50 for all job poges 
 except the last one.  
 jobs_to_load <- as.integer(jdata[3]) - as.integer(jdata[2]) + 1

 #This is a part of a simple status bar. It will show the user which 
 page is being scraped.   
 cat(paste("Scraping ",jobs_to_load, " jobs from page ",i," out of   
 ",page_count,": ", sep = ""))

  #This inner loop uses job URLs to download job descriptions for 
  each of the jobs listed on a JSON page and saves these descriptions 
  in the "Description" column of the temporary data frame     
  job_temp_table.
  for (job_id in 1:jobs_to_load){
      
      #The try({})block is used for catching errors. If there is an 
      error reading or scraping a particular URL, then move to next  
      URL.
      try({     
      #The lines below are used to load URLs containing job 
      descriptions, read HTML codes of pages loaded, and save data 
      contained in a CSS element containing a detailed job   
      description into a data frame.
      job_html <-   
      read_html(curl(job_temp_table$resultItemList.detailUrl[job_id], 
      handle = curl::new_handle("useragent" = "RStudio")))
      job_node <- html_node(job_html,"#jobdescSec")
      job_text <- html_text(job_node)
      job_temp_table$Description[job_id] <- job_text
      
      #This is a part of a simple status bar that shows progress in  
      scraping jobs from each page
      cat("*")
      
      })
  }
    
  #To prevent data loss, each page is saved into a separate Excel    
  file
  page_file_name <- paste("page",i,".xlsx", sep = "")
  write.xlsx(job_temp_table,file = page_file_name)
  
  #Job data from the page is appended to the global data frame where 
  all job descriptions are stored
  job_table <- rbind.data.frame(job_table, job_temp_table)
 
  #Output screen is cleared to avoid clutter
  cat("\014")
}

#Tidying the previously created data frame by renaming the columns of the global data frame in a way that will make it easier for a user to understand data
colnames(job_table) <- c("JobURL", "JobTitle", "Company", "JobLocation", "JobDate", "JobDescription")

#Generating a string containing current date and time
current_date <- as.character(date())
file_date <- gsub(" ", "_", current_date, fixed = TRUE)
file_date_clean <- gsub(":", "_",file_date, fixed = TRUE)

#Generating a meaningful file name that contains current data and time
file_name <- paste("Jobs_",file_date_clean,".csv", sep= "")

#Writing all the data scraped and stored in the job_table data frame (see previous script) into an Excel file. 
write.xlsx(job_table,file = file_name)
