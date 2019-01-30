/* 1. Assign Email Filename */
FileName Outbox Email 'ToAddress@xyz.com'; *Syntax is FileName FileRef Email 'Address' <Email-Options>; 

/* 2. Generate Email */
Data _Null_;
	File Outbox
	To=('')  /* Overrides value in  filename statement  */
/*	CC=( 'Copied1@xyz.com' 'Copied2@xyz.com')*/
/*	BCC=( 'BCC1@xyz.com')*/
	Subject="Test: Database Updated for%SYSFUNC(intnx(month,%SYSFUNC(date()),-1), MONNAME.)"                              
	Attach=("C:\Database.xlsx");
	Put "Please find attached the updated through %SYSFUNC(intnx(month,%SYSFUNC(date()),-1), MONNAME.)";
Run;
