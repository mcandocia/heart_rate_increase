library(plyr)
library(dplyr)
library(rstan)
heart = read.csv('s1_heart_increase.csv') %>% filter(
  !is.na(avg_temp) & !is.na(heart_rate_stop)
)

## IMPACT EXPONENTIATION
# rate and asymptote are functions of 
# temp + INTEGRATE(-s(t)*exp(-RATE*t))
# each difference is integrated to (exp(-RATE * t_0)-exp(-RATE * t_f))/RATE * prop_time
# RATE = b_0 + b_1 * temp
# overall equation is HR_f = b_0 + b_1 * temp + b_2 * f(X, temp, b_3, b_4)

heart_data = list(N=nrow(heart))
for (name in names(heart))
  heart_data[[name]] = heart[,name]

## DISCRETE-DIFFERENCED IMPACT (SHORTER-TERM)

init_00 = list(
  hr_const=80,
  hr_temp=0.8,
  rate_const=1/60,
  rate_temp=1/600,
  factor_const=1,
  factor_temp=0.1,
  sigma2=400
)

fit <- stan(file='heart_rate_increase_01.stan',
            data=heart_data,
            init=function(chain_id) init_00,
            verbose=TRUE,
            chains=1,diagnostic_file='model_00_diagnostic.txt')
