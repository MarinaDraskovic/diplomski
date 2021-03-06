% Control measure is self protection, with minimal implementation cost.
% SIR model: 
%       ds/dt = -(1-u1)*beta*i*s
%       di/dt = (1-u1)*beta*i*s - gamma*i
%       dr/dt = gamma*i   
% __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __
% Model is converted by Pontryagin's max principle to objective functional:
%       J(u(.))=integral(0->T)(A1*s + A2*i + A3*r + cu^2)dt
% __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __
% Numerical solution for optimality problem using the
% FOURTH-ORDER RUNGE-KUTTA FORWARD-BACKWARD SWEEP METHOD.
% _______________________________________________
function dy = SIR_model_control_personal_protection(params, adata)
    % Parameters of the model
    beta = params(1);
    gamma = params(2);
    u_max = 0.5;   
    T=length(adata);
    
    %Parameters of the 4th order Runge-Kutta (RK) method
    test = -1;
    deltaError = 0.001;
    N = 1000;
    t = linspace(0, T, N+1);
    h = T / N; 
    
    S = zeros(1,N+1);
    I = zeros(1,N+1);
    R = zeros(1,N+1);
    pS = zeros(1,N+1); 
    pI = zeros(1,N+1);
    pR = zeros(1,N+1);
    U = zeros(1,N+1);
    
    % Initial conditions of the model
    S(1) = 1-adata(1)/params(3);
    I(1) = adata(1)/params(3);
    R(1) = 0;
       
    A1=-1; A2=1; A3=0; C1=1/2; 
    
    % Iterations of the RK method
    while(test < 0)
        oldS = S; 
        oldI = I;
        oldR = R; 
        old_pS = pS; 
        old_pI = pI;
        old_pR = pR; 
        oldU = U;
        
        %RK Forward for SIR
        for i = 1:N
            % 1st RK parameter
            k1_S = -(1-U(i))*beta*S(i)*I(i);
            k1_I = (1-U(i))*beta*S(i)*I(i) - gamma*I(i);
            k1_R = gamma*I(i);
        
            % 2nd RK parameter
            kS = S(i) + h/2 * k1_S; 
            kI = I(i) + h/2 * k1_I;
          
            k2_S = -(1-U(i))*beta*kS*kI;
            k2_I = (1-U(i))*beta*kS*kI - gamma*kI;
            k2_R = gamma*kI;
            
            % 3rd RK parameter
            kS = S(i) + h/2 * k2_S; 
            kI = I(i) + h/2 * k2_I;
            
            k3_S = -(1-U(i))*beta*kS*kI;
            k3_I = (1-U(i))*beta*kS*kI - gamma*kI;
            k3_R = gamma*kI;
            
            % 4th RK parameter
            kS = S(i) + h * k3_S;
            kI = I(i) + h * k3_I;
            
            k4_S = -(1-U(i))*beta*kS*kI;
            k4_I = (1-U(i))*beta*kS*kI - gamma*kI;
            k4_R = gamma*kI;
            
            % RK new approximation
            S(i+1) = S(i) + h/6 * (k1_S + 2 * (k2_S + k3_S) + k4_S);
            I(i+1) = I(i) + h/6 * (k1_I + 2 * (k2_I + k3_I) + k4_I);
            R(i+1) = R(i) + h/6 * (k1_R + 2 * (k2_R + k3_R) + k4_R);
        end
        
        % RK Backward for lambda
        for i = 1:N
            j = N + 2 - i;
            
            % 1st RK parameter
            k1_pS = -A1 + (pS(j)-pI(j))*beta*I(j)*(1-U(j));
            k1_pI = -A2 + (pS(j)-pI(j))*beta*S(j)*(1-U(j)) + (pI(j)-pR(j))*gamma;
            k1_pR = -A3;
            
            % 2nd RK parameter
            kpS = pS(j) - h/2 * k1_pS;
            kpI = pI(j) - h/2 * k1_pI;
            kpR = pR(j) - h/2 * k1_pR;
            
            k2_pS = -A1 + (kpS-kpI)*beta*I(j)*(1- U(j));
            k2_pI = -A2 + (kpS-kpI)*beta*S(j)*(1- U(j)) + (kpI-kpR)*gamma;
            k2_pR = -A3;
            
            % 3rd RK parameter
            kpS = pS(j) - h/2 * k2_pS;
            kpI = pI(j) - h/2 * k2_pI;
            kpR = pR(j) - h/2 * k2_pR;
            
            k3_pS = -A1 + (kpS-kpI)*beta*I(j)*(1- U(j));
            k3_pI = -A2 + (kpS-kpI)*beta*S(j)*(1- U(j)) + (kpI-kpR)*gamma;
            k3_pR = -A3;
            
            % 4th RK parameter
            kpS = pS(j) - h * k3_pS;
            kpI = pI(j) - h * k3_pI;
            kpR = pR(j) - h * k3_pR;
            
            k4_pS = -A1 + (kpS-kpI)*beta*I(j)*(1-U(j));
            k4_pI = -A2 + (kpS-kpI)*beta*S(j)*(1-U(j)) + (kpI-kpR)*gamma;
            k4_pR = -A3;
            
            % RK new approximation
            pS(j-1) = pS(j) - h/6 *(k1_pS + 2*(k2_pS+k3_pS) + k4_pS);
            pI(j-1) = pI(j) - h/6 *(k1_pI + 2*(k2_pI+k3_pI) + k4_pI);
            pR(j-1) = pR(j) - h/6 *(k1_pR + 2*(k2_pR+k3_pR) + k4_pR);
        end
        
        % Update U
        L = zeros(1,N+1);
        for i = 1:N+1
            L(i) = ((pI(i)-pS(i))*beta*I(i)*S(i))/(2*C1);
            U(i) = min([max([0 L(i)]) u_max]);
        end

        % Absolute error for convergence
        temp1 = deltaError * sum(abs(S)) - sum(abs(oldS - S));
        temp2 = deltaError * sum(abs(I)) - sum(abs(oldI - I));
        temp3 = deltaError * sum(abs(R)) - sum(abs(oldR - R));
        temp4 = deltaError * sum(abs(U)) - sum(abs(oldU - U));
        temp5 = deltaError * sum(abs(pS)) - sum(abs(old_pS - pS));
        temp6 = deltaError * sum(abs(pI)) - sum(abs(old_pI - pI));
        temp7 = deltaError * sum(abs(pR)) - sum(abs(old_pR - pR));
            
        test = min(temp1,min(temp2,min(temp3,min(temp4, ...
            min(temp5,min(temp6,temp7))))));
    end
    dy(1,:) = t; dy(2,:) = S; dy(3,:) = I;
    dy(4,:) = R; dy(5,:) = U;    
end