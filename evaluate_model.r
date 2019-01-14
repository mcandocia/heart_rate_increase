
params_01 = list(
  hr_const = 129.3,
  hr_temp = -0.76,
  rate_const = 2.108e10,
  rate_temp = -4.28e8,
  factor_const=4.76e10,
  factor_temp=-3.917e8,
  sigma2=11.62
)
predict_01 <- function(data, params=params_01){
  
  
  
  hr_const = params[['hr_const']]
  hr_temp = params[['hr_temp']]
  rate_const = params[['rate_const']]
  rate_temp = params[['rate_temp']]
  factor_const = params[['factor_const']]
  factor_temp = params[['factor_temp']]
  sigma2 = params[['sigma2']]
  rate = rate_const + data$avg_temp * rate_temp;
  
 
  yhat =  with(data, 
               hr_const + avg_temp*hr_temp + 
    (factor_const + factor_temp * avg_temp) * 
    (
      speed_past_0_to_60_seconds * total_time_spent_running_past_0_to_60_seconds/60 * 
        (exp(-rate * 0) - exp(-rate * 60))/rate +
        speed_past_60_to_120_seconds * total_time_spent_running_past_60_to_120_seconds/60 * 
        (exp(-rate * 60) - exp(-rate * 120))/rate +
        speed_past_120_to_180_seconds * total_time_spent_running_past_120_to_180_seconds/60 * 
        (exp(-rate * 120) - exp(-rate * 180))/rate +
        speed_past_180_to_240_seconds * total_time_spent_running_past_180_to_240_seconds/60 * 
        (exp(-rate * 180) - exp(-rate * 240))/rate +
        speed_past_240_to_300_seconds * total_time_spent_running_past_240_to_300_seconds/60 * 
        (exp(-rate * 240) - exp(-rate * 300))/rate +
        speed_past_300_to_360_seconds * total_time_spent_running_past_300_to_360_seconds/60 * 
        (exp(-rate * 300) - exp(-rate * 360))/rate +
        speed_past_360_to_420_seconds * total_time_spent_running_past_360_to_420_seconds/60 * 
        (exp(-rate * 360) - exp(-rate * 420))/rate +
        speed_past_420_to_480_seconds * total_time_spent_running_past_420_to_480_seconds/60 * 
        (exp(-rate * 420) - exp(-rate * 480))/rate +
        speed_past_480_to_540_seconds * total_time_spent_running_past_480_to_540_seconds/60 * 
        (exp(-rate * 480) - exp(-rate * 540))/rate +
        speed_past_540_to_600_seconds * total_time_spent_running_past_540_to_600_seconds/60 * 
        (exp(-rate * 540) - exp(-rate * 600))/rate +
        speed_past_600_to_660_seconds * total_time_spent_running_past_600_to_660_seconds/60 * 
        (exp(-rate * 600) - exp(-rate * 660))/rate +
        speed_past_660_to_720_seconds * total_time_spent_running_past_660_to_720_seconds/60 * 
        (exp(-rate * 660) - exp(-rate * 720))/rate +
        speed_past_720_to_780_seconds * total_time_spent_running_past_720_to_780_seconds/60 * 
        (exp(-rate * 720) - exp(-rate * 780))/rate +
        speed_past_780_to_840_seconds * total_time_spent_running_past_780_to_840_seconds/60 * 
        (exp(-rate * 780) - exp(-rate * 840))/rate +
        speed_past_840_to_900_seconds * total_time_spent_running_past_840_to_900_seconds/60 * 
        (exp(-rate * 840) - exp(-rate * 900))/rate +
        speed_past_900_to_1800_seconds * total_time_spent_running_past_900_to_1800_seconds/900 * 
        (exp(-rate * 900) - exp(-rate * 1800))/rate +
        speed_past_1800_to_3600_seconds * total_time_spent_running_past_1800_to_3600_seconds/1800 * 
        (exp(-rate * 1800) - exp(-rate * 3600))/rate)
  )
  
  
  return(yhat)
}

preds = predict_01(heart)
residuals = preds - heart$heart_rate_stop
(r2 = 1-var(residuals)/var(heart$heart_rate_stop))