#!/usr/bin/env Rscript

suppressMessages(suppressWarnings(library(tidyverse)))
suppressMessages(suppressWarnings(library(tidytext)))

input_file = commandArgs(TRUE)[1]
data_frame(text = read_lines(input_file)) %>%
    unnest_tokens(word, text) %>%
    anti_join(stop_words, by = "word") %>%
    count(word, sort = TRUE) %>%
    print()
