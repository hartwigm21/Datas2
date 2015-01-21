
dbDisconnect(MySQLcon1)
MySQL. <- MySQL()
MySQLcon1 <- dbConnect(MySQL.,user="can't show:)"
PlusCities <- dbGetQuery(MySQLcon1,"select 
r.id ride_id, 
r.provider_id,
r.pickup_now asap,
r.ride_status_code, 
if(ros.id is not null, 'D2D', '') D2D,
(select timestampdiff(second, r.created_at, min(re.event_at))  from ride_events re where re.ride_id = r.id and re.name= 'canceled_with_dispatch_system') rider_c,
(select count(distinct re.id) from ride_events re where re.ride_id = r.id and re.name = 'assigned') assigned_count,
r.pickup_time_local,
count(distinct ro.id) offer_count, 
r.from_latitude latitude,
r.from_longitude longitudee


from 
rides r
left join
ride_offer_strategies ros
on ros.ride_id = r.id  
left join
ride_offers ro
on ro.ride_offer_strategy_id = ros.id
left join
bounce_payments bp
on bp.ride_id = r.id
where                              
r.booking_channel_id in (5,9) and
r.provider_id in (48,11560,11566,11569,11,24,11395,11556,11561,11555,11471,11458,11459,11460,11474,11534,94,98,11490,11573)
and
r.pickup_now = 1 and
r.pickup_time > curdate() - interval 3 day
and ride_status_code in ('completed', 'canceled','missed')
group by r.id, r.provider_id") 


City <- subset(PlusCities, provider_id == "24"  | provider_id == "11460" | provider_id == "11572")
OfferCount <- sum(City$offer_count)
NumOffersPerJob <- OfferCount/nrow(City)

par(mfcol=c(3,1))

#Total Offer Count for City
hist(City$offer_count,xlim = c(0,10),breaks=10,main="City Offer Counts",xlab="Offer Count")
abline(v=median(as.numeric(City$offer_count)),col="red")
abline(v=quantile(as.numeric(City$offer_count),c(.75,.85,.95)),col="blue")

#Offer count for Completed
Completes <-subset(City,ride_status_code == "completed")
hist(Completes$offer_count,xlim=c(0,10),breaks=15,main="Completed Rides - Offer Count",xlab="Offer Count")
abline(v=median(Completes$offer_count),col="red")
abline(v=quantile(Completes$offer_count,c(.75,.85,.95)),col="blue")

#Num offers per Cancel
Cancels <-subset(City,ride_status_code == "canceled")
CancelOfferCount <- sum(Cancels$offer_count)
NumOffersPerCancel <- sum(Cancels$offer_count)/nrow(Cancels)

#Offer Count for City Cancels
hist(Cancels$offer_count,xlim = c(0,10),breaks = 10,main="Canceled Rides - Offer Count",xlab="Offer Count")
abline(v=median(as.numeric(Cancels$offer_count)),col="red")
abline(v=quantile(as.numeric(Cancels$offer_count),c(.75,.85,.95)),col="blue")

par(mfcol=c(1,1))
#Time to User Cancel
hist(as.numeric(Cancels$rider_c),main="Time to User Cancel City",xlab="Time to Cancel",xlim = c(0,600),breaks=100,na.rm=TRUE)
abline(v=median(as.numeric(Cancels$rider_c),na.rm=TRUE),col="red",)
abline(v=quantile(Cancels$rider_c,c(.75,.85,.9,.95),na.rm=TRUE),col="blue")

#Offer Count versus Time to Cancel
plot(as.numeric(Cancels$rider_c) ~ Cancels$offer_count, xlim=c(0,10),ylim=c(0,2000),pch=20,col=rgb(0,0,0,.5),main="Offer Count vs. Time to Cancel - Broadway",ylab="Time to Cancel",xlab="Offer Count")
abline(lm(Cancels$rider_c~Cancels$offer_count), col="red")

dbDisconnect(MySQLcon1)
MySQLcon1 <- dbConnect(MySQL.,user="can't show")

PlusAssign <- dbGetQuery(MySQLcon1, "select
                         time_to_sec(case
                         when timediff(rides.pickup_time,rides.created_at) < '00:04:00' then
                         timediff(
                         max(
                         case 
                         when ride_events.name = 'assigned' then event_at 
                         else null 
                         END
                         ), 
                         case 
                         when timediff(rides.pickup_time, rides.created_at) < '00:04:00' then rides.created_at
                         else rides.pickup_time
                         end    
                         )
                         else null
                         END) timediff, 
                         rides.id,
                         providers.name,
                         rides.pickup_time_local    													
                         
                         from ride_events
                         join rides on ride_events.ride_id = rides.id
                         join providers on rides.provider_id = providers.id
                         join ride_offer_strategies ros on ros.ride_id = rides.id
                         where rides.pickup_time > curdate() - interval 3 day and providers.virtual = 0
                         group by rides.id
                         having timediff is not null")


fleetAssigns <- subset(PlusAssign, name == "fleet name")

# Time to Assign
hist(fleetAssigns$timediff, xlim = c(0,350),breaks = 1500,main="Fleet Cab Time to Assign",xlab="Time in Seconds")
abline(v=median(fleetAssigns$timediff),col="red")
abline(v=quantile(fleetAssigns$timediff,c(.75)),col="blue",)
abline(v=quantile(fleetAssigns$time,c(.95)),col="orange",)

plot(density(fleetAssigns$timediff),xlim=c(0,600),main="Fleet Cab Time to Assign")
