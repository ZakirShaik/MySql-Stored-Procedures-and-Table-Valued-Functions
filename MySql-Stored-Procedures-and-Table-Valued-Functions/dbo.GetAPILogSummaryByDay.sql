/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.4206)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [SSO360]
GO

/****** Object:  UserDefinedFunction [dbo].[GetAPILogSummaryByDay]    Script Date: 7/02/2017 3:28:10 PM ******/
--<Author: Zakir Shaik>
-- Description: This table valued function will return API Log summary details of log files by each day.
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER FUNCTION [dbo].[GetAPILogSummaryByDay] 
(
@AppObjectId int,
@startdate date,
@enddate date
)
RETURNS TABLE
AS
RETURN
(
select convert(date,tmsp) Date, datepart(hour,tmsp) hour, min(totalMillisecond)*0.001 minimumTime, 
max(totalMillisecond)*0.001 maximumTime, avg(totalMillisecond)*0.001 AverageTime, 
max(totalMillisecond)*0.001 - min(totalMillisecond)*0.001 AS difference,  count(totalMillisecond) count
  from ApiLog  where AppObjectId = @AppObjectId and convert(date,tmsp) >= @startdate 
  and convert(date,tmsp) <= @enddate
  group by convert(date,tmsp), datepart(hour, tmsp)
  --order by convert(date,tmsp), datepart(hour, tmsp)

)
GO


