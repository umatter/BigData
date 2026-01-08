# Big Data Analytics


This repository contains the source of the [Big Data Analytics book](https://umatter.github.io/BigData/), as well as  supplementary online resources. The book is built using [bookdown](https://github.com/rstudio/bookdown).

## Supplementary online resources

### R code examples

The [R_code_examples](/R_code_examples) folder contains R-scripts with all code examples and tutorials shown in the book. 

### Data

The corresponding sections in the book contain typically contain detailed instructions of where and how the datasets used in the code examples can be downloaded from the original sources.

To ensure data availability for the code examples and tutorials in the long run, you find (smaller scale) versions for all key datasets discussed in the book here: [bda-examples](https://www.dropbox.com/scl/fo/jadkdmdt8nghiws0bs4j4/ANqPEXbvQ-5KEdRw9GrsEHE?rlkey=ko9l1isgy4etskn2rdfzirzz6&st=ivu2wjau&dl=0)


### Installation of dependencies and packages

Here you find additional resources and hints regarding the installation of some of the tools used in the book.

 - `gpuR`: The package is not anymore available via `install.packages()`. However, you can install it with `devtools::install_github("cdeterman/gpuR")`. For additional installation instructions (in particular regarding dependencies), see the wiki here: https://github.com/cdeterman/gpuR/wiki.
 - Install Apache Spark via `sparklyr`: https://spark.rstudio.com/get-started/
 - Install Tensorflow and Keras via the `tensorflow` and `keras` packages (from within R): https://tensorflow.rstudio.com/install/
 
 
