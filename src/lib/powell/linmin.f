      SUBROUTINE LINMIN(P,XI,N,FRET)
      PARAMETER (NMAX=50,TOL=1.E-4)
      EXTERNAL F1DIM
      DIMENSION P(N),XI(N)
      COMMON /F1COM/ NCOM,PCOM(NMAX),XICOM(NMAX)
      NCOM=N
      DO 11 J=1,N
        PCOM(J)=P(J)
        XICOM(J)=XI(J)
11    CONTINUE
      AX=0.
      XX=1.
      CALL MNBRAK(AX,XX,BX,FA,FX,FB,F1DIM)
      FRET=BRENT(AX,XX,BX,F1DIM,TOL,XMIN)
      DO 12 J=1,N
        XI(J)=XMIN*XI(J)
        P(J)=P(J)+XI(J)
12    CONTINUE
      RETURN
      END
