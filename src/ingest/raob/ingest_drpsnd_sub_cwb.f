      subroutine get_drpsnd_data_cwb ( i4time_sys, ilaps_cycle_time,
     ~         nx_l, ny_l, i4time_drpsnd_earliest, i4time_drpsnd_latest,
     ~         a9_time, filename, istatus )

      integer   loopNum, levelNum  
      parameter ( loopNum=100, levelNum=90 )

      character(*)   filename
      character(3)   reportFlag
      character(5)   taskName(loopNum)
      character(2)   yy, mo, dd, hh, mn, flag
      character(9)   a9time(loopNum), a9timeDummy, a10_to_a9, a9_time
      character(10)  time

      real  lat_a(nx_l,ny_l), lon_a(nx_l,ny_l), topo_a(nx_l,ny_l)
      real  latitudeDummy, longitudeDummy
      real  elevation(loopNum), latitude(loopNum), longitude(loopNum)
      real  pressure(loopNum,levelNum), height(loopNum,levelNum)
      real  temperature(loopNum,levelNum)
      real  tempDewDiff(loopNum,levelNum), dewpoint(loopNum,levelNum)
      real  windDir(loopNum,levelNum), windSpeed(loopNum,levelNum)
      real  PrsHtDbtL(loopNum), PrsHtDbtH(loopNum)
      real  PrsTmDbtL(loopNum), PrsTmDbtH(loopNum)

      integer wmoId(loopNum), layerNum(loopNum)
      integer heightQua(loopNum,levelNum), dewpointQua(loopNum,levelNum)       
      integer temperatureQua(loopNum,levelNum),windQua(loopNum,levelNum)
      integer recNum, inNum, jumpNum, logicRecNum
      integer d(12)

      data  d / 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /

      call get_r_missing_data(r_missing_data,istatus)
      if ( istatus /= 1 ) then
         write (6,*) ' Error getting r_missing_data'
         return
      endif

      recNum=    0
      inNum=     0        ! inNum : the record number within time window
      istatus=   0
      wmoId=     0
      elevation= 0.

      open ( 1, file=filename, status='old', err=1000 )

      istatus= 1

      do i= 1,loopNum
         read (1,5,end=99,err=29) reportFlag, 
     ~                            latitudeDummy, longitudeDummy,
     ~                            iy, m1, id, ih, m2, logicRecNum
5        format ( a3, i5, f4.0, 2f5.2, 2x, 5i2, i3 )

         if ( reportFlag /= '*15' )  then
            write (6,*) 
     ~            ' Error reading drpsnd data of identification -reject'
	    write (6,*) reportFlag, latitudeDummy, longitudeDummy

            jumpNum= logicRecNum -1
            do 11 k= 1,jumpNum
11             read (1,*)
            go to 51
         endif

c               ------ creat a9time in yydddhhmm format ------
         if ( m1 == 2  .and.  mod(iy,4) == 0 )  d(m1)= d(m1) +1
	  
         if ( m2 /= -9 )  then   ! minus 30 mins to obtain the time in the air
            m2= m2 -30

            if ( m2 .lt. 0 )  then
               m2= m2 +60
               ih= ih -1

               if ( ih .lt. 0 )  then
                  ih= 23
                  id= id -1

                  if ( id .lt. 1 )  then
                     m1= m1 -1
                         
                     if ( m1 .lt. 1 )  then
                        m1= 12
                        iy= iy -1
                     endif

                     id= d(m1)
                  endif
               endif
            endif

         else         ! 00:-9 23:-9 -> 00:00 as the time in the air
            m2= 0     ! 12:-9 11:-9 -> 12:00 
	    if ( ih == 11  .or.  ih == 23 )  ih= ih +1

            if ( ih >= 24 )  then
               ih= 0
               id= id +1

               if ( id > d(m1) )  then
                  id= 1
                  m1= m1 +1
                      
                  if ( m1 > 12 )  then
                     m1= 1
                     iy= iy +1
                  endif
               endif
            endif

         endif
            
         call i2a ( iy, yy )
         call i2a ( m1, mo )
         call i2a ( id, dd )
         call i2a ( ih, hh )
         call i2a ( m2, mn )

         time= yy//mo//dd//hh//mn
         a9timeDummy= a10_to_a9(time,istatus)
         call cv_asc_i4time( a9timeDummy, i4time_drpsnd )

c          ----------    test if drpsnd is within time window    ----------
         if ( i4time_drpsnd /= 0 ) then    
            if ( i4time_drpsnd >= i4time_drpsnd_earliest .and.
     ~           i4time_drpsnd <= i4time_drpsnd_latest )  then
	       write (6,*) reportFlag, latitudeDummy, longitudeDummy,
     ~                     yy, mo, dd, hh, mn, logicRecNum,
     ~                     ' Inside time window'
	       inNum= inNum +1

	       latitude(inNum)= latitudeDummy
	       longitude(inNum)= longitudeDummy
	       a9time(inNum)= a9timeDummy

               layerNum(inNum)= logicRecNum -5
               do j= 1,layerNum(inNum)
                  read (1,15,err=19,end=99) pressure(inNum,j),
     ~              height(inNum,j), heightQua(inNum,j),      
     ~              temperature(inNum,j), temperatureQua(inNum,j),        
     ~              tempDewDiff(inNum,j), dewpointQua(inNum,j),
     ~              windDir(inNum,j),windSpeed(inNum,j),windQua(inNum,j)      
15                format ( 2x, f5.1, f5.0, i2, 2(f4.1,i2), 2f3.0, i2 )
	          go to 20

19                write (6,*)' Error reading variables of drpsnd data'
                  do k= 1,j
                     write (6,*) pressure(inNum,k),
     ~                    height(inNum,k), heightQua(inNum,k),       
     ~                    temperature(inNum,k), temperatureQua(inNum,k),
     ~                    tempDewDiff(inNum,k), dewpointQua(inNum,k),
     ~                    windDir(inNum,k), windSpeed(inNum,k),
     ~                    windQua(inNum,k)
                  enddo
20             enddo

               read (1,*)
               read (1,21) taskName(inNum), 
     ~                     PrsHtDbtL(inNum), PrsHtDbtH(inNum)
               read (1,22) PrsTmDbtL(inNum), PrsTmDbtH(inNum)
               read (1,*)
21             format ( 5x, a5, 10x, 2f5.1 )
22             format ( 2f5.1 )
    	       goto 50

            else
               write (6,*) reportFlag, latitudeDummy, longitudeDummy,
     ~                     yy, mo, dd, hh, mn, logicRecNum,
     ~                     ' Outside time window -reject'
    	       goto 40

            endif
         endif

29       write (6,*) ' Error reading drpsnd codes of stations -reject'
	 write (6,*) reportFlag, latitudeDummy, longitudeDummy,
     ~               iy, m1, id, ih, m2, logicRecNum
	 do k= 1,levelNum
            read (1,'(a2)') flag
	    if ( flag == '25' )  go to 50
	 enddo

40       jumpNum= logicRecNum -1
         do 41 k= 1,jumpNum
41          read (1,*) 

50       recNum= recNum +1
51    enddo

c      ----------     examing data quality and changing units     ---------    
c      when elevation is missing, return -999. without change for the sake of 
c      format f15.0 in snd files
99    do 100 i= 1,inNum
      do 100 j= 1,layerNum(i)

         if ( pressure(i,j) == -999. )  pressure(i,j)= r_missing_data
         if ( heightQua(i,j) /= 1 )  height(i,j)= r_missing_data
         if ( temperatureQua(i,j) /= 1 ) temperature(i,j)=r_missing_data

         tmpFlag= 0
         if     ( PrsHtDbtL(i) >= pressure(i,j)  .and.
     ~            PrsHtDbtH(i) <= pressure(i,j) ) then
            height(i,j)= r_missing_data
         elseif ( PrsTmDbtL(i) >= pressure(i,j)  .and.
     ~            PrsTmDbtH(i) <= pressure(i,j) ) then
            temperature(i,j)= r_missing_data
            tmpFlag= 1.
         endif

         if ( temperatureQua(i,j) == 1 .and. dewpointQua(i,j) == 1 .and.
     ~        tmpFlag == 0 ) then
               dewpoint(i,j)= temperature(i,j) -tempDewDiff(i,j)
            else
               dewpoint(i,j)= r_missing_data
         endif

         if ( windQua(i,j) /= 1 )  then
            windDir(i,j)= r_missing_data
            windSpeed(i,j)= r_missing_data
         endif
100   continue

      do 900 i= 1,inNum
	 write(11,895) wmoId(i), layerNum(i), latitude(i), longitude(i),
     ~                 elevation(i), taskName(i), a9time(i), 'DRPSND'
895      format (i12, i12, f11.4, f15.4, f15.0, 1x, a5, 3x, a9, 1x, a8)

         do 900 j= 1,layerNum(i)
            write (11,*) height(i,j), pressure(i,j), temperature(i,j),
     ~                   dewpoint(i,j), windDir(i,j), windSpeed(i,j)
900   continue

      write (6,*) ' found', inNum, 
     ~            'stations available within time window in',
     ~            recNum, 'drpsnd stations'

1000  return
      end



