% Plot settings
ShowPlots = 1;              % Enable|Disable plot outputs
SkipSimFrames = 1;          % Number of EM output plot frames to skip 
ShowPredict = 0;            % Show KF Prediction Step plot Output
ShowUpdate = 0;             % Show KF Update Step plot Output
nEMIter = 50000;            % Number of EM iterations

% loglik = @(F,H,Q,R)-.5*( ln(det(params_kf.P_init)) ...
%                                  - sum((Log.xV(2:end) - F*Log.xV(1:end-1))/Q*(Log.xV(2:end) - F*Log.xV(1:end-1))') ...
%                                  - sum((zV-H*Log.xV)/R*sum(zV-H*Log.xV)') - (N-1)*ln(det(Q)) ...
%                                  - N*ln(det(R)) - 2*N*ln(2*pi));

% Recording Settings
Record = 0;                 % Enable|Disable recording
clear Frames                % Clear stored frames from previous simulations

% Simulation Settings
N = 1000;                   % Number of timesteps

% Results Log Container
Log.xFilt = zeros(1,N);     % Log to store filtered state vectors (for each EM iteration)             
Log.exec_time = 0;          % Log to store total execution time
Log.estFilt = cell(1,N);    % Log to store all filtered estimates (for each EM iteration)
    

% Create figure windows
if(ShowPlots)
    figure('units','normalized','outerposition',[0 0 1 1])
    ax(1) = gca;
end

% Instantiate a generic dynamic model
Params_dyn.xDim = 1;
Params_dyn.q = 1;                          
DynModel = GenericDynamicModelX(Params_dyn);
DynModel.Params.F = @(~) 1;                 % Set Transition matrix F = 1;
DynModel.Params.Q = @(~) 1;    % Set Process noise covariance Q = q^2

% Instatiate a generic observation model
% ( H = 1, R = r^2)
Params_obs.xDim = 1;
Params_obs.yDim = 1;
Params_obs.r = 1;
ObsModel = GenericObservationModelX(Params_obs);
ObsModel.Params.R = @(~) 10;


Q_old = DynModel.Params.Q(1);
F_old = DynModel.Params.F(1);
R_old = ObsModel.Params.R(1);

% Generate ground truth and measurements
sV = 5;
zV = ObsModel.sample(0, sV(1),1);
clear pErr mErr;
mErr = zV - sV;
for k = 2:N
    % Generate new measurement from ground truth
    sV(:,k) = DynModel.sys(1,sV(:,k-1),DynModel.sys_noise(1,1));     % save ground truth
    pErr(k) = sV(k) - sV(k-1);
    zV(:,k) = ObsModel.sample(0, sV(:,k),1);     % generate noisy measurment
    mErr(k) = zV(k) - sV(k);
    
end

% Calculate and store the true process and measurement noise covariances
Q_true = std(pErr)^2;
R_true = std(mErr)^2;

% Corrupt the model parameters
DynModel.Params.F = @(~) 10;
%ObsModel.Params.H = @(~) 10;
ObsModel.Params.R = @(~) ObsModel.Params.R(1)*.001;
DynModel.Params.Q = @(~) DynModel.Params.Q(1)*.001;

% Initiate Kalman Filter
Params_kf.k        = 1;
Params_kf.x_init   = sV(1)-DynModel.sys_noise(1,1);
Params_kf.P_init   = DynModel.Params.Q(1);
Params_kf.DynModel = DynModel;
Params_kf.ObsModel = ObsModel;
KFilter            = KalmanFilterX(Params_kf);
%KFilter.DynModel.Params.F = @(~)F;
%KFilter.DynModel.Params.Q = @(~)Q;
%KFilter.ObsModel.Params.R = @(~)R;

% For all EM iterations
for EMIter = 1:nEMIter
    
    fprintf('\nEMIter: %d/%d\n', EMIter, nEMIter);

    % FILTERING
    % ===================>
    
    % For all timesteps
    for k = 1:N
        
        % Update KF measurement vector
        KFilter.Params.y = zV(:,k);

        % Iterate Kalman Filter
        KFilter.Iterate();

        % Store Logs
        Log.xV(:,k)     = KFilter.Params.x;
        Log.estFilt{k}  = KFilter.Params;

        % Plot update step results
        if(ShowPlots && ShowUpdate)
            % Plot data
            cla(ax(1));
            hold on;
            h2 = plot(ax(1), k, zV(k),'k*','MarkerSize', 10);
            h3 = plot(ax(1), 1:k, sV(1:k),'b.-','LineWidth',1);
            plot(ax(1), k, sV(k),'bo','MarkerSize', 10);
            plot(k, Log.xV(k), 'o', 'MarkerSize', 10);
            h4 = plot(1:k, Log.xV(1:k), '.-', 'MarkerSize', 10);
            title(sp1,'\textbf{State evolution}','Interpreter','latex')
            xlabel(sp1,'Time (s)','Interpreter','latex')
            ylabel(sp1,'x (m)','Interpreter','latex')
            legend(sp1,[h2 h3 h4], 'Measurements', 'Ground truth', 'Filtered state', 'Interpreter','latex');
            pause(0.01);
        end
    end
    
    estFilt = Log.estFilt;
    
    if(Record || (ShowPlots && (EMIter==1 || rem(EMIter,SkipSimFrames)==0)))
        
        clf;
        sp1 = subplot(3,1,1);
        % NOTE: if your image is RGB, you should use flipdim(img, 1) instead of flipud.
        % Flip the image upside down before showing it
        % Plot data
         % Flip the image upside down before showing it

        % NOTE: if your image is RGB, you should use flipdim(img, 1) instead of flipud.
        hold on;
        h2 = plot(sp1,1:k,zV(1:k),'k*','MarkerSize', 10);
        h3 = plot(sp1,1:k,sV(1:k),'b.-','LineWidth',1);
        plot(sp1,k,sV(k),'bo','MarkerSize', 10);
        plot(sp1,k, Log.xV(k), 'ro', 'MarkerSize', 10);
        h4 = plot(sp1,1:k, Log.xV(1:k), 'r.-', 'MarkerSize', 10);
        title(sp1,'\textbf{State evolution}','Interpreter','latex')
        xlabel(sp1,'Time (s)','Interpreter','latex')
        ylabel(sp1,'x (m)','Interpreter','latex')
        legend(sp1,[h2 h3 h4], 'Measurements', 'Ground truth', 'Filtered state', 'Interpreter','latex');
        %axis(ax(1),V_bounds)
    end
    
    % SMOOTHING
    % ===================>
    estSmooth = cell(1,N);
    estSmooth{N}.x = estFilt{N}.x;
    estSmooth{N}.P = estFilt{N}.P;
    for k = N-1:-1:1
        [estSmooth{k}.x, estSmooth{k}.P, estSmooth{k}.C] = KalmanFilterX_SmoothRTS_Single(estFilt{k}.x,estFilt{k}.P,estFilt{k+1}.xPred,estFilt{k+1}.PPred, estSmooth{k+1}.x, estSmooth{k+1}.P, KFilter.DynModel.sys());
    end
    %smoothed_estimates = FilterList{i}.Filter.Smooth(filtered_estimates);
    xV_smooth = zeros(1,N);
    PV_smooth = zeros(1,N);
    for k=1:N
        xV_smooth(:,k) = estSmooth{k}.x;          %estmate        % allocate memory
        PV_smooth(:,k) = estSmooth{k}.P;
    end
    
    xV_filt = cell2mat(cellfun(@(x)x.x,estFilt,'un',0)); 
    meanRMSE_filt   = mean(abs(xV_filt - sV))
    meanRMSE_smooth = mean(abs(xV_smooth - sV))
    
    [F,Q,H,R,B,EMParams] = KalmanFilterX_LearnEM_Mstep(estFilt, estSmooth,KFilter.DynModel.sys(),KFilter.ObsModel.obs());
    
    R_old = KFilter.ObsModel.Params.R();
    H_old = KFilter.ObsModel.Params.H();
    F_old = KFilter.DynModel.Params.F();
    Q_old = KFilter.DynModel.Params.Q();
    
    % Reset KF
    F = F
    Q = Q
    R = R
    H = H
    KFilter = KalmanFilterX(Params_kf);
    KFilter.DynModel.Params.F = @(~)F;
    KFilter.DynModel.Params.Q = @(~)Q;
    KFilter.ObsModel.Params.H = @(~)H;
    KFilter.ObsModel.Params.R = @(~)R; %diag(diag(R));
    
    if(Record || (ShowPlots && (EMIter==1 || rem(EMIter,SkipSimFrames)==0)))
        
        clf;
        sp1 = subplot(2,4,[1 2 3 4]);
        % NOTE: if your image is RGB, you should use flipdim(img, 1) instead of flipud.
        % Flip the image upside down before showing it
        % Plot data
         % Flip the image upside down before showing it

        % Plot State evolution
        hold on;
        h6 = errorbar(sp1,1:k,xV_smooth,PV_smooth);
        h2 = plot(sp1,1:k,zV(1:k),'k*','MarkerSize', 10);
        h3 = plot(sp1,1:k,sV(1:k),'b.-','LineWidth',1);
        plot(sp1,k,sV(k),'bo','MarkerSize', 10);
        plot(sp1,k, Log.xV(k), 'ro', 'MarkerSize', 10);
        h4 = plot(sp1,1:k, Log.xV(1:k), 'r.-', 'MarkerSize', 10);
        plot(sp1,k, xV_smooth(k), 'go', 'MarkerSize', 10);
        h5 = plot(sp1,1:k, xV_smooth(1:k), 'g.-', 'MarkerSize', 10);
        title(sp1,'\textbf{State evolution}','Interpreter','latex')
        xlabel(sp1,'Time (s)','Interpreter','latex')
        ylabel(sp1,'x (m)','Interpreter','latex')
        legend(sp1,[h2 h3 h4 h5 h6], 'Measurements', 'Ground truth', 'Filtered state', 'Smoothed state', 'Smoothed variance','Interpreter','latex');
        %axis(ax(1),V_bounds)
        
        
        % Plot loglikelihood vs. Q
%         Qi = Q-abs(Q):0.01:Q+abs(Q);
%         loglik_sum = 0;
%         for t = 2:N
%             loglik_sum = loglik_sum + EMParams.Pt{t} + F_old*EMParams.Pt{t-1}*F_old'...
%                           - EMParams.Pt_tm1{t}*F_old' - F*EMParams.Pt_tm1{t}';
%         end
%         loglik = [];
%         for i = 1:numel(Qi)
%             loglik(i) = .5*(-(N-1)*log(Qi(i)) - loglik_sum/Qi(i));
%         end
%         sp2 = subplot(2,4,5);    
%         plot(sp2,Qi,loglik);
%         hold on;
%         plot(sp2, Q, -.5*(N-1)*log(Q) - .5*loglik_sum/Q,'r+');
%         str = sprintf('(%0.5f,%0.5f)',Q,-(N-1)*log(Q) - loglik_sum/Q);
%         text(sp2, Q+0.52, -(N-1)*log(Q) - loglik_sum/Q+abs(max(loglik)-min(loglik))*0.02, str);
%         %plot(repmat(loglik_sum-N*R,1,numel(Ri)),'r--');
%         axis([Q-abs(Q)*0.5 Q+abs(Q)*0.5 max(loglik)- abs(max(loglik)*.05) max(loglik)+abs(max(loglik)*.05)]);
%         xlabel(sp2,'\textbf{Q}','Interpreter','latex');
%         ylabel(sp2,'Joint log-likelihood','Interpreter','latex');
%         title(sp2,'\textbf{Joint LogLikelihood vs Q}','Interpreter','latex');    
%               
%         % Plot loglikelihood vs. R
%         loglik_sum = 0;
%         for t = 1:N
%             loglik_sum = loglik_sum + zV(t)*zV(t)' - zV(t)*xV_smooth(t)'*H_old' - H_old*xV_smooth(t)*zV(t)' + H_old*EMParams.Pt{t}*H_old';
%         end  
%         Ri = R-abs(R):0.01:R+abs(R);
%         loglik = [];
%         for i = 1:numel(Ri)
%             loglik(i) = -N*log(Ri(i)) + loglik_sum/Ri(i);
%         end
%         sp2 = subplot(2,4,6);                  
%         plot(sp2,Ri,loglik);
%         hold on;
%         plot(R, loglik_sum*R-N*R^2/2,'r+');
%         str = sprintf('(%0.5f,%0.5f)',R,loglik_sum*R-N*R^2/2);
%         text(R+0.2, loglik_sum*R-N*R^2/2+abs(max(loglik)-min(loglik))*0.02, str);
%         %plot(repmat(loglik_sum-N*R,1,numel(Ri)),'r--');
%         %axis([R-abs(R) R+abs(R) max(loglik)-abs(max(loglik)*.05) max(loglik)+abs(max(loglik)*.05)]);
%         xlabel(sp2,'\textbf{R}','Interpreter','latex');
%         ylabel(sp2,'joint likelihood','Interpreter','latex');
%         title(sp2,'\textbf{LogLikelihood vs R}','Interpreter','latex');                            
        
        sp3 = subplot(2,4,[5 6]);
        x = -5*Q_true:0.0001:5*Q_true;
        y = mvnpdf(x',0,Q_true);
        plot(sp3,x,y);
        hold on;
        y = mvnpdf(x',0,KFilter.DynModel.Params.Q());
        plot(sp3,x,y);
        xlabel(sp3,'\textbf{Process noise $w_k \sim \mathcal{N}(0,Q)$}','Interpreter','latex');
        ylabel(sp3,'pdf($w_k$)','Interpreter','latex');
        title(sp3,'\textbf{True vs Estimated process noise pdf}','Interpreter','latex');
        
        sp4 = subplot(2,4,[7 8]);
        x = -5*R_true:0.01:5*R_true;
        y = mvnpdf(x',0,R_true);
        plot(sp4,x,y);
        hold on;    
        y = mvnpdf(x',0,KFilter.ObsModel.Params.R());
        plot(sp4,x,y);
        xlabel(sp4,'\textbf{Measurement noise $v_k \sim \mathcal{N}(0,R)$}','Interpreter','latex');
        ylabel(sp4,'pdf($v_k$)','Interpreter','latex');
        title(sp4,'\textbf{True vs Estimated measurement noise pdf}','Interpreter','latex');
        
        pause(.01);
    end
end

% figure
% for i=1:FilterNum
%     hold on;
%     plot(sqrt(Logs{i}.pos_err(1,:)/SimNum), '.-');
% end
% legend('KF','EKF', 'UKF', 'PF', 'EPF', 'UPF');%, 'EPF', 'UPF')

% figure
% bars = zeros(1, FilterNum);
% c = {'KF','EKF', 'UKF', 'PF', 'EPF', 'UPF'};
% c = categorical(c, {'KF','EKF', 'UKF', 'PF', 'EPF', 'UPF'},'Ordinal',true); %, 'EPF', 'UPF'
% for i=1:FilterNum
%     bars(i) =  Logs{i}.exec_time;
% end
% bar(c, bars);
%smoothed_estimates = pf.Smooth(filtered_estimates);
% toc;
% END OF SIMULATION
% ===================>

if(Record)
    Frames = Frames(2:end);
    vidObj = VideoWriter(sprintf('em_test.avi'));
    vidObj.Quality = 100;
    vidObj.FrameRate = 100;
    open(vidObj);
    writeVideo(vidObj, Frames);
    close(vidObj);
end