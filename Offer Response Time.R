

library(sm)

MySQL. <- MySQL()
dbDisconnect(MySQLcon1)
MySQLcon1 <- dbConnect(MySQL.,user="cant show")
offers <- dbGetQuery(MySQLcon1,"select ride_offers.*, time_zone_olsons.name, convert_tz(ride_offers.created_at, 'GMT',time_zone_olsons.name) created_at_local, providers.name

from ride_offers 
left outer join providers
on ride_offers.provider_id = providers.id

left outer join time_zone_olsons
on providers.time_zone_olson_id = time_zone_olsons.id

where status in ('accepted','rejected','expired', 'accepted_late','failed') and ride_offers.created_at between '2014-12-15' and '2014-12-17'
and provider_id in (24)
")

offers$created_at <- as.POSIXct(offers$created_at, tz = 'gmt')
offers$updated_at <- as.POSIXct(offers$updated_at, tz = 'gmt')

offers$seconds.to.response <- as.numeric(difftime(offers$updated_at,offers$created_at,units = 'secs'))
offers <- offers[offers$seconds.to.response < 200,]

hist(offers$seconds.to.response)
sm.density.compare(offers$seconds.to.response, factor(offers$status),h = 10,xlab='seconds to response',xlim=c(0,150))
title(main="Offer Response Time")
colfill<-c(2:(2+length(levels(factor(offers$status))))) 
legend('topright', levels(factor(offers$status)), fill=colfill)

par(mfcol=c(3,2))
hist(offers$seconds.to.response[offers$status == 'accepted'],xlim=c(0,100),breaks=100)
hist(offers$seconds.to.response[offers$status == 'rejected'],xlim=c(0,100),breaks=100)
hist(offers$seconds.to.response[offers$status == 'expired'],xlim=c(0,100),breaks=100)
hist(offers$seconds.to.response[offers$status == 'accepted_late'],xlim=c(0,55),breaks=100)

par(mfcol=c(1,1))

hist(offers$created_at,breaks='days')
mean.response.time.by.day <- tapply(offers$seconds.to.response,cut(offers$created_at,breaks = 'days'),mean)
plot(as.POSIXct(as.character(names(mean.response.time.by.day)),tz='gmt'),mean.response.time.by.day,pch=20)

mean.response.time.by.day.and.status <- tapply(offers$seconds.to.response,INDEX = list(days = cut(offers$created_at,breaks = 'days'),status = offers$status),mean)

plot(as.POSIXct(as.character(names(mean.response.time.by.day.and.status[,'expired'])),tz='gmt'),mean.response.time.by.day.and.status[,'expired'],pch=20,ylim=c(0,80),xlab='date',ylab='mean seconds to response',main='mean seconds to response by offer status - LA')
points(as.POSIXct(as.character(names(mean.response.time.by.day.and.status[,'accepted'])),tz='gmt'),mean.response.time.by.day.and.status[,'accepted'],pch=20,col='green')
points(as.POSIXct(as.character(names(mean.response.time.by.day.and.status[,'rejected'])),tz='gmt'),mean.response.time.by.day.and.status[,'rejected'],pch=20,col='red')
legend('topright', c('accepted','expired','rejected'), fill=c('green','black','red'))



#LA offer time was changed around this date
recent.offers <- offers[offers$created_at > as.POSIXct("2014-06-30"),]

par(mfcol=c(3,1))
hist(recent.offers$seconds.to.response[recent.offers$status == 'accepted'],xlim=c(0,100),breaks=100,main = "",xlab='seconds until response')
abline(v=mean(recent.offers$seconds.to.response[recent.offers$status == 'accepted']),col='red',lwd=2)
abline(v=median(recent.offers$seconds.to.response[recent.offers$status == 'accepted']),col='blue',lwd=2)
abline(v=quantile(recent.offers$seconds.to.response[recent.offers$status == 'accepted'],probs = c(0.75,0.95,0.99)),col='orange',lwd=2)


quantile(recent.offers$seconds.to.response[recent.offers$status == 'accepted'],probs = c(0.9,0.95,0.97,0.99))

hist(recent.offers$seconds.to.response[recent.offers$status == 'rejected'],xlim=c(0,100),breaks=100,main = "",xlab='seconds until response')
abline(v=mean(recent.offers$seconds.to.response[recent.offers$status == 'rejected']),col='red',lwd=2)
abline(v=median(recent.offers$seconds.to.response[recent.offers$status == 'rejected']),col='blue',lwd=2)
abline(v=quantile(recent.offers$seconds.to.response[recent.offers$status == 'rejected'],probs = c(0.75,0.95,.99)),col='orange',lwd=2)

par(mfcol=c(1,1))
hist(recent.offers$seconds.to.response[recent.offers$status == 'expired'],xlim=c(0,85),breaks=75,main = "",xlab='seconds until response')
#abline(v=mean(recent.offers$seconds.to.response[recent.offers$status == 'expired']),col='red',lwd=2)
#abline(v=median(recent.offers$seconds.to.response[recent.offers$status == 'expired']),col='blue',lwd=2)
#abline(v=quantile(recent.offers$seconds.to.response[recent.offers$status == 'expired'],probs = c(0.75,0.95,0.99)),col='orange',lwd=2)


