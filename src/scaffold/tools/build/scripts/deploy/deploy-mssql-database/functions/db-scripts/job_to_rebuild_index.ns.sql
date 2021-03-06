USE [msdb]

DECLARE @existed_job_id BINARY(16) 
DECLARE @new_job_name nvarchar(max)
DECLARE @login_user nvarchar(max)
DECLARE @target_server_name nvarchar(max)
DECLARE @target_db_name nvarchar(max)
DECLARE @job_command nvarchar(max)

SET @new_job_name = N'$(jobName)'

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = @new_job_name)
BEGIN
	SET @existed_job_id = (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = @new_job_name)
	EXEC msdb.dbo.sp_delete_job @job_id=@existed_job_id, @delete_unused_schedule=1
END

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=@new_job_name, 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'rebuild indexes in database', 
		@category_name=N'[Uncategorized (Local)]', 
		@job_id = @jobId OUTPUT
select @jobId

set @job_command = N'
USE [$(targetDBName)]
GO
EXEC [rebuild_indexes]
GO
'

EXEC msdb.dbo.sp_add_jobserver @job_name=@new_job_name
PRINT 'jobserver added'
EXEC msdb.dbo.sp_add_jobstep @job_name=@new_job_name, @step_name=N'rebuild_index', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@job_command, 
		@database_name=[$(targetDBName)], 
		@flags=0
PRINT 'Step added'

EXEC msdb.dbo.sp_update_job @job_name=@new_job_name, 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'rebuild indexes in database', 
		@category_name=N'[Uncategorized (Local)]', 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=@new_job_name, @name=N'12_00AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120101, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
