function TheTheta = MIMO_ML_DeNormalise(TheTheta, Thewscale, TheModelVar);%%	TheTheta = MIMO_ML_DeNormalise(TheTheta, Thewscale, TheModelVar);%%	Output parameters%		TheTheta			=	see input parameters%%	Input parameters%		TheTheta			=	plant, noise, and initial conditions parameters%								structure with fields 'A', 'B', 'Ig'%									TheTheta = struct('A',[],'B',[], 'Ig', [])%									TheTheta.A = 1 x (OrderA+1)%										TheTheta.A(r) = coefficient a(r-1) of Omega^(r-1) %									TheTheta.B = ny x nu x (OrderB+1)%										TheTheta.B(i,j,r) = coefficient b(i,j,r-1) of Omega^(r-1)%									TheTheta.Ig = ny x (OrderIg+1)%										TheTheta.Ig(i,r) = coefficient ig(i,r-1) of Omega^(r-1) %								Note:	all coefficients (except those for which Sel = 0) are free%										during the minimization + in each iteration step the following%										constraints are imposed:%											norm([a, vec(b), vec(ig)] = 1 %%		Thewscale			=	angular frequency scaling%%		TheModelVar			=	contains the information about the model to be identified%								structure with fields 'Transient', 'ThePlane', 'Reciprocal'%									TheModelVar = struct('Transient', [], 'PlantPlane', [], 'Struct', [], 'Reciprocal',[])%									TheModelVar.Transient		=	1 then the initial conditions of the plant and/or noise are estimated%									TheModelVar.PlantPlane		=	plane of the plant model%																	's':	continuous-time;%																	'w':	sqrt(s)-domain%																	'z':	discrete-time;%																	'':		plane not defined%									TheModelVar.Struct			=	model structure%																	'EIV':  errors-in-variables (noisy input-output data)%																	'OE':	generalised output error (known input, noisy output)%									TheModelVar.Reciprocal		=	1 if plant and noise models are reciprocal: G(i,j) = G(j,i) %									TheModelVar.nu				=	number of inputs%									TheModelVar.ny				= 	number of outputs%									TheModelVar.na				=	order polynomial A%									TheModelVar.nb				=	order ny x nu matrix polynomial B%									TheModelVar.nig             =	order ny x 1 vector polynomial Ig%%% Copyright (c) Rik Pintelon, Vrije Universiteit Brussel - dept. ELEC, November 2009% All rights reserved.% Software can be used freely for non-commercial applications only.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% denormalisation plant model parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%if ~strcmp(TheModelVar.PlantPlane,'z')		na = TheModelVar.na;	nb = TheModelVar.nb;	nig = TheModelVar.nig;	nmax = max([na, nb, nig]);	TheScale = zeros(1,1,nmax+1);	for ii = 0:nmax		TheScale(1,1,ii+1) = Thewscale^ii;	end	% polynomial A	TheTheta.A = TheTheta.A./(squeeze(TheScale(1,1,1:na+1)).');	% ny x nu matrix polynomial B	nu = TheModelVar.nu;	ny = TheModelVar.ny;	TheTheta.B = TheTheta.B./repmat(TheScale(1,1,1:nb+1),[ny, nu, 1]);		% ny x 1 vector polynomial Ig	if TheModelVar.Transient			TheTheta.Ig = TheTheta.Ig./repmat(squeeze(TheScale(1,1,1:nig+1)).',[ny, 1]);	end % if transient	end % if not z-domain