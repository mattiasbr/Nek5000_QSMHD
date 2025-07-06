# MHD duct with electrically insulating walls

This example simulates the laminar flow in a square duct with an externally imposed transverse magnetic field and electrically insulating walls [1]. As initial condition, the solution given in ch. 2.2 of [2] is used. 

<ins>Instructions:</ins>
1. Create the files 'duct.re2' and 'duct.ma2' using genbox, reatore2, genmap.
2. Modify the following paths in 'compile.sh': \
   _NEK_HOME_ - Nek5000 home directory \
   _NEK_LOCAL_ - path to local Nek5000 home directory (will be created) \
   _QSMHD_SRC_ - path to directory with the QSMHD source files \
   _MOD_SRC_ - path to directory with the modified Nek5000 source files
3. Compile the example with: \
   `./compile.sh all`
   
**Note:** Accurate evaluation of the analytical series solution in [2] requires quadruple precision (see ref. [3]). Here, routines from the GNU compiler collection is used but adaptation to other compilers is straightforward.

# References

[1] Shercliff, J. A. (1953). Steady motion of conducting fluids in pipes under transverse magnetic fields. Math. Proc. Cambridge (Vol. 49, No. 1, pp. 136-144). https://doi.org/10.1017/S0305004100028139

[2] Mueller U. and Buehler L. (2002). Liquid metal magneto-hydraulics flows in ducts and cavities. Magnetohydrodynamics (pp. 1-67). Vienna: Springer Vienna. https://doi.org/10.1007/978-3-7091-2546-5_1

[3] Brynjell-Rahkola, M. (2024). A spectral element discretization for quasi-static magnetohydrodynamic flows. Int. J. Numer. Meth. Fl., 96(11), 1795-1812. https://doi.org/10.1002/fld.5321
