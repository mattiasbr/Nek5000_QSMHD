# Nek5000 support for quasi-static magnetohydrodynamics

This repository adds simulation support for quasi-static magnetohydrodynamics (MHD) to the spectral element code Nek5000. In this framework, which is valid for flows subject to a strong (imposed) magnetic field at low magnetic Reynolds numbers, the Lorentz force is to leading order approximated by solving Ohm's law subject to a charge conservation condition [1].

Details about the spectral element formulation of the quasi-static MHD equations are given in [2]. Briefly, evaluation of the current density in the Lorentz force involves projecting the electromotive force on a divergence-free manifold. To this end, similar numerical techniques as used when computing the pressure in the fractional step method are utilised (i.e. extrapolation, projection, GMRES with Schwarz preconditioner). Currently, only a constant magnetic field is supported. At the end of a simulation, the solution time for the electric potential and the time spent in the corresponding E-solver are reported in the run-time statistics as 'epot' and 'epes', respectively.

The electric current density (and potential field) are evaluated on the mesh for the magnetic field in the usual MHD mode. The following boundary conditions are supported:

EI  : perfectly electrically insulating
EC  : perfectly electrically conducting
SYM : symmetry boundary condition (see ref. [3])

To define a simulation case, the following parameters are available through the section [QSMHD] in the par-file:

hartmann     : Hartmann number
conductivity : Electrical conductivity 
ebx          : x-component of the magnetic field
eby          : y-component of the magnetic field
ebz          : z-component of the magnetic field
residualTol  : solver tolerance (similar to param(21))
residualProj : projection flag (similar to param(94))

Further details regarding the usage are provided in the example folder. The implementation has been developed and validated on Nek5000 Version 20.0-dev (commit 9b3d9227b5896dfef4bc5245d85c25f7ba12334d). It has been used in ref. [3, 4]. Please cite ref. [2] (together with Nek5000) in a publication where the code is utilised.

# References

[1] Zikanov, O., Krasnov, D., Boeck, T., Thess, A., & Rossi, M. (2014). Laminar-turbulent transition in magnetohydrodynamic duct, pipe, and channel flows. Appl. Mech. Rev., 66(3), 030802. 
[2] Brynjell-Rahkola, M. (2024). A spectral element discretization for quasi-static magnetohydrodynamic flows. Int. J. Numer. Meth. Fl., 96(11), 1795-1812. https://doi.org/10.1002/fld.5321
[3] Brynjell-Rahkola, M., Duguet, Y., & Boeck, T. (2025). Route to turbulence in magnetohydrodynamic square duct flow. Phys. Rev. Fluids, 10(2), 023903. https://doi.org/10.1103/PhysRevFluids.10.023903
[4] Brynjell-Rahkola, M., Duguet, Y., & Boeck, T. (2024). Chaotic edge regimes in magnetohydrodynamic channel flow: An alternative path towards the tipping point. Phys. Rev. Res., 6(3), 033066. https://doi.org/10.1103/PhysRevResearch.6.033066
