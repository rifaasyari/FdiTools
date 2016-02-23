%% Discrete-time or continuous-time BJ (Box-Jenkins) modeling starting from frequency domain data. % The plant operates in open loop.%% The following BJ models are allowed:%       - continuous-time plant and noise models (both s-domain or sqrt(s)-domain): open and closed loop %       - discrete-time plant and noise models: open and closed loop%       - discrete-time plant and continuous-time noise models (hybrid BJ): open loop only %       - continuous-time plant and discrete-time noise models (hybrid BJ): open loop only %% Rik Pintelon, 21 October 2011%close allclear all%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Definition simulation parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%N = 5000;		% number of time domain samples% domain of the noise modelNoisePlane = 'z';NoisePlane = 's';% NoisePlane = 'w';% domain of the plant modelPlantPlane = 'z';PlantPlane = 's';% PlantPlane = 'w';RecipPlant = 1;                                             % reciprocal plant model% standard deviation of the unobserved driving white noise sourceswitch NoisePlane	case 'z', stde = 0.1;	% standard deviation output noise	case 's', stde = 0.1;	case 'w', stde = 0.1;endTs = 1/5.5;         % sampling periodfs = 1/Ts;          % sampling frequencyfmin = 0.1;     % begin frequency band of interestfmax = 2;       % end frequency band of interest% selection of the corresponding DFT linesSelect = [floor(fmin/(fs/N))+1:1:floor(fmax/(fs/N))+1].';	% select from fmin to fmaxF = length(Select);                                         % number of frequencies in the frequency band of interestSelectAll = [1:1:N+1].';                                    % from DC to Nyquist on 2*N points for s-domainfreq = (Select-1)*fs/N;                                     % frequencies selected DFT linesfreqAll = ((SelectAll-1)/(2*N)/Ts);                         % frequencies all DFT linesif PlantPlane == 's'    sAll_Plant = sqrt(-1)*2*pi*freqAll;end % if s-domainif NoisePlane == 's'    sAll_Noise = sqrt(-1)*2*pi*freqAll;end % if s-domainif PlantPlane == 'w'    sAll_Plant = (sqrt(-1)*2*pi*freqAll).^0.5;end % if sqrt(s)-domainif NoisePlane == 'w'    sAll_Noise = (sqrt(-1)*2*pi*freqAll).^0.5;end % if sqrt(s)-domainny = 3;         % number of outputs ny <= 3nu = 2;         % number of inputs nu <= 3%%%%%%%%%%%%%%%%%%%%%%%%%%% Definition noise model %%%%%%%%%%%%%%%%%%%%%%%%%%%switch NoisePlane    	case 'z',		c0 = zeros(3,3,3);		c0(1,1,:) = [3.5666e-01   0.9830e-01   3.3444e-01];		c0(2,2,:) = [1 -1 0.9];		c0(3,3,:) = [9.6478e-01   -5.4142e-01   9.4233e-01];        c0(1,2,:) = [0.1 -0.05 0.07];        c0(2,1,:) = c0(1,2,:);        c0(2,1,end) = c0(2,1,end)*0.4;		d0 = [1 -0.2 0.85];        	case 's',        		c0 = zeros(3,3,3);		% entry 1,1		fz = 0.6;		deltaz = 0.1;		TheZero = 2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz);		c0(1,1,:) = fliplr(real(poly([TheZero,conj(TheZero)])));		% entry 2,2		fz = 1.2;		deltaz = 0.05;		TheZero = 2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz);		c0(2,2,:) = fliplr(real(poly([TheZero,conj(TheZero)])));		% entry 3,3		fz = 0.35;		deltaz = 0.15;		TheZero = 2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz);		c0(3,3,:) = fliplr(real(poly([TheZero,conj(TheZero)])));        c0(1,2,:) = 0.1*c0(3,3,:);        c0(2,1,:) = 0.1*c0(1,1,:);				fp1 = 0.25;		deltap1 = 0.2;		ThePole1 = 2*pi*sqrt(-1)*fp1*(1 + sqrt(-1)*deltap1);		fp2 = 1;		deltap2 = 0.05;		ThePole2 = 2*pi*sqrt(-1)*fp2*(1 + sqrt(-1)*deltap2);		d0 = real(poly([ThePole1,conj(ThePole1),ThePole2,conj(ThePole2)]));		d0 = fliplr(d0);              case 'w',		c0 = zeros(3,3,3);		% entry 1,1		fz = 1.5/2;		deltaz = 0.1;		TheZero = (2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz)).^0.5;		c0(1,1,:) = fliplr(real(poly([TheZero,conj(TheZero)])));		% entry 2,2		fz = 1.2;		deltaz = 0.05;		TheZero = (2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz)).^0.5;		c0(2,2,:) = fliplr(real(poly([TheZero,conj(TheZero)])));        % c0(2,2,:) = [1 0 0];		% entry 3,3		fz = 0.35;		deltaz = 0.15;		TheZero = (2*pi*sqrt(-1)*fz*(1 + sqrt(-1)*deltaz)).^0.5;		c0(3,3,:) = fliplr(real(poly([TheZero,conj(TheZero)])));        c0 = 0.1*c0;				fp1 = 0.25;		deltap1 = 0.2;		ThePole1 = (2*pi*sqrt(-1)*fp1*(1 + sqrt(-1)*deltap1)).^0.5;		fp2 = 1;		deltap2 = 0.05;		ThePole2 = (2*pi*sqrt(-1)*fp2*(1 + sqrt(-1)*deltap2)).^0.5;		d0 = real(poly([ThePole1,conj(ThePole1),ThePole2,conj(ThePole2)]));		d0 = real(poly([ThePole2,conj(ThePole2)]));       		d0 = fliplr(d0);       end % switch% simulate a non-diagonal noise modelswitch NoisePlane        case 'z',        c0(1,2,:) = [0.1 -0.05 0.07]*2;        c0(2,1,:) = c0(1,2,:);        c0(2,1,end) = c0(2,1,end)*0.4;            case {'s','w'}        c0(1,2,:) = c0(3,3,:);        c0(2,1,:) = c0(1,1,:);        end % switch% order noise (matrix) polynomialsnc = size(c0, 3) - 1;nd = length(d0) - 1;% reduce to ny outputsc0 = c0(1:ny, 1:ny, :);%%%%%%%%%%%%%%%%%%%%%%%%%%% Definition plant model %%%%%%%%%%%%%%%%%%%%%%%%%%%nmax = 3;switch PlantPlane    	case 'z',		b0 = rand(nmax, nmax, 5);		% chebychev polynomial for noise model		[b110, a0] = cheby1(4, 3, 0.5);        	case 's',        		b0 = rand(nmax, nmax, 3);		% inverse chebychev polynomial for plant		[b110, a0] = cheby2(3, 40, 2*pi,'s');		b110 = fliplr(b110(2:end));		b110(2) = 5e-4;		a0 = fliplr(a0);		b0(1,1,:) = b110;		b0(2,2,:) = fliplr([a0(1) 2e-4 2e-3]);		b0(3,3,:) = fliplr([2e-3 a0(1) 2e-4]);		b0(3,2,:) = fliplr([5e-3 5e-4 a0(1)]);        	case 'w'        rand('state',0);		b0 = rand(nmax, nmax, 4);		% inverse chebychev polynomial for plant		[b110, a0] = cheby2(4, 40, 2*2*pi,'s');		b110 = fliplr(b110(2:end));		b110(2) = 5e-4;        ThePoles = roots(a0);        ThePoles = ThePoles.^0.5;        a0 = poly(ThePoles);		a0 = fliplr(a0);		b0(1,1,:) = 0.1*b110;        b0(1,2,:) = b0(1,1,:);        b0(1,3,:) = b0(1,2,:);        b0(2,1,:) = b0(2,1,:);		b0(2,2,:) = fliplr([a0(1) 0 2e-3 1])/100;		b0(3,3,:) = fliplr([2e-3 a0(1) 0 1]);		b0(3,2,:) = fliplr([0 5e-4 a0(1) 1]);        end % switch% order plant (matrix) polynomialsna = length(a0) - 1;nb = size(b0,3) - 1;% if needed impose the reciprocity of the plant modelif RecipPlant	for ll = 1:nb+1		b0(:,:,ll) = (b0(:,:,ll) + b0(:,:,ll).')/2;	endend% reduce to ny outputs and nu inputsb0 = b0(1:ny, 1:nu, :);%%%%%%%%%%%%%%%%%%%%%%%%%%% Set the default values %%%%%%%%%%%%%%%%%%%%%%%%%%%[Sel, Theta0, ModelVar, IterVar] = DefaultValues(na, nb, nc, nd, nu, ny, PlantPlane, NoisePlane, 'BJ', RecipPlant);if (PlantPlane == 's') || (PlantPlane == 'w')    nig = 5;    ModelVar.nig = nig;    Sel.Ig = ones(ny, nig+1);end % if s-domain plant modelif (NoisePlane == 's') || (NoisePlane == 'w')    nih = 3;    if ((PlantPlane == 's') || (PlantPlane == 'w')) && NoisePlane == 'w'        nih = 1;    end % if    ModelVar.nih = nih;    Sel.Ih = ones(ny, nih+1);end % if s-domain noise model% true parameter valuesTheta0.A = a0;for ii = 1:ny	for jj = 1:nu		Theta0.B(ii,jj,:) = b0(ii,jj,:);	end % jjend % iiTheta0.B = Theta0.B(1:ny,1:nu,:);nig = ModelVar.nig;Theta0.Ig = zeros(ny, nig+1);Theta0.D = d0;for ii = 1:ny	for jj = 1:ny		Theta0.C(jj,ii,:) = c0(jj,ii,:);	endendTheta0.C = Theta0.C(1:ny,1:ny,:);nih = ModelVar.nih;Theta0.Ih = zeros(ny, nih+1);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Contribution known excitation to output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%switch ModelVar.PlantPlane    	case 'z',                       % calculation N samples time domain response		u = randn(nu, N);		y0 = zeros(ny, N);		for jj=1:ny			for ii=1:nu				y0(jj,:) = y0(jj,:) + filter(squeeze(b0(jj,ii,:)),a0,u(ii,:));			end % ii		end % jj        	case {'s','w'}		u = randn(nu, 2*N);         % calculation 2N samples time domain response via frequency domain		U = fft(u,[],2);		Y0 = zeros(ny, length(SelectAll));		for jj=1:ny			for ii=1:nu				Y0(jj,:) = Y0(jj,:) + ...                          ((polyval(fliplr(squeeze(b0(jj,ii,:)).'),sAll_Plant)./polyval(fliplr(a0),sAll_Plant)).').*U(ii,SelectAll);			end % ii		end % jj		y0 = 2*real(ifft([zeros(ny,1),Y0(:,2:end-1),zeros(ny,N)],[],2));		u = u(:,1:N);		y0 = y0(:,1:N);        end % switch%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Contribution noise to output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Te = fliplr(hankel(ones(ny,1)));switch ModelVar.NoisePlane    	case 'z',                           % calculation N samples time domain response		e = stde*randn(ny, N);		v = zeros(ny, N);		e = Te*e;		for jj=1:ny			for ii=1:ny				v(jj,:) = v(jj,:) + filter(squeeze(c0(jj,ii,:)),d0,e(ii,:));			end % ii		end % jj        	case {'s','w'}                      % calculation 2N samples time domain response via frequency domain		e = stde*randn(ny, 2*N);           		e = Te*e;		E = fft(e,[],2);		V = zeros(ny, length(SelectAll));		for jj=1:ny			for ii=1:ny				V(jj,:) = V(jj,:) + ...                         ((polyval(fliplr(squeeze(c0(jj,ii,:)).'),sAll_Noise)./polyval(fliplr(d0),sAll_Noise)).').*E(ii,SelectAll);			end % ii		end % jj		v = 2*real(ifft([zeros(ny,1),V(:,2:end-1),zeros(ny,N)],[],2));		v = v(:,1:N);        end % switch% add noise to the outputy = y0 + v;%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data for identification %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Selection of the frequency band of interestU = fft(u,[],2)/sqrt(N);Y = fft(y,[],2)/sqrt(N);U = U(:, Select);Y = Y(:, Select);data.Y = Y;data.U = U;data.Ts = Ts;data.freq = freq;%%%%%%%%%%%%%%%%%%%% Starting values %%%%%%%%%%%%%%%%%%%%% starting value plant model via GTLS and BTLS estimateFigNum = 1;ThetaStart = StartPlantModel(data, Sel, ModelVar, IterVar, FigNum);% starting values noise modelFigNum = 2;ThetaStart = StartNoiseModel(data, ThetaStart, Sel, ModelVar, IterVar, FigNum);%%%%%%%%%%%%%%%%%%%%%%%% Estimation BJ-model %%%%%%%%%%%%%%%%%%%%%%%%[Theta, Sel, Cost, smax, smin, wscale] = MIMO_BoxJenkins(data, Sel, ThetaStart, ModelVar, IterVar);%%%%%%%%%%%%%%%%%%%%%%%%%%% Cram�r-Rao lower bound %%%%%%%%%%%%%%%%%%%%%%%%%%%[CRbound, Theta, CovThetan, Thetan, Seln, wscale, TheCond] = MIMO_CR_bound(data, Sel, Theta, ModelVar);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Calculation true, estimated and measured noise power spectra %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%switch ModelVar.PlantPlane	case 'z', x.Plant = exp(-sqrt(-1)*2*pi*freq*Ts);	case 's', x.Plant = sqrt(-1)*2*pi*freq;	case 'w', x.Plant = (sqrt(-1)*2*pi*freq).^0.5;endswitch ModelVar.NoisePlane	case 'z', x.Noise = exp(-sqrt(-1)*2*pi*freq*Ts);	case 's', x.Noise = sqrt(-1)*2*pi*freq;	case 'w', x.Noise = (sqrt(-1)*2*pi*freq).^0.5;endPolyTrans0 = CalcPolyTrans(Theta0, x);PolyTrans = CalcPolyTrans(Theta, x);S0 = CalcPowerSpectrum(PolyTrans0, stde^2*Te*Te.');S = CalcPowerSpectrum(PolyTrans, Theta.CovE);% calculate observed noise power spectrumF = length(freq);data.Gc = zeros(ModelVar.nu, ModelVar.ny, F);data.DC = 0;data.Nyquist = 0;[TheError, CovE, gF, Err] = PredError(data, PolyTrans);Sy = zeros(ny,ny,F);for kk = 1:F	Sy(:,:,kk) = Err(:,kk)*Err(:,kk)';end % kk%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Calculation true poles, resonance frequencies, %% damping ratios, time constants                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Poles0 = struct('noise', [], 'plant', []);% the covariance has no meaning here% True plant poles[CovPoles0, dummy] = CovRoots(Theta0.A, eye(na+1), Sel.A, PlantPlane, Ts);Poles0.plant = dummy;% True noise poles[CovPoles0, dummy] = CovRoots(Theta0.D, eye(nd+1), Sel.D, NoisePlane, Ts);Poles0.noise = dummy;%%%%%%%%%%%%%%%%%%%%% Plot the results %%%%%%%%%%%%%%%%%%%%%% comparison true and estimated plant modelsfigure(FigNum+1)mm = 0;for jj = 1:ny	for ii = 1:nu		mm = mm+1;		subplot(ny, nu, mm)		plot(freq, db(squeeze(PolyTrans0.G(jj,ii,:))), 'k', freq, db(squeeze(PolyTrans.G(jj,ii,:))), 'r', ...             freq, db(squeeze(PolyTrans0.G(jj,ii,:)-PolyTrans.G(jj,ii,:))), 'k--', ...             freq, db(squeeze(CRbound.G(jj,ii,:)))/2, 'r--');        xlabel('Frequency (Hz)')        ylabel('G (dB)')	end % iiend % jjsubplot(ny, nu, ceil(nu/2));title('true value: black; estim.: red; diff.: black --; CR: red --');zoom on; shgfigure(FigNum+2)mm = 0;for jj = 1:ny	for ii = 1:nu		mm = mm+1;		subplot(ny, nu, mm)		plot(freq,angle(squeeze(PolyTrans0.G(jj,ii,:)))*180/pi, 'k', ...             freq, angle(squeeze(PolyTrans.G(jj,ii,:)))*180/pi, 'r');        xlabel('Frequency (Hz)')        ylabel('angle(G) (�)')	end % iiend % jjsubplot(ny, nu, ceil(nu/2));title('true value: black; estim.: red');zoom on; shg% comparison measured and estimated noise modelfigure(FigNum+3)clfmm = 0;for jj = 1:ny	for ii = 1:ny		mm = mm+1;        subplot(ny, ny, mm)        plot(freq, db(squeeze(Sy(jj,ii,:)))/2, 'k+', freq ,db(squeeze(S(jj,ii,:)))/2, 'r');        xlabel('Frequency (Hz)')        ylabel('Noise power (dB)')	end % iiend % jjsubplot(ny, ny, ceil(ny/2));title('data ''+''; estimate: red');zoom on; shg% comparison true and estimated power spectrafigure(FigNum+4)clfmm = 0;for jj = 1:ny	for ii = 1:ny		mm = mm+1;        subplot(ny, ny, mm)        plot(freq, db(squeeze(S0(jj,ii,:)))/2, 'k', freq, db(squeeze(S(jj,ii,:)))/2, 'r', ...             freq, db(squeeze(S0(jj,ii,:)-S(jj,ii,:)))/2, 'k--', freq, db(squeeze(CRbound.NoisePower(jj,ii,:)))/4, 'r--');        xlabel('Frequency (Hz)')        ylabel('Noise power (dB)')	end % iiend % jjsubplot(ny, ny, ceil(ny/2));title('true Power: black; estim.: red; diff.: black --; CR: red --');zoom on; shg% comparison true and estimated phase power spectrumfigure(FigNum+5)clfmm = 0;for jj = 1:ny	for ii = 1:ny		mm = mm+1;        subplot(ny, ny, mm)        plot(freq, angle(squeeze(S0(jj,ii,:)))*180/pi, 'k', freq, angle(squeeze(S(jj,ii,:)))*180/pi, 'r');        xlabel('Frequency (Hz)')        ylabel('Phase (�)')	end % iiend % jjsubplot(ny, ny, ceil(ny/2));title('true value: black; estim.: red');zoom on;shg% comparison true and estimated resonance frequencies plant: case 1, known reference signal disp('Estimates plant model')disp('Estim. f0 [Hz], std(f0) [Hz], estim. - true [Hz]')[Theta.plant.poles.freq, CRbound.plant.poles.freq.^0.5, Theta.plant.poles.freq-Poles0.plant.freq]% comparison true and estimated damping ratios plant: case 1, known reference signal disp('Estim. damping, std(damping), estim. - true')[Theta.plant.poles.damp, CRbound.plant.poles.damp.^0.5, Theta.plant.poles.damp-Poles0.plant.damp]if ModelVar.PlantPlane == 's'    disp('Estim. tau [s], std(tau) [s], estim. - true [s]')    [Theta.plant.poles.time, CRbound.plant.poles.time.^0.5, Theta.plant.poles.time-Poles0.plant.time] end % if s-domain plant model% comparison true and estimated resonance frequencies noise: case 1, known reference signal disp('Estimates noise model')disp('Estim. f0 [Hz], std(f0) [Hz], estim. - true [Hz]')[Theta.noise.poles.freq, CRbound.noise.poles.freq.^0.5, Theta.noise.poles.freq-Poles0.noise.freq]% comparison true and estimated damping ratios noise: case 1, known reference signal disp('Estim. damping, std(damping), estim. - true')[Theta.noise.poles.damp, CRbound.noise.poles.damp.^0.5, Theta.noise.poles.damp-Poles0.noise.damp]