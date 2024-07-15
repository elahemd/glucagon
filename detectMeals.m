function subjData = detectMeals(subjData,flagPlot)

    dt = 5;
    cgmt = (subjData.cgm.time(1):dt/60/24:subjData.cgm.time(end))';
    cgmv = interp1(subjData.cgm.time,subjData.cgm.value,cgmt);
    
    dCgmv = computeDerivative(cgmv,dt); % 1st derivative
    ddCgmv = computeDerivative(dCgmv,dt); % 2nd derivative
    
    det = zeros(size(cgmv)); 
    det(dCgmv>0 & ddCgmv>0) = dCgmv(dCgmv>0 & ddCgmv>0); % detect increasing cgm and change of concavity
    thres = 0.65;
    mutePrev = 12*2;
    muteNext = 12;
    shift = 3;
    mealDet = zeros(size(det));
    for i = 1:length(det)
        startOfDay = dateshift(cgmt(i), 'start', 'day'); % elahe
        % if length(subjData.cgm.time(subjData.cgm.time>=cgmt(i) & subjData.cgm.time<cgmt(i)+1/24))>=0.75*12 && ... % enough data
        %         (cgmt(i)<floor(cgmt(i))+1/24 || cgmt(i)>=floor(cgmt(i))+6/24) && ... % mute overnight
        %         isempty(subjData.meal.time(subjData.meal.time>cgmt(i)-mutePrev*subjData.ts/60/24 & subjData.meal.time<cgmt(i)+muteNext*subjData.ts/60/24)) && ... % mute around recorded meals
        %         det(i)>thres && max(mealDet(max(1,i-mutePrev+1):i))==0 % above threshold and with no recent detections
        %     mealDet(max(1,i-shift)) = 1;
        % end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %(cgmt(i)<floor(cgmt(i))+1/24 || cgmt(i)>=floor(cgmt(i))+6/24) && ... % mute overnight % maria
        if length(subjData.cgm.time(subjData.cgm.time>=cgmt(i) & subjData.cgm.time<cgmt(i)+1/24))>=0.75*12 && ... % enough data
                (cgmt(i)< startOfDay +1/24 || cgmt(i)>= startOfDay +6/24) && ... % mute overnight % elahe
                det(i)>thres && max(mealDet(max(1,i-mutePrev+1):i))==0 % above threshold and with no recent detections
            mealDet(max(1,i-shift)) = 1;
        end
    end
    subjData.mealDet.time = cgmt(mealDet==1);
    subjData.mealDet.value = 50*mealDet(mealDet==1); %mean(subjData.meal.value)*mealDet(mealDet==1);
    
    if flagPlot
        % nDays = floor(cgmt(end))-floor(cgmt(1))+1;
        % for i = 1:nDays
            % idx = find(cgmt>=floor(cgmt(1))+i-1 & cgmt<floor(cgmt(1))+i);
            % idx2 = find(subjData.cgm.time>=floor(cgmt(1))+i-1 & subjData.cgm.time<floor(cgmt(1))+i);
            idx = 1:length(cgmv);
            TimeVec = datetime(datevec(cgmt(idx)));
            % idx3 = find(subjData.meal.time>=floor(cgmt(1))+i-1 & subjData.meal.time<floor(cgmt(1))+i);
            figure
            subplot(211)
            plot(TimeVec,cgmv(idx),'-b','linewidth',1.5)
            hold on
            % plot(subjData.cgm.time(idx2),subjData.cgm.value(idx2),'or','linewidth',1.5)
            % plot(subjData.meal.time(idx3),subjData.meal.value(idx3)*5,'*m','linewidth',5)
            plot(TimeVec,mealDet(idx).*cgmv(idx),'*g','linewidth',5)
            hold off
            datetick('x')
            ylim([40 300])
            ylabel('CGM')

            subplot(212)
            plot(TimeVec,dCgmv(idx),'-b','linewidth',1.5)
            hold on
            plot(TimeVec,10*ddCgmv(idx),'-k','linewidth',1.5)
            plot(TimeVec,det(idx),'-r','linewidth',2.5)
            plot([TimeVec(idx(1)) TimeVec(idx(end))],[thres thres],'--g','linewidth',2.5)
            hold off
            datetick('x')
            ylabel('Detector')
        % end
        % close all
    end

end

function dS = computeDerivative(s,dt)
    s = smooth(smooth(s));
    dS = zeros(size(s));
    for i  = 1:length(s)-1
        dS(i) = (s(i+1)-s(i))/dt;
    end
    dS(end) = dS(end-1);
    dS = smooth(smooth(dS));
end
