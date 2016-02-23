function s2 = varestJoJo(Fdat,B,A,T,feedback)%% estimation of the noise variance% Robust method%   1st differentiation of the output residuals reduces model errors on the transient%   2nd differentiation (after devision by differentiated input) reduces transfer function errors% Fdat = [F U Y]: Fourier data%	q	=	z^-1, s, or sqrt(s)% B,A: (optional): the modelled transfer function G=B/A% T:   (optional): models the transient in the output  T/A% feedback=='on': the data should be processed as being collected in feedback%      this option can only be used if a good estimate of B,A and T is available% n: width of the window 2*n+1 to average the final variance estimates% s2: estimated variance as a function of frequency Fn=max(ceil(length(Fdat)/500),5);  % width of the window 2*n+1 to average the final variance estimates% select the proper algorithmif nargin<5      select =1;  % use the robust method  elseif feedback=='on'      select=2;   % identify under feedback conditions    else      select=1;   % use the robust methodend    if nargin<4        T=0;     % no transient parameters availableendif nargin <3    B=0;A=1; % no transfer function parameters availableendN=length(Fdat);      % number of data pointsG=freqz(B,A,Fdat(:,1)*2*pi); % estimated transfer functionTrans=freqz(T,A,Fdat(:,1)*2*pi); % estimated transientY=Fdat(:,3)-Trans-G.*Fdat(:,2);  % eliminate the model contributions to the outputswitch select    % select==1  robust method                      %       ==2  feedback identification            case 1                 	U=Fdat(:,2);		UU=[U(2:end)' 0]';UU=abs(UU).^2;		Y=diff([Y' 0]');     % reduce impact of model errors on the transient	U=diff([U' 0]');	E=diff([(Y./U)' 0]'); % reduce impact of model errors on the transfer function		E=abs(E).^2;		U2=abs(U).^2;		linesA=[0:2*n];lines=[0:2*n-1]; 	for k=1:2*n+1:N-2*n		i=k+lines;		%s=sum(E(i).*U2(i).*U2(i+1))/sum(U2(i)+U2(i+1)-UU(i));  %old		%formula only valid for independent in Four. coeff        s=sum(E(i).*U2(i).*U2(i+1))/sum(U2(i)+U2(i+1)+(abs(U(i+1)+U(i))).^2);   % improved formula 		i=k+linesA;		s2(i,1)=s;	end	s2(k+2*n+1:N)=s;    % border effects --> can be improved		s2(s2<0)=eps*ones(size(s2(s2<0)));   % put negative values equal to zero	s2=s2;    case 2    	E=Fdat(:,3)-Trans-G.*Fdat(:,2);  % wegnemen van modelbijdrage --> residu's	E=abs(E).^2;		linesA=[0:2*n];lines=[0:2*n-1]; 	for k=1:2*n+1:N-2*n		i=k+lines;		s=sum(E(i));		i=k+linesA;		s2(i,1)=s;	end	s2(k+2*n+1:N)=s;    % border effects --> can be improved	s2=s2/(2*n);end