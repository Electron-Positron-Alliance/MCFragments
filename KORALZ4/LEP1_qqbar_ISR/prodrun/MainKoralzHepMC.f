      PROGRAM KZHEPM
C     KORALZ 4.04 e+e- -> q qbar (+ YFS3 ISR photons) written to HepMC3 for KKMCee's hadronizeKKMC.
C     Inputs mirror KKMCee ProdRun/workQQ_isr{0,1}/pro.input + KKMCee_defaults.
C     Usage: MainKoralzHepMC NEVT OUT.hepmc3 PDGQ(1-5) ISR(0/1) SEED
      COMMON / INOUT / INUT,IOUT
      COMMON  / / BLAN(10000)
      REAL*4    E1(3),E2(3),PB1(4),PB2(4)
      REAL*4    XPR(40)
      INTEGER   NPR(40)
      REAL*4    AMQ(5)
      CHARACTER*512 ARG,OUTF
C KKMCee constituent quark masses d,u,s,c,b (xpar 516..556; d,u "for comparison with KoralZ")
      DATA AMQ /0.083, 0.100, 0.215, 1.5, 4.7/
      INUT=5
      IOUT=6
      CALL GLIMIT(20000)
      CALL GOUTPU(6)
      IF (COMMAND_ARGUMENT_COUNT().NE.5) STOP 'usage'
      CALL GET_COMMAND_ARGUMENT(1,ARG)
      READ(ARG,*) NEVT
      CALL GET_COMMAND_ARGUMENT(2,OUTF)
      CALL GET_COMMAND_ARGUMENT(3,ARG)
      READ(ARG,*) KFQ
      CALL GET_COMMAND_ARGUMENT(4,ARG)
      READ(ARG,*) ISR
      CALL GET_COMMAND_ARGUMENT(5,ARG)
      READ(ARG,*) ISEED
      IF (KFQ.LT.1.OR.KFQ.GT.5) STOP 'PDGQ must be 1..5'
      IF (ISR.NE.0.AND.ISR.NE.1) STOP 'ISR must be 0 or 1'
C TAUOLA RANMAR and YFS3 MARRAN share /RASET1/; MARRAN would re-seed it to 54217137 on its
C first call (YFS3, ISR on) unless MARINI is called first. Seed both.
      CALL RMARIN(ISEED,0,0)
      CALL MARINI(ISEED,0,0)
      DO I=1,40
        XPR(I)=0
        NPR(I)=0
      ENDDO
C ISR on = YFS3 multiphoton, ISR only (forced for quarks); ISR off = no bremsstrahlung.
      KEYRAD=0
      IF (ISR.EQ.1) KEYRAD=12
      NPR(1)=1
      NPR(2)=1
      NPR(3)=4
      NPR(4)=KEYRAD
      NPR(5)=1
      NPR(6)=1
      NPR(7)=500+KFQ
      NPR(8)=0
      NPR(9)=1
      NPR(11)=3
      NPR(12)=1000001
      XPR(1)=91.1876
      XPR(2)=125.1
      XPR(3)=173.0
      XPR(4)=1
      XPR(5)=-1
      XPR(8)=0.010
      XPR(9)=AMQ(KFQ)
      XPR(11)=0.01
      XPR(12)=1E-5
      XPR(13)=0.99
      XPR(14)=0.001
      DO I=1,3
        E1(I)=0
        E2(I)=0
      ENDDO
      ENE=91.1876/2
      PB1(1)=0
      PB1(2)=0
      PB1(3)=ENE
      PB1(4)=ENE
      DO I=1,3
        PB2(I)=-PB1(I)
      ENDDO
      PB2(4)=PB1(4)
C electron along +z, as in KKMCee
      KFB=11
      CALL KORALZ(-1,KFB,PB1,E1,-KFB,PB2,E2,XPR,NPR)
      CALL HEPMCOPEN(OUTF)
      DO IEV=1,NEVT
        CALL KORALZ(0,KFB,PB1,E1,-KFB,PB2,E2,XPR,NPR)
        CALL HEPMCWRITE(IEV)
      ENDDO
      CALL HEPMCCLOSE
      CALL KORALZ(1,0,PB1,E1,0,PB2,E2,XPR,NPR)
      END
      SUBROUTINE TAURDF(KTO)
C THIS ROUTINE CAN BE CALLED BEFORE ANY TAU+ OR TAU- EVENT IS GENERATED
C IT CAN BE USED TO GENERATE TAU+ AND TAU- SAMPLES OF DIFFERENT
C CONTENTS
      COMMON / TAUKLE / BRA1,BRK0,BRK0B,BRKS
      REAL*4            BRA1,BRK0,BRK0B,BRKS
      COMMON / TAUBRA / GAMPRT(30),JLIST(30),NCHAN
      IF (KTO.EQ.1) THEN
C     ==================
C LIST OF BRANCHING RATIOS
      NCHAN = 19
      DO 1 I = 1,30
      IF (I.LE.NCHAN) THEN
        JLIST(I) = I
        IF(I.EQ. 1) GAMPRT(I) = .0000
        IF(I.EQ. 2) GAMPRT(I) = .0000
        IF(I.EQ. 3) GAMPRT(I) = .0000
        IF(I.EQ. 4) GAMPRT(I) = .0000
        IF(I.EQ. 5) GAMPRT(I) = .0000
        IF(I.EQ. 6) GAMPRT(I) = .0000
        IF(I.EQ. 7) GAMPRT(I) = .0000
        IF(I.EQ. 8) GAMPRT(I) = 1.0000
        IF(I.EQ. 9) GAMPRT(I) = 1.0000
        IF(I.EQ.10) GAMPRT(I) = 1.0000
        IF(I.EQ.11) GAMPRT(I) = 1.0000
        IF(I.EQ.12) GAMPRT(I) = 1.0000
        IF(I.EQ.13) GAMPRT(I) = 1.0000
        IF(I.EQ.14) GAMPRT(I) = 1.0000
        IF(I.EQ.15) GAMPRT(I) = 1.0000
        IF(I.EQ.16) GAMPRT(I) = 1.0000
        IF(I.EQ.17) GAMPRT(I) = 1.0000
        IF(I.EQ.18) GAMPRT(I) = 1.0000
        IF(I.EQ.19) GAMPRT(I) = 1.0000
      ELSE
        JLIST(I) = 0
        GAMPRT(I) = 0.
      ENDIF
   1  CONTINUE
C --- COEFFICIENTS TO FIX RATIO OF:
C --- A1 3CHARGED/ A1 1CHARGED 2 NEUTRALS MATRIX ELEMENTS (MASLESS LIM.)
C --- PROBABILITY OF K0 TO BE KS
C --- PROBABILITY OF K0B TO BE KS
C --- RATIO OF COEFFICIENTS FOR K*--> K0 PI-
C --- ALL COEFFICENTS SHOULD BE IN THE RANGE (0.0,1.0)
C --- THEY MEANING IS PROBABILITY OF THE FIRST CHOICE ONLY IF ONE
C --- NEGLECTS MASS-PHASE SPACE EFFECTS
      BRA1=0.5
      BRK0=0.5
      BRK0B=0.5
      BRKS=0.6667
      ELSE
C     ====
C LIST OF BRANCHING RATIOS
      NCHAN = 19
      DO 2 I = 1,30
      IF (I.LE.NCHAN) THEN
        JLIST(I) = I
        IF(I.EQ. 1) GAMPRT(I) = .0000
        IF(I.EQ. 2) GAMPRT(I) = .0000
        IF(I.EQ. 3) GAMPRT(I) = .0000
        IF(I.EQ. 4) GAMPRT(I) = .0000
        IF(I.EQ. 5) GAMPRT(I) = .0000
        IF(I.EQ. 6) GAMPRT(I) = .0000
        IF(I.EQ. 7) GAMPRT(I) = .0000
        IF(I.EQ. 8) GAMPRT(I) = 1.0000
        IF(I.EQ. 9) GAMPRT(I) = 1.0000
        IF(I.EQ.10) GAMPRT(I) = 1.0000
        IF(I.EQ.11) GAMPRT(I) = 1.0000
        IF(I.EQ.12) GAMPRT(I) = 1.0000
        IF(I.EQ.13) GAMPRT(I) = 1.0000
        IF(I.EQ.14) GAMPRT(I) = 1.0000
        IF(I.EQ.15) GAMPRT(I) = 1.0000
        IF(I.EQ.16) GAMPRT(I) = 1.0000
        IF(I.EQ.17) GAMPRT(I) = 1.0000
        IF(I.EQ.18) GAMPRT(I) = 1.0000
        IF(I.EQ.19) GAMPRT(I) = 1.0000
      ELSE
        JLIST(I) = 0
        GAMPRT(I) = 0.
      ENDIF
   2  CONTINUE
C --- COEFFICIENTS TO FIX RATIO OF:
C --- A1 3CHARGED/ A1 1CHARGED 2 NEUTRALS MATRIX ELEMENTS (MASLESS LIM.)
C --- PROBABILITY OF K0 TO BE KS
C --- PROBABILITY OF K0B TO BE KS
C --- RATIO OF COEFFICIENTS FOR K*--> K0 PI-
C --- ALL COEFFICENTS SHOULD BE IN THE RANGE (0.0,1.0)
C --- THEY MEANING IS PROBABILITY OF THE FIRST CHOICE ONLY IF ONE
C --- NEGLECTS MASS-PHASE SPACE EFFECTS
      BRA1=0.5
      BRK0=0.5
      BRK0B=0.5
      BRKS=0.6667
      ENDIF
C     =====
      END
