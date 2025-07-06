c-----------------------------------------------------------------------
      subroutine ohms_law(igeom)
c
c     Evaluate Ohm's law for a constant magnetic field
c      
      include 'SIZE'
      include 'TSTEP'           ! IFIELD, ISTEP, NELFLD
      include 'SOLN'            ! VX, VY, VZ, J?MASK
      include 'MASS'            ! BM1, BM2, BINVM1, BM2INV, VOLVM2
      include 'INPUT'           ! IFLDMHD
      include 'GEOM'            ! IFJCOR
      
      common /SCRCRS/ vloc(3), vbloc(3)
      
      common /SCRUZ/ DIVV (LX2,LY2,LZ2,LELV)
     $ ,             BDIVV(LX2,LY2,LZ2,LELV)
     $ ,             WP   (LX2,LY2,LZ2,LELV)
     $ ,             TA1  (LX1,LY1,LZ1,LELV)
     $ ,             TA2  (LX1,LY1,LZ1,LELV)
     $ ,             TA3  (LX1,LY1,LZ1,LELV)
      common /CTOLPR/ DIVEX

      if (igeom.ne.2) return

      IFIELD = IFLDMHD
      ntot1 = NX1*NY1*NZ1*NELFLD(IFIELD)
      ntot2 = NX2*NY2*NZ2*NELFLD(IFIELD)

c     Extrapolate the potential from timesteps (and add to rhs)
      call extrapp(EPOT,EPLAG)
      call opgradt(TA1,TA2,TA3,EPOT)
      
c     Add contribution from u x eb
      do i=1,ntot1
         vloc(1) = VX(i,1,1,1)
         vloc(2) = VY(i,1,1,1)
         vloc(3) = VZ(i,1,1,1)

         call cross(vbloc,vloc,EBVEC)
         TA1(i,1,1,1) = TA1(i,1,1,1) + BM1(i,1,1,1)*vbloc(1)
         TA2(i,1,1,1) = TA2(i,1,1,1) + BM1(i,1,1,1)*vbloc(2)
         TA3(i,1,1,1) = TA3(i,1,1,1) + BM1(i,1,1,1)*vbloc(3)
      enddo

c     Avg at bndry, apply the inverse mass matrix
      call dssum (TA1,NX1,NY1,NZ1)
      call col2  (TA1,BINVM1,ntot1)      
      call dssum (TA2,NX1,NY1,NZ1)
      call col2  (TA2,BINVM1,ntot1)
      call dssum (TA3,NX1,NY1,NZ1)
      call col2  (TA3,BINVM1,ntot1)
      
c     Solve for the electric potential update
      call epotential(WP,TA1,TA2,TA3)
      
c     Compute the gradient of the electric potential
      call opgradt(JX,JY,JZ,WP)

c     Avg at bndry, apply the inverse mass matrix
      call dssum (JX,NX1,NY1,NZ1)
      call col2  (JX,BINVM1,ntot1)      
      call dssum (JY,NX1,NY1,NZ1)
      call col2  (JY,BINVM1,ntot1)
      call dssum (JZ,NX1,NY1,NZ1)
      call col2  (JZ,BINVM1,ntot1)

c     Apply mask
      call col2(JX, J1MASK,ntot1)
      call col2(JY, J2MASK,ntot1)
      call col2(JZ, J3MASK,ntot1)
      call col2(TA1,J1MASK,ntot1)
      call col2(TA2,J2MASK,ntot1)
      call col2(TA3,J3MASK,ntot1)

c     Compute j = u x eb - grad(phi)
      do i=1,ntot1
         JX(i,1,1,1) = VSIGM(i,1,1,1)*(TA1(i,1,1,1) + JX(i,1,1,1))
         JY(i,1,1,1) = VSIGM(i,1,1,1)*(TA2(i,1,1,1) + JY(i,1,1,1))
         JZ(i,1,1,1) = VSIGM(i,1,1,1)*(TA3(i,1,1,1) + JZ(i,1,1,1))
      enddo

c     Full potential
      call add2(EPOT,WP,ntot2)

!c     Ensure zero average
!      if (IFJCOR) then
!         avepot = -glsc2(EPOT,BM2,ntot2)/VOLVM2
!         call cadd(EPOT,avepot,ntot2)
!      endif

c     Check divergence (derived from chkptol)
      call opdiv(BDIVV,JX,JY,JZ)
      call col3 (DIVV,BDIVV,BM2INV,ntot2)
      dnorm = sqrt(glsc2(DIVV,BDIVV,ntot2)/VOLVM2)
      if (nid.eq.0) write (6,'(4x,i7,a,1p2e12.4)')
     $     ISTEP,'  CURRENT: DNORM, DIVEX',dnorm,DIVEX
      
      return
      end
c-----------------------------------------------------------------------
      subroutine epotential(ep,ubx,uby,ubz)
c
c     Compute the electric potential
c     (this routine is derived from incomprn).
c
c     Input:  U x B := (ubx,uby,ubz)
c
c     Output: ep    := electric potential
c
      include 'SIZE'
      include 'TOTAL'
      include 'CTIMER'
c
      common /scrns/ w1    (lx1,ly1,lz1,lelv)
     $ ,             w2    (lx1,ly1,lz1,lelv)
     $ ,             w3    (lx1,ly1,lz1,lelv)
      common /scrvh/ h1    (lx1,ly1,lz1,lelv)
     $ ,             h2    (lx1,ly1,lz1,lelv)
      common /scrhi/ h2inv (lx1,ly1,lz1,lelv)

      real ep(lx2,ly2,lz2,lelv)
      real ubx(lx1,ly1,lz1,lelv), uby(lx1,ly1,lz1,lelv),
     $     ubz(lx1,ly1,lz1,lelv)
      common /screpp/ epprev(lx2*ly2*lz2*lelv*mxprev)

      logical ifprjeep

!     Project out previous potential solutions?    
      ifprjeep=.false.    
      istart=ipepstrt
      if (istep.ge.istart.and.istart.ne.0) ifprjeep=.true.

      if (icalld.eq.0) tepot=0.0
      icalld = icalld+1
      nepot  = icalld
      etime1 = dnekclock()

      ntot1  = lx1*ly1*lz1*nelfld(ifield)
      ntot2  = lx2*ly2*lz2*nelfld(ifield)
      intype = 1

      call rzero   (h1,ntot1)
      call copy    (h2inv,vsigm,ntot1)
      call invers2 (h2,h2inv,ntot1)

      call opcolv3 (w1,w2,w3,ubx,uby,ubz,vsigm)
      call opcol2  (w1,w2,w3,j1mask,j2mask,j3mask)
      call opdiv   (ep,w1,w2,w3)

      call chsign  (ep,ntot2)

      call ortho   (ep)

      if (ifprjeep) call setrhsp  (ep,h1,h2,h2inv,epprev,nepprev)
                    call esolver  (ep,h1,h2,h2inv,intype)
      if (ifprjeep) call gensolnp (ep,h1,h2,h2inv,epprev,nepprev)

      tepot=tepot+(dnekclock()-etime1)

      return
      end
c-----------------------------------------------------------------------
      subroutine set_ifjcor

      include 'SIZE'
      include 'GEOM'
      include 'INPUT'
      include 'SOLN'
c     include 'TSTEP'   ! ifield?

      common  /nekcb/ cb
      character cb*3
      logical ifalgn,ifnorx,ifnory,ifnorz
      
      ifjcor = .true.
      ifield = ifldmhd
      
      nface  = 2*ldim
      ierr   = 0
      do iel=1,nelv
      do ifc=1,nface
         cb = cbc(ifc,iel,ifield)

         if (cb.eq.'EC ') ifjcor = .false.
         if (cb.eq.'SYM') then
            call chknord(ifalgn,ifnorx,ifnory,ifnorz,ifc,iel)
c
c     If the component of the magnetic field orthognal to the symmetry
c     plane vanishes, the corresponding current component is even,
c     which implies that the potential vanishes on the boundary.
c            
            if (ifnorx) then
               if (ebvec(1).eq.0) ifjcor = .false.
               if (ebvec(1).ne.0.and.ebvec(2).ne.0 .or.
     $             ebvec(1).ne.0.and.ebvec(3).ne.0) ierr=ierr+1 ! Consistency check
            endif
            if (ifnory) then
               if (ebvec(2).eq.0) ifjcor = .false.
               if (ebvec(2).ne.0.and.ebvec(1).ne.0 .or.
     $             ebvec(2).ne.0.and.ebvec(3).ne.0) ierr=ierr+1 ! Consistency check
            endif
            if (ifnorz) then
               if (ebvec(3).eq.0) ifjcor = .false.
               if (ebvec(3).ne.0.and.ebvec(1).ne.0 .or.
     $             ebvec(3).ne.0.and.ebvec(2).ne.0) ierr=ierr+1 ! Consistency check
            endif
         endif

      enddo
      enddo

      ierr = iglsum(ierr,1)
      if (ierr.gt.0)
     $     call exitti('Inconsistent symmetries for qsmhd.$',ierr)
      
      call gllog(ifjcor , .false.)

      if (nio.eq.0)  write (6,*) 'IFJCOR    =',ifjcor

      return
      end    
c-----------------------------------------------------------------------
