with customers as
  (
    select
      start_date,
      end_date
    from
      customers
  ),
  
-- Enumerate days from 0 to 999 so we can get the value of the survival curve for 1,000 days.

day_shift as
  (
      select
        a.i * 100 + b.i * 10 + c.i as day_num
      from
        integers as a
      left join
        integers as b
      on
        1 = 1
      left join
        integers as c
      on
        1 = 1
      where
        a.i * 100 + b.i * 10 + c.i <= 999
  ),
  
-- Calculate the conditional probability that someone who is at risk survived each day

daily_survival as
  (
    select
      d.day_num,
      
      -- Survival today is 'alive' at the end of the day / 'alive' at the start of the day
      -- We can figure out if somebody churned today by adding today's index to their start date. If it matches their end date, they churned today!
      
      cast(sum(case when dateadd(day, d.day_num, c.start_date) = c.end_date then 0 else 1 end) as float) / cast(count(*) as float) as survived_today
    from
      customers as c
    left join
      day_shift as d
    on
      -- This gives us one record per sub per day index on which we've observed them.
      -- We'll can't observe somebody for more days than the number between their start and end dates, or start date and current date (whichever is smaller)
      
      dateadd(day, d.day_num, c.start_date) <= coalesce(c.end_date, current_date)
    group by
      d.day_num
  )
  
-- Calculate the probability that somebody survived UP TO and INCLUDING each day

select
  day_num,
  
  -- Calculate cumulative product using SUM and the product property of logarithms
  
  exp(sum(ln(survived_today)) over (order by day_num rows between unbounded preceding and current row)) as survival
from
  daily_survival
order by
  day_num;