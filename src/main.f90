program LQGeq
    
    use iso_fortran_env, only: RK => real64
    use OMP_LIB
    implicit none

    real(RK) :: T1, T2, xxx
    integer  :: iTimes1, iTimes2, rate!, iTimesA,iTimesB

    integer :: error_code

    ! Physical parameters
    real(RK), parameter :: eps = 0.0001_RK, PI=4._RK*DATAN(1._RK)

    real(RK) :: T_final, &   ! Max integration time
                    r0,      &   ! Density cutoff
                    a0,      &   ! FRW param
                    m,       &   ! Total mass
                    t,       &   ! Integrated time
                    dt           ! Time step
    real(RK), dimension(:), allocatable :: &
                    xs,      &   ! Grid
                    u,       &   ! Solution
                    u_p,     &   ! Previous solution
                    rho          ! Density profile

    ! Computational parameters
    real(RK) :: xM,      &   ! Outer boundary of the grid
                h,       &   ! Grid spacing
                ssum        
    integer  :: r,       &   ! Order of the WENO method
                nghost,  &   ! Number of ghost cells
                NX,      &   ! Number of points in xs
                N_output,&   ! Print output every
                N_save,  &   ! Save every
                nthreads     ! Number of threads for OpenMP
                
    ! Iterators           
    integer :: i, counter

    ! Input arguments
    integer :: num_args
    character(len=100), dimension(2) :: args
    ! Save
    character(len=100) :: fpath

    CALL system_clock(count_rate=rate)
    call cpu_time(T1)
    call SYSTEM_CLOCK(iTimes1)
    ! iTimesA = iTimes1

    ! Read configuration parameters
    num_args = command_argument_count()
    if (num_args .gt. 2) STOP "Only two args are contemplated, the path of the configuration file and the path for the output!"
    do i = 1, 2
        call get_command_argument(i,args(i))
        if (args(i) .eq. '') then
            if (i.eq.1) then
                args(i) = 'ParameterFile.dat'
            else if (i .eq. 2) then
                args(i) = 'outputs'
            end if
        end if
    end do

    !!! TEMP
    a0 = 20_RK
    
    call inputParser(args(1), T_final, r0, m, r, xM, h, N_save, N_output, nthreads)

    CALL OMP_SET_NUM_THREADS(nthreads)

    ! Perform consistency checks
    if (r .eq. 2) then
        nghost = 1
    else
        STOP "Only r = 2 is implemented."
    end if

    ! PRINT SUMMARY AND NICE OUTPUT
    write(*, "(A42)") "------------------------------------------"
    write(*, "(A12)") "WENO3 SOLVER"
    write(*, "(A42)") "------------------------------------------"
    write(*, "(A7)") "SUMMARY"
    write(*, "(A27, F9.2)") "   - Simulation time      :    ", T_final
    write(*, "(A27, E9.3)") "   - Grid spacing         :    ", h
    write(*, "(A27, F9.2)") "   - Total mass           :    ", m
    write(*, "(A27, F9.2)") "   - Characteristic radius:    ", r0
    write(*, "(A27, I9)") "   - Number of threads    :    ", nthreads
    write(*, "(A42)") "------------------------------------------"
    write(*, "(A36)") "        Starting simulation...      "
    write(*, "(A42)") "------------------------------------------"
    write(*, "(A42)") "    Time   ||    Iteration   ||    M - M0 "

    ! Define numerical grid
    NX = int(xM / h + 1 + 2*nghost)
    allocate(xs(NX), u(2*NX), u_p(2*NX), rho(NX), stat=error_code)
    if(error_code /= 0) STOP "Error during array allocations!"

    do i = 1, NX
        xs(i) = (eps + i - 1 - nghost) * h
    end do
    fpath = trim(args(2)) // '/xs.dat'
    call save(fpath, xs(nghost+1:NX-nghost-1), NX-2*nghost)

    ! Produce initial data
    call initial_data(NX, xs, m, r0, a0, u_p)
    
    counter = 0
    ! Time evolution
    t = 0_RK
    do while (t.lt.T_final)

        ! Determine dt from Courant condition
        call CLF(NX, u_p, xs, h, dt)

        if ((t + dt).gt.T_final) then
            dt = T_final - t
            t = T_final
        else
            t = t + dt
        end if

        ! Perform time step
        call TVD_RK(NX, u_p, xs, h, dt, nghost, u)

        ! TERMINAL OUTPUT
        if (mod(counter, N_output).eq.0) then
            ! call SYSTEM_CLOCK(iTimesB)
            ! xxx = real(iTimesB-iTimesA)/real(rate)
            ! call SYSTEM_CLOCK(iTimesA)

            call compRho(NX, h, dt, u(1:NX), u_p(1:NX), u(NX+1:2*NX), xs, rho)
            ! COMPUTE MASS
            ssum = 0_RK
            do i = 2, NX
                ssum = ssum + (rho(i-1) + rho(i)) / (2._RK * dt)
            end do

            write(*, "(2x, F6.3, 3x, A2, 3x, I9, 4x, A2, 3x, E11.3)") t, "||",  counter,  "||",  ssum*h - m
            ! write(*,*) "Computed in", xxx, "seconds."
        end if

        if ( (mod(counter, N_save).eq.0).or.(t.eq.T_final) ) then
            call compRho(NX, h, dt, u(1:NX), u_p(1:NX), u(NX+1:2*NX), xs, rho)
            call saveOutput(args(2), NX, u(1:NX), u(NX+1:2*NX), rho, nghost)
        end if
        counter = counter + 1

        ! Update previous step
        if ( t.lt.T_final ) then
            do i = 1, 2*NX
                u_p(i) = u(i)
            end do
        end if

    end do

    write(*, "(A36)") "------------------------------------"
    write(*, "(A36)") "            All done!               "
    write(*, "(A36)") "------------------------------------"

    call cpu_time(T2)
    call SYSTEM_CLOCK(iTimes2)
    write(*, "(A18,1x, F7.2, A8)") "Total CPU time   :", T2 - T1, " seconds."
    xxx = real(iTimes2-iTimes1)/real(rate)
    write(*, "(A18,1x, F7.2, A8)") "Total system time:", xxx, " seconds."

    deallocate(xs, u, u_p, rho)

end program LQGeq