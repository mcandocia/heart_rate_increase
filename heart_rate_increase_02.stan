data {
  int<lower=0> N;
  vector[N] heart_rate_stop;
  vector[N] avg_temp;
  
  vector[N] speed_past_0_to_60_seconds;
  
 vector[N] total_time_spent_running_past_0_to_60_seconds;

}

parameters {
 real<lower=45> hr_min_const;
 real<upper=190> hr_max_const;
 
 real<lower=0> hr_min_temp;
 
 real<lower=0> rate_temp;
 real<lower=0> rate_speed;
 real<lower=0> rate_temp_speed;
 real rate_idle;
  
  real<lower=0> sigma2;
}

model{
  vector[N] rate;
  vector[N] yhat;
  vector[N] hr_min;
  
  for (n in 1:N){
    rate[n] = avg_temp[n] * rate_temp + speed_past_0_to_60_seconds[n] * total_time_spent_running_past_0_to_60_seconds[n] * rate_speed + avg_temp[n] *  speed_past_0_to_60_seconds[n] * total_time_spent_running_past_0_to_60_seconds[n] * rate_temp_speed /60 + (60-total_time_spent_running_past_0_to_60_seconds[n]) * rate_idle;
    hr_min[n] = hr_min_const + hr_min_temp * avg_temp[n];
    yhat[n] = hr_min[n] + (hr_max_const - hr_min[n]) * (1-exp(-rate[n]));
  }
  heart_rate_stop ~ normal(yhat, sigma2);
}
