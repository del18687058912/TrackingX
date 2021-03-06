function loglik = computeEMLoglik(xInit,PInit,xSmooth,y,F,H,Q,R,B,u)
% COMPUTEEMLOGLIK Compute EM loglikelihood p(y_{1:t},x_{1:t} | theta), where
% theta = {F,H,Q,R,B}.
%
% INPUTS:   xInit       The (xDim x 1) initial state mean for time 1
%           PInit       The (xDim x xDim) initial state covariance for time 1
%           xSmooth     The (xDim x N) matrix of smoothed estimates for time 1:N
%           y           The (yDim x N) matrix of measurements for time 1:N
%           F           The (xDim x xDim) state transition matrix
%           H           The (yDim x xDim) measurement matrix
%           Q           The (xDim x xDim) process noise covariance
%           R           The (yDim x yDim) measurement noise covariance
%           B           The (xDim x uDim) control input gain matrix
%           u           The (uDim x N) control input matrix for time 1:N
%           
% OUTPUTS:  loglik   A boolean stating if EM has converged
%
% [1] A. W. Blocker, An EM algorithm for the estimation of affine state-space systems with or without known inputs, (2008)
%
% January 2018 Lyudmil Vladimirov, University of Liverpool.

    [xDim, N] = size(xSmooth);
    yDim = size(y,1);
    
    loglik = -sum((y-H*xSmooth).^2)/(2*R) - N/2*log(abs(R))...
        -1/2*sum((xSmooth(2:N)-F*xSmooth(1:N-1)-B*u(2:N)).^2)/(Q) - (N-1)/2*log(abs(Q))...
        -sum((xSmooth(1)-xInit).^2)/(2*PInit) - 0.5*log(abs(PInit)) - N*log(2*pi);
    
%     loglik = -.5*(y-H*xSmooth)/R*(y-H*xSmooth)' - N/2*log(abs(R))...
%         -1/2*(xSmooth(:,2:N)-F*xSmooth(1:N-1)-B*u(2:N))/Q - (N-1)/2*log(abs(Q))...
%         -sum((xSmooth(1)-xInit).^2)/(2*PInit) - 0.5*log(abs(PInit)) - N*log(2*pi);
    
%     loglik = cell(1,3);
%     loglik{1} = -.5*(xSmooth(:,1) - xInit)/PInit*(xSmooth(:,1) - xInit)' ...
%                   -.5*log(abs(PInit)) - .5*(N-1)*log(abs(Q)) - .5*N*log(abs(R)) ...
%                   -.5*N*(xDim+yDim)*log(2*pi);
%     loglik{2} = 0;
%     loglik{3} = 0;
%     for k = 1:N
%         if(k>1)
%             loglik{2} = loglik{2} + .5*(xSmooth(:,k) ...
%                           - F*xSmooth(:,k-1) - B*u(:,k))/Q*(xSmooth(:,k) - F*xSmooth(:,k-1) - B*u(:,k))';
%         end
%         loglik{3} = loglik{3} + .5*(y(:,k) - H*xSmooth(:,k))/R*(y(:,k) - H*xSmooth(:,k))';
%     end
%     loglik = loglik{1} - loglik{2} - loglik{3};
end