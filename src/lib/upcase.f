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

        subroutine      upcase(input,output)

!       This routine only handles strings up to 500 characters long.

        character*(*)   input,
     1          output
        character*500   string

        integer*4       nchar,
!       1               lnblnk,
     1          l,
     1          len,
     1          chr,
     1          i

        string=input

!       nchar=lnblnk(string)

        if(string(500:500) .ne. ' ')then
            write(6,*)'String truncated to 500 characters.'
        endif

        do i = 500,1,-1
            if(string(i:i) .ne. ' ')then
                nchar = i
                go to 10
            endif
        enddo

10      continue

        l=len(output)
        do i=1,l
                output(i:i)=' '
        enddo

        do i=1,nchar
                chr=ichar(string(i:i))
                if (chr .ge. 97 .and. chr .le. 122) chr=chr-32
                output(i:i)=char(chr)
        enddo

        return

        end

