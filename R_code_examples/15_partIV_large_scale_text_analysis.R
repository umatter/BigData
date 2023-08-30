# install additional packages
# install.packages("gutenbergr") # download book from Project Gutenberg
# install.packages("dplyr") # for the data preparatory steps

# load packages
library(sparklyr)
library(gutenbergr)
library(dplyr)

# fix vars
TELL <- "https://www.gutenberg.org/cache/epub/6788/pg6788.txt"


# connect rstudio session to cluster
sc <- spark_connect(master = "yarn")


# install additional packages
# install.packages("gutenbergr") # to download book texts from Project Gutenberg
# install.packages("dplyr") # for the data preparatory steps
# load packages
library(sparklyr)
library(gutenbergr)
library(dplyr)
# fix vars
TELL <- "https://www.gutenberg.org/cache/epub/6788/pg6788.txt"
# connect rstudio session to cluster
conf <- spark_config()
conf$`sparklyr.shell.driver-memory` <- "8g"
sc <- spark_connect(master = "local",
                    config = conf)


# Data gathering and preparation
# fetch Schiller's Tell, load to cluster
tmp_file <- tempfile()
download.file(TELL, tmp_file)
raw_text <- readLines(tmp_file)
tell <- data.frame(raw_text=raw_text)
tell_spark <- copy_to(sc, tell,
                      "tell_spark",
                      overwrite = TRUE)


# data cleaning
tell_spark <- filter(tell_spark, raw_text!="")
tell_spark <- select(tell_spark, raw_text)
tell_spark <- mutate(tell_spark, 
                     raw_text = regexp_replace(raw_text, "[^0-9a-zA-Z]+", " "))



# split into words
tell_spark <- ft_tokenizer(tell_spark, 
                           input_col = "raw_text",
                           output_col = "words")



# remove stop-words
tell_spark <- ft_stop_words_remover(tell_spark,
                                    input_col = "words",
                                    output_col = "words_wo_stop")


# unnest words, combine in one row
all_tell_words <- mutate(tell_spark, 
               word = explode(words_wo_stop))

# final cleaning
all_tell_words <- select(all_tell_words, word)
all_tell_words <- filter(all_tell_words, 2<nchar(word))

# get word count and store result in Spark memory
compute(count(all_tell_words, word), "wordcount_tell")

spark_disconnect(sc)

# download and unzip the raw text data
URL <- "https://stacks.stanford.edu/file/druid:md374tz9962/hein-daily.zip"
PATH <- "data/hein-daily.zip"
system(paste0("curl ",
              URL,
              " > ",
              PATH,
              " && unzip ",
              PATH))
# move the speeches files
system("mkdir data/text/ && mkdir data/text/speeches")
system("mv hein-daily/speeches* data/text/speeches/")
# move the speaker files
system("mkdir data/text/speakers")
system("mv hein-daily/*SpeakerMap.txt data/text/speakers/")


# download and unzip procedural phrases data
URL_P <- "https://stacks.stanford.edu/file/druid:md374tz9962/vocabulary.zip"
PATH_P <- "data/vocabulary.zip"
system(paste0("curl ",
              URL_P,
              " > ",
              PATH_P,
              " && unzip ",
              PATH_P))
# move the procedural vocab file
system("mv vocabulary/vocab.txt data/text/")

# SET UP ----------------

# load packages
library(sparklyr)
library(dplyr)
# fix vars
INPUT_PATH_SPEECHES <- "data/text/speeches/" 
INPUT_PATH_SPEAKERS <- "data/text/speakers/" 

# configuration of local spark cluster
conf <- spark_config()
conf$`sparklyr.shell.driver-memory` <- "16g"
# connect rstudio session to cluster
sc <- spark_connect(master = "local", 
                    config = conf)


# LOAD TEXT DATA  --------------------

# load data
speeches <- spark_read_csv(sc,
                           name = "speeches",
                           path =  INPUT_PATH_SPEECHES,
                           delimiter = "|")
speakers <- spark_read_csv(sc,
                           name = "speakers",
                           path =  INPUT_PATH_SPEAKERS,
                           delimiter = "|")


# JOIN --------------------
speeches <- 
     inner_join(speeches,
                speakers,
                by="speech_id") %>%
     filter(party %in% c("R", "D"), chamber=="H")  %>%
     mutate(congress=substr(speech_id, 1,3)) %>%
     select(speech_id, speech, party, congress)
     

# CLEANING ----------------
# clean text: numbers, letters (bill IDs, etc.
speeches <- 
     mutate(speeches, speech = tolower(speech)) %>%
     mutate(speech = regexp_replace(speech,
                                    "[_\"\'():;,.!?\\-]",
                                    "")) %>%
     mutate(speech = regexp_replace(speech, "\\\\(.+\\\\)", " ")) %>%
     mutate(speech = regexp_replace(speech, "[0-9]+", " ")) %>%
     mutate(speech = regexp_replace(speech, "<[a-z]+>", " ")) %>%
     mutate(speech = regexp_replace(speech, "<\\w+>", " ")) %>%
     mutate(speech = regexp_replace(speech, "_", " ")) %>%
     mutate(speech = trimws(speech))


# TOKENIZATION, STOPWORDS REMOVAL, NGRAMS ----------------

# stopwords list 
stop <- readLines("http://snowball.tartarus.org/algorithms/english/stop.txt")
stop <- trimws(gsub("\\|.*", "", stop))
stop <- stop[stop!=""]

# clean text: numbers, letters (bill IDs, etc.
bigrams <- 
     ft_tokenizer(speeches, "speech", "words")  %>%
     ft_stop_words_remover("words", "words_wo_stop",
                           stop_words = stop )  %>%
     ft_ngram("words_wo_stop", "bigram_list", n=2)  %>%
     mutate(bigram=explode(bigram_list)) %>%
     mutate(bigram=trim(bigram)) %>%
     mutate(n_words=as.numeric(length(bigram) - 
                                    length(replace(bigram, ' ', '')) + 1)) %>%
     filter(3<nchar(bigram), 1<n_words) %>%
     select(party, congress, bigram)



# load the procedural phrases list
valid_vocab <- spark_read_csv(sc,
                             path="data/text/vocab.txt",
                             name = "valid_vocab",
                             delimiter = "|",
                             header = FALSE)
# remove corresponding bigrams via anti-join
bigrams <- inner_join(bigrams, valid_vocab, by= c("bigram"="V1"))

# BIGRAM COUNT PER PARTY ---------------
bigram_count <- 
     count(bigrams, party, bigram, congress)  %>%
     compute("bigram_count")

# FIND MOST PARTISAN BIGRAMS ------------

# compute frequencies and chi-squared values
freqs <- 
     bigram_count  %>%
     group_by(party, congress)  %>%
     mutate(total=sum(n), f_npl=total-n)
freqs_d <-
     filter(freqs, party=="D") %>%
     rename(f_pld=n, f_npld=f_npl) %>%
     select(bigram, congress, f_pld, f_npld)
freqs_r <-
     filter(freqs, party=="R") %>%
     rename(f_plr=n, f_nplr=f_npl) %>%
     select(bigram, congress, f_plr, f_nplr)

pol_bigrams <-
     inner_join(freqs_d, freqs_r, by=c("bigram", "congress")) %>%
     group_by(bigram, congress) %>%
     mutate(x2=((f_plr*f_npld-f_pld*f_nplr)^2)/
                 ((f_plr + f_pld)*(f_plr + f_nplr)*
                       (f_pld + f_npld)*(f_nplr + f_npld))) %>%
     select(bigram, congress, x2, f_pld, f_plr) %>%
     compute("pol_bigrams")


# create output data frame
output <- pol_bigrams  %>%
     group_by(congress) %>%
     arrange(desc(x2)) %>%
     sdf_with_sequential_id(id="index")  %>%
     filter(index<=2000) %>%
     mutate(Party=ifelse(f_pld<f_plr, "R", "D"))%>%
     select(bigram, congress, Party, x2) %>%
     collect()

# disconnect from cluster
spark_disconnect(sc)

# packages to prepare and plot
library(data.table)
library(ggplot2)
# select top ten per congress, clean
output <- as.data.table(output)
topten <- output[order(congress, x2, decreasing = TRUE),
                 rank:=1:.N, by=list(congress)][rank %in% (1:5)]
topten[, congress:=gsub("990", "99", congress)]
topten[, congress:=gsub("980", "98", congress)]
topten[, congress:=gsub("970", "97", congress)]

# plot a visualization of the most partisan terms
ggplot(topten, mapping=aes(x=as.integer(congress), y=log(x2), color=Party)) +
     geom_text(aes(label=bigram), nudge_y = 1)+
     ylab("Partisanship score (Ln of Chisq. value)") +
     xlab("Congress") +
     scale_color_manual(values=c("D"="blue", "R"="red"), name="Party") +
     guides(color=guide_legend(title.position="top")) +
     scale_x_continuous(breaks=as.integer(unique(topten$congress))) +
     theme_minimal() +
     theme(axis.text.x = element_text(angle = 90, hjust = 1),
           axis.text.y = element_text(hjust = 1),
           panel.grid.major = element_blank(),
           panel.grid.minor = element_blank(),
           panel.background = element_blank())
     


# load packages
library(dplyr)
library(sparklyr)
library(sparknlp)
library(sparklyr.nested)

# configuration of local spark cluster
conf <- spark_config()
conf$`sparklyr.shell.driver-memory` <- "16g"
# connect rstudio session to cluster
sc <- spark_connect(master = "local", 
                    config = conf)

# LOAD --------------------

# load speeches
INPUT_PATH_SPEECHES <- "data/text/speeches/" 
speeches <- 
     spark_read_csv(sc,
                    name = "speeches",
                    path =  INPUT_PATH_SPEECHES,
                    delimiter = "|",
                    overwrite = TRUE) %>% 
     sample_n(10000, replace = FALSE)  %>% 
     compute("speeches")
     

# load the nlp pipeline for sentiment analysis
pipeline <- nlp_pretrained_pipeline(sc, "analyze_sentiment", "en")

speeches_a <- 
     nlp_annotate(pipeline,
                  target = speeches,
                  column = "speech")

# extract sentiment coding per speech
sentiments <- 
     speeches_a %>%
     sdf_select(speech_id, sentiments=sentiment.result) %>% 
     sdf_explode(sentiments)  %>% 
     mutate(pos = as.integer(sentiments=="positive"),
            neg = as.integer(sentiments=="negative"))  %>% 
     select(speech_id, pos, neg) 


# aggregate and download to R environment -----
sentiments_aggr <- 
     sentiments  %>%
     select(speech_id, pos, neg) %>%
     group_by(speech_id) %>%
     mutate(rel_pos = sum(pos)/(sum(pos) + sum(neg))) %>%
     filter(0<rel_pos) %>%
     select(speech_id, rel_pos) %>%
     sdf_distinct(name = "sentiments_aggr") %>%
     collect()

# disconnect from cluster
spark_disconnect(sc)

# clean
library(data.table)
sa <- as.data.table(sentiments_aggr)
sa[, congress:=substr(speech_id, 1,3)]
sa[, congress:=gsub("990", "99", congress)]
sa[, congress:=gsub("980", "98", congress)]
sa[, congress:=gsub("970", "97", congress)]

# visualize results
library(ggplot2)
ggplot(sa, aes(x=as.integer(congress),
               y=rel_pos,
               group=congress)) +
     geom_boxplot() +
     ylab("Share of sentences with positive tone") +
     xlab("Congress") +
     theme_minimal()


system.time(
speeches_a <- 
     nlp_annotate(pipeline,
                  target = speeches,
                  column = "speech")
)

system.time(
speeches_a <- 
     nlp_annotate(pipeline,
                  target = speeches,
                  column = "speech") %>%
     compute(name= "speeches_a")
)

# disconnect from cluster
spark_disconnect(sc)
