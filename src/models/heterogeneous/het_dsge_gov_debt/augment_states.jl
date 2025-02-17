function augment_states(m::HetDSGEGovDebt{T}, TTT::Matrix{T}, TTT_jump::Matrix{T}, RRR::Matrix{T},
                        CCC::Vector{T}) where {T<:AbstractFloat}
    endo     = m.endogenous_states #augment_model_states(m.endogenous_states, n_model_states(m))
    endo_new = m.endogenous_states_augmented
    exo      = m.exogenous_shocks

    n_endo = n_model_states(m)
    n_exo  = n_shocks_exogenous(m)

    @assert (n_endo, n_endo) == size(TTT)
    @assert (n_endo, n_exo) == size(RRR)
    @assert n_endo == length(CCC)

    # Initialize augmented matrices
    n_new_states = length(endo_new)
    n_new_eqs = n_new_states
    TTT_aug = zeros(n_endo + n_new_eqs, n_endo + n_new_states)
    TTT_aug[1:n_endo, 1:n_endo] = TTT
    RRR_aug = [RRR; zeros(n_new_eqs, n_exo)]
    CCC_aug = [CCC; zeros(n_new_eqs)]

    ### TTT modifications

    # Track Lags
    #TTT_aug[endo_new[:I_t1], first(endo[:I′_t])] = 1.0
    #TTT_aug[endo_new[:c_t1], endo_new[:c_t]] = 1.0 #1:get_setting(m, :n_backward_looking_states)] = C_eqn
    TTT_aug[endo_new[:C_t1], first(endo[:C′_t])] = 1.0 #endo_new[:c_t]] = 1.0

   #= TTT_aug[endo_new[:i_t1], endo[:i_t]] = 1.0
    TTT_aug[endo_new[:w_t1], endo[:w_t]] = 1.0
    TTT_aug[endo_new[:π_t1], endo[:π_t]] = 1.0
    TTT_aug[endo_new[:L_t1], endo[:L_t]]  = 1.0=#

    ## We construct state for expected inflation using the fact
    ##
    ##   E_t[s_{t+1}] = CCC + TTT*s_{t} = CCC + TTT * (CCC + TTT*s_{t-1} + RRR)
    ##                = (CCC+TTT*CCC) + (TTT^2)s_{t-1} + TTT*RRR
    ##
    ## So to construct the state for E_t[p_{t+1}], we need to make all these
    ## objects, and just index out the row relevant to pi_t

   #= T2 = TTT^2
    TR = TTT*RRR
    CTC = CCC+TTT*CCC


    TTT_aug[endo_new[:Et_π_t],:] = [T2[endo[:π_t],:]; zeros(n_new_states)]

    RRR_aug[endo_new[:Et_π_t],:] = TR[endo[:π_t],:]
    CCC_aug[endo_new[:Et_π_t],:] = CTC[endo[:π_t],:]=#

    return TTT_aug, RRR_aug, CCC_aug
end
