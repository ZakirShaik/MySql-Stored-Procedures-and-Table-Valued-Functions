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

/****** Object:  StoredProcedure [dbo].[usp_BCPDataIntoWebLogs]    Script Date: 7/28/2017 1:20:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<ZAKIR SHAIK>
-- Create date: <July 28 2017>
-- Description:	<This stored procedure will bulk insert data from LOG files into tables each file at a time. It will search for the
-- path in the file info table and then it will update its status, i.e, whether completed or not. This it will delete unnecessary
-- tuples. Also I used two functions not created by me to extract controller and action strings from an URL string. 
-- ie. dbo.GetControllerFromURI() and dbo.GetActionFromURI(). I had set foreign keys whereever possible to stop redundancy and prevent
-- invalid data to enter. Then I have updated this big WebLog table with small tables for each file. Finally I updated status of
-- file. 
-- =============================================


--exec dbo.usp_BCPDataIntoWebLogs


ALTER procedure [dbo].[usp_BCPDataIntoWebLogs]
as
begin
declare @FileId int
declare @pathfilename varchar(255)
DECLARE @sql NVARCHAR(4000)
declare @ServerId int 
declare @Siteid int
declare @Filename varchar(255) 
declare @temppath varchar(255)
declare @Count int

--update [FileInfo] set CompletedYN = 0 where CompletedYN = 1
WHILE(Select Count(*) From FileInfo Where CompletedYN = 'false') > 0
BEGIN

 select @temppath = fpi.FilePath, @FileId = FileInfoId, @Filename = fileName, @ServerId = fi.ServerId, @Siteid = fi.SiteId
  from FileInfo fi,FilePathInfo fpi where CompletedYN = 'false' and fi.FilePathId = fpi.FilePathId order by FileInfoId ASC
   

	print ' Starting bulk insert ' + cast(@Filename as varchar(255));
   set @pathfilename = @temppath + @Filename 
   set @sql = 'BULK INSERT vw_WebLog FROM ''' + @pathfilename + ''' WITH (FIELDTERMINATOR ='' '', ROWTERMINATOR =''\n'')';
   EXEC(@sql);
   print @sql

 delete from webLog where [cs-uri-stem] like '%.jpg'
 delete from webLog where [cs-uri-stem] like '%.png'
 delete from webLog where [cs-uri-stem] like '%.pdf'


 update [WebLog]
 set Controller = dbo.GetControllerFromURI([cs-uri-stem])
 where Controller is null

 update[WebLog]
 set Action = dbo.GetActionFromURI([cs-uri-stem])
 where Action is null

  delete from webLog where Action like 'robots.txt'
 delete from webLog where Action like 'jquery'

 Insert APICall(Controller, Action, Method, SiteId)
   select distinct Controller, Action, [cs-method], @SiteId from webLog where ApiCallid is null
	and NOT EXISTS (
    SELECT Controller, Action, Method, SiteId FROM APICall WHERE Controller = dbo.GetControllerFromURI([cs-uri-stem])
	 and Action = dbo.GetActionFromURI([cs-uri-stem]) and Method = [cs-method] and APICall.SiteId = @SiteId 
	 
)
Update WebLog 
      set ApiCallId = APICall.ApiCallId
	from APICall  
	  where APICall.Controller = weblog.controller
	   and APICall.Action = webLog.Action 
	   and APICall.SiteId = @SiteId
	   and WebLog.ApiCallid is null

Insert IPAddress(IPAddress)
   select distinct [s-ip] from WebLog where SourceIpId is null
   and NOT EXISTS (
    SELECT IPAddress FROM IPAddress WHERE IPAddress = [s-ip]
)

   	
Insert IPAddress(IPAddress)
   select distinct [c-ip] from WebLog where ClientIpId is null
   and NOT EXISTS (
    SELECT IPAddress FROM IPAddress WHERE IPAddress = [c-ip]
)

Update WebLog 
      set SourceIpId = IPAddress.IPAddressId
   from IPaddress where IPAddress.IPAddress = WebLog.[s-ip]
     
Update WebLog 
      set ClientIpId = IPAddress.IPAddressId
   from IPaddress where IPAddress.IPAddress = WebLog.[c-ip] 

Update WebLog 
   set tmspLocal = dateadd(hh,-7,convert(datetime,concat(convert(char(10),date,101),' ',convert(char(8),cast([time] as time)))))
   , tmspGMT =  convert(datetime,concat(convert(char(10),date,101),' ',convert(char(8),cast([time] as time))))

Update WebLog 
      set AlreadyExistsYN = 1 
   from LogInfo 
    where  LogInfo.tmspLocal = WebLog.tmspLocal
	  and LogInfo.APICallId = WebLog.ApiCallId
	  and LogInfo.SourceIPId = WebLog.SourceIPId 
	  and LogInfo.Port = WebLog.[s-Port]
	  and LogInfo.milliseconds = WebLog.[time-taken]
	  
Delete from WebLog where AlreadyExistsYN = 1 

Insert into LogInfo(tmspLocal, tmspGmt, FileInfoId, APICallId, milliseconds, clientIPId, sourceIpId, port, status)
		select tmspLocal, tmspGMT
		,@FileId, ApiCallId, [time-taken], [ClientIPid], [SourceIPId], [s-port], [sc-status] from dbo.WebLog

update [FileInfo] set CompletedYN = 1 where FileInfoId = @FileId
truncate table WebLog
print ' Processing file ' + cast(@FileId as varchar(255)) + ' done...';
Select @Count = Count(*) From FileInfo Where CompletedYN = 'false'
print 'Remaining unprocessed files are numbered as follows: '
print @Count;
END

print 'LogInfo is good to go...'

end 
GO


