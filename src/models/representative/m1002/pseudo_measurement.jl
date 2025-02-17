 """
```
pseudo_measurement(m::Model1002{T},
    TTT::Matrix{T}, RRR::Matrix{T}, CCC::Vector{T}) where {T<:AbstractFloat}
```

Assign pseudo-measurement equation (a linear combination of states):

```
x_t = ZZ_pseudo*s_t + DD_pseudo
```
"""
function pseudo_measurement(m::Model1002{T},
                            TTT::Matrix{T},
                            RRR::Matrix{T},
                            CCC::Vector{T}) where {T<:AbstractFloat}

    endo      = m.endogenous_states
    endo_addl = m.endogenous_states_augmented
    pseudo    = m.pseudo_observables

    _n_states = n_states_augmented(m)
    _n_pseudo = n_pseudo_observables(m)

    # Compute TTT^10, used for Expected10YearRateGap, Expected10YearRate, and Expected10YearNaturalRate
    TTT10 = (1/40)*((UniformScaling(1.) - TTT)\(TTT - TTT^41))

    # Initialize pseudo ZZ and DD matrices
    ZZ_pseudo = zeros(_n_pseudo, _n_states)
    DD_pseudo = zeros(_n_pseudo)

    ##########################################################
    ## PSEUDO-OBSERVABLE EQUATIONS
    ##########################################################

    ## Output
    ZZ_pseudo[pseudo[:y_t],endo[:y_t]] = 1.

    ## Flexible Output
    ZZ_pseudo[pseudo[:y_f_t],endo[:y_f_t]] = 1.

    ## Natural Rate
    ZZ_pseudo[pseudo[:NaturalRate],endo[:r_f_t]] = 1.
    DD_pseudo[pseudo[:NaturalRate]]              = 100.0*(m[:rstar]-1.0)

    ## π_t
    ZZ_pseudo[pseudo[:π_t],endo[:π_t]] = 1.
    DD_pseudo[pseudo[:π_t]]            = 100*(m[:π_star]-1);

    ## Output Gap
    ZZ_pseudo[pseudo[:OutputGap],endo[:y_t]] = 1;
    ZZ_pseudo[pseudo[:OutputGap],endo[:y_f_t]] = -1;

    ## Ex Ante Real Rate
    ZZ_pseudo[pseudo[:ExAnteRealRate],endo[:R_t]]  = 1;
    ZZ_pseudo[pseudo[:ExAnteRealRate],endo[:Eπ_t]] = -1;
    DD_pseudo[pseudo[:ExAnteRealRate]]             = m[:Rstarn] - 100*(m[:π_star]-1);

    ## Long Run Inflation
    ZZ_pseudo[pseudo[:LongRunInflation],endo[:π_star_t]] = 1.
    DD_pseudo[pseudo[:LongRunInflation]]                 = 100. *(m[:π_star]-1.)

    ## Marginal Cost
    ZZ_pseudo[pseudo[:MarginalCost],endo[:mc_t]] = 1.

    ## Wages
    ZZ_pseudo[pseudo[:Wages],endo[:w_t]] = 1.

    ## Flexible Wages
    ZZ_pseudo[pseudo[:FlexibleWages],endo[:w_f_t]] = 1.

    ## Hours
    ZZ_pseudo[pseudo[:Hours],endo[:L_t]] = 1.

    ## Flexible Hours
    ZZ_pseudo[pseudo[:FlexibleHours],endo[:L_f_t]] = 1.

    ## z_t
    ZZ_pseudo[pseudo[:z_t], endo[:z_t]] = 1.

    ## Expected 10-Year Rate Gap
    ZZ_pseudo[pseudo[:Expected10YearRateGap], :] = TTT10[endo[:R_t], :] - TTT10[endo[:r_f_t], :] - TTT10[endo[:Eπ_t], :]

    ## Nominal FFR
    ZZ_pseudo[pseudo[:NominalFFR], endo[:R_t]] = 1.
    DD_pseudo[pseudo[:NominalFFR]] = m[:Rstarn]

    ## Expected 10-Year Interest Rate
    ZZ_pseudo[pseudo[:Expected10YearRate], :] = TTT10[endo[:R_t], :]
    DD_pseudo[pseudo[:Expected10YearRate]]    = m[:Rstarn]

    ## Expected 10-Year Natural Rate
    ZZ_pseudo[pseudo[:Expected10YearNaturalRate], :] = TTT10[endo[:r_f_t], :] + TTT10[endo[:Eπ_t], :]
    DD_pseudo[pseudo[:Expected10YearNaturalRate]]    = m[:Rstarn]

    ## Expected Nominal Natural Rate
    ZZ_pseudo[pseudo[:ExpectedNominalNaturalRate], endo[:r_f_t]] = 1.
    ZZ_pseudo[pseudo[:ExpectedNominalNaturalRate], endo[:Eπ_t]]  = 1.
    DD_pseudo[pseudo[:ExpectedNominalNaturalRate]]               = m[:Rstarn]

    ## Nominal Rate Gap
    ZZ_pseudo[pseudo[:NominalRateGap], endo[:R_t]]   = 1.
    ZZ_pseudo[pseudo[:NominalRateGap], endo[:r_f_t]] = -1.
    ZZ_pseudo[pseudo[:NominalRateGap], endo[:Eπ_t]]  = -1.

    ## Labor Productivity Growth
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo[:y_t]]           = 1.
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo_addl[:y_t1]]     = -1.
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo[:z_t]]           = 1.
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo_addl[:e_gdp_t]]  = 1.
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo_addl[:e_gdp_t1]] = -m[:me_level]
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo[:L_t]]           = -1
    ZZ_pseudo[pseudo[:LaborProductivityGrowth], endo_addl[:L_t1]]     = 1.
    DD_pseudo[pseudo[:LaborProductivityGrowth]]                       = 100*(exp(m[:z_star]) - 1)

    ## u_t
    ZZ_pseudo[pseudo[:u_t], endo[:u_t]] = 1.

    ## Fundamental inflation related pseudo-obs
    if subspec(m) in ["ss13", "ss14", "ss15", "ss16", "ss17", "ss18", "ss19"]
        # Compute coefficient on Sinf
        betabar = exp((1-m[:σ_c] ) * m[:z_star]) * m[:β]
        κ = ((1 - m[:ζ_p]*m[:β]*exp((1 - m[:σ_c])*m[:z_star]))*
             (1 - m[:ζ_p]))/(m[:ζ_p]*((m[:Φ]- 1)*m[:ϵ_p] + 1))/
        (1 + m[:ι_p]*m[:β]*exp((1 - m[:σ_c])*m[:z_star]))
        κcoef = κ * (1 + m[:ι_p] * betabar)

        ZZ_pseudo[pseudo[:Sinf_t], endo_addl[:Sinf_t]] = 1.
        ZZ_pseudo[pseudo[:Sinf_w_coef_t], endo_addl[:Sinf_t]] = κcoef
        DD_pseudo[pseudo[:ι_p]] = m[:ι_p]
        ZZ_pseudo[pseudo[:πtil_t], endo_addl[:πtil_t]] = 1.
        DD_pseudo[pseudo[:πtil_t]] = 100 * (m[:π_star] - 1)
        ZZ_pseudo[pseudo[:e_tfp_t], endo_addl[:e_tfp_t]] = 1.
        if subspec(m) in ["ss14", "ss15", "ss16", "ss18", "ss19"]
            ZZ_pseudo[pseudo[:e_tfp_t1], endo_addl[:e_tfp_t1]] = 1.
        end
    end

    ## Exogenous processes
    if subspec(m) == "ss12"
        to_add = [:g_t, :b_t, :μ_t, :z_t, :λ_f_t, :λ_w_t, :rm_t, :σ_ω_t, :μ_e_t,
                  :γ_t, :π_star_t]
        to_add_addl = [:e_lr_t, :e_tfp_t, :e_gdpdef_t, :e_corepce_t, :e_gdp_t, :e_gdi_t]
        for i in to_add
            ZZ_pseudo[pseudo[i], endo[i]] = 1.
        end
        for i in to_add_addl
            ZZ_pseudo[pseudo[i], endo_addl[i]] = 1.
        end
    end

    return PseudoMeasurement(ZZ_pseudo, DD_pseudo)
end
