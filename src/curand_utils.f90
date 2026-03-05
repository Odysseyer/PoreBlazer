!-------------------------------------------------------------------------
! cuRAND Utilities Module for OpenACC GPU Random Number Generation
!
! This module provides random number generation for OpenACC parallel regions.
! It uses a per-thread Linear Congruential Generator (LCG) with thread-specific
! seeding for reproducible, parallel-safe random numbers.
!
! Usage:
!   ! Initialize before parallel loop (sets up any needed state)
!   call curand_init_states(nstates, seed)
!
!   ! Inside parallel loop - each thread gets independent random stream
!   !$acc parallel loop
!   do i = 1, n
!       rnum = curand_uniform(i)  ! Pass thread index
!   end do
!   !$acc end parallel loop
!
!   ! Cleanup after parallel loop
!   call curand_free_states()
!
! Note: Requires NVIDIA HPC SDK (nvfortran) with OpenACC support
!-------------------------------------------------------------------------
module curand_utils
    use iso_c_binding
    implicit none
    private

    ! Parameters for the LCG (from "Tables of Linear Congruential Generators
    ! of Different Sizes and Good Lattice Structure" by L'Ecuyer, 1999)
    ! These constants provide a period of 2^64
    integer(c_int64_t), parameter :: LCG_A = 2862933555777941757_c_int64_t
    integer(c_int64_t), parameter :: LCG_C = 1_c_int64_t
    real(c_double), parameter :: LCG_NORM = 5.4210108624275221700372640e-20_c_double

    ! State array for random number generation (kept for potential future use)
    integer(c_int64_t), allocatable, dimension(:) :: rng_states
    !$acc declare device_resident(rng_states)

    ! Number of states allocated
    integer :: nstates_alloc = 0

    public :: curand_init_states, curand_uniform, curand_free_states

contains

    !-----------------------------------------------------------------------
    ! Initialize random number states on the GPU device
    !
    ! Arguments:
    !   nstates - Number of parallel random streams to create
    !   seed    - Random seed for reproducibility
    !
    ! This allocates a state array and initializes each state with a
    ! different seed derived from the base seed.
    !-----------------------------------------------------------------------
    subroutine curand_init_states(nstates, seed)
        integer, intent(in) :: nstates
        integer, intent(in) :: seed

        integer :: i

        ! Free any previously allocated states
        if (allocated(rng_states)) then
            call curand_free_states()
        end if

        ! Allocate state array
        allocate(rng_states(nstates))
        nstates_alloc = nstates

        ! Initialize states on device
        ! Each thread gets a unique starting state based on its index and seed
        !$acc parallel loop present(rng_states)
        do i = 1, nstates
            ! Initialize with a hash of seed and index
            ! Using a simple multiplicative hash
            rng_states(i) = int(seed, c_int64_t) * LCG_A + int(i, c_int64_t) * LCG_C
            ! Advance state a few steps to ensure good distribution
            rng_states(i) = rng_states(i) * LCG_A + LCG_C
            rng_states(i) = rng_states(i) * LCG_A + LCG_C
            rng_states(i) = rng_states(i) * LCG_A + LCG_C
        end do
        !$acc end parallel loop

    end subroutine curand_init_states

    !-----------------------------------------------------------------------
    ! Generate a uniform random number in [0, 1) on the GPU
    !
    ! Arguments:
    !   idx - Index of the random stream (thread/gang index)
    !
    ! Returns:
    !   Uniform random number in [0, 1)
    !
    ! This function is designed to be called from within OpenACC parallel
    ! regions. It updates the state and returns a uniform random value.
    !-----------------------------------------------------------------------
    function curand_uniform(idx) result(rnum)
        integer, intent(in) :: idx
        real(c_double) :: rnum

        integer(c_int64_t) :: state

        ! Get current state (use module variable if initialized, else compute on fly)
        if (nstates_alloc > 0 .and. idx <= nstates_alloc) then
            ! Each thread accesses its own unique index - no race condition
            ! No atomics needed since idx is unique per thread in parallel loops
            state = rng_states(idx)

            ! Advance state
            state = state * LCG_A + LCG_C

            ! Update state (safe because idx is unique per thread)
            rng_states(idx) = state
        else
            ! Fallback: compute stateless random from index and seed
            ! Use a hash function for better distribution when unallocated
            state = int(idx, c_int64_t) * LCG_A + LCG_C
            state = state * LCG_A + LCG_C
            state = state * LCG_A + LCG_C
        end if

        ! Convert state to [0, 1) double
        ! Mask the sign bit to ensure positive value
        rnum = real(iand(state, 9223372036854775807_c_int64_t), c_double) * LCG_NORM

    end function curand_uniform

    !-----------------------------------------------------------------------
    ! Free GPU memory allocated for random number states
    !-----------------------------------------------------------------------
    subroutine curand_free_states()
        if (allocated(rng_states)) then
            !$acc exit data delete(rng_states)
            deallocate(rng_states)
        end if
        nstates_alloc = 0
    end subroutine curand_free_states

end module curand_utils
