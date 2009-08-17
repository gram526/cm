!> \file
!> $Id$
!> \author Chris Bradley
!> \brief This module handles all finite elasticity routines.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s): Kumar Mithraratne
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!>This module handles all finite elasticity routines.
MODULE FINITE_ELASTICITY_ROUTINES

  USE BASE_ROUTINES
  USE BASIS_ROUTINES
  USE BOUNDARY_CONDITIONS_ROUTINES
  USE CONSTANTS
  USE CONTROL_LOOP_ROUTINES
  USE DISTRIBUTED_MATRIX_VECTOR
  USE DOMAIN_MAPPINGS
  USE EQUATIONS_ROUTINES
  USE EQUATIONS_MAPPING_ROUTINES
  USE EQUATIONS_MATRICES_ROUTINES
  USE EQUATIONS_SET_CONSTANTS
  USE FIELD_ROUTINES
  USE INPUT_OUTPUT
  USE ISO_VARYING_STRING
  USE KINDS
  USE MATHS  
  USE MATRIX_VECTOR
  USE PROBLEM_CONSTANTS
  USE SOLVER_ROUTINES
  USE STRINGS
  USE TIMER
  USE TYPES

  IMPLICIT NONE

  PRIVATE

  !Module parameters

  !Module types

  !Module variables

  !Interfaces

  PUBLIC FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE,FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE, &
    & FINITE_ELASTICITY_EQUATIONS_SET_SETUP,FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET, &
    & FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET,FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET,FINITE_ELASTICITY_PROBLEM_SETUP

CONTAINS

  !
  !================================================================================================================================
  !

  !>Evaluates the Jacobian for a finite elasticity finite element equations set.
  SUBROUTINE FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set 
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER !<The element number to calculate
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    !TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: RHS_VECTOR
    !TYPE(EQUATIONS_JACOBIAN_TYPE), POINTER :: EQUATIONS_JACOBIAN
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD 
    !TYPE(FIELD_VARIABLE_TYPE), POINTER :: FIELD_VARIABLE
    TYPE(ELEMENT_VECTOR_TYPE) :: ELEMENT_VECTOR1,ELEMENT_VECTOR2,ELEMENT_VECTOR3
    TYPE(DISTRIBUTED_VECTOR_CMISS_TYPE) ::DISTRIBUTED_VECTOR_CMISS1
    INTEGER(INTG) :: component_idx,parameter_idx,element_dof_idx,m,n
    INTEGER(INTG) :: DEPENDENT_NUMBER_OF_COMPONENTS
    INTEGER(INTG) :: DEPENDENT_COMPONENT_INTERPOLATION_TYPE,DEPENDENT_COMPONENT_NUMBER_OF_PARAMETERS, &
      & DEPENDENT_TOTAL_ELEMENT_PARAMETERS
    REAL(DP) :: DELTA

    CALL ENTERS("FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD 
        DEPENDENT_NUMBER_OF_COMPONENTS=DEPENDENT_FIELD%VARIABLES(1)%NUMBER_OF_COMPONENTS       
        EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
        NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES

        ELEMENT_VECTOR3=NONLINEAR_MATRICES%ELEMENT_RESIDUAL
        DISTRIBUTED_VECTOR_CMISS1=DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(1)%PTR%PARAMETERS%CMISS

        DELTA=0.0001_DP

        element_dof_idx=0
        DO component_idx=1,DEPENDENT_NUMBER_OF_COMPONENTS
          DEPENDENT_COMPONENT_INTERPOLATION_TYPE=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%INTERPOLATION_TYPE
          IF (DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_NODE_BASED_INTERPOLATION) THEN
            DEPENDENT_COMPONENT_NUMBER_OF_PARAMETERS=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%PARAM_TO_DOF_MAP% &
              & NUMBER_OF_NODE_PARAMETERS
            DO parameter_idx=1,DEPENDENT_COMPONENT_NUMBER_OF_PARAMETERS
              element_dof_idx=element_dof_idx+1
              DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(element_dof_idx)= &
                & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(element_dof_idx)
            ENDDO !parameter_idx
          ELSEIF (DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_ELEMENT_BASED_INTERPOLATION) THEN
            element_dof_idx=element_dof_idx+1  
            DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(element_dof_idx)= &
              & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(element_dof_idx)  
          ENDIF
        ENDDO
        DEPENDENT_TOTAL_ELEMENT_PARAMETERS=element_dof_idx

        n=0
        DO component_idx=1,DEPENDENT_NUMBER_OF_COMPONENTS
          DEPENDENT_COMPONENT_INTERPOLATION_TYPE=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%INTERPOLATION_TYPE
          IF (DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_NODE_BASED_INTERPOLATION) THEN
            DEPENDENT_COMPONENT_NUMBER_OF_PARAMETERS=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%PARAM_TO_DOF_MAP% &
              & NUMBER_OF_NODE_PARAMETERS
            DO parameter_idx=1,DEPENDENT_COMPONENT_NUMBER_OF_PARAMETERS
              n=n+1

              DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
                & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)+DELTA
              CALL FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
              DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD        
              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
              NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
              ELEMENT_VECTOR2=NONLINEAR_MATRICES%ELEMENT_RESIDUAL
              DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
                & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)

              DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
                & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)-DELTA                    
              CALL FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
              DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD        
              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
              NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
              ELEMENT_VECTOR1=NONLINEAR_MATRICES%ELEMENT_RESIDUAL
              DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
                & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)

              DO m=1,DEPENDENT_TOTAL_ELEMENT_PARAMETERS
                NONLINEAR_MATRICES%JACOBIAN%ELEMENT_JACOBIAN%MATRIX(m,n)= &
                  & (ELEMENT_VECTOR2%VECTOR(m)-ELEMENT_VECTOR1%VECTOR(m))/(2.0_DP*DELTA)
              ENDDO
            ENDDO !parameter_idx

          ELSEIF (DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_ELEMENT_BASED_INTERPOLATION) THEN
            n=n+1  

            DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
              & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)+DELTA
            CALL FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
            DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD        
            EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
            NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
            ELEMENT_VECTOR2=NONLINEAR_MATRICES%ELEMENT_RESIDUAL
            DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
              & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)

            DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
              & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)-DELTA                       
            CALL FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
            DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD        
            EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
            NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
            ELEMENT_VECTOR1=NONLINEAR_MATRICES%ELEMENT_RESIDUAL                    
            DEPENDENT_FIELD%VARIABLES(1)%PARAMETER_SETS%PARAMETER_SETS(2)%PTR%PARAMETERS%CMISS%DATA_DP(n)= &
              & DISTRIBUTED_VECTOR_CMISS1%DATA_DP(n)      

            DO m=1,DEPENDENT_TOTAL_ELEMENT_PARAMETERS
              NONLINEAR_MATRICES%JACOBIAN%ELEMENT_JACOBIAN%MATRIX(m,n)= &
                & (ELEMENT_VECTOR2%VECTOR(m)-ELEMENT_VECTOR1%VECTOR(m))/(2.0_DP*DELTA)
            ENDDO

          ENDIF
        ENDDO

        NONLINEAR_MATRICES%ELEMENT_RESIDUAL=ELEMENT_VECTOR3

      ELSE
        CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_FINITE_ELEMENT_JACOBIAN_EVALUATE")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE

  !
  !================================================================================================================================
  !

  !>Evaluates the residual and RHS vectors for a finite elasticity finite element equations set.
  SUBROUTINE FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set 
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER !<The element number to calculate
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(BASIS_TYPE), POINTER :: DEPENDENT_BASIS,COMPONENT_BASIS
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD,FIBRE_FIELD,GEOMETRIC_FIELD,MATERIALS_FIELD
    TYPE(QUADRATURE_SCHEME_TYPE), POINTER :: DEPENDENT_QUADRATURE_SCHEME,COMPONENT_QUADRATURE_SCHEME
    TYPE(FIELD_INTERPOLATION_PARAMETERS_TYPE), POINTER :: GEOMETRIC_INTERPOLATION_PARAMETERS, &
      & FIBRE_INTERPOLATION_PARAMETERS,MATERIALS_INTERPOLATION_PARAMETERS,DEPENDENT_INTERPOLATION_PARAMETERS
    TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: GEOMETRIC_INTERPOLATED_POINT,FIBRE_INTERPOLATED_POINT, &
      & MATERIALS_INTERPOLATED_POINT,DEPENDENT_INTERPOLATED_POINT
    !TYPE(VARYING_STRING) :: LOCAL_ERROR   
    INTEGER(INTG) :: component_idx,parameter_idx,gauss_idx,element_dof_idx
    INTEGER(INTG) :: idx1,idx2
    INTEGER(INTG) :: DEPENDENT_NUMBER_OF_COMPONENTS
    INTEGER(INTG) :: NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS
    INTEGER(INTG) :: DEPENDENT_COMPONENT_INTERPOLATION_TYPE
    INTEGER(INTG) :: DEPENDENT_NUMBER_OF_GAUSS_POINTS       
    REAL(DP) :: DZDNU(3,3),CAUCHY_TENSOR(3,3)
    REAL(DP) :: DFDZ(64,3) !temporary until a proper alternative is found
    REAL(DP) :: GAUSS_WEIGHTS,Jznu,Jxxi
    
    CALL ENTERS("FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN  

        EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
        NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
        EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING

        DEPENDENT_FIELD=>EQUATIONS%INTERPOLATION%DEPENDENT_FIELD
        FIBRE_FIELD=>EQUATIONS%INTERPOLATION%FIBRE_FIELD
        GEOMETRIC_FIELD=>EQUATIONS%INTERPOLATION%GEOMETRIC_FIELD
        MATERIALS_FIELD=>EQUATIONS%INTERPOLATION%MATERIALS_FIELD

        DEPENDENT_BASIS=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
          & TOPOLOGY%ELEMENTS%ELEMENTS(ELEMENT_NUMBER)%BASIS       
        DEPENDENT_QUADRATURE_SCHEME=>DEPENDENT_BASIS%QUADRATURE%QUADRATURE_SCHEME_MAP(BASIS_DEFAULT_QUADRATURE_SCHEME)%PTR
        DEPENDENT_NUMBER_OF_GAUSS_POINTS=DEPENDENT_QUADRATURE_SCHEME%NUMBER_OF_GAUSS
	DEPENDENT_NUMBER_OF_COMPONENTS=DEPENDENT_FIELD%VARIABLES(1)%NUMBER_OF_COMPONENTS

        !Initialise tensors and matrices
        DO idx1=1,3
          DO idx2=1,3
            DZDNU(idx1,idx2)=0.0_DP
            CAUCHY_TENSOR(idx1,idx2)=0.0_DP
            IF(idx1==idx2) DZDNU(idx1,idx2)=1.0_DP
            IF(idx1==idx2) CAUCHY_TENSOR(idx1,idx2)=1.0_DP    
          ENDDO
        ENDDO        
        DO component_idx=1,3 !Always 3D
	  DO parameter_idx=1,64
            DFDZ(parameter_idx,component_idx)=0.0_DP
          ENDDO
        ENDDO
 
        GEOMETRIC_INTERPOLATION_PARAMETERS=>EQUATIONS%INTERPOLATION%GEOMETRIC_INTERP_PARAMETERS
        FIBRE_INTERPOLATION_PARAMETERS=>EQUATIONS%INTERPOLATION%FIBRE_INTERP_PARAMETERS
        MATERIALS_INTERPOLATION_PARAMETERS=>EQUATIONS%INTERPOLATION%MATERIALS_INTERP_PARAMETERS
        DEPENDENT_INTERPOLATION_PARAMETERS=>EQUATIONS%INTERPOLATION%DEPENDENT_INTERP_PARAMETERS

        GEOMETRIC_INTERPOLATED_POINT=>EQUATIONS%INTERPOLATION%GEOMETRIC_INTERP_POINT
        FIBRE_INTERPOLATED_POINT=>EQUATIONS%INTERPOLATION%FIBRE_INTERP_POINT
        MATERIALS_INTERPOLATED_POINT=>EQUATIONS%INTERPOLATION%MATERIALS_INTERP_POINT
        DEPENDENT_INTERPOLATED_POINT=>EQUATIONS%INTERPOLATION%DEPENDENT_INTERP_POINT

        CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ELEMENT_NUMBER,GEOMETRIC_INTERPOLATION_PARAMETERS, &
          & ERR,ERROR,*999)
        CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ELEMENT_NUMBER,FIBRE_INTERPOLATION_PARAMETERS, &
          & ERR,ERROR,*999)
        CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ELEMENT_NUMBER,MATERIALS_INTERPOLATION_PARAMETERS, &
          & ERR,ERROR,*999)
        CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ELEMENT_NUMBER,DEPENDENT_INTERPOLATION_PARAMETERS, &
          & ERR,ERROR,*999)

        DO gauss_idx=1,DEPENDENT_NUMBER_OF_GAUSS_POINTS
          GAUSS_WEIGHTS=DEPENDENT_QUADRATURE_SCHEME%GAUSS_WEIGHTS(gauss_idx)

          CALL FIELD_INTERPOLATE_GAUSS(FIRST_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
            & DEPENDENT_INTERPOLATED_POINT,ERR,ERROR,*999)	    
          CALL FIELD_INTERPOLATE_GAUSS(FIRST_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
            & GEOMETRIC_INTERPOLATED_POINT,ERR,ERROR,*999)
          CALL FIELD_INTERPOLATE_GAUSS(FIRST_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
            & FIBRE_INTERPOLATED_POINT,ERR,ERROR,*999)
          CALL FIELD_INTERPOLATE_GAUSS(NO_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
            & MATERIALS_INTERPOLATED_POINT,ERR,ERROR,*999)

          CALL FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR(DEPENDENT_INTERPOLATED_POINT,GEOMETRIC_INTERPOLATED_POINT, &
            & FIBRE_INTERPOLATED_POINT,DZDNU,Jxxi,Jznu,ERR,ERROR,*999)    

          CALL FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR(DEPENDENT_INTERPOLATED_POINT,MATERIALS_INTERPOLATED_POINT, &
            & CAUCHY_TENSOR,DZDNU,ERR,ERROR,*999)
           
          CALL FINITE_ELASTICITY_GAUSS_DFDZ(DEPENDENT_INTERPOLATED_POINT,ELEMENT_NUMBER,gauss_idx,DFDZ,ERR,ERROR,*999)

	  element_dof_idx=0
	  DO component_idx=1,DEPENDENT_NUMBER_OF_COMPONENTS
	    IF(component_idx<DEPENDENT_NUMBER_OF_COMPONENTS) THEN !geomteric components
	      DEPENDENT_COMPONENT_INTERPOLATION_TYPE=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%INTERPOLATION_TYPE
	      IF(DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_NODE_BASED_INTERPOLATION) THEN !node based
	       NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)% &
		 & MAX_NUMBER_OF_INTERPOLATION_PARAMETERS	      
	       DO parameter_idx=1,NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS  
		  element_dof_idx=element_dof_idx+1    
		  NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)= &
		    & NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)+ &
		    & GAUSS_WEIGHTS*Jxxi*Jznu*(CAUCHY_TENSOR(component_idx,1)*DFDZ(parameter_idx,1)+ &
		    & CAUCHY_TENSOR(component_idx,2)*DFDZ(parameter_idx,2)+ &
		    & CAUCHY_TENSOR(component_idx,3)*DFDZ(parameter_idx,3))	 
		ENDDO
	      ELSEIF(DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_ELEMENT_BASED_INTERPOLATION) THEN !element based - probably not required
		element_dof_idx=element_dof_idx+1
		!TODO:  	
	      ENDIF
	    ELSEIF(component_idx==DEPENDENT_NUMBER_OF_COMPONENTS) THEN !hydrostatic pressure component
	      DEPENDENT_COMPONENT_INTERPOLATION_TYPE=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%INTERPOLATION_TYPE       
	      IF(DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_NODE_BASED_INTERPOLATION) THEN !node based			       
		COMPONENT_BASIS=>DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)%DOMAIN%TOPOLOGY%ELEMENTS% &
		  & ELEMENTS(ELEMENT_NUMBER)%BASIS	     
		COMPONENT_QUADRATURE_SCHEME=>COMPONENT_BASIS%QUADRATURE%QUADRATURE_SCHEME_MAP(BASIS_DEFAULT_QUADRATURE_SCHEME)%PTR	       
	        NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS=DEPENDENT_FIELD%VARIABLES(1)%COMPONENTS(component_idx)% &
		  & MAX_NUMBER_OF_INTERPOLATION_PARAMETERS	      	       	       
	        DO parameter_idx=1,NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS 
	          element_dof_idx=element_dof_idx+1 
                  NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)= &
                    & NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)+ &
                    & GAUSS_WEIGHTS*Jxxi*COMPONENT_QUADRATURE_SCHEME%GAUSS_BASIS_FNS(parameter_idx,1,gauss_idx)*(Jznu-1.0_DP)		       
	        ENDDO	        		        
	      ELSEIF(DEPENDENT_COMPONENT_INTERPOLATION_TYPE==FIELD_ELEMENT_BASED_INTERPOLATION) THEN !element based
		element_dof_idx=element_dof_idx+1	     
		NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)= &
		  & NONLINEAR_MATRICES%ELEMENT_RESIDUAL%VECTOR(element_dof_idx)+GAUSS_WEIGHTS*Jxxi*(Jznu-1.0_DP)      
	      ENDIF
	    ENDIF
	  ENDDO !component_idx        
	ENDDO !gauss_idx
			     
      ELSE
        CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE

  !
  !================================================================================================================================
  !

  !>Evaluates the deformation gradient tensor at a given Gauss point
  SUBROUTINE FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR(DEPENDENT_INTERPOLATED_POINT,GEOMETRIC_INTERPOLATED_POINT, &
    & FIBRE_INTERPOLATED_POINT,DZDNU,Jxxi,Jznu,ERR,ERROR,*)    

    !Argument variables
    TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: DEPENDENT_INTERPOLATED_POINT,GEOMETRIC_INTERPOLATED_POINT, &
      & FIBRE_INTERPOLATED_POINT      
    REAL(DP) :: DZDNU(:,:),Jxxi,Jznu  !DZDNU - Deformation Gradient Tensor  
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string   
    !Local Variables
    INTEGER(INTG) :: derivative_idx,component_idx,xi_idx 
    REAL(DP) :: DNUDX(3,3),DNUDXI(3,3),DXDNU(3,3),DXIDNU(3,3),DXDXI(3,3),DZDXI(3,3),Jnuxi

    CALL ENTERS("FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR",ERR,ERROR,*999)

    DO component_idx=1,3 !Always 3 components - 3D
      DO xi_idx=1,3 !Thus 3 element coordinates
        derivative_idx=PARTIAL_DERIVATIVE_FIRST_DERIVATIVE_MAP(xi_idx) !2,4,7      
        DXDXI(component_idx,xi_idx)=GEOMETRIC_INTERPOLATED_POINT%VALUES(component_idx,derivative_idx) !dx/dxi
        DZDXI(component_idx,xi_idx)=DEPENDENT_INTERPOLATED_POINT%VALUES(component_idx,derivative_idx) !dz/dxi
      ENDDO
    ENDDO

    CALL FINITE_ELASTICITY_GAUSS_DXDNU(FIBRE_INTERPOLATED_POINT,DXDNU,DXDXI,ERR,ERROR,*999)

    CALL MATRIX_TRANSPOSE(DXDNU,DNUDX,ERR,ERROR,*999) !dx/dnu is orthogonal. Therefore transpose is its inverse

    CALL MATRIX_PRODUCT(DNUDX,DXDXI,DNUDXI,ERR,ERROR,*999) !dnu/dxi = dnu/dx * dx/dxi
    CALL INVERT(DNUDXI,DXIDNU,Jnuxi,ERR,ERROR,*999) !dxi/dnu 

    CALL MATRIX_PRODUCT(DZDXI,DXIDNU,DZDNU,ERR,ERROR,*999) !dz/dnu = dz/dxi * dxi/dnu  (deformation gradient tensor, F)

    Jxxi=DETERMINANT(DXDXI,ERR,ERROR)
    Jznu=DETERMINANT(DZDNU,ERR,ERROR)

    CALL EXITS("FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_GAUSS_DEFORMATION_GRADEINT_TENSOR

  !
  !================================================================================================================================
  !

  !>Evaluates dx/dnu(undeformed(x)-material(nu) css) tensor at a given Gauss point
  SUBROUTINE FINITE_ELASTICITY_GAUSS_DXDNU(INTERPOLATED_POINT,DXDNU,DXDXI,ERR,ERROR,*)

    !Argument variables
    TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: INTERPOLATED_POINT    
    REAL(DP) :: DXDNU(:,:),DXDXI(:,:)    
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: fibre_idx,i,j,nj_idx,NUMBER_OF_FIBRE_COMPONENTS 
    INTEGER(INTG) :: vector(3) = (/1,2,3/)
    REAL(DP) :: ANGLE(3),DXDNU1(3,3),DXDNU2(3,3),DXDNU3(3,3),DXDNUR(3,3),F(3),G(3),H(3), &
      & Ra(3,3),Rb(3,3)

    CALL ENTERS("FINITE_ELASTICITY_GAUSS_DXDNU",ERR,ERROR,*999)

    DO fibre_idx=1,3,1
      ANGLE(fibre_idx)=0.0_DP
    ENDDO 
    NUMBER_OF_FIBRE_COMPONENTS=INTERPOLATED_POINT%INTERPOLATION_PARAMETERS%FIELD_VARIABLE%NUMBER_OF_COMPONENTS    
    DO fibre_idx=1,NUMBER_OF_FIBRE_COMPONENTS    
      ANGLE(fibre_idx)=INTERPOLATED_POINT%VALUES(fibre_idx,1) !fibre, imbrication and sheet. All in radians
    ENDDO

    !First calculate reference material CS
    DO nj_idx=1,3
      F(nj_idx)=DXDXI(nj_idx,1) !reference material dirn-1.
    ENDDO
    CALL CROSS_PRODUCT(DXDXI(vector,1),DXDXI(vector,2),H,ERR,ERROR,*999) !reference material dirn-3.    
    CALL CROSS_PRODUCT(H,F,G,ERR,ERROR,*999) !reference material dirn-2.      

    DO nj_idx=1,3
      DXDNUR(nj_idx,1)=F(nj_idx)/L2NORM(F) 
      DXDNUR(nj_idx,2)=G(nj_idx)/L2NORM(G)      
      DXDNUR(nj_idx,3)=H(nj_idx)/L2NORM(H)        
    ENDDO
    
    !FIBRE ANGLE(alpha) - ANGLE(1) 
    !In order to rotate reference material CS by alpha(fibre angle) in anti-clockwise  
    !direction about its axis 3, following steps are performed.
    !(a) first align reference material direction 3 with Z(spatial) axis by rotating the ref matrial CS. 
    !(b) then rotate the aligned material CS by alpha about Z axis in anti-clockwise direction
    !(c) apply the inverse of step(a) to the CS in (b)
    !It can be shown that steps (a),(b) and (c) are equivalent to post-multiplying
    !rotation in (a) by rotation in (b). i.e. Ra*Rb  
       
    !The normalised reference material CS contains the transformation(rotaion) between 
    !the spatial CS -> reference material CS. i.e. Ra 
    DO i=1,3
      DO j=1,3
        Ra(i,j)=DXDNUR(i,j)  
      ENDDO
    ENDDO   

    !Initialise rotation matrix Rb
    DO i=1,3
      DO j=1,3
        Rb(i,j)=0.0_DP 
        IF (i==j) THEN
          Rb(i,j)=1.0_DP  
        ENDIF
      ENDDO
    ENDDO    
    !Populate rotation matrix Rb about axis 3 (Z)
    Rb(1,1)=cos(ANGLE(1))
    Rb(1,2)=-sin(ANGLE(1))
    Rb(2,1)=sin(ANGLE(1))
    Rb(2,2)=cos(ANGLE(1))
    
    CALL MATRIX_PRODUCT(Ra,Rb,DXDNU3,ERR,ERROR,*999)  
 
    !IMBRICATION ANGLE (beta) - ANGLE(2)     
    !In order to rotate alpha-rotated material CS by beta(imbrication angle) in anti-clockwise  
    !direction about its new axis 2, following steps are performed.
    !(a) first align new material direction 2 with Y(spatial) axis by rotating the new matrial CS. 
    !(b) then rotate the aligned CS by beta about Y axis in anti-clockwise direction
    !(c) apply the inverse of step(a) to the CS in (b)
    !As mentioned above, (a),(b) and (c) are equivalent to post-multiplying
    !rotation in (a) by rotation in (b). i.e. Ra*Rb  
        
    !DXNU3 contains the transformation(rotaion) between 
    !the spatial CS -> alpha-rotated reference material CS. i.e. Ra 
    DO i=1,3
      DO j=1,3
        Ra(i,j)=DXDNU3(i,j)  
      ENDDO
    ENDDO   
    !Initialise rotation matrix Rb
    DO i=1,3
      DO j=1,3
        Rb(i,j)=0.0_DP 
        IF (i==j) THEN
          Rb(i,j)=1.0_DP  
        ENDIF
      ENDDO
    ENDDO    
    !Populate rotation matrix Rb about axis 2 (Y). Note the sign change
    Rb(1,1)=cos(ANGLE(2))
    Rb(1,3)=sin(ANGLE(2))
    Rb(3,1)=-sin(ANGLE(2))
    Rb(3,3)=cos(ANGLE(2))

    CALL MATRIX_PRODUCT(Ra,Rb,DXDNU2,ERR,ERROR,*999)  

    !SHEET ANGLE (gama) - ANGLE(3)    
    !In order to rotate alpha-beta-rotated material CS by gama(sheet angle) in anti-clockwise  
    !direction about its new axis 1, following steps are performed.
    !(a) first align new material direction 1 with X(spatial) axis by rotating the new matrial CS. 
    !(b) then rotate the aligned CS by gama about X axis in anti-clockwise direction
    !(c) apply the inverse of step(a) to the CS in (b)
    !Again steps (a),(b) and (c) are equivalent to post-multiplying
    !rotation in (a) by rotation in (b). i.e. Ra*Rb  
        
    !DXNU2 contains the transformation(rotaion) between 
    !the spatial CS -> alpha-beta-rotated reference material CS. i.e. Ra 
    DO i=1,3
      DO j=1,3
        Ra(i,j)=DXDNU2(i,j)  
      ENDDO
    ENDDO   
    !Initialise rotation matrix Rb
    DO i=1,3
      DO j=1,3
        Rb(i,j)=0.0_DP 
        IF (i==j) THEN
          Rb(i,j)=1.0_DP  
        ENDIF
      ENDDO
    ENDDO    
    !Populate rotation matrix Rb about axis 1 (X). 
    Rb(2,2)=cos(ANGLE(3))
    Rb(2,3)=-sin(ANGLE(3))
    Rb(3,2)=sin(ANGLE(3))
    Rb(3,3)=cos(ANGLE(3))

    CALL MATRIX_PRODUCT(Ra,Rb,DXDNU1,ERR,ERROR,*999)  

    DO i=1,3
      DO j=1,3
        DXDNU(i,j)=DXDNU1(i,j)  
      ENDDO
    ENDDO   
    
    CALL EXITS("FINITE_ELASTICITY_GAUSS_DXDNU")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_GAUSS_DXDNU",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_GAUSS_DXDNU")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_GAUSS_DXDNU

  !
  !================================================================================================================================
  !

  !>Evaluates the Cauchy stress tensor at a given Gauss point
  SUBROUTINE FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR(DEPENDENT_INTERPOLATED_POINT,MATERIALS_INTERPOLATED_POINT, &
    & CAUCHY_TENSOR,DZDNU,ERR,ERROR,*)

    !Argument variables       
    TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: DEPENDENT_INTERPOLATED_POINT,MATERIALS_INTERPOLATED_POINT
    REAL(DP), INTENT(OUT) :: CAUCHY_TENSOR(:,:)
    REAL(DP), INTENT(IN) ::  DZDNU(:,:) !Deformation Gradient Tensor
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: i,j,PRESSURE_COMPONENT    
    REAL(DP) :: AZL(3,3),AZU(3,3),C(0:1,0:1),DZDNUT(3,3),PIOLA_TENSOR(3,3),TEMP(3,3),Jznu,I3,P 

    CALL ENTERS("FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR",ERR,ERROR,*999)

    C(1,0)=MATERIALS_INTERPOLATED_POINT%VALUES(1,1)
    C(0,1)=MATERIALS_INTERPOLATED_POINT%VALUES(2,1)
    PRESSURE_COMPONENT=DEPENDENT_INTERPOLATED_POINT%INTERPOLATION_PARAMETERS%FIELD_VARIABLE%NUMBER_OF_COMPONENTS
    P=DEPENDENT_INTERPOLATED_POINT%VALUES(PRESSURE_COMPONENT,1)

!    Jznu=DETERMINANT(DZDNU,ERR,ERROR)  ! Jznu=sqrt(I3)
    CALL MATRIX_TRANSPOSE(DZDNU,DZDNUT,ERR,ERROR,*999)    
    CALL MATRIX_PRODUCT(DZDNUT,DZDNU,AZL,ERR,ERROR,*999) !AZL = F'*F (deformed covariant or right cauchy defromation tensor, C)    
    CALL INVERT(AZL,AZU,I3,ERR,ERROR,*999) !AZU - deformed contravariant tensor; I3 = det(C)
    Jznu=I3**0.5_DP
    
    !Note: Form of constitutive model is w=c10*(I1-3)+c01*(I2-3)+p*(I3-1)
    !      Also assumed I3 = det(AZL) = 1.0       
     
    PIOLA_TENSOR(1,1)=2.0_DP*(C(1,0)+C(0,1)*(AZL(2,2)+AZL(3,3))+P*AZU(1,1))
    PIOLA_TENSOR(1,2)=2.0_DP*(       C(0,1)*(-AZL(2,1))        +P*AZU(1,2))
    PIOLA_TENSOR(1,3)=2.0_DP*(       C(0,1)*(-AZL(3,1))        +P*AZU(1,3))            
    PIOLA_TENSOR(2,1)=PIOLA_TENSOR(1,2)
    PIOLA_TENSOR(2,2)=2.0_DP*(C(1,0)+C(0,1)*(AZL(3,3)+AZL(1,1))+P*AZU(2,2))
    PIOLA_TENSOR(2,3)=2.0_DP*(       C(0,1)*(-AZL(3,2))        +P*AZU(2,3))  
    PIOLA_TENSOR(3,1)=PIOLA_TENSOR(1,3)       
    PIOLA_TENSOR(3,2)=PIOLA_TENSOR(2,3) 
    PIOLA_TENSOR(3,3)=2.0_DP*(C(1,0)+C(0,1)*(AZL(1,1)+AZL(2,2))+P*AZU(3,3))    

    CALL MATRIX_PRODUCT(DZDNU,PIOLA_TENSOR,TEMP,ERR,ERROR,*999)     
    CALL MATRIX_PRODUCT(TEMP,DZDNUT,CAUCHY_TENSOR,ERR,ERROR,*999)     

    DO i=1,3,1
      DO j=1,3,1
        CAUCHY_TENSOR(i,j)=CAUCHY_TENSOR(i,j)/Jznu
      ENDDO
    ENDDO

    CALL EXITS("FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR


  !
  !================================================================================================================================
  !

  !>Evaluates df/dz (derivative of interpolation function wrt deformed coord) matrix at a given Gauss point
  SUBROUTINE FINITE_ELASTICITY_GAUSS_DFDZ(INTERPOLATED_POINT,ELEMENT_NUMBER,GAUSS_POINT_NUMBER,DFDZ,ERR,ERROR,*)

    !Argument variables
    TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: INTERPOLATED_POINT       
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER       
    INTEGER(INTG), INTENT(IN) :: GAUSS_POINT_NUMBER   
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    REAL(DP) :: DFDZ(:,:)  
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string    
    !Local Variables
    TYPE(BASIS_TYPE), POINTER :: COMPONENT_BASIS
    TYPE(FIELD_TYPE), POINTER :: FIELD
    TYPE(QUADRATURE_SCHEME_TYPE), POINTER :: QUADRATURE_SCHEME
    INTEGER(INTG) :: NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS,derivative_idx,component_idx,xi_idx,parameter_idx 
    REAL(DP) :: DXIDZ(3,3),DZDXI(3,3)   
    REAL(DP) :: Jzxi,DFDXI(3,64,3)!temporary until a proper alternative is found
    
    CALL ENTERS("FINITE_ELASTICITY_GAUSS_DFDZ",ERR,ERROR,*999)

    !Initialise DFDXI array
    DO component_idx=1,3
      DO parameter_idx=1,64 
        DO xi_idx=1,3
	  DFDXI(component_idx,parameter_idx,xi_idx)=0.0_DP
        ENDDO
      ENDDO
    ENDDO
      	
    DO component_idx=1,3 !Always 3 spatial coordinates (3D)
      DO xi_idx=1,3 !Thus always 3 element coordinates
        derivative_idx=PARTIAL_DERIVATIVE_FIRST_DERIVATIVE_MAP(xi_idx)  !2,4,7      
        DZDXI(component_idx,xi_idx)=INTERPOLATED_POINT%VALUES(component_idx,derivative_idx)  !dz/dxi
      ENDDO
    ENDDO

    CALL INVERT(DZDXI,DXIDZ,Jzxi,ERR,ERROR,*999) !dxi/dz 

    FIELD=>INTERPOLATED_POINT%INTERPOLATION_PARAMETERS%FIELD
    DO component_idx=1,3 
      COMPONENT_BASIS=>FIELD%VARIABLES(1)%COMPONENTS(component_idx)%DOMAIN%TOPOLOGY%ELEMENTS% &
        & ELEMENTS(ELEMENT_NUMBER)%BASIS
      QUADRATURE_SCHEME=>COMPONENT_BASIS%QUADRATURE%QUADRATURE_SCHEME_MAP(BASIS_DEFAULT_QUADRATURE_SCHEME)%PTR
      NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS=FIELD%VARIABLES(1)%COMPONENTS(component_idx)% &
        & MAX_NUMBER_OF_INTERPOLATION_PARAMETERS
      DO parameter_idx=1,NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS
        DO xi_idx=1,3
	  derivative_idx=PARTIAL_DERIVATIVE_FIRST_DERIVATIVE_MAP(xi_idx)  !2,4,7 
	  DFDXI(component_idx,parameter_idx,xi_idx)=QUADRATURE_SCHEME%GAUSS_BASIS_FNS(parameter_idx,derivative_idx,GAUSS_POINT_NUMBER)
	ENDDO
      ENDDO      
    ENDDO
    
    DO component_idx=1,3    
      COMPONENT_BASIS=>FIELD%VARIABLES(1)%COMPONENTS(component_idx)%DOMAIN%TOPOLOGY%ELEMENTS% &
        & ELEMENTS(ELEMENT_NUMBER)%BASIS
      NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS=FIELD%VARIABLES(1)%COMPONENTS(component_idx)% &
        & MAX_NUMBER_OF_INTERPOLATION_PARAMETERS
      DO parameter_idx=1,NUMBER_OF_FIELD_COMPONENT_INTERPOLATION_PARAMETERS
	DFDZ(parameter_idx,component_idx)=DFDXI(component_idx,parameter_idx,1)*DXIDZ(1,component_idx)+ &
	  & DFDXI(component_idx,parameter_idx,2)*DXIDZ(2,component_idx)+DFDXI(component_idx,parameter_idx,3)*DXIDZ(3,component_idx)	   
      ENDDO    
    ENDDO    
    
    CALL EXITS("FINITE_ELASTICITY_GAUSS_DFDZ")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_GAUSS_DFDZ",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_GAUSS_DFDZ")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_GAUSS_DFDZ

  !
  !================================================================================================================================
  !

  !>Sets up the finite elasticity equation type of an elasticity equations set class.
  SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to setup a Laplace equation on.
    TYPE(EQUATIONS_SET_SETUP_TYPE), INTENT(INOUT) :: EQUATIONS_SET_SETUP !<The equations set setup information
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx,GEOMETRIC_MESH_COMPONENT,GEOMETRIC_SCALING_TYPE,NUMBER_OF_COMPONENTS, &
      & NUMBER_OF_DIMENSIONS
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS
    TYPE(DECOMPOSITION_TYPE), POINTER :: GEOMETRIC_DECOMPOSITION
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_SET_MATERIALS_TYPE), POINTER :: EQUATIONS_MATERIALS
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("FINITE_ELASTICITY_EQUATIONS_SET_SETUP",ERR,ERROR,*999)

    NULLIFY(BOUNDARY_CONDITIONS)
    NULLIFY(EQUATIONS)
    NULLIFY(EQUATIONS_MAPPING)
    NULLIFY(EQUATIONS_MATRICES)
    NULLIFY(GEOMETRIC_DECOMPOSITION)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      SELECT CASE(EQUATIONS_SET%SUBTYPE)
      CASE(EQUATIONS_SET_NO_SUBTYPE)
        SELECT CASE(EQUATIONS_SET_SETUP%SETUP_TYPE)
        CASE(EQUATIONS_SET_SETUP_INITIAL_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            !Default to FEM solution method
            CALL FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET(EQUATIONS_SET,EQUATIONS_SET_FEM_SOLUTION_METHOD,ERR,ERROR,*999)
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
!!TODO: Check valid setup
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_GEOMETRY_TYPE)
          !\todo Check dimension of geometric field
        CASE(EQUATIONS_SET_SETUP_DEPENDENT_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED) THEN
              !Create the auto created dependent field
              CALL FIELD_CREATE_START(EQUATIONS_SET_SETUP%FIELD_USER_NUMBER,EQUATIONS_SET%REGION,EQUATIONS_SET%DEPENDENT% &
                & DEPENDENT_FIELD,ERR,ERROR,*999)
              CALL FIELD_TYPE_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_GEOMETRIC_TYPE,ERR,ERROR,*999)
              CALL FIELD_DEPENDENT_TYPE_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DEPENDENT_TYPE,ERR,ERROR,*999)
              CALL FIELD_MESH_DECOMPOSITION_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,GEOMETRIC_DECOMPOSITION,ERR,ERROR,*999)
              CALL FIELD_MESH_DECOMPOSITION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,GEOMETRIC_DECOMPOSITION, &
                & ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_VARIABLES_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,2,ERR,ERROR,*999)
              CALL FIELD_DIMENSION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                & FIELD_VECTOR_DIMENSION_TYPE,ERR,ERROR,*999)
              CALL FIELD_DIMENSION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE, &
                & FIELD_VECTOR_DIMENSION_TYPE,ERR,ERROR,*999)
              CALL FIELD_DATA_TYPE_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                & FIELD_DP_TYPE,ERR,ERROR,*999)
              CALL FIELD_DATA_TYPE_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE, &
                & FIELD_DP_TYPE,ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_COMPONENTS_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                & NUMBER_OF_DIMENSIONS,ERR,ERROR,*999)
              NUMBER_OF_COMPONENTS=NUMBER_OF_DIMENSIONS+1 !Include hydrostatic pressure component
              CALL FIELD_NUMBER_OF_COMPONENTS_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                & NUMBER_OF_COMPONENTS,ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_COMPONENTS_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE, &
                & NUMBER_OF_COMPONENTS,ERR,ERROR,*999)
              !Default to the geometric interpolation setup
              DO component_idx=1,NUMBER_OF_DIMENSIONS
                CALL FIELD_COMPONENT_MESH_COMPONENT_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & component_idx,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & component_idx,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE, &
                  & component_idx,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
              ENDDO !component_idx
	      
!kmith :09.06.09 - Do we need this ?      
              !Set the hydrostatic component to that of the first geometric component
              CALL FIELD_COMPONENT_MESH_COMPONENT_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                & 1,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
              CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                & NUMBER_OF_COMPONENTS,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
              CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE, &
                & NUMBER_OF_COMPONENTS,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)            
!kmith
              
	      SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                !Set the displacement components to node based interpolation
                DO component_idx=1,NUMBER_OF_DIMENSIONS
                  CALL FIELD_COMPONENT_INTERPOLATION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                    & component_idx,FIELD_NODE_BASED_INTERPOLATION,ERR,ERROR,*999)
                  CALL FIELD_COMPONENT_INTERPOLATION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD, &
                    & FIELD_DELUDELN_VARIABLE_TYPE,component_idx,FIELD_NODE_BASED_INTERPOLATION,ERR,ERROR,*999)
                ENDDO !component_idx
                !Set the hydrostatic pressure component to element based interpolation
                CALL FIELD_COMPONENT_INTERPOLATION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & NUMBER_OF_COMPONENTS,FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_INTERPOLATION_SET_AND_LOCK(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD, &
                  & FIELD_DELUDELN_VARIABLE_TYPE,NUMBER_OF_COMPONENTS,FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
                !Default the scaling to the geometric field scaling
                CALL FIELD_SCALING_TYPE_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,GEOMETRIC_SCALING_TYPE,ERR,ERROR,*999)
                CALL FIELD_SCALING_TYPE_SET(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,GEOMETRIC_SCALING_TYPE,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The solution method of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              !Check the user specified field
              CALL FIELD_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_GENERAL_TYPE,ERR,ERROR,*999)
              CALL FIELD_DEPENDENT_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DEPENDENT_TYPE,ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_VARIABLES_CHECK(EQUATIONS_SET_SETUP%FIELD,2,ERR,ERROR,*999)
              CALL FIELD_VARIABLE_TYPES_CHECK(EQUATIONS_SET_SETUP%FIELD,(/FIELD_U_VARIABLE_TYPE,FIELD_DELUDELN_VARIABLE_TYPE/), &
                & ERR,ERROR,*999)
              CALL FIELD_DIMENSION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VECTOR_DIMENSION_TYPE,ERR,ERROR,*999)
              CALL FIELD_DIMENSION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DELUDELN_VARIABLE_TYPE,FIELD_VECTOR_DIMENSION_TYPE, &
                & ERR,ERROR,*999)
              CALL FIELD_DATA_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,FIELD_DP_TYPE,ERR,ERROR,*999)
              CALL FIELD_DATA_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DELUDELN_VARIABLE_TYPE,FIELD_DP_TYPE,ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_COMPONENTS_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                & NUMBER_OF_DIMENSIONS,ERR,ERROR,*999)
              NUMBER_OF_COMPONENTS=NUMBER_OF_DIMENSIONS+1 !Include hydrostatic pressure component
              CALL FIELD_NUMBER_OF_COMPONENTS_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,NUMBER_OF_COMPONENTS, &
                & ERR,ERROR,*999)
              CALL FIELD_NUMBER_OF_COMPONENTS_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DELUDELN_VARIABLE_TYPE,NUMBER_OF_COMPONENTS, &
                & ERR,ERROR,*999)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                DO component_idx=1,NUMBER_OF_DIMENSIONS
                  CALL FIELD_COMPONENT_INTERPOLATION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,component_idx, &
                    & FIELD_NODE_BASED_INTERPOLATION,ERR,ERROR,*999)
                  CALL FIELD_COMPONENT_INTERPOLATION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DELUDELN_VARIABLE_TYPE,component_idx, &
                    & FIELD_NODE_BASED_INTERPOLATION,ERR,ERROR,*999)
                ENDDO !component_idx

!kmith :09.06.09 - Hydrostatic pressure could be node-based as well		
!                CALL FIELD_COMPONENT_INTERPOLATION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,4, &
!                  & FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
!                CALL FIELD_COMPONENT_INTERPOLATION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_DELUDELN_VARIABLE_TYPE,4, &
!                  & FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
!kmith
              
	      CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The solution method of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ENDIF
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED) THEN
              CALL FIELD_CREATE_FINISH(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD,ERR,ERROR,*999)
            ENDIF
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation"
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_MATERIALS_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            EQUATIONS_MATERIALS=>EQUATIONS_SET%MATERIALS
            IF(ASSOCIATED(EQUATIONS_MATERIALS)) THEN
              IF(EQUATIONS_MATERIALS%MATERIALS_FIELD_AUTO_CREATED) THEN
                !Create the auto created materials field
                !Just default to Moony-Rivelen for now.
                CALL FIELD_CREATE_START(EQUATIONS_SET_SETUP%FIELD_USER_NUMBER,EQUATIONS_SET%REGION,EQUATIONS_MATERIALS% &
                  & MATERIALS_FIELD,ERR,ERROR,*999)
                CALL FIELD_TYPE_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_MATERIAL_TYPE,ERR,ERROR,*999)
                CALL FIELD_DEPENDENT_TYPE_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_INDEPENDENT_TYPE,ERR,ERROR,*999)
                CALL FIELD_MESH_DECOMPOSITION_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,GEOMETRIC_DECOMPOSITION,ERR,ERROR,*999)
                CALL FIELD_MESH_DECOMPOSITION_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,GEOMETRIC_DECOMPOSITION, &
                  & ERR,ERROR,*999)
                CALL FIELD_GEOMETRIC_FIELD_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,EQUATIONS_SET%GEOMETRY% &
                  & GEOMETRIC_FIELD,ERR,ERROR,*999)
                CALL FIELD_NUMBER_OF_VARIABLES_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,1,ERR,ERROR,*999)
                CALL FIELD_VARIABLE_TYPES_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,(/FIELD_U_VARIABLE_TYPE/), &
                  & ERR,ERROR,*999)
                CALL FIELD_DIMENSION_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & FIELD_VECTOR_DIMENSION_TYPE,ERR,ERROR,*999)
                CALL FIELD_DATA_TYPE_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & FIELD_DP_TYPE,ERR,ERROR,*999)
                CALL FIELD_NUMBER_OF_COMPONENTS_SET_AND_LOCK(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 2,ERR,ERROR,*999)
                !Default the materials components to the geometric interpolation setup with constant interpolation
                CALL FIELD_COMPONENT_MESH_COMPONENT_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 1,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 1,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_INTERPOLATION_SET(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 1,FIELD_CONSTANT_INTERPOLATION,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_MESH_COMPONENT_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 2,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 2,GEOMETRIC_MESH_COMPONENT,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_INTERPOLATION_SET(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & 2,FIELD_CONSTANT_INTERPOLATION,ERR,ERROR,*999)
                !Default the field scaling to that of the geometric field
                CALL FIELD_SCALING_TYPE_GET(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD,GEOMETRIC_SCALING_TYPE,ERR,ERROR,*999)
                CALL FIELD_SCALING_TYPE_SET(EQUATIONS_MATERIALS%MATERIALS_FIELD,GEOMETRIC_SCALING_TYPE,ERR,ERROR,*999)
              ELSE
                !Check the user specified field
                !Just default to Moony-Rivelen for now.
                CALL FIELD_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_MATERIAL_TYPE,ERR,ERROR,*999)
                CALL FIELD_DEPENDENT_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_INDEPENDENT_TYPE,ERR,ERROR,*999)
                CALL FIELD_NUMBER_OF_VARIABLES_CHECK(EQUATIONS_SET_SETUP%FIELD,1,ERR,ERROR,*999)
                CALL FIELD_VARIABLE_TYPES_CHECK(EQUATIONS_SET_SETUP%FIELD,(/FIELD_U_VARIABLE_TYPE/),ERR,ERROR,*999)
                CALL FIELD_DIMENSION_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VECTOR_DIMENSION_TYPE, &
                  & ERR,ERROR,*999)
                CALL FIELD_DATA_TYPE_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,FIELD_DP_TYPE,ERR,ERROR,*999)
                CALL FIELD_NUMBER_OF_COMPONENTS_CHECK(EQUATIONS_SET_SETUP%FIELD,FIELD_U_VARIABLE_TYPE,2,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Equations set materials is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            EQUATIONS_MATERIALS=>EQUATIONS_SET%MATERIALS
            IF(ASSOCIATED(EQUATIONS_MATERIALS)) THEN
              IF(EQUATIONS_MATERIALS%MATERIALS_FIELD_AUTO_CREATED) THEN
                !Finish creating the materials field
                CALL FIELD_CREATE_FINISH(EQUATIONS_MATERIALS%MATERIALS_FIELD,ERR,ERROR,*999)
                !Set the default values for the materials field
                !Default to Mooney-Rivlin for now and set the c10 and c01 constants to be 2.0 and 3.0
                CALL FIELD_COMPONENT_VALUES_INITIALISE(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & FIELD_VALUES_SET_TYPE,1,2.0_DP,ERR,ERROR,*999)
                CALL FIELD_COMPONENT_VALUES_INITIALISE(EQUATIONS_MATERIALS%MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE, &
                  & FIELD_VALUES_SET_TYPE,2,3.0_DP,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Equations set materials is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_SOURCE_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            !Do nothing
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            !Do nothing
            !? Maybe set finished flag????
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_ANALYTIC_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED) THEN
              !Do nothing
            ELSE
              CALL FLAG_ERROR("Equations set dependent field has not been finished.",ERR,ERROR,*999)
            ENDIF
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            !Do nothing
            !? Maybe set finished flag????
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_EQUATIONS_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED) THEN
              !Start the equations creation
              CALL EQUATIONS_CREATE_START(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
              CALL EQUATIONS_LINEARITY_TYPE_SET(EQUATIONS,EQUATIONS_NONLINEAR,ERR,ERROR,*999)
              CALL EQUATIONS_TIME_DEPENDENCE_TYPE_SET(EQUATIONS,EQUATIONS_STATIC,ERR,ERROR,*999)
            ELSE
              CALL FLAG_ERROR("Equations set dependent field has not bee finished.",ERR,ERROR,*999)
            ENDIF
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
            CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
              !Finish the equations creation
              CALL EQUATIONS_SET_EQUATIONS_GET(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
              CALL EQUATIONS_CREATE_FINISH(EQUATIONS,ERR,ERROR,*999)
              !Create the equations mapping.
              CALL EQUATIONS_MAPPING_CREATE_START(EQUATIONS,EQUATIONS_MAPPING,ERR,ERROR,*999)
              CALL EQUATIONS_MAPPING_RESIDUAL_VARIABLE_TYPE_SET(EQUATIONS_MAPPING,FIELD_U_VARIABLE_TYPE,ERR,ERROR,*999)
              CALL EQUATIONS_MAPPING_LINEAR_MATRICES_NUMBER_SET(EQUATIONS_MAPPING,0,ERR,ERROR,*999)
              CALL EQUATIONS_MAPPING_RHS_VARIABLE_TYPE_SET(EQUATIONS_MAPPING,FIELD_DELUDELN_VARIABLE_TYPE,ERR,ERROR,*999)
              CALL EQUATIONS_MAPPING_CREATE_FINISH(EQUATIONS_MAPPING,ERR,ERROR,*999)
              !Create the equations matrices
              CALL EQUATIONS_MATRICES_CREATE_START(EQUATIONS,EQUATIONS_MATRICES,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_CREATE_FINISH(EQUATIONS_MATRICES,ERR,ERROR,*999)
            CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solution method of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                & " is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(EQUATIONS_SET_SETUP_BOUNDARY_CONDITIONS_TYPE)
          SELECT CASE(EQUATIONS_SET_SETUP%ACTION_TYPE)
          CASE(EQUATIONS_SET_SETUP_START_ACTION)
            CALL EQUATIONS_SET_EQUATIONS_GET(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
            IF(ASSOCIATED(EQUATIONS)) THEN
              IF(EQUATIONS%EQUATIONS_FINISHED) THEN
                CALL BOUNDARY_CONDITIONS_CREATE_START(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
              ELSE
                CALL FLAG_ERROR("Equations set equations has not been finished.",ERR,ERROR,*999)               
              ENDIF
            ELSE
              CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE(EQUATIONS_SET_SETUP_FINISH_ACTION)
            CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_GET(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
            CALL BOUNDARY_CONDITIONS_CREATE_FINISH(BOUNDARY_CONDITIONS,ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity equation."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE DEFAULT
          LOCAL_ERROR="The setup type of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a finite elasticity equation."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      CASE DEFAULT
        LOCAL_ERROR="Equations set subtype "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SUBTYPE,"*",ERR,ERROR))// &
          & " is not valid for a finite elasticity equation type of an elasticity equation set class."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SETUP")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_EQUATIONS_SET_SETUP",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SETUP")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SETUP

  !
  !================================================================================================================================
  !

  !>Sets/changes the solution method for a finite elasticity equation type of an elasticity equations set class.
  SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to set the solution method for
    INTEGER(INTG), INTENT(IN) :: SOLUTION_METHOD !<The solution method to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      SELECT CASE(EQUATIONS_SET%SUBTYPE)
      CASE(EQUATIONS_SET_NO_SUBTYPE)        
        SELECT CASE(SOLUTION_METHOD)
        CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
          EQUATIONS_SET%SOLUTION_METHOD=EQUATIONS_SET_FEM_SOLUTION_METHOD
        CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The specified solution method of "//TRIM(NUMBER_TO_VSTRING(SOLUTION_METHOD,"*",ERR,ERROR))//" is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      CASE DEFAULT
        LOCAL_ERROR="Equations set subtype of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SUBTYPE,"*",ERR,ERROR))// &
          & " is not valid for a finite elasticity equation type of an elasticity equations set class."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SOLUTION_METHOD_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes the equation subtype for a finite elasticity equation type of an elasticity equations set class.
  SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET(EQUATIONS_SET,EQUATIONS_SET_SUBTYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to set the equation subtype for
    INTEGER(INTG), INTENT(IN) :: EQUATIONS_SET_SUBTYPE !<The equation subtype to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_FIELD_USER_NUMBER
    TYPE(FIELD_TYPE), POINTER :: DUMMY_FIELD
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DUMMY_FIELD_USER_NUMBER=0
      NULLIFY(DUMMY_FIELD)
      SELECT CASE(EQUATIONS_SET_SUBTYPE)
      CASE(EQUATIONS_SET_NO_SUBTYPE)        
        EQUATIONS_SET%CLASS=EQUATIONS_SET_ELASTICITY_CLASS
        EQUATIONS_SET%TYPE=EQUATIONS_SET_FINITE_ELASTICITY_TYPE
        EQUATIONS_SET%SUBTYPE=EQUATIONS_SET_NO_SUBTYPE       
      CASE DEFAULT
        LOCAL_ERROR="Equations set subtype "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_SUBTYPE,"*",ERR,ERROR))// &
          & " is not valid for a finite elasticity equation type of an elasticity equations set class."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_EQUATIONS_SET_SUBTYPE_SET

  !
  !================================================================================================================================
  !

  !>Sets up the finite elasticity problem.
  SUBROUTINE FINITE_ELASTICITY_PROBLEM_SETUP(PROBLEM,PROBLEM_SETUP,ERR,ERROR,*)

    !Argument variables
    TYPE(PROBLEM_TYPE), POINTER :: PROBLEM !<A pointer to the problem set to setup a Laplace equation on.
    TYPE(PROBLEM_SETUP_TYPE), INTENT(INOUT) :: PROBLEM_SETUP !<The problem setup information
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(CONTROL_LOOP_TYPE), POINTER :: CONTROL_LOOP,CONTROL_LOOP_ROOT
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("FINITE_ELASTICITY_PROBLEM_SETUP",ERR,ERROR,*999)

    NULLIFY(CONTROL_LOOP)
    NULLIFY(SOLVER)
    NULLIFY(SOLVER_EQUATIONS)
    NULLIFY(SOLVERS)
    IF(ASSOCIATED(PROBLEM)) THEN
      SELECT CASE(PROBLEM%SUBTYPE)
      CASE(PROBLEM_NO_SUBTYPE)
        SELECT CASE(PROBLEM_SETUP%SETUP_TYPE)
        CASE(PROBLEM_SETUP_INITIAL_TYPE)
          SELECT CASE(PROBLEM_SETUP%ACTION_TYPE)
          CASE(PROBLEM_SETUP_START_ACTION)
            !Do nothing????
          CASE(PROBLEM_SETUP_FINISH_ACTION)
            !Do nothing????
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity problem."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(PROBLEM_SETUP_CONTROL_TYPE)
          SELECT CASE(PROBLEM_SETUP%ACTION_TYPE)
          CASE(PROBLEM_SETUP_START_ACTION)
            !Set up a simple control loop
            CALL CONTROL_LOOP_CREATE_START(PROBLEM,CONTROL_LOOP,ERR,ERROR,*999)
          CASE(PROBLEM_SETUP_FINISH_ACTION)
            !Finish the control loops
            CONTROL_LOOP_ROOT=>PROBLEM%CONTROL_LOOP
            CALL CONTROL_LOOP_GET(CONTROL_LOOP_ROOT,CONTROL_LOOP_NODE,CONTROL_LOOP,ERR,ERROR,*999)
            CALL CONTROL_LOOP_CREATE_FINISH(CONTROL_LOOP,ERR,ERROR,*999)            
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity problem."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(PROBLEM_SETUP_SOLVERS_TYPE)
          !Get the control loop
          CONTROL_LOOP_ROOT=>PROBLEM%CONTROL_LOOP
          CALL CONTROL_LOOP_GET(CONTROL_LOOP_ROOT,CONTROL_LOOP_NODE,CONTROL_LOOP,ERR,ERROR,*999)
          SELECT CASE(PROBLEM_SETUP%ACTION_TYPE)
          CASE(PROBLEM_SETUP_START_ACTION)
            !Start the solvers creation
            CALL SOLVERS_CREATE_START(CONTROL_LOOP,SOLVERS,ERR,ERROR,*999)
            CALL SOLVERS_NUMBER_SET(SOLVERS,1,ERR,ERROR,*999)
            !Set the solver to be a nonlinear solver
            CALL SOLVERS_SOLVER_GET(SOLVERS,1,SOLVER,ERR,ERROR,*999)
            CALL SOLVER_TYPE_SET(SOLVER,SOLVER_NONLINEAR_TYPE,ERR,ERROR,*999)
            !Set solver defaults
            CALL SOLVER_LIBRARY_TYPE_SET(SOLVER,SOLVER_PETSC_LIBRARY,ERR,ERROR,*999)
          CASE(PROBLEM_SETUP_FINISH_ACTION)
            !Get the solvers
            CALL CONTROL_LOOP_SOLVERS_GET(CONTROL_LOOP,SOLVERS,ERR,ERROR,*999)
            !Finish the solvers creation
            CALL SOLVERS_CREATE_FINISH(SOLVERS,ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity problem."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE(PROBLEM_SETUP_SOLVER_EQUATIONS_TYPE)
          SELECT CASE(PROBLEM_SETUP%ACTION_TYPE)
          CASE(PROBLEM_SETUP_START_ACTION)
            !Get the control loop
            CONTROL_LOOP_ROOT=>PROBLEM%CONTROL_LOOP
            CALL CONTROL_LOOP_GET(CONTROL_LOOP_ROOT,CONTROL_LOOP_NODE,CONTROL_LOOP,ERR,ERROR,*999)
            !Get the solver
            CALL CONTROL_LOOP_SOLVERS_GET(CONTROL_LOOP,SOLVERS,ERR,ERROR,*999)
            CALL SOLVERS_SOLVER_GET(SOLVERS,1,SOLVER,ERR,ERROR,*999)
            !Create the solver equatgions
            CALL SOLVER_EQUATIONS_CREATE_START(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)
            CALL SOLVER_EQUATIONS_LINEARITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_EQUATIONS_NONLINEAR,ERR,ERROR,*999)
            CALL SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET(SOLVER_EQUATIONS,SOLVER_EQUATIONS_STATIC,ERR,ERROR,*999)
            CALL SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_SPARSE_MATRICES,ERR,ERROR,*999)
          CASE(PROBLEM_SETUP_FINISH_ACTION)
            !Get the control loop
            CONTROL_LOOP_ROOT=>PROBLEM%CONTROL_LOOP
            CALL CONTROL_LOOP_GET(CONTROL_LOOP_ROOT,CONTROL_LOOP_NODE,CONTROL_LOOP,ERR,ERROR,*999)
            !Get the solver equations
            CALL CONTROL_LOOP_SOLVERS_GET(CONTROL_LOOP,SOLVERS,ERR,ERROR,*999)
            CALL SOLVERS_SOLVER_GET(SOLVERS,1,SOLVER,ERR,ERROR,*999)
            CALL SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)
            !Finish the solver equations creation
            CALL SOLVER_EQUATIONS_CREATE_FINISH(SOLVER_EQUATIONS,ERR,ERROR,*999)             
          CASE DEFAULT
            LOCAL_ERROR="The action type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%ACTION_TYPE,"*",ERR,ERROR))// &
              & " for a setup type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a finite elasticity problem."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        CASE DEFAULT
          LOCAL_ERROR="The setup type of "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SETUP%SETUP_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a finite elasticity problem."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      CASE DEFAULT
        LOCAL_ERROR="Problem subtype "//TRIM(NUMBER_TO_VSTRING(PROBLEM%SUBTYPE,"*",ERR,ERROR))// &
          & " is not valid for a finite elasticity type of an elasticity problem class."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Problem is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_PROBLEM_SETUP")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_PROBLEM_SETUP",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_PROBLEM_SETUP")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_PROBLEM_SETUP

  !
  !================================================================================================================================
  !

  !>Sets/changes the problem subtype for a finite elasticity type .
  SUBROUTINE FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET(PROBLEM,PROBLEM_SUBTYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(PROBLEM_TYPE), POINTER :: PROBLEM !<A pointer to the problem to set the problem subtype for
    INTEGER(INTG), INTENT(IN) :: PROBLEM_SUBTYPE !<The problem subtype to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(PROBLEM)) THEN
      SELECT CASE(PROBLEM_SUBTYPE)
      CASE(PROBLEM_NO_SUBTYPE)        
        PROBLEM%CLASS=PROBLEM_ELASTICITY_CLASS
        PROBLEM%TYPE=PROBLEM_FINITE_ELASTICITY_TYPE
        PROBLEM%SUBTYPE=PROBLEM_NO_SUBTYPE      
      CASE DEFAULT
        LOCAL_ERROR="Problem subtype "//TRIM(NUMBER_TO_VSTRING(PROBLEM_SUBTYPE,"*",ERR,ERROR))// &
          & " is not valid for a finite elasticity type of an elasticity problem class."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Problem is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET")
    RETURN
999 CALL ERRORS("FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET",ERR,ERROR)
    CALL EXITS("FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET")
    RETURN 1
  END SUBROUTINE FINITE_ELASTICITY_PROBLEM_SUBTYPE_SET

  !
  !================================================================================================================================
  !

END MODULE FINITE_ELASTICITY_ROUTINES
