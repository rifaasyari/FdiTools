function TheJacob = MIMOJacob(data, xMat, Error, PolyTrans, ModelVar);%%      TheJacob = MIMOJacob(data, xMat, Error, PolyTrans, ModelVar)%%   Calculates the jacobian matrix w.r.t. ALL the plant and transient model parameters.%	The selection of the free model parameters, and the imposition of the model constraints%	(ARMAX, reciprocity) is done in the routine Add_SelectColumns%% Output parameters%% 	TheJacob 		=	jacobian matrix, size: ny x ntheta x number of freq.%% Input parameters%%		data		=	structure containing the non-patameteric data%							data.Y			=	DFT spectrum ny x 1 output signal, dimensions ny x number of frequencies%							data.U			=	DFT spectrum nu x 1 input signal, dimensions: nu x number of frequencies%							data.freq		=	vector of frequency values (Hz), dimension: number of frequencies x 1%							data.Ts			=	sampling time (s)%							data.Gc			=	controller transfer function, zero or empty if unknown or not present,%												dimension nu x ny x number of frequencies%							data.DC			=	1 if DC present otherwise 0%							data.Nyquist	=	1 if Nyquist frequency present otherwise 0%%		xMat		=	structure with tables of powers of (jwk)^r or (zk^-r)%							xMat.Plant		=	plant model, dimension: number of frequencies x max order%							xMat.Noise		=	noise model, dimension: number of frequencies x max order%%		TheError	=	prediction error model equations, dimension ny x number of freq.%%		PolyTrans	=	structure containing the polynomials and transfer functions evaluated in x%							PolyTrans.A		=	denominator polynomial plant transfer function evaluated in x.Plant, dimensions 1 x number of freq.%							PolyTrans.D		=	D polynomial evaluated in x.Noise, dimensions 1 x number of freq.%							PolyTrans.G		=	plant transfer matrix evaluated in x.Plant, dimensions ny x nu x number of freq.%							PolyTrans.Hinv	=	inverse of the noise transfer matrix evaluated in x.Noise, dimensions ny x ny x number of freq.%							PolyTrans.Tg	=	plant transient term evaluated in x.Plant, dimension ny x number of freq.%							PolyTrans.Th	=	noise transient term evaluated in x.Noise, dimension ny x number of freq.%%		ModelVar	=	contains the information about the model to be identified%						structure with fields 'Transient', 'ThePlane', 'TheModel', 'Reciprocal', ...%							ModelVar.Transient		=	1 then the initial conditions of the plant and/or noise are estimated%							ModelVar.PlantPlane		=	plane of the plant model%															's':	continuous-time;%															'w':	sqrt(s)-domain%															'z':	discrete-time;%															'':		plane not defined%							ModelVar.NoisePlane		=	plane of the plant model%															's':	continuous-time;%															'w':	sqrt(s)-domain%															'z':	discrete-time;%															'':		plane not defined%							ModelVar.Struct			=	model structure%															'BJ':		Box-Jenkins%															'OE':		output error (plant model only)%															'ARMA':		autoregressive moving average (noise model only)%															'ARMAX':	autoregressive moving average with exogenous input%							ModelVar.DiagNoiseModel	=	1 if C is a diagonal matrix%							ModelVar.RecipPlant		=	1 if plant model is reciprocal: G(i,j) = G(j,i)%							ModelVar.RecipNoise		=	1 if noise model is reciprocal: H(i,j) = H(j,i)%							ModelVar.nu				=	number of inputs%							ModelVar.ny				= 	number of outputs%							ModelVar.na				=	order polynomial A%							ModelVar.nb				= 	order matrix polynomial B%							ModelVar.nig			=	order vector polynomial Ig%							ModelVar.nc				=	order matrix polynomial C%							ModelVar.nd				=	order polynomial D%							ModelVar.nih			=	order vector polynomial Ih%%% Copyright (c) Rik Pintelon, Vrije Universiteit Brussel - dept. ELEC, 2004 % All rights reserved.% Software can be used freely for non-commercial applications only.% Version April 2008%% note that DC and Nyquist have a contribution 1/2 to the cost function% therefore the appropriate variables must be scaled by 1/sqrt(2) at DC% and Nyquist; this is alreday done for the variable Error%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% calculate the derivative of the transfer functions w.r.t. the model parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Deriv = CalcDeriv(xMat, PolyTrans, ModelVar);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% caculate alfa = Gc*(Iny + G*Gc)^-1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%alfa = CalcAlfa(data.Gc, PolyTrans.G);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% derivative prediction error w.r.t. ALL model parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% number of frequenciesF = size(xMat.Plant,1);% order polynomialsna = ModelVar.na;nb = ModelVar.nb;nig = ModelVar.nig;nc = ModelVar.nc;nd = ModelVar.nd;nih = ModelVar.nih;% number of outputs and inputsny = ModelVar.ny;nu = ModelVar.nu;% total number of model parametersntheta = (na+1) + (nb+1)*nu*ny + (nig+1)*ny + (nc+1)*ny^2 + (nd+1) + (nih+1)*ny;TheJacob = zeros(ny, ntheta, F);% frequency independent terms in the derivativesalfaT = permute(alfa, [2,1,3]);				% transpose rows and columns of alfaHinvT = permute(PolyTrans.Hinv, [2,1,3]);	% transpose rows and columns of Hinv% DC and Nyquist count for 1/sqrt(2)% This is already done in Error => scaling with 1/sqrt(2) should not be done in the terms containing Error% in gF the scaling occurs in the exponent with factor 1/2 + number of effective frequencies F1 should% be adapted accordinglyHinv = PolyTrans.Hinv;F1 = F;if data.DC == 1	Hinv(:,:,1) = Hinv(:,:,1)/sqrt(2);	alfaT(:,:,1) = alfaT(:,:,1)/2;	HinvT(:,:,1) = HinvT(:,:,1)/2;	F1 = F1-1/2;endif data.Nyquist == 1	Hinv(:,:,end) = Hinv(:,:,end)/sqrt(2);	alfaT(:,:,end) = alfaT(:,:,end)/2;	HinvT(:,:,end) = HinvT(:,:,end)/2;	F1 = F1-1/2;end% Note: reshape(permute(Deriv.vecGa, [1,3,2]), F*ny*nu, na+1) puts all the%       frequency contributions on top of each otheralfaDerivGa = alfaT(:).' * reshape(permute(Deriv.vecGa, [1,3,2]), F*ny*nu, na+1);alfaDerivGb = alfaT(:).' * reshape(permute(Deriv.vecGb, [1,3,2]), F*ny*nu, (nb+1)*ny*nu);HinvDerivHc = HinvT(:).' * reshape(permute(Deriv.vecHc, [1,3,2]), F*ny^2, (nc+1)*ny^2);HinvDerivHd = HinvT(:).' * reshape(permute(Deriv.vecHd, [1,3,2]), F*ny^2, nd+1);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. a. The lines below are equivalent with              % % for kk = 1:F                                                                                  % %	Low = 1;                                                                                    % %	Upp = (na+1);                                                                               % %	Mat = kron(data.U(:,kk).', Hinv(:,:,kk));                                                   % %	TheJacob(:,Low:Upp,kk) = - Mat * Deriv.vecGa(:,:,kk) - Hinv(:,:,kk) * Deriv.Tga(:,:,kk) ... % %                            - (Error(:,kk)/(ny*F1)) * alfaDerivGa;                             % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% calculation of the matrix Mat for all frequenciesUii = zeros(1,1,F);Mat = zeros(ny, nu*ny, F);for ii = 1:nu    Uii(1,1,:) = data.U(ii,:);    columns = [(ii-1)*ny+1:ii*ny];    Mat(:, columns, :) = Hinv .* repmat(Uii, [ny, ny, 1]);end % ii% derivative w.r.t. aLow = 1;Upp = (na+1);for ii = 1:ny        Matii = squeeze(Mat(ii,:,:));    if ny*nu == 1        Matii = Matii.';                                        % squeeze on 1 x 1 x F gives F x 1 !!!      end % if    Hinvii = squeeze(Hinv(ii,:,:));    if ny == 1        Hinvii = Hinvii.';                                      % squeeze on 1 x 1 x F gives F x 1 !!!    end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivvecGajj = squeeze(Deriv.vecGa(:,jk,:));        if nu*ny == 1            DerivvecGajj = DerivvecGajj.';                      % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        DerivTgajj = squeeze(Deriv.Tga(:,jk,:));        if ny == 1            DerivTgajj = DerivTgajj.';                          % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Matii.*DerivvecGajj, 1) - sum(Hinvii.*DerivTgajj, 1) ...                            - (Error(ii,:)/(ny*F1)) * alfaDerivGa(jk);            end %jj    end % ii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. b. The lines below are equivalent with              % % for kk = 1:F                                                                                  % %	Low = Upp + 1;                                                                              % %	Upp = Upp = Low + (nb+1)*ny*nu - 1;                                                         % %	TheJacob(:,Low:Upp,kk) = - Mat * Deriv.vecGb(:,:,kk) - (Error(:,kk)/(ny*F1)) * alfaDerivGb  % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% derivative w.r.t. bLow = Upp + 1;Upp = Low + (nb+1)*ny*nu - 1;for ii = 1:ny        Matii = squeeze(Mat(ii,:,:));    if ny*nu == 1        Matii = Matii.';                                        % squeeze on 1 x 1 x F gives F x 1 !!!      end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivvecGbjj = squeeze(Deriv.vecGb(:,jk,:));        if nu*ny == 1            DerivvecGbjj = DerivvecGbjj.';                      % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Matii.*DerivvecGbjj, 1) - (Error(ii,:)/(ny*F1)) * alfaDerivGb(jk);            end %jj    end % ii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. ig. The lines below are equivalent with             % % for kk = 1:F                                                                                  % %	Low = Upp+1;                                                                                % %	Upp = Low + (nig+1)*ny - 1;                                                                 % %	TheJacob(:,Low:Upp,kk) = - Hinv(:,:,kk) * Deriv.Tgig(:,:,kk)                                % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% derivative w.r.t. igLow = Upp+1;Upp = Low + (nig+1)*ny - 1;for ii = 1:ny        Hinvii = squeeze(Hinv(ii,:,:));    if ny == 1        Hinvii = Hinvii.';                                      % squeeze on 1 x 1 x F gives F x 1 !!!    end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivTgigjj = squeeze(Deriv.Tgig(:,jk,:));        if ny == 1            DerivTgigjj = DerivTgigjj.';                        % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Hinvii.*DerivTgigjj, 1);            end %jj    end % ii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. c. The lines below are equivalent with              % % for kk = 1:F                                                                                  % %	Low = Upp+1;                                                                                % %	Upp = Low + (nc+1)*ny^2 - 1;                                                                % %	Mat = kron(Error(:,kk).', PolyTrans.Hinv(:,:,kk));                                          % %	TheJacob(:,Low:Upp,kk) = - Mat * Deriv.vecHc(:,:,kk) + (Error(:,kk)/(ny*F1)) * HinvDerivHc; % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% calculation of the matrix Mat for all frequenciesErrorii = zeros(1,1,F);Mat = zeros(ny, ny^2, F);for ii = 1:ny    Errorii(1,1,:) = Error(ii,:);    columns = [(ii-1)*ny+1:ii*ny];    Mat(:, columns, :) = Hinv .* repmat(Errorii, [ny, ny, 1]);end % ii% derivative w.r.t. cLow = Upp+1;Upp = Low + (nc+1)*ny^2 - 1;for ii = 1:ny        Matii = squeeze(Mat(ii,:,:));    if ny == 1        Matii = Matii.';                                        % squeeze on 1 x 1 x F gives F x 1 !!!      end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivvecHcjj = squeeze(Deriv.vecHc(:,jk,:));        if ny == 1            DerivvecHcjj = DerivvecHcjj.';                      % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Matii.*DerivvecHcjj, 1) + (Error(ii,:)/(ny*F1)) * HinvDerivHc(jk);            end %jj    end % ii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. d. The lines below are equivalent with              % % for kk = 1:F                                                                                  % %	Low = Upp+1;                                                                                % %	Upp = Low + (nd+1) - 1;                                                                     % %	TheJacob(:,Low:Upp,kk) = - Mat * Deriv.vecHd(:,:,kk) - Hinv(:,:,kk) * Deriv.Thd(:,:,kk) ... %%                            + (Error(:,kk)/(ny*F1)) * HinvDerivHd;                             % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% derivative w.r.t. dLow = Upp+1;Upp = Low + (nd+1) - 1;for ii = 1:ny        Matii = squeeze(Mat(ii,:,:));    if ny == 1        Matii = Matii.';                                        % squeeze on 1 x 1 x F gives F x 1 !!!      end % if    Hinvii = squeeze(Hinv(ii,:,:));    if ny == 1        Hinvii = Hinvii.';                                      % squeeze on 1 x 1 x F gives F x 1 !!!    end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivvecHdjj = squeeze(Deriv.vecHd(:,jk,:));        if ny == 1            DerivvecHdjj = DerivvecHdjj.';                      % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        DerivThdjj = squeeze(Deriv.Thd(:,jk,:));        if ny == 1            DerivThdjj = DerivThdjj.';                          % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Matii.*DerivvecHdjj, 1) - sum(Hinvii.*DerivThdjj, 1) ...                            + (Error(ii,:)/(ny*F1)) * HinvDerivHd(jk);            end %jj    end % ii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fast calculation of the derivative w.r.t. ih. The lines below are equivalent with             % % for kk = 1:F                                                                                  % %	Low = Upp+1;                                                                                % %	Upp = Low + (nih+1)*ny - 1;                                                                 % %	TheJacob(:,Low:Upp,kk) = - Hinv(:,:,kk) * Deriv.Thih(:,:,kk)                                % % end                                                                                           % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% derivative w.r.t. ihLow = Upp+1;Upp = Low + (nih+1)*ny - 1;for ii = 1:ny        Hinvii = squeeze(Hinv(ii,:,:));    if ny == 1        Hinvii = Hinvii.';                                      % squeeze on 1 x 1 x F gives F x 1 !!!    end % if        for jj = Low:Upp                jk = jj-Low+1;        DerivThihjj = squeeze(Deriv.Thih(:,jk,:));        if ny == 1            DerivThihjj = DerivThihjj.';                        % squeeze on 1 x 1 x F gives F x 1 !!!        end % if        TheJacob(ii,jj,:) = - sum(Hinvii.*DerivThihjj, 1);            end %jj    end % ii