cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis 
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS 
cdis 
cdis    This software and its documentation are in the public domain and 
cdis    are furnished "as is."  The United States government, its 
cdis    instrumentalities, officers, employees, and agents make no 
cdis    warranty, express or implied, as to the usefulness of the software 
cdis    and documentation for any purpose.  They assume no responsibility 
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis    
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making 
cdis    the modifications.  If significant modifications or enhancements 
cdis    are made to this software, the FSL Software Policy Manager  
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
         subroutine readcsc(i4time,dir,cscnew)
C
         include 'lapsparms.for'
         parameter(imax=nx_l,jmax=ny_l)
c
         real*4 csc(imax,jmax),lcv(imax,jmax),csctot(imax,jmax)
         real*4 snow_total(imax,jmax)
         real*4 missval,cscnew(imax,jmax)
         integer*4 i4time
         CHARACTER*50 DIR
         CHARACTER*17 TIME
c         data missval/1.0e37/
         missval=r_missing_data
c
c ************************************************************
        i4time=i4time-48*3600
c
c first set csctot to all missing values
c
         do i=1,imax
         do j=1,jmax
           csctot(i,j)=missval
         enddo
         enddo
c
c now loop through past 48 hours, looking only at csc files
c
        icsc=0
        do itime=1,49
c

           call cv_i4tim_asc_lp(i4time,time,istatus)
c           if(time(13:14).eq.'13')goto 52
           write(6,101)time
c
	   CALL GETLAPSLCV(I4TIME,LCV,CSC,ISTATUS,DIR)
	   IF (ISTATUS .NE. 1) THEN
	      WRITE(6,*) 'Error getting LAPS LCV at ',i4time
              write(6,*) 'Not using this lcv file'
              go to 522
           ENDIF
           icsc=icsc+1
           do i=1,imax
           do j=1,jmax
             if(csc(i,j).le.1.1)csctot(i,j)=csc(i,j)  
	     if(csc(i,j).le.0.1)csctot(i,j)=0.0
           enddo
           enddo
 522       continue
c
           i4time=i4time+3600
        enddo
 101    format(1x,'First csc loop data search time: ',a17)
c
         if(icsc.eq.0)then
         write(6,*) '**** No lcv data available over 48 hours ****'
           do i=1,imax
           do j=1,jmax
             csctot(i,j)=missval
           enddo
           enddo
         endif
c
        i4time=i4time-3600
c
        call analyze(csctot,cscnew,missval)
c
c now loop through past 48 hours, looking for latest snow_total and
c  latest csc obs. snow_total only applies to a point - it is not
c  spread horizontally. If there are then any later csc obs at that 
c  point, then the csctot point is set to the csc ob.
c
        i4time=i4time-48*3600
        do itime=1,49
c
           call cv_i4tim_asc_lp(i4time,time,istatus)
c           if(time(13:14).eq.'13')goto 52
           write(6,102)time
c
c First get csc field again. Will not analyze - just use this to
c   write over any previous time's snow_total obs.
	   CALL GETLAPSLCV(I4TIME,LCV,CSC,ISTATUS,DIR)
	   IF (ISTATUS .NE. 1) THEN
	      WRITE(6,*) 'Error getting LAPS LCV at ',i4time
              write(6,*) 'Not using this lcv file'
              go to 52
           ENDIF
           do i=1,imax
           do j=1,jmax
             if(csc(i,j).le.1.1)cscnew(i,j)=csc(i,j)  
	     if(csc(i,j).le.0.1)cscnew(i,j)=0.0
           enddo
           enddo
 52        continue
c
c now get snow_total obs
c
	   CALL GETLAPSL1S(I4TIME,snow_total,ISTATUS,DIR)
	   IF (ISTATUS .NE. 1) THEN
	      WRITE(6,*) 'Error getting LAPS L1S at ',i4time
              write(6,*) 'Not using this l1s file'
              go to 51
           ENDIF
c Adjust snow cover field based upon snow total 
c   if snowfall total >= 2cm, then set snow cover to 1.
c   if snowfall total  = 1cm, then set snow cover to 0.5
c   if snowfall total between 1 and 2cm, then ramp snow cover 0.5 to 1.
           do i=1,imax
           do j=1,jmax
            if(snow_total(i,j) .ge. 0.02)cscnew(i,j)=1.0
            if((snow_total(i,j).ge.0.01).and.(snow_total(i,j).lt.0.02))
     1         cscnew(i,j)=snow_total(i,j)/0.02
           enddo
           enddo     
 51        continue
c
           i4time=i4time+3600
        enddo
 102    format(1x,'Second loop data search time: ',a17)
          i4time=i4time-3600
c
c        do j=jmax,1,-1
c          write(6,76)j,(cscnew(i,j),i=1,18)
c 76       format(1x,i2,1x,18f4.1)
c        enddo
c
        return
        end
C-------------------------------------------------------------------------------
C
      SUBROUTINE GETLAPSLCV(I4TIME,LCV,CSC,ISTATUS,DIR)
C
         include 'lapsparms.for'
         parameter(imax=nx_l,jmax=ny_l,kmax=2)
c
      INTEGER*4 I4TIME,LVL(KMAX),I,J,ERROR(2),ISTATUS
C
      REAL*4 lcv(imax,jmax),csc(imax,jmax),readv(imax,jmax,kmax)		
C
      CHARACTER*50 DIR,LDIR
      CHARACTER*31 EXT
      CHARACTER*3 VAR(KMAX)
      CHARACTER*4 LVL_COORD(KMAX)
      CHARACTER*10 UNITS(KMAX)
      CHARACTER*125 COMMENT(KMAX)
C
C-------------------------------------------------------------------------------
C
	ERROR(1)=1
	ERROR(2)=0
C
c        DO I=50,1,-1
c          IF (DIR(I:I) .NE. ' ') GOTO 8
c        ENDDO

        call get_directory('lcv',ldir,len)

c8       LDIR=DIR(1:I)//'lcv/'
c        print *,'ldir=',ldir
	EXT='lcv'
	VAR(1)='LCV'
	VAR(2)='CSC'
	LVL(1)=0
	LVL(2)=0
C
C ****  Read LAPS lcv and csc.
C
	CALL READ_LAPS_DATA(I4TIME,LDIR,EXT,IMAX,JMAX,KMAX,KMAX,VAR,LVL,
     1      LVL_COORD,UNITS,COMMENT,readv,ISTATUS)
C
	IF (ISTATUS .NE. 1) THEN
		PRINT *,'Error reading LAPS lcv data.'
		ISTATUS=ERROR(2)
		RETURN
	ENDIF
C
        do j=1,jmax
        do i=1,imax
          csc(i,j)=readv(i,j,2)
          lcv(i,j)=readv(i,j,1)
        enddo
        enddo
c
c        print *,' '
c        print *,'lcv field'
c        do j=1,jmax
c          write(6,20)j,(lcv(i,j),i=21,40)
c        enddo
c        print *,' '
c        print *,'csc field'
c        do j=1,jmax
c          write(6,20)j,(csc(i,j),i=21,40)
c        enddo
c        print *,'csc(21,55)=',csc(21,55)
c 20     format(1x,i2,1x,20f4.1)
c
	ISTATUS=ERROR(1)
	RETURN
C
	END
C
C-------------------------------------------------------------------------------
C
      SUBROUTINE GETLAPSL1S(I4TIME,snow_total,ISTATUS,DIR)
C
         include 'lapsparms.for'
         parameter(imax=nx_l,jmax=ny_l,kmax=1)
c
      INTEGER*4 I4TIME,LVL(KMAX),I,J,ERROR(2),ISTATUS
C
      REAL*4 snow_total(imax,jmax),readv(imax,jmax,kmax)		
C
      CHARACTER*50 DIR,LDIR
      CHARACTER*31 EXT
      CHARACTER*3 VAR(KMAX)
      CHARACTER*4 LVL_COORD(KMAX)
      CHARACTER*10 UNITS(KMAX)
      CHARACTER*125 COMMENT(KMAX)
C
C-------------------------------------------------------------------------------
C
	ERROR(1)=1
	ERROR(2)=0
C
c        DO I=50,1,-1
c          IF (DIR(I:I) .NE. ' ') GOTO 8
c        ENDDO
        call get_directory('lls',ldir,len)
c8       LDIR=DIR(1:I)//'l1s/'
c        print *,'ldir=',ldir
	EXT='L1S'
	VAR(1)='STO'
	LVL(1)=0
C
C ****  Read LAPS l1s
C
	CALL READ_LAPS_DATA(I4TIME,LDIR,EXT,IMAX,JMAX,KMAX,KMAX,VAR,LVL,
     1      LVL_COORD,UNITS,COMMENT,readv,ISTATUS)
C
	IF (ISTATUS .NE. 1) THEN
		PRINT *,'Error reading LAPS l1s data.'
		ISTATUS=ERROR(2)
		RETURN
	ENDIF
C
        do j=1,jmax
        do i=1,imax
          snow_total(i,j)=readv(i,j,1)
        enddo
        enddo
c
c        print *,' '
c        print *,'lcv field'
c        do j=1,jmax
c          write(6,20)j,(lcv(i,j),i=21,40)
c        enddo
c        print *,' '
c        print *,'csc field'
c        do j=1,jmax
c          write(6,20)j,(csc(i,j),i=21,40)
c        enddo
c        print *,'csc(21,55)=',csc(21,55)
c 20     format(1x,i2,1x,20f4.1)
c
	ISTATUS=ERROR(1)
	RETURN
C
	END
C
C
C-------------------------------------------------------------------------------
         subroutine analyze(csctot,cscnew,missval)
C
         include 'lapsparms.for'
         parameter(imax=nx_l,jmax=ny_l,nboxes=100,nruns=5)
c
         real csctot(imax,jmax),cscnew(imax,jmax)
         dimension iimin(nruns,nboxes),
     1       iimax(nruns,nboxes),jjmin(nruns,nboxes),
     2       jjmax(nruns,nboxes),nbtot(nruns)
         real*4 missval
c
c set up boundaries for boxes to do averaging over
c
         do i=1,imax
         do j=1,jmax
            cscnew(i,j)=csctot(i,j)
         end do
         end do
         nbtot(1)=1
         nbtot(2)=4
         nbtot(3)=9
         nbtot(4)=36
         nbtot(5)=100
         call setboxes(imax,jmax,iimin,iimax,jjmin,jjmax,
     1    nbtot,nruns,nboxes)   
c  
c **************************************************************
c
c Don't know ahead of time how much missing data, so:
c   1) Take average for whole grid, apply to missing points (create
c        cscnew grid).
c   2) Divide grid into 4 boxes. Take average from original grid 
c        in each box. If there are some non-missing points in the
c        box, apply average to missing points (modify cscnew grid). 
c   3) Divide grid into 9 boxes. Take average from original grid 
c        in each box. If there are some non-missing points in the
c        box, apply average to missing points (modify cscnew grid).
c   4) Apply original grid non-missing values to cscnew grid.
c
       do nrun=1,nruns
c 
       do nn=1,nbtot(nrun)
         total=0.
         sum=0.
         do i=iimin(nrun,nn),iimax(nrun,nn)
         do j=jjmin(nrun,nn),jjmax(nrun,nn)
           if(csctot(i,j).le.1.1)then
             sum=sum+csctot(i,j)
             total=total+1.
           endif
         enddo
         enddo
         if(total.eq.0.)then
c          print *,'all values missing for this box'
c          print *,'nrun,nbox=',nrun,nn
c          if(nrun.eq.1)then
c             print *,'ALL VALUES MISSING - CANNOT CONTINUE'
c             stop
c          endif
          go to 50
       else
          avrg=sum/total
c          print *,'nrun,nbox=',nrun,nn
c          print *,'box average=',avrg,' npts=',total
          do i=iimin(nrun,nn),iimax(nrun,nn)
          do j=jjmin(nrun,nn),jjmax(nrun,nn)
             cscnew(i,j)=avrg
          enddo
          enddo
       endif
 50    continue
c
       enddo
c
c       print *,'nrun,nbox=',nrun,nn
c       do j=jmax,1,-1
c       write(6,75)j,(cscnew(i,j),i=1,imax)
c       enddo
c 75    format(1x,i2,61f2.1)
c
       enddo
c
c now overwrite non-missing points
c
       do i=1,imax
       do j=1,jmax
         if(csctot(i,j).le.1.1)cscnew(i,j)=csctot(i,j)
       enddo
       enddo
c
        return
        end
c
c ***********************************************************
c
         subroutine setboxes(imax,jmax,iimin,iimax,jjmin,jjmax,
     1    nbtot,nruns,nboxes)   
c
c set up boundaries for boxes to do averaging over
c   
         dimension iimin(nruns,nboxes),
     1       iimax(nruns,nboxes),jjmin(nruns,nboxes),
     2       jjmax(nruns,nboxes),nbtot(nruns)
c
         do nn=1,nruns
           idir=sqrt(real(nbtot(nn)))
           inc=imax/idir+0.99
c           print *,'nn,idir,inc=',nn,idir,inc
           nbox=1
           do i=1,idir
             do j=1,idir
               iimin(nn,nbox)=1+(i-1)*inc
               iimax(nn,nbox)=min(imax,1+i*inc)
               jjmin(nn,nbox)=1+(j-1)*inc
               jjmax(nn,nbox)=min(jmax,1+j*inc)
               nbox=nbox+1
             enddo
           enddo
c           do nbox=1,nbtot(nn)
c             write(6,10)nn,nbox,inc,iimin(nn,nbox),iimax(nn,nbox),
c     1        jjmin(nn,nbox),jjmax(nn,nbox)
c 10          format(1x,'nn,nbox,inc=',3i3,'imin,max,jmin,max=',4i4)
c           enddo
         enddo
c
         return
         end









