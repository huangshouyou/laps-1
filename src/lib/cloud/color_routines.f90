
        subroutine nl_to_RGB(rad,glwref,contrast,cntref,iverbose,rc,gc,bc)

        include 'wa.inc'
        include 'wac.inc'

        real luminance ! candela / m**2
        real luma_of_counts
        integer init /0/
        save init,fasun

        parameter (day_int = 3e9)

        counts_to_rad(counts) = 10.**(((counts-cntref)/contrast)+glwref)
        rad_to_counts(rad) = (log10(rad)-glwref)*contrast + cntref

        expgamma(x) = 1. - exp(-x**(1./gamma))
        expgaminv(x) = (-(log(1.-x)))**gamma ! inverse of expgamma
        radhi(glwref,cntref) = (10.**glwref) / (expgaminv(cntref/255.))
        rad_to_counts2(rad) = expgamma(rad/radhi(glwref,cntref)) * 255.

!       Convert nl to rintensity

!       Radiance units are watts/(m**2 sr nm)

!       Input rad defined as 3e9 nl for each color normalized by solar
!       spectrum reflecting off a lambertian surface. An input matching
!       the solar spectrum has equal values in each color.
!       Note solar constant is 1361.5 watts/m**2
        real rad(nc) 
        real rel_solar(nc), cdm2(nc)
        real fasun(nct), rel_solar_extrap(nct), farad(nct)
        real nl_int

        if(init .eq. 0)then
            call get_fluxsun(wa_tri,nct,1,fasun)
            init = 1
        endif

!       nl_int = rgb_to_y(rad(1),rad(2),rad(3))

        rel_solar(:) = rad(:) / day_int
        rel_solar_luminance = rgb_to_y(rel_solar(1),rel_solar(2) &
                                      ,rel_solar(3))
        if(iverbose .eq. 1)then
          write(6,*)'rel_solar_luminance = ',rel_solar_luminance
        endif

!       1 lambert = 3183.0988 candela/m**2        (luminance)
!       1 lux = 1 lumen/m**2                      (illuminance)
!       1 candela = 1/683.002 watts/sr (at 550nm)                 
!       1 watt = 683 lumens (555nm source)        (radiant flux)
!       1 watt =  93 lumens (solar spectrum)      (radiant flux)
!       1 watt/m**2                               (irradiance)
!       1 lumen = 1 cd*sr                         (luminous flux)
!       1 candela = 1 lumen per steradian
        cdm2(:) = (rad(:)/1e9) * 3183.0988 ! nl to candela/m**2

!       Extrapolate color            
        call extrap_color(rel_solar,rel_solar_extrap)
        farad(:) = fasun(:) * rel_solar_extrap(:)
        if(iverbose .eq. 1)write(6,*)' farad = ',farad

!       Convert rad to xyz
        call get_tricolor(farad,iverbose,xx,yy,zz,x,y,z,luminance)
        if(iverbose .eq. 1)write(6,*)'xyzfarad = ',x,y,z
        if(iverbose .eq. 1)write(6,*)'luminance farad = ',luminance

!       Convert xyz to (linear) rgb
        call xyztosrgb(x,y,z,r,g,b)             

!       Convert rintensity to rgb
        call linearrgb_to_counts(r,g,b,rc,gc,bc)

        if(iverbose .eq. 1)write(6,*)'glwref/contrast = ',glwref,contrast
!       if(iverbose .eq. 1)write(6,*)'rad of 240 counts = ',counts_to_rad(240.)

!       desired_rad = counts_to_rad(240.) * rel_solar_luminance
!       if(iverbose .eq. 1)write(6,*)'desired rad = ',desired_rad

        luma_of_counts = RGB2luma(rc,gc,bc)
        if(iverbose .eq. 1)write(6,*)'luma_of_counts = ',luma_of_counts

!       solar_counts = 240.
        solar_counts = rad_to_counts2(day_int)
        if(iverbose .eq. 1)write(6,*)'solar_counts = ',solar_counts

!       desired_luma = 240. * rel_solar_luminance**(1./gamma)
!       desired_luma = solar_counts + log10(rel_solar_luminance) * contrast
        desired_luma = rad_to_counts2(day_int*rel_solar_luminance)
        if(iverbose .eq. 1)write(6,*)'desired luma = ',desired_luma
        scale_luma = desired_luma / luma_of_counts
        if(iverbose .eq. 1)write(6,*)'scale_luma = ',scale_luma
        rc = rc * scale_luma       
        gc = gc * scale_luma       
        bc = bc * scale_luma       
        
        return
        end

        subroutine extrap_color(a_nc,a_nct)

        include 'wa.inc'
        include 'wac.inc'

        real a_nc(nc), a_nct(nct)

!       Assuming nc = 3, find polynomial fit
        X1 = wa(1);   X2 = wa(2);   X3 = wa(3)
        Y1 = a_nc(1); Y2 = a_nc(2); Y3 = a_nc(3)

        a = ((Y2-Y1)*(X1-X3) + (Y3-Y1)*(X2-X1)) / &
            ((X1-X3)*(X2**2-X1**2) + (X2-X1)*(X3**2-X1**2))
        b = ((Y2 - Y1) - A*(X2**2 - X1**2)) / (X2-X1)
        c = Y1 - A*X1**2 - B*X1

        a_nct(:) = a*wa_tri(:)**2 + b*wa_tri(:) + c
 
        return
        end

        subroutine rad_to_xyz(rad_in,x,y,z)

        real rad_in(3),rad(3)

        rad(1) = rad_in(1) + 0.2 * rad_in(3)
        rad(2) = rad_in(2)
        rad(3) = rad_in(3)

        x = rad(1) / sum(rad)
        y = rad(2) / sum(rad)
        z = rad(3) / sum(rad)

        return
        end

        subroutine linearrgb_to_counts(r,g,b,rc,gc,bc)

        parameter (gamma = 2.2)

        rr = r ** (1./gamma)
        gg = g ** (1./gamma)
        bb = b ** (1./gamma)

        rc = rr*255. 
        gc = gg*255. 
        bc = bb*255. 
      
        return
        end

        subroutine xyztorgb(x,y,z,r,g,b)

        xx = x; yy = y; zz = z

        R=  (0.41847   *XX)-(0.15866  *YY)-(0.082835*ZZ)
        G= -(0.091169  *XX)+(0.25243  *YY)+(0.015708*ZZ)
        B=  (0.00092090*XX)-(0.0025498*YY)+(0.17860 *ZZ)

        return
        end

        subroutine rgbtoxyz(r,g,b,x,y,z) 

        x = (.49    * r + .31    * g + .20    * b) / 0.17697
        y = (.17697 * r + .81240 * g + .01063 * b) / 0.17697
        z = (             .01    * g + .99    * b) / 0.17697

        return
        end

        subroutine xyztosrgb(x,y,z,r,g,b)

        r =  3.2406*x -1.5372*y -0.4986*z
        g = -0.9689*x +1.8758*y +0.0415*z
        b =  0.0557*x -0.2040*y +1.0570*z

        return
        end

        subroutine srgbtoxyz(r,g,b,x,y,z)
 
        x =  0.4124*r + 0.3576*g + 0.1805*b
        y =  0.2126*r + 0.7152*g + 0.0722*b
        z =  0.0193*r + 0.1192*g + 0.9505*b
 
        return
        end

        subroutine get_fluxsun(wa,nc,iverbose,fa)

!       include 'wa.inc'
!       include 'wac.inc'

        real fa(nc) ! watts/(m**2 sr nm)
        real wa(nc)

        if(iverbose .eq. 1)write(6,*)'  subroutine get_fluxsun',nc,wa

        TS = 5780.
        RS = 1.0 ; DS = 1.0
        xc = 0.; yc = 0.; zc = 0.

        do ic = 1,nc   
          W = wa(ic) * 1e-4 ! microns to cm  
          w_ang = wa(ic) * 10000.
          BB = (.0000374/(W**5.)) / (EXP(1.43/(W*TS))-1.)
          if(iverbose .eq. 1)write(6,*)'ic/w/bb',ic,w,bb
          FA(IC)=((RS/DS)**2)*BB*1E-8
        enddo ! ic

        if(iverbose .eq. 1)write(6,*)'fa sun is ',fa   

        return
        end

        subroutine get_tricolor(fa,iverbose,xc,yc,zc,x,y,z,luminance)

        include 'wa.inc'
        include 'wac.inc'

        real fa(nct)   ! 
        real luminance ! candela / m**2
        character*255 static_dir

!       3500 to 8000 Angstroms in 10 steps (color matching functions)
        real x1(nct)!/0, .014, .336, .005, .433, 1.062, .283, .011, 0, 0/
        real y1(nct)!/0, .0004, .038, .323, .995, .631, .107, .004, .0001, 0/
        real z1(nct)!/0, .068, 1.773, .272, .009, 0,0,0,0,0/
        integer init/0/
        save x1,y1,z1,init

        if(init .eq. 0)then
          call get_directory('static',static_dir,len_dir)
          open(11,file=trim(static_dir)//'/cie2.txt',status='old')
!         open(11,file='cie2.txt',status='old')
          do ict = 1,nct
            read(11,*)inm,x1(ict),y1(ict),z1(ict)
          enddo ! ict
          init = 1
        endif

        xc = 0.; yc = 0.; zc = 0.

!       Integrate with trapezoidal rule
        do ic = 2,nct   
          icm = ic-1
          W = wa_tri(ic) * 1e-4 ! microns to cm  
          w_ang = wa_tri(ic) * 10000.

          xs = 0.5 * (x1(icm)*fa(icm) + x1(ic)*fa(ic))
          ys = 0.5 * (y1(icm)*fa(icm) + y1(ic)*fa(ic))
          zs = 0.5 * (z1(icm)*fa(icm) + z1(ic)*fa(ic))
  
          xc = xc + xs
          yc = yc + ys
          zc = zc + zs

          if(iverbose .eq. 1)then
            write(6,1)ic,w_ang,fa(ic),xs,ys,zs,xc,yc,zc
1           format(' ic,wa,fa',i4,f8.0,f10.0,' xyzs',3f10.0,' xyzc',3f10.0)
          endif
 
        enddo ! ic

        x = xc / (xc+yc+zc)
        y = yc / (xc+yc+zc)
        z = zc / (xc+yc+zc)

        luminance = yc

        if(iverbose .eq. 1)write(6,11)x,y,z,luminance
11      format(' xyzl tricolor is ',3f10.6,f12.0)

        return
        end
