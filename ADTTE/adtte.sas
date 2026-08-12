*********************************************************************
*  Project:    CDISC Pilot                                      
*                                                                    
*  Description:   Create ADTTE dataset
*
*  Name:          Lauren Rackley
*
*  Date:          12AUG2026                                 
*------------------------------------------------------------------- 
*  Job name:      adtte.sas 
*
*  Purpose:       To create ADTTE dataset for efficacy analyses 
* 
*  Language:      SAS 9.4
*
*  Input:         ADSL, ADAE
*
*  Output:        ADTTE dataset
*
*  Notes:         Not validated                                                               
********************************************************************;
libname adam "/home/lrackley0/CDISC Pilot/ADaM";

data adsl;
   format startdt date9.;
   set adam.adsl;
   startdt=input(RFSTDTC,??yymmdd10.);
   trtp=trt01p;
   trta=trt01a;
   trtan=trt01an;
   keep studyid siteid usubjid age agegr1 agegr1n race racen sex trtsdt trtedt trtdurd
   trta trtp trtan saffl startdt rfendtc;
run;

proc sort data = adam.adae;
   by usubjid astdt;
run;


data adae01;
   set adam.adae;
   where cq01nam='DERMATOLOGIC EVENTS' and trtemfl='Y';
   by usubjid astdt;   
   if first.usubjid; /*Keep only the first TEAE per subject*/
   keep usubjid astdt trtemfl;
run;

*Merge ADAE with ADSL;
data adtte;
   length evntdesc $28 srcdom $4 srcvar $6 param $100 paramcd $8;
   format adt date9.;
   merge adsl(in=a) adae01(in=b);
   by usubjid;
   if a;
   param='Time to First Dermatological Event';
   paramcd='TTDE';
   if trtemfl='Y' then do;
      cnsr=0;
      evntdesc='Dermatologic Event Occurred';
      srcdom='ADAE';
      srcvar='ASTDT';
      adt=astdt;
   end;
   else do;
      cnsr=1;
      evntdesc='Study Completion Date';
      srcdom='ADSL';
      srcvar='RFENDT';
      adt=input(RFENDTC,??yymmdd10.); 
   end;
   
   *Aval derivation;
   if nmiss(adt,startdt)=0 then aval=ADT-STARTDT+1;
run;

proc compare base=adam.adtte compare=adtte;
   id usubjid;
run;

*Creating Kaplan-Meier plot for the study;
/* proc lifetest data = adam.adtte (where=(saffl="Y")) plots=s; */
/*  id usubjid; */
/*  strata trtan; */
/*  time aval*cnsr(1); */
/*  test trtan; */
/* run;  */
