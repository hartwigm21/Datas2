
SET @@SESSION.sql_mode = "ONLY_FULL_GROUP_BY";
-- -----

SET @end_date_exclusive_local = curdate(); 
SET @start_date_local = greatest(curdate() - interval 14 day, '2014-04-15'); 
-- select @start_date_local, @end_date_exclusive_local;
-- -----


select
	date(RideOffers_CreatedAtLocal)																as LocalDate,
	dayname(RideOffers_CreatedAtLocal)															as Weekday,

	count(*) 																					as 'D2D Offers',
	
	count(if(!PfEventFilterPass, RideOfferID,null)) 											as 'Num D2D Offers Failing One-Offer-And-One-Offer-Response Filter',
	concat(round(
		avg(!PfEventFilterPass)
		*100,2),'%') 																			as 'Pct D2D Offers Failing One-Offer-And-One-Offer-Response Filter',

	count(if(NumPfOffers=1 and NumPfOfferResponses=0, RideOfferID,null)) 						as 'Num D2D Offers w 1 Offer No Offer Response',
	concat(round(
		avg(if(NumPfOffers=1 and NumPfOfferResponses=0,1,0))
		*100,2),'%') 																			as 'Pct D2D Offers w 1 Offer No Offer Response',
	concat(round(
		sum(if(NumPfOffers=1 and NumPfOfferResponses=0,1,0))/sum(!PfEventFilterPass)
		*100,2),'%') 																			as 'Proportion of D2D Offers Failing Filter that are 1 Offer 0 OfferResponse',
	
	-- sum(PFE_MeterOn) 																			as 'D2D Offers w >=1 PF Meter On / Load event(s)',
	count(if(NumPfOffers=1 and NumPfOfferResponses=0 and PFE_MeterOn, RideOfferID,null)) 		as 'Num D2D Offers w 1 Offer, No Offer Response, but a PF MeterOn/Load',
	concat(round(
		avg(if(NumPfOffers=1 and NumPfOfferResponses=0 and PFE_MeterOn,1,0))
		*100,2),'%')																			as 'Pct D2D Offers w 1 Offer, No Offer Response, but a PF MeterOn/Load'

from
(
	select
		ros.ride_id as TM_RideID,
		ro.id as RideOfferID,
		ro.status,
		group_concat(distinct date(convert_tz(ro.created_at,'GMT', 'America/Chicago'))) as RideOffers_Date_CreatedAtLocal,
		group_concat(distinct hour(convert_tz(ro.created_at,'GMT', 'America/Chicago'))) as RideOffers_Hour_CreatedAtLocal,
		group_concat(distinct convert_tz(ro.created_at,'GMT', 'America/Chicago')) as RideOffers_CreatedAtLocal,
		
		-- group_concat(distinct ro.created_at) as RideOfferCreatedAt,
		group_concat(distinct date(if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.event_at_local,null))) as PathFinder_Date_OfferAtLocal,
		group_concat(distinct if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.event_at_local,null)) as PathFinder_OfferAtLocal,

		count(distinct dds_pathfinder_events.driver_id) as DriverCount,
		group_concat(distinct dds_pathfinder_events.driver_id) as PfDriverId,
		group_concat(distinct dds_pathfinder_events.driver_name) as PfDriverName,

		count(distinct if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.id,null)) as PathFinderOffers,
        group_concat(distinct if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.id,null)) as PathFinderOfferEventIDs,
		group_concat(distinct dds_pathfinder_events.provider_ride_id) as ProviderRideIds,

		if(
			count(distinct if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.id,null)) =1 
			AND count(distinct if(dds_pathfinder_event_types.description in ("Accept","Ride Manual Reject","Ride Auto-Reject"),dds_pathfinder_events.id,null)) =1
			,1,0
			) as PfEventFilterPass,
		count(distinct if(dds_pathfinder_event_types.description = "Ride Offer",dds_pathfinder_events.id,null)) as NumPfOffers,
		count(distinct if(dds_pathfinder_event_types.description in ("Accept","Ride Manual Reject","Ride Auto-Reject"),dds_pathfinder_events.id,null)) as NumPfOfferResponses,
		

		count(distinct if(dds_pathfinder_event_types.description in ("Accept","Ride Manual Reject","Ride Auto-Reject"), dds_pathfinder_event_types.description,null)) as PFE_NumResponseTypes, 
		count(distinct if(dds_pathfinder_event_types.description in ("Accept","Ride Manual Reject"), dds_pathfinder_event_types.description,null)) as PFE_NumDriverInitiatedResponseTypes, 
		max(if(dds_pathfinder_event_types.description = "Ride Offer",1,0)) PFE_Offer,
		max(if(dds_pathfinder_event_types.description = "Accept",1,0)) PFE_Accept,
		max(if(dds_pathfinder_event_types.description = "Ride Manual Reject",1,0)) PFE_RideManualReject,
		max(if(dds_pathfinder_event_types.description = "Ride Auto-Reject",1,0)) PFE_RideAutoReject,

		max(if(dds_pathfinder_event_types.description = 'Meter On/Load',1,0)) PFE_MeterOn,
		
		
		group_concat(distinct drivers_fleets.driver_code) as driver_code, 
		group_concat(distinct drivers.first_name) as first_name, 
		group_concat(distinct drivers.last_name) as last_name, 
		group_concat(distinct drivers.email) as email, 
		group_concat(distinct drivers.cell_number) as cell_number, 
		group_concat(distinct drivers.account_state) as account_state, 
		group_concat(distinct drivers.hex_id) as hex_id,

		group_concat(distinct rides.driver_id) as RideDriverID,
		group_concat(distinct rides.driver_name) as RideDriverName,

		if(ro.status = "accepted",1,0) as `OfferAccepted?`,
		if(group_concat(distinct dds_pathfinder_events.driver_name) = group_concat(distinct rides.driver_name),1,0) as `PfEventsToRidesDriverNameMatch?`,
		
		if(
			max(case when ride_events.name = 'canceled_with_dispatch_system' then 1 else 0 end) >= 1
            and group_concat(distinct rides.ride_status_code) <> 'completed' 
            ,1,0
			) as rider_cancel_no_resurrect_flag,
          
        max(if(ride_events.name = 'no_show',1,0)) as no_show_event_flag,
		if(group_concat(distinct rides.ride_status_code) = "missed",1,0) as RscMissed,
		if(max(if(ride_events.name = 'no_show',1,0)) and group_concat(distinct rides.ride_status_code) = "missed",1,0) as NoShow,

		group_concat(distinct rides.ride_status_code) as RideRSC,
		group_concat(distinct rides.ride_status_code) = 'completed' as test,

		sum(case when ride_events.name = ('rapid_meter_detected') then 1 else 0 end) as `RapidMeter?`,
		sum(case when ride_events.name in ('likely_different_pickup') then 1 else 0 end) as `LikelyDifferentPickup?`,

		if(
			group_concat(distinct rides.ride_status_code) = 'completed' 
			and max(if(ride_events.name = 'rapid_meter_detected',1,0)) = 0  
			and max(if(ride_events.name = 'likely_different_pickup',1,0)) = 0
			,1,0
			)
			as successful_pickup_flag

	from 
		rc_production.ride_offers ro
		
		left outer join rc_production.ride_offer_strategies ros
		on ro.ride_offer_strategy_id = ros.id

		left outer join rc_fleet_production.dds_pathfinder_events force index (index_dds_pathfinder_events_on_event_at_local)
		on dds_pathfinder_events.ride_offer_id = ro.id 
		and dds_pathfinder_events.dds_pathfinder_event_type_id in (1,19,20,26,2) 

		left outer join rc_fleet_production.dds_pathfinder_event_types
		on dds_pathfinder_events.dds_pathfinder_event_type_id = dds_pathfinder_event_types.id

		left outer join fleet_production.drivers_fleets
		on dds_pathfinder_events.driver_id = fleet_production.drivers_fleets.driver_code
		and fleet_production.drivers_fleets.fleet_id =22

		left outer join fleet_production.drivers
		on drivers_fleets.driver_id = drivers.user_id

		left outer join rc_production.rides 
		on ros.ride_id = rides.id

		left outer join rc_production.ride_events
		on rides.id = ride_events.ride_id 
		and ride_events.name <> 'position'
		
	where
		dds_pathfinder_events.event_at_local >= @start_date_local and dds_pathfinder_events.event_at_local < @end_date_exclusive_local  -- switch to filter on ride_offers.created_at?  this will drop Offers not having Offer PF event...but would get dropped anyway b/c the no Driver
		and ro.provider_id = 11471

	group by
		ros.ride_id,
		ro.id,
		ro.status
	) OfferLevel
group by
	date(RideOffers_CreatedAtLocal),
	dayname(RideOffers_CreatedAtLocal)