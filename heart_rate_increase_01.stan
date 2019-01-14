data {
  int<lower=0> N;
  vector[N] heart_rate_stop;
  vector[N] avg_temp;
  
  vector[N] speed_past_0_to_60_seconds;
  vector[N] speed_past_60_to_120_seconds;
  vector[N] speed_past_120_to_180_seconds;
  vector[N] speed_past_180_to_240_seconds;
  vector[N] speed_past_240_to_300_seconds;
  vector[N] speed_past_300_to_360_seconds;
  vector[N] speed_past_360_to_420_seconds;
  vector[N] speed_past_420_to_480_seconds;
  vector[N] speed_past_480_to_540_seconds;
  vector[N] speed_past_540_to_600_seconds;
  vector[N] speed_past_600_to_660_seconds;
  vector[N] speed_past_660_to_720_seconds;
  vector[N] speed_past_720_to_780_seconds;
  vector[N] speed_past_780_to_840_seconds;
  vector[N] speed_past_840_to_900_seconds;
  vector[N] speed_past_900_to_1800_seconds;
  vector[N] speed_past_1800_to_3600_seconds;
  
 vector[N] total_time_spent_running_past_0_to_60_seconds;
 vector[N] total_time_spent_running_past_60_to_120_seconds;
 vector[N] total_time_spent_running_past_120_to_180_seconds;
 vector[N] total_time_spent_running_past_180_to_240_seconds;
 vector[N] total_time_spent_running_past_240_to_300_seconds;
 vector[N] total_time_spent_running_past_300_to_360_seconds;
 vector[N] total_time_spent_running_past_360_to_420_seconds;
 vector[N] total_time_spent_running_past_420_to_480_seconds;
 vector[N] total_time_spent_running_past_480_to_540_seconds;
 vector[N] total_time_spent_running_past_540_to_600_seconds;
 vector[N] total_time_spent_running_past_600_to_660_seconds;
 vector[N] total_time_spent_running_past_660_to_720_seconds;
 vector[N] total_time_spent_running_past_720_to_780_seconds;
 vector[N] total_time_spent_running_past_780_to_840_seconds;
 vector[N] total_time_spent_running_past_840_to_900_seconds;
 vector[N] total_time_spent_running_past_900_to_1800_seconds;
 vector[N] total_time_spent_running_past_1800_to_3600_seconds;
  
}

parameters {
  real hr_const;
  real hr_temp;
  
  real rate_const;
  real rate_temp;
  
  real factor_const;
  real factor_temp;
  
  real<lower=0> sigma2;
}

model{
  vector[N] rate;
  vector[N] yhat;
  
  for (n in 1:N){
    rate[n] = rate_const + avg_temp[n] * rate_temp;
    
    yhat[n] = hr_const + avg_temp[n]*hr_temp + 
    (factor_const + factor_temp * avg_temp[n]) * 
    (
        speed_past_0_to_60_seconds[n] * total_time_spent_running_past_0_to_60_seconds[n]/60 * 
         (exp(-rate[n] * 0) - exp(-rate[n] * 60))/rate[n] +
        speed_past_60_to_120_seconds[n] * total_time_spent_running_past_60_to_120_seconds[n]/60 * 
         (exp(-rate[n] * 60) - exp(-rate[n] * 120))/rate[n] +
        speed_past_120_to_180_seconds[n] * total_time_spent_running_past_120_to_180_seconds[n]/60 * 
         (exp(-rate[n] * 120) - exp(-rate[n] * 180))/rate[n] +
        speed_past_180_to_240_seconds[n] * total_time_spent_running_past_180_to_240_seconds[n]/60 * 
         (exp(-rate[n] * 180) - exp(-rate[n] * 240))/rate[n] +
        speed_past_240_to_300_seconds[n] * total_time_spent_running_past_240_to_300_seconds[n]/60 * 
         (exp(-rate[n] * 240) - exp(-rate[n] * 300))/rate[n] +
        speed_past_300_to_360_seconds[n] * total_time_spent_running_past_300_to_360_seconds[n]/60 * 
         (exp(-rate[n] * 300) - exp(-rate[n] * 360))/rate[n] +
        speed_past_360_to_420_seconds[n] * total_time_spent_running_past_360_to_420_seconds[n]/60 * 
         (exp(-rate[n] * 360) - exp(-rate[n] * 420))/rate[n] +
        speed_past_420_to_480_seconds[n] * total_time_spent_running_past_420_to_480_seconds[n]/60 * 
         (exp(-rate[n] * 420) - exp(-rate[n] * 480))/rate[n] +
        speed_past_480_to_540_seconds[n] * total_time_spent_running_past_480_to_540_seconds[n]/60 * 
         (exp(-rate[n] * 480) - exp(-rate[n] * 540))/rate[n] +
        speed_past_540_to_600_seconds[n] * total_time_spent_running_past_540_to_600_seconds[n]/60 * 
         (exp(-rate[n] * 540) - exp(-rate[n] * 600))/rate[n] +
        speed_past_600_to_660_seconds[n] * total_time_spent_running_past_600_to_660_seconds[n]/60 * 
         (exp(-rate[n] * 600) - exp(-rate[n] * 660))/rate[n] +
        speed_past_660_to_720_seconds[n] * total_time_spent_running_past_660_to_720_seconds[n]/60 * 
         (exp(-rate[n] * 660) - exp(-rate[n] * 720))/rate[n] +
        speed_past_720_to_780_seconds[n] * total_time_spent_running_past_720_to_780_seconds[n]/60 * 
         (exp(-rate[n] * 720) - exp(-rate[n] * 780))/rate[n] +
        speed_past_780_to_840_seconds[n] * total_time_spent_running_past_780_to_840_seconds[n]/60 * 
         (exp(-rate[n] * 780) - exp(-rate[n] * 840))/rate[n] +
        speed_past_840_to_900_seconds[n] * total_time_spent_running_past_840_to_900_seconds[n]/60 * 
         (exp(-rate[n] * 840) - exp(-rate[n] * 900))/rate[n] +
        speed_past_900_to_1800_seconds[n] * total_time_spent_running_past_900_to_1800_seconds[n]/900 * 
         (exp(-rate[n] * 900) - exp(-rate[n] * 1800))/rate[n] +
        speed_past_1800_to_3600_seconds[n] * total_time_spent_running_past_1800_to_3600_seconds[n]/1800 * 
         (exp(-rate[n] * 1800) - exp(-rate[n] * 3600))/rate[n]);
    //yhat[n] = undefined;
  }
  heart_rate_stop ~ normal(yhat, sigma2);
}
