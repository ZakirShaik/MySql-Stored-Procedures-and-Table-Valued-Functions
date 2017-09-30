/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.4206)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [SSO360WebLog]
GO

/****** Object:  StoredProcedure [dbo].[GetApiLogDetailsByTimeProcedure]    Script Date: 7/06/2017 3:17:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Zakir Shaik>
-- Create date: <July 06 2017>
-- Description:	< This stored procedure returns API LOG file details grouped by minute|fifteen minutes|thirty minutes|hour|day|
--	week|month|year. >
-- =============================================

ALTER PROCEDURE [dbo].[GetApiLogDetailsByTimeProcedure]  
	-- Add the parameters for the stored procedure here
	@APICallId int,
	@startdate date,
	@enddate date,
	@ByTime varchar(30)
AS
BEGIN

	  if(@ByTime = 'Minute')

	  select convert(datetime,convert(char(10),result1.DateItemId) + ' ' + format(result1.HourPart,'00') + ':' + format(result1.MinutePart,'00')) tmsp,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [HourPart] HourPart, [MinutePart] MinutePart from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  CONVERT(date,tmspLocal) date
	  ,DATEPART(Hour, tmspLocal) hour
	  ,DATEPART(MINUTE, tmspLocal) minute
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by CONVERT(date,tmspLocal), DATEPART(Hour, tmspLocal), DATEPART(MINUTE, tmspLocal)) result2
	  ON result1.DateItemId = result2.date and result1.HourPart = result2.hour and result1.MinutePart = result2.minute
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'fifteenMinute')

	  select 
	  convert(datetime,convert(char(10),result1.DateItemId) + ' ' + format(result1.HourPart,'00') + ':' + format(result1.quarterMinute,'00')) tmsp,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [HourPart] HourPart, [quarterMinute] quarterMinute from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  CONVERT(date,tmspLocal) date
	  ,DATEPART(Hour, tmspLocal) hour
	  ,(DATEPART(minute,tmspLocal)/15)*15 quarterMin
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by CONVERT(date,tmspLocal), DATEPART(Hour, tmspLocal), (datepart(minute,tmspLocal)/15)*15) result2
	  ON result1.DateItemId = result2.date and result1.HourPart = result2.hour and result1.quarterMinute = result2.quarterMin
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'thirtyMinute')

	  select 
	  convert(datetime,convert(char(10),result1.DateItemId) + ' ' + format(result1.HourPart,'00') + ':' + format(result1.halfHour,'00')) tmsp,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [HourPart] HourPart, [halfHour] halfHour from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  CONVERT(date,tmspLocal) date
	  ,DATEPART(Hour, tmspLocal) hour
	  ,(DATEPART(minute,tmspLocal)/30)*30 halfhr
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by CONVERT(date,tmspLocal), DATEPART(Hour, tmspLocal), (datepart(minute,tmspLocal)/30)*30) result2
	  ON result1.DateItemId = result2.date and result1.HourPart = result2.hour and result1.halfHour = result2.halfhr
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'Hourly')
	 select convert(datetime,convert(char(10),result1.DateItemId) + ' ' + format(result1.HourPart,'00') + ':00') tmsp,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [HourPart] HourPart from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  CONVERT(date,tmspLocal) date
	  ,DATEPART(Hour, tmspLocal) hour
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by CONVERT(date,tmspLocal), DATEPART(Hour, tmspLocal)) result2
	  ON result1.DateItemId = result2.date and result1.HourPart = result2.hour
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart


	  if(@ByTime = 'Day')
	  select convert(datetime,convert(char(10),result1.DateItemId) + ' ' + '00:00') tmsp,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  CONVERT(date,tmspLocal) date
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by CONVERT(date,tmspLocal)) result2
	  ON result1.DateItemId = result2.date
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'Week')
	  select distinct result1.year Year, result1.weekk Week,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [WeekOfYear] weekk, [YearPart] year from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  datepart(year,tmspLocal) yearr
	  ,DATEPART(Week,tmspLocal) weektmsp
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by DATEPART(year,tmspLocal), DATEPART(Week,tmspLocal)) result2
	  ON result1.year = result2.yearr and result1.weekk = result2.weektmsp
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1,2 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'Month')
	  select distinct result1.year Year, convert(char(3),datename(month,DateItemId),0) Month,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, datepart(month,DateItemId) monthh, [YearPart] year from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  datepart(year,tmspLocal) yearr
	  ,DATEPART(month,tmspLocal) monthtmsp
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by DATEPART(year,tmspLocal), DATEPART(Month,tmspLocal)) result2
	  ON result1.year = result2.yearr and result1.monthh = result2.monthtmsp
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1,2 desc-- result1.DateItemId,result1.HourPart,result1.MinutePart

	  if(@ByTime = 'Year')
	  select distinct result1.year Year,
	  isnull(result2.minimumTime,0) minimumTime, isnull(result2.maximumTime,0) maximumTime, 
	  isnull(result2.averageTime,0) averageTime, isnull(result2.sumTime,0) sumTime, isnull(result2.countTime,0) count
	  from (select distinct [DateItemId] DateItemId, [YearPart] year from DateTimeItem
	  where DateItemID >= @startdate and DateItemId <= @enddate) result1
	  LEFT JOIN 
	  (select 
	  datepart(year,tmspLocal) yearr
	  ,min(milliseconds)*0.001 minimumTime
	  ,max(milliseconds)*0.001 maximumTime
	  ,avg(milliseconds)*0.001 averageTime
	  ,sum(milliseconds)*0.001 sumTime 
	  ,count(milliseconds) countTime from LogInfo li where li.APICallId = @APICallId
	  and convert(date,li.tmspLocal) >= @startdate and CONVERT(date,li.tmspLocal)<=@enddate
	  group by DATEPART(year,tmspLocal)) result2
	  ON result1.year = result2.yearr
	 -- group by result1.DateItemId,result1.HourPart,result1.MinutePart
	  order by 1 -- result1.DateItemId,result1.HourPart,result1.MinutePart

	  /*
	exec GetApiLogDetailsByTimeProcedure 4360, '04/01/2017', '07/04/2017', 'Minute'
	exec GetApiLogDetailsByTimeProcedure 4494, '04/01/2017', '07/04/2017', 'Hourly'
	exec GetApiLogDetailsByTimeProcedure 4494, '04/01/2017', '07/04/2017', 'Day'
	exec GetApiLogDetailsByTimeProcedure 4360, '06/01/2017', '06/04/2017', 'fifteenMinute'
	exec GetApiLogDetailsByTimeProcedure 4360, '06/01/2017', '06/04/2017', 'thirtyMinute'
	exec GetApiLogDetailsByTimeProcedure 4494, '05/01/2017', '06/20/2017', 'Week'
	exec GetApiLogDetailsByTimeProcedure 4494, '05/01/2017', '06/20/2017', 'Month'
	exec GetApiLogDetailsByTimeProcedure 4494, '05/01/2017', '06/20/2017', 'Year'
	*/




END
GO


