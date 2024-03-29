USE [SMT]
GO
/****** Object:  StoredProcedure [dbo].[RFC_MoveFile]    Script Date: 2024/01/26 3:57:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[RFC_MoveFile]
as
------------------------------------------------------------------------------------------------------
--*Program*: <Job: PU9_RFC_DeleteFile>------------  
--*Programer*:<Henry>  
--*Date*:<2020/04/27> 
--*Unify*:<ALL>  
--*Description*:<Delete out-of-date files>  
--########## Parameter Description Begin ##########  
  
--########## Parameter Description End # ##########  
--*Marked*
--##########Update Log Begin ###################  
--Date					UpdateOwner				Description              

--##########Update Log End # ###################  
---------------------------------------------------------------------------------------------------------
SET NOCOUNT ON  

BEGIN TRY
	DECLARE @FileList TABLE(FileName VARCHAR(100))

	DECLARE @CMD NVARCHAR(1000), @BackUpPath VARCHAR(200), @BackUpPath2 VARCHAR(200), @WorkPath VARCHAR(200), @FileName VARCHAR(200), @FullFileName VARCHAR(200)

	IF OBJECT_ID('tempdb..#WorkPath') IS NOT NULL DROP TABLE #WorkPath
	SELECT distinct WorkPath into #WorkPath FROM RFC_BasicData with(nolock)
	
	update #WorkPath set WorkPath = WorkPath+'\' where RIGHT(WorkPath,1)<>'\'

	WHILE EXISTS(SELECT TOP 1 0 FROM #WorkPath) 
	BEGIN
		SELECT TOP 1 @WorkPath = WorkPath FROM #WorkPath

		SET @BackUpPath=@WorkPath+'Backup\IN\'
		SET @BackUpPath2=@BackUpPath+dbo.FormatDate(GETDATE(),'YYYY')+'\'+dbo.FormatDate(GETDATE(),'MM')+'\'+dbo.FormatDate(GETDATE(),'DD')+'\'
		SET @CMD='MASTER..xp_cmdshell ''MD '+@BackUpPath2+''''
	
		EXEC(@CMD)

		SET @CMD='DIR '+@BackUpPath+' /B'
		INSERT INTO @FileList(FileName)
		EXEC XP_CMDSHELL @CMD

		DELETE @FileList WHERE FileName IS NULL or len(FileName) <= 4

		WHILE EXISTS(SELECT TOP 1 0 FROM @FileList)
		BEGIN
			SELECT TOP 1 @FileName=FileName FROM @FileList
			--select @FileName
			SELECT @FullFileName = @BackUpPath+@FileName
			--select @FullFileName

			SET @CMD='COPY '+@FullFileName+' '+@BackUpPath2+@FileName
			print @CMD
			EXEC MASTER..XP_CMDSHELL @CMD

			SET @CMD='DEL '+@FullFileName
			print @CMD
			EXEC MASTER..XP_CMDSHELL @CMD

			DELETE @FileList WHERE FileName = @FileName
		END
		
		SET @BackUpPath=@WorkPath+'Backup\QMS\'
		SET @BackUpPath2=@BackUpPath+dbo.FormatDate(GETDATE(),'YYYY')+'\'+dbo.FormatDate(GETDATE(),'MM')+'\'+dbo.FormatDate(GETDATE(),'DD')+'\'
		SET @CMD='MASTER..xp_cmdshell ''MD '+@BackUpPath2+''''
	
		EXEC(@CMD)

		SET @CMD='DIR '+@BackUpPath+' /B'
		INSERT INTO @FileList(FileName)
		EXEC XP_CMDSHELL @CMD

		DELETE @FileList WHERE FileName IS NULL or len(FileName) <= 4

		WHILE EXISTS(SELECT TOP 1 0 FROM @FileList)
		BEGIN
			SELECT TOP 1 @FileName=FileName FROM @FileList
			--select @FileName
			SELECT @FullFileName = @BackUpPath+@FileName
			--select @FullFileName

			SET @CMD='COPY '+@FullFileName+' '+@BackUpPath2+@FileName
			print @CMD
			EXEC MASTER..XP_CMDSHELL @CMD

			SET @CMD='DEL '+@FullFileName
			print @CMD
			EXEC MASTER..XP_CMDSHELL @CMD

			DELETE @FileList WHERE FileName = @FileName
		END

		DELETE #WorkPath WHERE WorkPath = @WorkPath
	END
END TRY
BEGIN CATCH
	DECLARE @SystemName VARCHAR(200)= '', @ErrorMsg NVARCHAR(max), @BU VARCHAR(20), @TransDateTime VARCHAR(14)
	SELECT @SystemName = Object_name(@@PROCID)
	SELECT @BU = SITE FROM SITE
	SELECT @TransDateTime = DBO.FormatDate(GETDATE(),'YYYYMMDDHHNNSS')

	SET @ErrorMsg = 'Stored Precedure:[' + @SystemName + ']' + Char(13) + 
					'ErrNum:' + Cast( Error_number() AS VARCHAR(50) ) + Char(13) + 
					'ErrMsg:' + Error_message() + Char(13) + 
					'@BU:' + @BU + Char(13)

	INSERT INTO SF_Error_Log(Station, Line, SN, Type, Err_Msg, TransDateTime)
	SELECT @SystemName, '', '', 'PortalAlarm', @ErrorMsg, @TransDateTime --@Line和@SN有需要添加的可以自己加,注意变量的类型大小和table列的大小

	SELECT Result = 1, Description = @ErrorMsg --返回的结果列名由存储决定
END CATCH