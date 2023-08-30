# SET UP ------------------
# load packages
library(foreign)
library(data.table)
library(lmtest)
# fix vars
DATA_PATH <- "data/data_for_tables.dta"

# import data
cm <- as.data.table(read.dta(DATA_PATH))
# keep only clean obs
cm <- cm[!(is.na(yes)
           |is.na(pctsumyessameparty)
           |is.na(pctsumyessameschool)
           |is.na(pctsumyessamestate))] 


# pooled model (no FE)
model0 <-   yes ~ 
  pctsumyessameschool + 
  pctsumyessamestate + 
  pctsumyessameparty 

dim(model.matrix(model0, data=cm))

model1 <- 
  yes ~ pctsumyessameschool + 
        pctsumyessamestate + 
        pctsumyessameparty + 
        factor(congress) +
        factor(id) -1
mm1 <- model.matrix(model1, data=cm)
dim(mm1)


# fit specification (1)
runtime <- system.time(fit1 <- lm(data = cm, formula = model1))
coeftest(fit1)[2:4,]
# median amount of time needed for estimation
runtime[3]

# illustration of within transformation for the senator fixed effects
cm_within <- 
  with(cm, data.table(yes = yes - ave(yes, id),
                      pctsumyessameschool = pctsumyessameschool -
                        ave(pctsumyessameschool, id),
                      pctsumyessamestate = pctsumyessamestate -
                        ave(pctsumyessamestate, id),
                      pctsumyessameparty = pctsumyessameparty -
                        ave(pctsumyessameparty, id)
                      ))

# comparison of dummy fixed effects estimator and within estimator
dummy_time <- system.time(fit_dummy <- 
              lm(yes ~ pctsumyessameschool + 
                       pctsumyessamestate +
                       pctsumyessameparty + 
                       factor(id) -1, data = cm
                         ))
within_time <- system.time(fit_within <- 
                             lm(yes ~ pctsumyessameschool +
                                      pctsumyessamestate + 
                                      pctsumyessameparty -1, 
                                      data = cm_within))
# computation time comparison
as.numeric(within_time[3])/as.numeric(dummy_time[3])

# comparison of estimates
coeftest(fit_dummy)[1:3,]
coeftest(fit_within)


library(lfe)

# model and clustered SE specifications
model1 <- yes ~ pctsumyessameschool + 
                pctsumyessamestate + 
                pctsumyessameparty |congress+id|0|id
model2 <- yes ~ pctsumyessameschool + 
                pctsumyessamestate + 
                pctsumyessameparty |congress_session_votenumber+id|0|id

# estimation
fit1 <- felm(model1, data=cm)
fit2 <- felm(model2, data=cm)

stargazer::stargazer(fit1,fit2,
                     type="text",
                     dep.var.labels = "Vote (yes/no)",
                     covariate.labels = c("School Connected Votes",
                                          "State Votes",
                                          "Party Votes"),
                     keep.stat = c("adj.rsq", "n"))

# read dataset into R
economics <- read.csv("data/economics.csv")
# have a look at the data
head(economics, 2)
# create a 'large' dataset out of this
for (i in 1:3) {
     economics <- rbind(economics, economics)
}
dim(economics)


# Naïve approach (ignorant of R)
deflator <- 1.05 # define deflator
# iterate through each observation
pce_real <- c()
n_obs <- length(economics$pce)
for (i in 1:n_obs) {
  pce_real <- c(pce_real, economics$pce[i]/deflator)
}

# look at the result
head(pce_real, 2)



# Naïve approach (ignorant of R)
deflator <- 1.05 # define deflator
# iterate through each observation
pce_real <- list()
n_obs <- length(economics$pce)
time_elapsed <-
     system.time(
         for (i in 1:n_obs) {
              pce_real <- c(pce_real, economics$pce[i]/deflator)
})

time_elapsed



time_per_row <- time_elapsed[3]/n_obs
time_per_row


# in seconds
(time_per_row*100^4) 
# in minutes
(time_per_row*100^4)/60 
# in hours
(time_per_row*100^4)/60^2 


# Improve memory allocation (still somewhat ignorant of R)
deflator <- 1.05 # define deflator
n_obs <- length(economics$pce)
# allocate memory beforehand
# Initialize the vector to the right size
pce_real <- rep(NA, n_obs)
# iterate through each observation
time_elapsed <-
     system.time(
         for (i in 1:n_obs) {
              pce_real[i] <- economics$pce[i]/deflator
})




time_per_row <- time_elapsed[3]/n_obs
time_per_row


# in seconds
(time_per_row*100^4) 
# in minutes
(time_per_row*100^4)/60 
# in hours
(time_per_row*100^4)/60^2 


# Do it 'the R way'
deflator <- 1.05 # define deflator
# Exploit R's vectorization
time_elapsed <- 
     system.time(
     pce_real <- economics$pce/deflator
          )
# same result
head(pce_real, 2)


library(microbenchmark)
# measure elapsed time in microseconds (avg.)
time_elapsed <- 
  summary(microbenchmark(pce_real <- economics$pce/deflator))$mean
# per row (in sec)
time_per_row <- (time_elapsed/n_obs)/10^6


# in seconds
(time_per_row*100^4) 
# in minutes
(time_per_row*100^4)/60 
# in hours
(time_per_row*100^4)/60^2 


url <- 
"https://vincentarelbundock.github.io/Rdatasets/csv/carData/MplsStops.csv"
stopdata <- data.table::fread(url) 

url <-
"https://vincentarelbundock.github.io/Rdatasets/csv/carData/MplsStops.csv"
stopdata <- data.table::fread(url)

# remove incomplete obs
stopdata <- na.omit(stopdata)
# code dependent var
stopdata$vsearch <- 0
stopdata$vsearch[stopdata$vehicleSearch=="YES"] <- 1
# code explanatory var
stopdata$white <- 0
stopdata$white[stopdata$race=="White"] <- 1

model <- vsearch ~ white + factor(policePrecinct)

fit <- lm(model, stopdata)
summary(fit)

# load packages
library(data.table)
# set the 'seed' for random numbers (makes the example reproducible)
set.seed(2)

# set number of bootstrap iterations
B <- 10
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)
# draw bootstrap samples, estimate model for each sample
for (i in 1:B) {
     
     # draw sample of precincts (cluster level)
     precincts_i <- base::sample(precincts, size = 5, replace = TRUE)
     # get observations
     bs_i <- 
          lapply(precincts_i, function(x){
               stopdata[stopdata$policePrecinct==x,]
     } )
     bs_i <- rbindlist(bs_i)
     
     # estimate model and record coefficients
     boot_coefs[i,] <- coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
}

se_boot <- apply(boot_coefs, 
                 MARGIN = 2,
                 FUN = sd)
se_boot

# load packages for parallel processing
library(doSNOW)
# get the number of cores available
ncores <- parallel::detectCores()
# set cores for parallel processing
ctemp <- makeCluster(ncores) # 
registerDoSNOW(ctemp)


# set number of bootstrap iterations
B <- 10
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)

# bootstrapping in parallel
boot_coefs <- 
     foreach(i = 1:B, .combine = rbind, .packages="data.table") %dopar% {
          # draw sample of precincts (cluster level)
          precincts_i <- base::sample(precincts, size = 5, replace = TRUE)
          # get observations
          bs_i <- lapply(precincts_i, function(x) {
            stopdata[stopdata$policePrecinct==x,]
          })
          bs_i <- rbindlist(bs_i)
          # estimate model and record coefficients
          coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
     }
# be a good citizen and stop the snow clusters
stopCluster(cl = ctemp)


se_boot <- apply(boot_coefs, 
                 MARGIN = 2,
                 FUN = sd)
se_boot


# install packages
install.packages("data.table")
install.packages("doSNOW")
# load packages
library(data.table)

# fetch the data
url <-
"https://vincentarelbundock.github.io/Rdatasets/csv/carData/MplsStops.csv"
stopdata <- read.csv(url)
# remove incomplete obs
stopdata <- na.omit(stopdata)
# code dependent var
stopdata$vsearch <- 0
stopdata$vsearch[stopdata$vehicleSearch=="YES"] <- 1
# code explanatory var
stopdata$white <- 0
stopdata$white[stopdata$race=="White"] <- 1

# model fit
model <- vsearch ~ white + factor(policePrecinct)
fit <- lm(model, stopdata)
summary(fit)
# bootstrapping: normal approach
# set the 'seed' for random numbers (makes the example reproducible)
set.seed(2)
# set number of bootstrap iterations
B <- 50
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)
# draw bootstrap samples, estimate model for each sample
for (i in 1:B) {
  # draw sample of precincts (cluster level)
  precincts_i <- base::sample(precincts, size = 5, replace = TRUE)
  # get observations
  bs_i <-
    lapply(precincts_i, function(x){
      stopdata[stopdata$policePrecinct==x,]})
  bs_i <- rbindlist(bs_i)
  # estimate model and record coefficients
  boot_coefs[i,] <- coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
}

se_boot <- apply(boot_coefs,
                 MARGIN = 2,
                 FUN = sd)
se_boot


# bootstrapping: parallel approaach
# install.packages("doSNOW", "parallel")
# load packages for parallel processing
library(doSNOW)
# set cores for parallel processing
ncores <- parallel::detectCores()
ctemp <- makeCluster(ncores)
registerDoSNOW(ctemp)
# set number of bootstrap iterations
B <- 50
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)

# bootstrapping in parallel
boot_coefs <-
  foreach(i = 1:B, .combine = rbind, .packages="data.table") %dopar% {
    # draw sample of precincts (cluster level)
    precincts_i <- base::sample(precincts, size = 5, replace = TRUE)
    # get observations
    bs_i <- lapply(precincts_i, function(x){
         stopdata[stopdata$policePrecinct==x,])
    }
    bs_i <- rbindlist(bs_i)

    # estimate model and record coefficients
    coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
  }

# be a good citizen and stop the snow clusters
stopCluster(cl = ctemp)
# compute the bootstrapped standard errors
se_boot <- apply(boot_coefs,
                 MARGIN = 2,
                 FUN = sd)
