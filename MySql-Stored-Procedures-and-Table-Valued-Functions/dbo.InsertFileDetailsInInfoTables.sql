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

/****** Object:  StoredProcedure [dbo].[InsertFileDetailsInInfoTables]    Script Date: 7/26/2017 12:19:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<ZAKIR SHAIK>
-- Create date: <July 26 2017>
-- Description:	<This stored procedure will automatically copy all the file details into file info tables and it will flag it with
-- Completed/Not Completed to know the status of the file completion. For this I created tree table to store them temporarily.
-- I used {{EXEC Master.dbo.xp_DirTree @totalpath,1,1}} command to retrieve details of the files and stored them in temporary tree 
-- and I copied details based on depths. If depth = 0 it is a folder and if depth = 1 then it is a file. So, it will work till 2
-- depths.>
-- =============================================
/*
exec InsertFileDetailsInInfoTables '\192.168.1.2\Log\Final\', 'DW-WEB1', 'W3SVC3'
exec InsertFileDetailsInInfoTables 'C:\Develop\', 'FolderTestD', 'W3SVC3'
*/
--NOTE :: @FilePathBtwn should be the path between 'C:\Develop\'  and 'folders' which we want to traverse. Example:'Logs\'
ALTER PROCEDURE [dbo].[InsertFileDetailsInInfoTables](@FilePathStart varchar(50), @ServerName varchar(50), @SiteName varchar(50), @SiteId int)	
AS
BEGIN


declare @NotCompleted nvarchar(10)
set @NotCompleted = 0
declare @idd int
declare @totalpath varchar(50)
declare @ServerId int
--declare @SiteId int


set @totalpath = @FilePathStart + @ServerName + '\' + @SiteName + '\' 
print @totalpath
--Inserting folder names and ids in filepathinfo
 Insert FilePathInfo(FilePath, FolderCompletedYN, SiteId, ServerId)
 select @totalpath, @NotCompleted, SiteId, ServerId from Server,Site
 where @ServerName = Server.ServerName and @SiteId = Site.IISServiceId and NOT EXISTS (
    SELECT FilePath, SiteId, ServerId FROM FilePathInfo WHERE FilePath = @totalpath
	and SiteId = SiteId and ServerId = ServerId
)
select * from FilePathInfo
update [FilePathInfo] set FolderCompletedYN = 0 where FolderCompletedYN = 1
select * from FilePathInfo
WHILE(Select Count(*) From FilePathInfo Where FolderCompletedYN = 'false') > 0
--select * from FilePathInfo
begin

 select @idd = FilePathId, @totalpath = FilePath, @ServerId = ServerId, @SiteId = SiteId from FilePathInfo
 where FolderCompletedYN = 0
 IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;
	   CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
      ,subdirectory nvarchar(512)
      ,depth int
      ,isfile bit);

 INSERT #DirectoryTree (subdirectory,depth,isfile)
EXEC Master.dbo.xp_DirTree @totalpath,1,1

Insert into FileInfo(FilePathId, ServerId, SiteId, FileName, CompletedYN)
select @idd, @ServerId, @SiteId, subdirectory, @NotCompleted from #DirectoryTree where isfile = 1 
and NOT EXISTS (
    SELECT FilePathId, ServerId, SiteId, FileName FROM FileInfo WHERE FilePathId = @idd
	and ServerId = @ServerId and SiteId = @SiteId and FileName = subdirectory
)
order by subdirectory asc

update [FilePathInfo] set FolderCompletedYN = 1 where FilePathId = @idd 

end--while end

END
GO


