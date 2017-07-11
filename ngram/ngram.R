#!/usr/bin/env Rscript

library(tidyverse)
library(tidytext)

# get 2-gram and 3-gram model from input text file, write output dataframe
# as rds file
input_file = commandArgs(TRUE)[1]

data_frame(text = read_lines(input_file)) %>%
    unnest_tokens(bigram, text, token = 'ngrams', n = 2) %>%
    separate(bigram, c("word1", "word2"), sep = " ") %>%
    anti_join(stop_words, by = c("word1" = "word")) %>%
    anti_join(stop_words, by = c("word2" = "word")) %>%
    count_(c("word1", "word2"), sort = TRUE) %>%
    write_rds(path = paste0(input_file, '.2gram.rds'), compress = "xz")

data_frame(text = read_lines(input_file)) %>%
    unnest_tokens(trigram, text, token = 'ngrams', n = 3) %>%
    separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%
    anti_join(stop_words, by = c("word1" = "word")) %>%
    anti_join(stop_words, by = c("word2" = "word")) %>%
    anti_join(stop_words, by = c("word3" = "word")) %>%
    count_(c("word1", "word2", "word3"), sort = TRUE) %>%
    write_rds(path = paste0(input_file, '.3gram.rds'), compress = "xz")
