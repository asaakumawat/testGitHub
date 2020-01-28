
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

ALTER PROCEDURE ImportRecords
	@XMLData VARCHAR(MAX),
	@IsValid BIT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	--TEMP TABLE TO HOLD DATA
	IF OBJECT_ID('tempdb..#tmpStudentDetails') IS NOT NULL DROP TABLE #tmpStudentDetails
	CREATE TABLE #tmpStudentDetails (
		SerialNo INT,
		StudentName VARCHAR(100),
		ParentsName VARCHAR(100),
		Class VARCHAR(100),
		EmailId VARCHAR(100),
		Address VARCHAR(100),
		City VARCHAR(100),
		State VARCHAR(100),
		MobileNo VARCHAR(100),
		EnrollmentNo VARCHAR(100),
		DOB VARCHAR(100),
		ErrorMessage VARCHAR(500),
	)

    SET @XMLData=replace(@XMLData,'<?xml version="1.0" encoding="UTF-8"?>','')
	DECLARE @xml XML=CAST(@XMLData AS XML)
	--INSERT DATA IN TEMP TABLE
	INSERT INTO #tmpStudentDetails (SerialNo,StudentName,ParentsName,Class,EmailId,Address,City,State,MobileNo,EnrollmentNo,DOB)
	SELECT 
		 CAST(RootVal.NodeVal.value('SerialNo [1]','INT') AS INT),
		 CAST(RootVal.NodeVal.value('StudentName [1]','VARCHAR(100)') AS VARCHAR(100)),
		 CAST(RootVal.NodeVal.value('ParentsName[1]','VARCHAR(100)') AS VARCHAR(100)),
		 CAST(RootVal.NodeVal.value('Class[1]','VARCHAR(100)') AS VARCHAR(100)),
		 CAST(RootVal.NodeVal.value('EmailId[1]','VARCHAR(100)') AS VARCHAR(100)),
		 CAST(RootVal.NodeVal.value('Address[1]','VARCHAR(50)') AS VARCHAR(100)),
		 CAST(RootVal.NodeVal.value('City[1]','VARCHAR(50)') AS VARCHAR(50)),
		 CAST(RootVal.NodeVal.value('State[1]','VARCHAR(50)') AS VARCHAR(50)),
		 CAST(RootVal.NodeVal.value('MobileNo[1]','VARCHAR(50)') AS VARCHAR(50)),
		 CAST(RootVal.NodeVal.value('EnrollmentNo[1]','VARCHAR(50)') AS VARCHAR(50)),
		 CAST(RootVal.NodeVal.value('DOB[1]','VARCHAR(50)') AS VARCHAR(50))
        FROM @xml.nodes('/root/row') RootVal(NodeVal) 

	--VALIDATIONS

	--CHECK MOBILE NUMBER ALREADY REGISTRED WITH BOOK SELLER'S
	IF EXISTS(SELECT COUNT(1) FROM BookSeller_Mas WHERE BSM_MobileNo IN (SELECT MobileNo FROM #tmpStudentDetails))
	BEGIN
		UPDATE TSD SET TSD.ErrorMessage=CONCAT(TSD.ErrorMessage,' ','This mobile number is already registred with other user type.')
		 FROM #tmpStudentDetails TSD 
		 INNER JOIN BookSeller_Mas BSM ON TSD.MobileNo=BSM.BSM_MobileNo
		 SET @IsValid=0
	END

	--CHECK MOBILE NUMBER ALREADY REGISTRED WITH BOOK SELLER'S
	IF EXISTS(SELECT COUNT(1) FROM Employee_Mas WHERE EMP_MobileNo IN (SELECT MobileNo FROM #tmpStudentDetails))
	BEGIN
		UPDATE TSD SET TSD.ErrorMessage=CONCAT(TSD.ErrorMessage,' ','This mobile number is already registred with other user type.')
		 FROM #tmpStudentDetails TSD 
		 INNER JOIN Employee_Mas EM ON TSD.MobileNo=EM.EMP_MobileNo
		 SET @IsValid=0
	END

	--CHECK STUDENT DUPLICATE
	IF EXISTS(SELECT * FROM Parents_Mas PM 
				INNER JOIN Student_Mas SM ON PM.P_Id=SM.St_ParentId 
				WHERE EXISTS (SELECT 1 FROM #tmpStudentDetails TSD WHERE  PM.P_MobileNo = TSD.MobileNo AND SM.St_Name = TSD.StudentName))
	BEGIN
		UPDATE TSD SET TSD.ErrorMessage=CONCAT(TSD.ErrorMessage,' ','Data already exists with same mobile number and name.')
		 FROM #tmpStudentDetails TSD WHERE EXISTS(
		 SELECT * FROM Parents_Mas PM 
				INNER JOIN Student_Mas SM ON PM.P_Id=SM.St_ParentId 
				WHERE  PM.P_MobileNo = TSD.MobileNo AND SM.St_Name = TSD.StudentName)
		 SET @IsValid=0
	END

	--IF(@IsValid)
	--BEGIN
	--	DECLARE @SerialNo INT,@MobileNo VARCHAR(50),@ParentsId INT
	--	WHILE((SELECT COUNT(1) FROM #tmpStudentDetails)>0)
	--	BEGIN
	--		SELECT TOP 1 @SerialNo=SerialNo,@MobileNo=MobileNo FROM #tmpStudentDetails
	--		SELECT @ParentsId=@ParentsId
	--	END
	--END
	SELECT * FROM #tmpStudentDetails
END
GO
