# install packages for parallelization
install.packages("parallel", "doSNOW", "stringr")

# load packages
library(parallel)
library(doSNOW)

# verify no. of cores available
n_cores <- detectCores()
n_cores



# PREPARATION -----------------------------

# packages
library(stringr)

# import data
marketing <- read.csv("data/marketing_data.csv")
# clean/prepare data
marketing$Income <- as.numeric(gsub("[[:punct:]]", "", marketing$Income))
marketing$days_customer <- as.Date(Sys.Date())-
  as.Date(marketing$Dt_Customer, "%m/%d/%y")
marketing$Dt_Customer <- NULL

# all sets of independent vars
indep <- names(marketing)[ c(2:19, 27,28)]
combinations_list <- lapply(1:length(indep),
                            function(x) combn(indep, x, simplify = FALSE))
combinations_list <- unlist(combinations_list, recursive = FALSE)
models <- lapply(combinations_list,
                 function(x) paste("Response ~", paste(x, collapse="+")))

# set cores for parallel processing
# ctemp <- makeCluster(ncores)
# registerDoSNOW(ctemp)

# prepare loop
N <- 10 # just for illustration, the actual code is N <- length(models)
# run loop in parallel
pseudo_Rsq <-
  foreach ( i = 1:N, .combine = c) %dopar% {
    # fit the logit model via maximum likelihood
    fit <- glm(models[[i]], data=marketing, family = binomial())
    # compute the proportion of deviance explained
    #by the independent vars (~R^2)
    return(1-(fit$deviance/fit$null.deviance))
}


# set cores for parallel processing
ctemp <- makeCluster(ncores)
registerDoSNOW(ctemp)










library(knitr)
hook_output = knit_hooks$get('output')
knit_hooks$set(output = function(x, options) {
  # this hook is used only when the linewidth option is not NULL
  if (!is.null(n <- options$linewidth)) {
    x = xfun::split_lines(x)
    # any lines wider than n should be wrapped
    if (any(nchar(x) > n)) x = strwrap(x, width = n)
    x = paste(x, collapse = '\n')
  }
  hook_output(x, options)
})

aws emr create-cluster \

--release-label emr-6.1.0 \

--applications Name=Hadoop Name=Spark Name=Hive Name=Pig \

Name=Tez Name=Ganglia \

--name "EMR 6.1 RStudio + sparklyr"  \

--service-role EMR_DefaultRole \

--instance-groups InstanceGroupType=MASTER,InstanceCount=1,\

InstanceType=m3.2xlarge,InstanceGroupType=CORE,\

InstanceCount=2,InstanceType=m3.2xlarge \

--bootstrap-action \

Path='s3://aws-bigdata-blog/artifacts/

aws-blog-emr-rstudio-sparklyr/rstudio_sparklyr_emr6.sh',\

Name="Install RStudio" --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,\

KeyName="sparklyr"

--configurations '[{"Classification":"spark",

"Properties":{"maximizeResourceAllocation":"true"}}]' \

--region us-east-1




# load packages
library(sparklyr)
# connect rstudio session to cluster
sc <- spark_connect(master = "yarn")

