data {
  int<lower=0> N;
  int<lower=0> n_intervals;
  int<lower=0> n_run_groups;
  
  vector[N] heart_rate_stop;
  vector[N] avg_temp;
  int run_group[N];
  
  row_vector[n_intervals] duration_lower;
  row_vector[n_intervals] duration_upper;
  row_vector[n_intervals] interval_size;
  
  matrix[N, n_intervals] total_time_spent_running_matrix;
  matrix[N, n_intervals] speed_matrix;
  
}

parameters {
  real<lower=45> hr_min_const;
  real<upper=190> hr_max_const;
  
  real<lower=0, upper=2> hr_min_temp;
  
  real decay_rate_temp;
  real<lower=0> decay_rate_const;
  
  real impact_temp;
  real<lower=0> impact_speed;
  real impact_temp_speed;
  
  vector[n_run_groups] run_group_effect;
  
  real<lower=0> sigma2;
  
  real<lower=0> run_group_sigma2;
}

model{
  vector[N] impact;
  vector[N] decay_rate;
  vector[N] yhat;
  vector[N] hr_min;
  
  // sensible priors to restrict blowing up
  decay_rate_const ~ exponential(10);
  decay_rate_temp ~ normal(0,1);
  impact_speed ~ exponential(0.01);
  impact_temp ~ normal(0,5);
  impact_temp_speed ~ normal(0,1);
  sigma2 ~ exponential(1./20);
  run_group_sigma2 ~ exponential(1./3);
  
  run_group_effect ~ normal(0, run_group_sigma2);
  
  for (n in 1:N){
    decay_rate[n] = decay_rate_temp * avg_temp[n] + decay_rate_const + run_group_effect[run_group[n]];
    // decay rate cannot be allowed to be negative
    decay_rate[n] = fmax(0.0, decay_rate[n]);
    
    impact[n] = sum(
      avg_temp[n] * impact_temp + (impact_speed*speed_matrix[n].*total_time_spent_running_matrix[n]./interval_size + impact_temp_speed * speed_matrix[n]*avg_temp[n] .* total_time_spent_running_matrix[n]./interval_size) .* (exp(-duration_lower * decay_rate[n]) - exp(-duration_upper * decay_rate[n]))
    );
    
    // attenuate if there are problems to allow smoother ascent
    impact[n] = fmax(-1/(1+abs(impact[n])), impact[n]);
    
   
    hr_min[n] = hr_min_const + hr_min_temp * avg_temp[n];
    yhat[n] = hr_min[n] + (hr_max_const - hr_min[n]) * (1-exp(-impact[n]));
  }
  heart_rate_stop ~ normal(yhat, sigma2);
}


