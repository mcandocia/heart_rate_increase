library(plyr)
library(dplyr)
library(lubridate)

# determine all running events

FILE_DIRECTORY = 'D://workspace/fit_conversion/subject_data/maxcan/fit_csv'

INCONSISTENCY_ACTION = 'skip'# or 'stop'

files = dir(FILE_DIRECTORY)

files = files[grepl('running_.*[0-9]\\.csv', files)]

dates = sapply(
  files,
  function(x){
    gsub('running_(.+?)\\.csv','\\1',x) # %>% gsub(pattern='_', replacement=' ')
  }
)

load_run_data <- function(date){
  filename = paste0(FILE_DIRECTORY, '/running_',date, '.csv')
  # if I were in multiple time zones, I would extract the time zone based on the UTC offset
  # looking at OlsonNames(), you can set this to 'Etc/GMT-X' or something else if needed
  data = read.csv(filename) %>% mutate(timestamp=as_datetime(timestamp, tz='US/Central'))
  return(data)
}


load_start_data <- function(date){
  filename = paste0(FILE_DIRECTORY, '/running_',date, '_starts.csv')
  # see comment in above function for dealing with multiple time zones
  data = read.csv(filename) %>% mutate(timestamp=as_datetime(timestamp, tz='US/Central'))
  return(data)
}


process_start_data <- function(data){
  events = list()
  for (i in seq(1, nrow(data)-1, 2)){
    if (data[i, 'event_type'] != 'start' | data[i+1, 'event_type'] != 'stop_all'){
      msg = sprintf('Check rows %d and %d of data', i, i+1)
      if (INCONSISTENCY_ACTION=='skip'){
        print(msg)
        break
      }
      else{
        stop(msg)
      }
      # this is for workouts with auto-timers
    }
    events[[(i+1)/2]] = data.frame(timestamp_start=data[i, 'timestamp'], 
                               timestamp_stop=data[i+1, 'timestamp'])
  }
  df = bind_rows(events)
  
  if (nrow(df) > 1)
    df = df %>% mutate(time_since_last_stop = c(NA, as.numeric(difftime(tail(timestamp_stop, -1),head(timestamp_start, -1), units='secs'))))
  else
    df$time_since_last_stop = NA
  
  return(df)
}


combine_start_and_run_data <- function(start_data, run_data){
  # join by timestamp
  # get HR, distance, temperature, timestamp, duration of run, cadence, elevation, and speed of 
  bound_data = (run_data %>% transmute(timestamp_start=timestamp, altitude_start=altitude, 
                                       distance_start=distance, speed_start=speed, 
                                       heart_rate_start=heart_rate, cadence_start=cadence)) %>% 
    inner_join(start_data, by='timestamp_start') %>%
    inner_join(run_data %>%  transmute(timestamp_stop=timestamp, altitude_stop=altitude, distance_stop=distance, speed_stop=speed, heart_rate_stop=heart_rate, cadence_stop=cadence), by='timestamp_stop') %>%
    mutate(rest_time = as.numeric(difftime(timestamp_start,timestamp_stop, units='secs')))
  
  # calculate average temperature and median lat/lon of run
  if (nrow(bound_data)==0){
    print(paste0('warning: no rows found for run data with start time of ', 
                 as.character(run_data$timestamp[1]), '...returning NULL'))
    return(NULL)
  }
  
  avg_temp = median(run_data$temperature, na.rm=TRUE)
  avg_lat = median(run_data$position_lat, na.rm=TRUE)
  avg_long = median(run_data$position_long, na.rm=TRUE)
  avg_alt = mean(run_data$altitude, na.rm=TRUE)
  # not to be used in calculations, only viz
  avg_hr = mean(run_data$heart_rate, na.rm=TRUE)
  avg_speed = mean(run_data$speed)
  total_dist = tail(run_data$distance, 1)
  
  # get HR, elevation change & average speed in (a) past minute (b) past 3 minutes (c) past 15 minutes; assume 0 for any gaps in time
  calculate_average_for_past_time <- function(data, timestamp, duration_second, variable, FUN=mean){
    # total time calculation
    if (variable=='total_time_spent_running'){
      # should not use just run data, since measurements are sometimes not every second while recording
      bound_data = FUN()
      beginning_time= timestamp - duration_second
      t1 = data$timestamp[1]
      
      # determine which time ranges are valid start/end times
      valid_start_rows = which(bound_data$timestamp_start >= beginning_time & 
                                 bound_data$timestamp_start< timestamp)
      valid_stop_rows = which(bound_data$timestamp_stop >= beginning_time & 
                                bound_data$timestamp_stop <= timestamp)
      
      total_time=0
      
      
      # start time contained within range
      for (row in valid_stop_rows){
        # AND start time
        if ((row) %in% valid_start_rows){
          total_time = total_time + as.numeric(difftime(bound_data[row,'timestamp_stop'], 
                                                        bound_data[row, 'timestamp_start'], 
                                                        units='secs'))
        }
        # BUT NOT start time
        else{
          total_time = total_time + as.numeric(difftime(bound_data[row, 'timestamp_stop'], 
                                                        beginning_time,
                                                        units='secs'))
        }
      }

      return(total_time)
    }
    # regular calculation
    applicable_data = data[data$timestamp<=timestamp & data$timestamp > timestamp - duration, 
                           variable, drop=T]
    return(FUN(applicable_data))
  }
  
  durations = c(seq(60,900, 60), 1800, 3600)
  
  for (variable in c('altitude','speed','heart_rate', 'total_time_spent_running')){
    for (duration in durations){
      new_varname = sprintf('%s_past_%d_seconds', variable, duration)
      bound_data[,new_varname] = -9999
      for (i in 1:nrow(bound_data)){
        if (variable=='altitude'){
          fn = function(x, na.rm=TRUE) {x=na.omit(x); tail(x, 1)-head(x, 1)}
        }
        else if (variable=='total_time_spent_running'){
          fn = function() return(bound_data)
        }
        else{
          fn = mean
        }
        bound_data[i, new_varname] = calculate_average_for_past_time(
          run_data, bound_data[i, 'timestamp_stop'], duration, variable, FUN=fn)
      }
    }
  }
  
  #calculate differences in durations
  for (variable in c('altitude','speed','heart_rate', 'total_time_spent_running')){
    for (i in 1:length(durations)){
      varname1 = sprintf('%s_past_%d_seconds', variable, durations[i])
      if (i==1){
        new_varname = sprintf('%s_past_%d_to_%d_seconds', variable, 0, durations[i])
        bound_data[,new_varname] = bound_data[,varname1]
      }
      else{
        varname2 = sprintf('%s_past_%d_seconds', variable, durations[i-1])
        new_varname = sprintf('%s_past_%d_to_%d_seconds', variable, durations[i-1], durations[i])
        # alt,  time spent running can be diffed directly
        # speed, heart rate should be overall/time diff
        # or (av2 * t2 - av1*t1)/(t2-t1)
        if (!variable %in% c('altitude','total_time_spent_running')){
          interval_diff = durations[i] - durations[i-1]
          bound_data[,new_varname] = (bound_data[,varname1] * durations[i] - 
                                        bound_data[,varname2] * durations[i-1])/interval_diff
        }
        else{
          bound_data[,new_varname] = bound_data[,varname1] - bound_data[,varname2]
        }
      }
      
    }
  }
  # get time since start of run and total time running
  #print(bound_data$timestamp_stop)
  #print(run_data$timestamp[1])
  #print( as.numeric(bound_data$timestamp_stop - run_data$timestamp[1]))
  bound_data$time_elapsed = as.numeric(difftime(bound_data$timestamp_stop,run_data$timestamp[1], 
                                                units='secs'))
  bound_data$total_running_time = bound_data$time_elapsed - c(0, head(cumsum(bound_data$rest_time), -1))
  
  # other variables that may or may not be useful
  bound_data$avg_temp = avg_temp
  bound_data$avg_lat = avg_lat
  bound_data$avg_long = avg_long
  bound_data$avg_alt=avg_alt
  bound_data$avg_hr = avg_hr
  bound_data$avg_speed = avg_speed
  bound_data$total_dist = total_dist
  return(bound_data)
}


master_run_list = list()
master_combined_list = list()

event_id = 0
for (date in dates){
  print(event_id)
  event_id = event_id + 1
  pretty_date = gsub('_',' ',date)
  start_data = load_start_data(date)
  if (nrow(start_data) < 2)
    next
  processed_start_data = process_start_data(start_data) %>% mutate(datetime_ts=date)
  run_data = load_run_data(date) %>% mutate(datetime_ts=date)
  master_run_list[[date]] = run_data
  
  combined_data = combine_start_and_run_data(processed_start_data, run_data)
  combined_data$event_id = event_id
  master_combined_list[[date]] = combined_data
}

heart_data = bind_rows(master_combined_list)
heart_data$time_from_start_to_stop = as.numeric(
  difftime(heart_data$timestamp_stop, heart_data$timestamp_start, units='secs')
)

important_columns =  c('event_id','rest_time', 'timestamp_stop','timestamp_start','heart_rate_stop','heart_rate_start',
                       'time_elapsed','total_running_time', 'time_since_last_stop', 'time_from_start_to_stop')

secondary_columns = names(heart_data)[!names(heart_data) %in% important_columns]
heart_data = heart_data[c(important_columns, secondary_columns)]
names(heart_data) = gsub('altitude_past','altitude_change_past', names(heart_data))



write.csv(heart_data, file='s1_heart_increase.csv', row.names=FALSE)
