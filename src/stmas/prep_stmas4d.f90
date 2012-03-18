MODULE PREP_STMAS4D

  USE PRMTRS_STMAS

  PRIVATE  GTSCALING
  PUBLIC   PREPROCSS, GRDMEMALC, RDINITBGD, PHYSCPSTN

!**************************************************
!COMMENT:
!   THIS MODULE IS USED BY stmas_core.f90 TO DO SOME PREPROCESS.
!   SUBROUTINES:
!      PREPROCSS: CALL SUBROUTINE OF GRDMEMALC TO ALLOCATE MEMORYS TO ANALYSIS FIELD AND CALL GTSCALING TO GET SCALES OF OBSERVATIONS.
!      GRDMEMALC: MEMORY ALLOCATE FOR ANALYSIS FIELDS, BACKGROUND FIELDS AND THE COORDINATES. 
!      GTSCALING: GET SCALES OF EACH OBSERVATION.
!      RDINITBGD: GET BACKGROUND FILED ON THE CURRENT LEVEL GRID FROM THE INITIAL BACKGROUND (WITH MAX GRID NUMBER).
!      PHYSCPSTN: CALCULATE PENALTY COEFFICENTS AND MAKE SOME SCALING OF CONTROL VARIABLES AND COORDINATES.
!**************************************************

CONTAINS

SUBROUTINE PREPROCSS
!*************************************************
! DATA PREPROCESS
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
  CALL GRDMEMALC
  CALL GTSCALING
  RETURN
END SUBROUTINE PREPROCSS

SUBROUTINE GRDMEMALC
!*************************************************
! MEMORY ALLOCATE FOR GRD ARRAY
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,ER
! --------------------
  ALLOCATE(WWW(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4)),STAT=ER)
  IF(ER.NE.0)STOP 'WWW ALLOCATE WRONG'
  ALLOCATE(COR(NUMGRID(1),NUMGRID(2)),STAT=ER)
  IF(ER.NE.0)STOP 'COR ALLOCATE WRONG'
  ALLOCATE(XXX(NUMGRID(1),NUMGRID(2)),STAT=ER)
  IF(ER.NE.0)STOP 'XXX ALLOCATE WRONG'
  ALLOCATE(YYY(NUMGRID(1),NUMGRID(2)),STAT=ER)
  IF(ER.NE.0)STOP 'YYY ALLOCATE WRONG'
  ALLOCATE(DEG(NUMGRID(1),NUMGRID(2)),STAT=ER)
  IF(ER.NE.0)STOP 'DEG ALLOCATE WRONG'
  ALLOCATE(DEN(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4)),STAT=ER)
  IF(ER.NE.0)STOP 'DEN ALLOCATE WRONG'
  IF(IFPCDNT.EQ.0 .OR. IFPCDNT.EQ.2)THEN
    ALLOCATE(ZZZ(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4)),STAT=ER)
    IF(ER.NE.0)STOP 'ZZZ ALLOCATE WRONG'
  ELSEIF(IFPCDNT.EQ.1)THEN
    ALLOCATE(PPP(NUMGRID(3)),STAT=ER)
    IF(ER.NE.0)STOP 'PPP ALLOCATE WRONG'
  ENDIF
!jhui
!NUMSTAT+1
  ALLOCATE(GRDBKGND(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4),NUMSTAT+1),STAT=ER)
  IF(ER.NE.0)STOP 'GRDBKGND ALLOCATE WRONG'
  ALLOCATE(GRDANALS(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4),NUMSTAT+1),STAT=ER)
  IF(ER.NE.0)STOP 'GRDANALS ALLOCATE WRONG'
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    DO S=1,NUMSTAT+1
      GRDANALS(I,J,K,T,S)=0.0D0
      GRDBKGND(I,J,K,T,S)=0.0D0
    ENDDO   
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  NUMVARS=NUMGRID(1)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4)*(NUMSTAT+1)
  ALLOCATE(GRADINT(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4),NUMSTAT+1),STAT=ER)
  IF(ER.NE.0)STOP 'GRADINT ALLOCATE WRONG'
  RETURN
END SUBROUTINE GRDMEMALC

SUBROUTINE GTSCALING
!*************************************************
! ALLOCATE OBSERVATION MEMORY AND READ IN DATA AND SCALE
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  REAL ,PARAMETER :: SM=1.0E-5
  INTEGER  :: O,S,ER,UU,VV,WW,NO
!added by shuyuan liu 20101028 for adding the OI OI=OBSERROR(O)**2  OI=1.0/OI
  REAL    ::  OI
! --------------------
  UU=U_CMPNNT
  VV=V_CMPNNT
  WW=W_CMPNNT
  

!jhui
!NUMSTAT+1
  ALLOCATE(SCL(NUMSTAT+1),STAT=ER)
  IF(ER.NE.0)STOP 'SCL ALLOCATE WRONG'
  DO S=1,NUMSTAT+1
    SCL(S)=0.0D0
  ENDDO

  IF(NALLOBS.EQ.0) RETURN
!!!!!!!!!!!!!!!!!!!!
 O=0
!  DO S=1,NUMSTAT
!    DO NO=1,NOBSTAT(S)
 !     O=O+1
!      SCL(S)=SCL(S)+OBSVALUE(O)*OBSVALUE(O)
!    ENDDO
 ! ENDDO
 ! DO S=NUMSTAT+1,NUMSTAT+2
!    DO NO=1,NOBSTAT(S)
!      O=O+1
!      SCL(UU)=SCL(UU)+OBSVALUE(O)*OBSVALUE(O)
!      SCL(VV)=SCL(VV)+OBSVALUE(O)*OBSVALUE(O)
 !   ENDDO
!  ENDDO
!jhui
 ! DO S=NUMSTAT+3,NUMSTAT+3
 !   DO NO=1,NOBSTAT(S)
 !     O=O+1
 !     SCL(NUMSTAT+1)=SCL(NUMSTAT+1)+OBSVALUE(O)*OBSVALUE(O)
 !   ENDDO
 ! ENDDO
! STATISTIC SCALES OF EACH STATE VARIABLE BASED ON OBSERVATIONS.
!!!!!!!!!!adding the OI  modified by shuyuan liu 20101028
  O=0
  DO S=1,NUMSTAT
    DO NO=1,NOBSTAT(S)
      O=O+1
      OI=OBSERROR(O)*OBSERROR(O)
      OI=1.0/OI
      SCL(S)=SCL(S)+OBSVALUE(O)*OBSVALUE(O)*OI
   ENDDO
  ENDDO
  DO S=NUMSTAT+1,NUMSTAT+2
    DO NO=1,NOBSTAT(S)
      O=O+1
      OI=OBSERROR(O)*OBSERROR(O)
      OI=1.0/OI
      SCL(UU)=SCL(UU)+OBSVALUE(O)*OBSVALUE(O)*OI
      SCL(VV)=SCL(VV)+OBSVALUE(O)*OBSVALUE(O)*OI
    ENDDO
  ENDDO
  DO S=NUMSTAT+3,NUMSTAT+3
    DO NO=1,NOBSTAT(S)
      O=O+1
      OI=OBSERROR(O)*OBSERROR(O)
      OI=1.0/OI
      SCL(NUMSTAT+1)=SCL(NUMSTAT+1)+OBSVALUE(O)*OBSVALUE(O)*OI
    ENDDO
  ENDDO
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  DO S=1,NUMSTAT
    IF(NOBSTAT(S).GT.0 .AND. SCL(S).GE.1E-5) THEN
      IF(S.EQ.UU .OR. S.EQ.VV) THEN
        SCL(S)=SQRT(SCL(S)/(NOBSTAT(S)+NOBSTAT(NUMSTAT+1)+NOBSTAT(NUMSTAT+2)))
      ELSE
        SCL(S)=SQRT(SCL(S)/NOBSTAT(S))
      ENDIF
    ELSEIF(NOBSTAT(S).EQ.0) THEN
      SCL(S)=SL0(S)
    ENDIF
  ENDDO
  IF(NUMDIMS.GE.2)SCL(UU)=MAX(SCL(UU),SCL(VV))
  IF(NUMDIMS.GE.2)SCL(VV)=SCL(UU)
  IF(WW.NE.0)SCL(WW)=SCL(UU)
!jhui
  IF (NOBSTAT(NUMSTAT+3) .GT. 0) THEN  ! YUANFU: AVOID DIVISION OF ZERO
    DO S=NUMSTAT+3,NUMSTAT+3
        SCL(NUMSTAT+1)=SQRT(SCL(NUMSTAT+1)/NOBSTAT(S))
    ENDDO
  ENDIF

! SCALE THE OBSERVATIONS
  O=0
  DO S=1,NUMSTAT
    DO NO=1,NOBSTAT(S)
      O=O+1
      OBSVALUE(O)=OBSVALUE(O)/SCL(S)
      OBSERROR(O)=OBSERROR(O)/SCL(S)
    ENDDO
  ENDDO
  DO S=NUMSTAT+1,NUMSTAT+2
    DO NO=1,NOBSTAT(S)
      O=O+1
      OBSVALUE(O)=OBSVALUE(O)/SCL(UU)
      OBSERROR(O)=OBSERROR(O)/SCL(UU)
    ENDDO
  ENDDO
!jhui
  !DO S=NUMSTAT+3,NUMSTAT+3  !changed by shuyuan 20100903
    S=NUMSTAT+3
    DO NO=1,NOBSTAT(S)
      O=O+1
      OBSVALUE(O)=OBSVALUE(O)/SCL(NUMSTAT+1)
      OBSERROR(O)=OBSERROR(O)/SCL(NUMSTAT+1)
    ENDDO
  !ENDDO

  RETURN
END SUBROUTINE GTSCALING

SUBROUTINE RDINITBGD
!*************************************************
! READ IN INITIAL BACKGROUND FIELDS
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,NX,NY,NZ,NT,I1,J1,K1,T1,TT
  REAL     :: R
! --------------------
  R=287
  TT=TEMPRTUR

  IF(NUMGRID(1).GE.2)THEN
    NX=(MAXGRID(1)-1)/(NUMGRID(1)-1)
  ELSE
    NX=1
  ENDIF
  IF(NUMGRID(2).GE.2)THEN
    NY=(MAXGRID(2)-1)/(NUMGRID(2)-1)
  ELSE
    NY=1
  ENDIF
  IF(NUMGRID(3).GE.2)THEN
    NZ=(MAXGRID(3)-1)/(NUMGRID(3)-1)
  ELSE
    NZ=1
  ENDIF
  IF(NUMGRID(4).GE.2)THEN
    NT=(MAXGRID(4)-1)/(NUMGRID(4)-1)
  ELSE
    NT=1
  ENDIF
! INTERPLATE THE BACKGROUND FIELD ONTO THE CURRENT ANALYSIS GRID POINTS.
  DO T=1,MAXGRID(4),NT
  DO K=1,MAXGRID(3),NZ
  DO J=1,MAXGRID(2),NY
  DO I=1,MAXGRID(1),NX
    I1=(I-1)/NX+1
    J1=(J-1)/NY+1
    K1=(K-1)/NZ+1
    T1=(T-1)/NT+1
!jhui
    DO S=1,NUMSTAT+1
      GRDBKGND(I1,J1,K1,T1,S)=GRDBKGD0(I,J,K,T,S)/SCL(S)
    ENDDO
     IF(IFPCDNT.NE.1) DEN(I1,J1,K1,T1)=DN0(I,J,K,T)     ! here the pressure is not aviable
     IF(IFPCDNT.EQ.1) DEN(I1,J1,K1,T1)=(PPP(K1)*SCP(PSL)+ORIVTCL)/R/((GRDBKGND(I1,J1,K1,T1,TT)+GRDANALS(I1,J1,K1,T1,TT))*SCL(TT))
  ENDDO
  ENDDO
  ENDDO
  ENDDO

  RETURN
END SUBROUTINE RDINITBGD

SUBROUTINE PHYSCPSTN
!*************************************************
! DEALING WITH PHYSICAL POSITION AND PENALTY COEFFICENT AND MAKING SOME SCALING
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,NX,NY,NZ,NT,I1,J1,K1,T1,UU,VV,PP
  REAL     :: Z1,Z2
! --------------------
  UU=U_CMPNNT
  VV=V_CMPNNT
  PP=PRESSURE
! PHYSICAL POSITION AND CORIOLIS FREQUENCY
  IF(NUMGRID(1).GE.2)THEN
    NX=(MAXGRID(1)-1)/(NUMGRID(1)-1)
  ELSE
    NX=1
  ENDIF
  IF(NUMGRID(2).GE.2)THEN
    NY=(MAXGRID(2)-1)/(NUMGRID(2)-1)
  ELSE
    NY=1
  ENDIF
  DO J=1,MAXGRID(2),NY
  DO I=1,MAXGRID(1),NX
    I1=(I-1)/NX+1
    J1=(J-1)/NY+1
    IF(NUMGRID(1).GE.2)XXX(I1,J1)=XX0(I,J)
    IF(NUMGRID(2).GE.2)YYY(I1,J1)=YY0(I,J)
    IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)COR(I1,J1)=CR0(I,J)
    IF(NUMGRID(2).GE.2)DEG(I1,J1)=DG0(I,J)
  ENDDO
  ENDDO

  IF(NUMGRID(3).GE.2)THEN
    NZ=(MAXGRID(3)-1)/(NUMGRID(3)-1)
  ELSE
    NZ=1
  ENDIF
  IF(NUMGRID(4).GE.2)THEN
    NT=(MAXGRID(4)-1)/(NUMGRID(4)-1)
  ELSE
    NT=1
  ENDIF

  IF(IFPCDNT.EQ.0 .OR. IFPCDNT.EQ.2)THEN          ! FOR SIGMA AND HEIGHTCOORDINATE
    DO T=1,MAXGRID(4),NT
    DO K=1,MAXGRID(3),NZ
    DO J=1,MAXGRID(2),NY
    DO I=1,MAXGRID(1),NX
      I1=(I-1)/NX+1
      J1=(J-1)/NY+1
      K1=(K-1)/NZ+1
      T1=(T-1)/NT+1
      ZZZ(I1,J1,K1,T1)=ZZ0(I,J,K,T)
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ELSEIF(IFPCDNT.EQ.1)THEN
    DO K=1,MAXGRID(3),NZ
      K1=(K-1)/NZ+1
      PPP(K1)=PP0(K)
    ENDDO
  ENDIF

! PENALTY COEFFICENT
!jhui
  DO S=1,NUMSTAT
!jhui
    !IF(NUMGRID(1).GE.3) PENAL_X(S)=PENAL0X(S)*GRDSPAC(1)*GRDSPAC(1)*GRDSPAC(1)*GRDSPAC(1)  &
    !                               /((NUMGRID(1)-2)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4))
    !IF(NUMGRID(2).GE.3) PENAL_Y(S)=PENAL0Y(S)*GRDSPAC(2)*GRDSPAC(2)*GRDSPAC(2)*GRDSPAC(2)  &
    !                               /((NUMGRID(2)-2)*NUMGRID(1)*NUMGRID(3)*NUMGRID(4))
    !IF(NUMGRID(3).GE.3) PENAL_Z(S)=PENAL0Z(S)  &
    !                               /((NUMGRID(3)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(4))
    !IF(NUMGRID(4).GE.3) PENAL_T(S)=PENAL0T(S)*GRDSPAC(4)*GRDSPAC(4)*GRDSPAC(4)*GRDSPAC(4)  &
    !                               /((NUMGRID(4)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(3))
    IF(NUMGRID(1).GE.3) PENAL_X(S)=PENAL0X(S)*((MAXGRID(1)-2)*MAXGRID(2)*NUMGRID(3)*MAXGRID(4))  &
                                   /((NUMGRID(1)-2)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4))
    IF(NUMGRID(2).GE.3) PENAL_Y(S)=PENAL0Y(S)*((MAXGRID(2)-2)*MAXGRID(1)*MAXGRID(3)*MAXGRID(4))  &
                                   /((NUMGRID(2)-2)*NUMGRID(1)*NUMGRID(3)*NUMGRID(4))
    IF(NUMGRID(3).GE.3) PENAL_Z(S)=PENAL0Z(S)*((MAXGRID(3)-2)*MAXGRID(1)*MAXGRID(2)*MAXGRID(4))  &
                                   /((NUMGRID(3)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(4))
    IF(NUMGRID(4).GE.3) PENAL_T(S)=PENAL0T(S)*((MAXGRID(4)-2)*MAXGRID(1)*MAXGRID(2)*MAXGRID(3))  &
                                   /((NUMGRID(4)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(3))
!    IF(NUMGRID(1).GE.3) PENAL_X(S)=PENAL0X(S)*GRDSPAC(1)*GRDSPAC(1)*GRDSPAC(1)*GRDSPAC(1)*SCL(S)*SCL(S)  &
!                                   /((NUMGRID(1)-2)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4))
!    IF(NUMGRID(2).GE.3) PENAL_Y(S)=PENAL0Y(S)*GRDSPAC(2)*GRDSPAC(2)*GRDSPAC(2)*GRDSPAC(2)*SCL(S)*SCL(S)  &
!                                   /((NUMGRID(2)-2)*NUMGRID(1)*NUMGRID(3)*NUMGRID(4))
!    IF(NUMGRID(3).GE.3) PENAL_Z(S)=PENAL0Z(S)*SCL(S)*SCL(S)  &
!                                   /((NUMGRID(3)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(4))
!    IF(NUMGRID(4).GE.3) PENAL_T(S)=PENAL0T(S)*GRDSPAC(4)*GRDSPAC(4)*GRDSPAC(4)*GRDSPAC(4)*SCL(S)*SCL(S)  &
!                                   /((NUMGRID(4)-2)*NUMGRID(1)*NUMGRID(2)*NUMGRID(3))
  ENDDO
    PENAL_X(NUMSTAT+1) = PENAL_X(1)
    PENAL_Y(NUMSTAT+1) = PENAL_Y(1)
    PENAL_Z(NUMSTAT+1) = PENAL_Z(1)
    PENAL_T(NUMSTAT+1) = PENAL_T(1)

  PNLT_PU=PNLT0PU*SCL(UU)*SCL(UU)/(2**(GRDLEVL-1)) &
              /(NUMGRID(1)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4))
  PNLT_PV=PNLT0PV*SCL(VV)*SCL(VV)/(2**(GRDLEVL-1)) &
              /(NUMGRID(1)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4))
  IF(NALLOBS.NE.0) THEN
    IF(NOBSTAT(UU).EQ.0.AND.NOBSTAT(PP).EQ.0)PNLT_PU=0.0D0
    IF(NOBSTAT(VV).EQ.0.AND.NOBSTAT(PP).EQ.0)PNLT_PV=0.0D0
  ENDIF

  PNLT_HY=PNLT0HY*TAUL_HY**(GRDLEVL-1)  &
              /(NUMGRID(1)*NUMGRID(2)*NUMGRID(3)*NUMGRID(4)) 

! CALCULATE SCALE FOR PHYSICAL POSITION AND CORIOLIS FREQUENCY
  SCP(XSL)=ABS((XXX(NUMGRID(1),NUMGRID(2))-XXX(1,1))/(NUMGRID(1)-1))
  SCP(YSL)=ABS((YYY(NUMGRID(1),NUMGRID(2))-YYY(1,1))/(NUMGRID(2)-1))
  IF(IFPCDNT.EQ.0 .OR. IFPCDNT.EQ.2)THEN         ! FOR SIGMA AND HEIGHTCOORDINATE
    Z2=ZZZ(1,1,NUMGRID(3),1)
    Z1=ZZZ(1,1,1,1)
    DO I=1,NUMGRID(1)
    DO J=1,NUMGRID(2)
    DO T=1,NUMGRID(4)
      Z2=MAX(Z2,ZZZ(I,J,NUMGRID(3),T))
      Z1=MIN(Z1,ZZZ(I,J,1,T))
    ENDDO
    ENDDO
    ENDDO
    SCP(PSL)=ABS((Z2-Z1)/(NUMGRID(3)-1))
  ELSEIF(IFPCDNT.EQ.1)THEN
    SCP(PSL)=ABS((PPP(NUMGRID(3))-PPP(1))/(NUMGRID(3)-1))
  ENDIF
  IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)SCP(CSL)=ABS(COR(1,1))
  DO I=1,NUMGRID(1)
  DO J=1,NUMGRID(2)
    IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)SCP(CSL)=MAX(SCP(CSL),ABS(COR(I,J)))
  ENDDO
  ENDDO
  IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)SCP(DSL)=ABS(DEN(1,1,1,1))
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)SCP(DSL)=MAX(SCP(DSL),ABS(DEN(I,J,K,T)))
  ENDDO
  ENDDO
  ENDDO
  ENDDO
! SCALE THE PHYSICAL POSITION AND CORIOLIS FREQUENCY
  DO I=1,NUMGRID(1)
  DO J=1,NUMGRID(2)
    IF(NUMGRID(1).GE.2)XXX(I,J)=(XXX(I,J)-ORIPSTN(1))/SCP(XSL)
    IF(NUMGRID(2).GE.2)YYY(I,J)=(YYY(I,J)-ORIPSTN(2))/SCP(YSL)
    IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)COR(I,J)=COR(I,J)/SCP(CSL)
  ENDDO
  ENDDO
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    IF(PNLT0PU.GE.1.0E-10.OR.PNLT0PV.GE.1.0E-10)DEN(I,J,K,T)=DEN(I,J,K,T)/SCP(DSL)
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  IF(IFPCDNT.EQ.0 .OR. IFPCDNT.EQ.2)THEN         ! FOR SIGMA AND HEIGHT COORDINATE
    ORIVTCL=ZZZ(1,1,1,1)
    DO T=1,NUMGRID(4)
    DO K=1,NUMGRID(3)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)
      ZZZ(I,J,K,T)=(ZZZ(I,J,K,T)-ORIVTCL)/SCP(PSL)
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ELSEIF(IFPCDNT.EQ.1)THEN                       ! FOR PRESSURE COORDINATE
    ORIVTCL=PPP(1)
    DO K=1,NUMGRID(3)
      PPP(K)=(PPP(K)-ORIVTCL)/SCP(PSL)
    ENDDO
  ENDIF

  RETURN
END SUBROUTINE PHYSCPSTN

END MODULE PREP_STMAS4D
