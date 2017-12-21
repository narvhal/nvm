%ex: [z,b,norm_erosion_rate] = hillslope_profile3_lab_wr('L',10,'E',0.0003)%%function [z,b,norm_erosion_rate, z_ss] =hillslope_profile3_lab_nm(varargin)%% hillslope_profile is a generic 2-D hillslope profile evolution solver% hillslope_profile solves the eqns: qs = kx^ms^n ; dz/dt = -1/(1-porosity)*(dqs/dx)% soil production as well as transport may be modeled%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~% note  that s = -dz/dx (flow from left to right).% no flow and no sediment flux is assumed at the left boundary, i=1% %%PARAMETERS% 'plt'[true] can be set to turn plotting on and off.% 'debug'[true] can be set to suppress display for certain outputs.% need to add%% %BOUNDARY CONDITIONS% bcflag specifies variable boundary conditions at the right margin (toe of hill, i=Maxi)% bcflag 1: z(Maxi) = constant (all sediment carried away)% bcflag 2: z(Maxi) lowered at a constant rate (stream incision)% bcflag 3: zero slope at i=Maxi; zero flux (all sediment accumulates)%% %INITIAL CONDITIONS% icflag specifies initial conditions% icflag 1: option intial slope, w/o flats: a triangular ridge% icflag 2: option initial scarp in the midst of long flats above and below% icflag 3: option intial slope, w flats: a triangular ridge in the midst of a plain.% icflag 4: use input vectors z, b for initial elevation and soil-rock interface% wflag 1: do not compute weathering (transport limited)% wflag 2: compute weathering% rflag = 2 is roering non-linear diffusion model(only for wflag=1 case for now)% % %WARNING:% time step dt is determined from std advection-diffusion eqn stability (FTCS explicit)% possible stability problems when n > 1,% use stabil < 1 if problems arise.  stabil = 2.25 is max for n=1; m=1;% stabil = 3 is max for n=1, m=2.% for best stability with diffusion and non-linear diffusion (m=0) use CS in calc qs% and dqs/dx% for best stability with advection (m>0) use FS in calc qs but CS for% dqs/dx%% units: z [m], dx [m], timeyr [yr], k [m^(2-n)/yr], E [m/yr]; all time and rates in yr%%% %example% [z,b,norm_erosion_rate] = hillslope_profile3_lab_wr('L',10,'E',0.0003,'Si','debug',false)%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%%    default_path_main = 'K:\\Users\\nvmille1\\Classes\\AdvGeomorphology\\Hillslope Exercise';	default_m_num = 'Default_01';    default_min_time = 0;    default_n=1;    default_m=0;    default_timeyr=5e5;    default_nplot=5;        % number of timesteps to plot    default_dx=0.5;    default_bcflag=2;       % see header for info on boundary condition options    default_icflag=1;       % see header for info on initial condition options    default_wflag=1;        % wflag=2 (model soil production) is only intended (and tested) for diffusive hillslopes (m=0)    default_rflag=1;        % rflag=2 is roering non-linear diffusion model (m=0,n=1) (only for wflag=1 case for now)    default_Sc=0.90;        % threshold slope in the roering non-linear diffusion model    default_k=.005;         % 0.005 is default for m=0. default for m=2 is 0.0001 (different process, different units = different k value)    default_porosity=0.0;   % use this if you want a porosity correction -- if k is calibrated on flux of sediment grains, not flux of soil    default_E=.0001;        % lowering rate for bcflag = 2 (stream incision)    default_Wd=2.3;         % decay constant in soil production function. 1/Wd is the e-folding depth, typically near 0.5 m    default_Ws=.001;        % surface (maximum) soil production rate [m/yr]    default_i_soil_h = 1;      default_Si = 0.8;           %set initial slope IF rflag=2 MUST be < Sc!!    default_L = 40;            %set slope length    default_z_min = 200;        %set initial baselevel    %default_scarp_h = default_L*default_Si;     %calc initial scarp_h    %default_z_max = default_z_min + default_scarp_h;    default_z_stabil =1;    default_plt = false;    default_debug = false;    default_xoffset = 0;    p = inputParser;    p.FunctionName = 'hillslope_profile3_lab_nm';    addParameter(p, 'path_main', default_path_main, @ischar);    addParameter(p, 'm_num', default_m_num, @ischar);    addParameter(p,'min_time', default_min_time,@isnumeric)    addParameter(p,'z',linspace(1,200))    addParameter(p,'b',linspace(1,200))    addParameter(p,'n',default_n,@isnumeric)    addParameter(p,'m',default_m,@isnumeric)    addParameter(p,'timeyr',default_timeyr,@isnumeric)    addParameter(p,'nplot',default_nplot,@isnumeric)    addParameter(p,'dx',default_dx,@isnumeric)    addParameter(p,'bcflag',default_bcflag,@isnumeric)    addParameter(p,'icflag',default_icflag,@isnumeric)    addParameter(p,'wflag',default_wflag,@isnumeric)    addParameter(p,'rflag',default_rflag,@isnumeric)    addParameter(p,'Sc',default_Sc,@isnumeric)    addParameter(p,'porosity',default_porosity,@isnumeric)    addParameter(p,'E',default_E,@isnumeric)    addParameter(p,'Wd',default_Wd,@isnumeric)    addParameter(p,'Ws',default_Ws,@isnumeric)    addParameter(p,'i_soil_h',default_i_soil_h,@isnumeric)    addParameter(p,'Si',default_Si,@isnumeric)    addParameter(p,'L',default_L,@isnumeric)    addParameter(p,'z_min',default_z_min,@isnumeric)    addParameter(p,'stabil',default_z_stabil,@isnumeric)    addParameter(p,'k',default_k,@isnumeric)    addParameter(p,'plt',default_plt,@(x)isa(x,'logical'))    addParameter(p,'debug',default_debug,@(x)isa(x,'logical'))    addParameter(p, 'xoffset', default_xoffset, @isnumeric)    parse(p,varargin{:});    hold off%% define parameters%    path_main = p.Results.path_main;    m_num = p.Results.m_num;    min_time = p.Results.min_time;	n=p.Results.n;	m=p.Results.m;	timeyr=p.Results.timeyr;    nplot=p.Results.nplot;       % number of timesteps to plot	dx=p.Results.dx;	bcflag=p.Results.bcflag;     % see header for info on boundary condition options    icflag=p.Results.icflag;      % see header for info on initial condition options	wflag=p.Results.wflag;       % wflag=2 (model soil production) is only intended (and tested) for diffusive hillslopes (m=0)    rflag=p.Results.rflag;       % rflag=2 is roering non-linear diffusion model (m=0,n=1) (only for wflag=1 case for now)    Sc=p.Results.Sc;        % threshold slope in the roering non-linear diffusion model	k=p.Results.k;        % 0.005 is default for m=0. default for m=2 is 0.0001 (different process, different units = different k value)	porosity=p.Results.porosity;   % use this if you want a porosity correction -- if k is calibrated on flux of sediment grains, not flux of soil	E=p.Results.E;        % lowering rate for bcflag = 2 (stream incision)	Wd=p.Results.Wd;        % decay constant in soil production function. 1/Wd is the e-folding depth, typically near 0.5 m	Ws=p.Results.Ws;       % surface (maximum) soil production rate [m/yr]    i_soil_h = p.Results.i_soil_h;  % initial soil thickness    stabil = p.Results.stabil;    plt = p.Results.plt;    debug = p.Results.debug;    xoffset = p.Results.xoffset;    %See lines below icflag setup, offsets x axis nodes from 0 by this number.% use stabil < 1 if problems arise with m not = 0.  stabil = 2.25 is max for n=1; m=1;% stabil = 3 is max for n=1, m=2. lines 120-127 define stabil2 = 0.95 for% m=0 case.%    %    Si = p.Results.Si;          %set initial slope IF rflag=2 MUST be < Sc!!    L = p.Results.L;%set slope length    z_min = p.Results.z_min;       %set initial baselevel    scarp_h = L*Si;   %calc initial scarp_h    z_max = z_min + scarp_h;    if debug        if ~isempty(p.UsingDefaults)        disp('Using defaults: ')        disp(p.UsingDefaults)        end    end%%    % IC FLAGS%   specify initial conditions if not specified in command line (e.g., [z2,b2]=hillslope_profile3(z1,b1))%%   option intial slope, w/o flats: a triangular ridge    if icflag == 1       z=[z_max:-(Si*dx):z_min];%%   option initial scarp in the midst of long flats above and below    elseif icflag == 2        z=[z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max,z_max:-(Si*dx):z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min];%%   option initial ridge with long flat below    elseif icflag == 3        z=[z_max:-(Si*dx):z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min,z_min];%       else % i.e., if icflag == 4        b = p.Results.b;        z = p.Results.z;%   %   do nothing -- use the z, b vectors input with command line >>hillslope_profile3(z,b);%    end%    if icflag<4         b=z-i_soil_h;    end    if wflag==1        b=z-i_soil_h;    end	h = z - b;    if debug    scarp_h = max(z) - min(z)    else    scarp_h = max(z) - min(z);    end    %Make the x axis    % length of x axis matches z data    Maxi=length(z);    % x array spaced dx from 0 to number of x data	ax=((xoffset):(Maxi-1 + xoffset)).*dx;    % x position of the final point at # of x * x spacing	x=(Maxi + xoffset).*dx;%% compute dt for stability (first guess)%    stabil = 2.25;    if rflag == 2        stabil2 = .02;          % reduce from 0.95 to 0.02 for roering model if approaching angle of repose    else         stabil2 = .95;    end	if m==0		B=dx.*dx.*(1-porosity)./(2.*k);		        if debug        dt=stabil2.*B        else        dt=stabil2.*B;        end  	else		A=2.*dx.*(1-porosity)./(k.*m.*x.^(m-1));		B=dx.*dx.*(1-porosity)./(2.*k.*x.^m);		dt=stabil.*min(A,B);	end%% compute constants%	k1 = -1.*k./(dx.^n);	k3 = dt./((1-porosity).*dx);    Scdx = 2.*dx.*Sc;%% determine # timesteps for the simulation and specify number of times % to output data%    if debug        nsteps = timeyr./dt    else        nsteps = timeyr./dt;    end		tplot=round(nsteps./nplot);%% initialize variables and compute x^n outside timeloops for maximized efficiency%	qs = zeros(size(z));	xm = zeros(size(z));	k1xm = zeros(size(z));%	for i = 1:Maxi		xm(i) = ((i-1).*dx).^m;	end	xm(1)=xm(1)+(.2.*dx);%	k1xm1 = k1.*xm(1);	k1xmm = k1.*xm(Maxi);	k1xm = k1*xm;%% plot z initial for reference and then loop over time t = 1:nsteps%    if plt    	hold off    	figure(1)    	clf    	plot(ax,z,'b')        %%% Save z        hold on        set(gca,'xlabel',text(0,0,'distance (m)'))    	set(gca,'ylabel',text(0,0,'elevation (m)'))%% only if computing soil production, plot soil-rock interface%        if wflag == 2            plot (ax,b,'k')            figure(5)            plot(ax,h,'b')            hold on            xlabel('distance (m)')            ylabel('soil thickness (m)')        end    end%% calc initial slope and curvature, plot (uncomment to plot)%        i=1;        s(i) = -1*(z(i+1) - z(i))/dx;        plot_s(i) = s(i);        for i = 2:Maxi-1            s(i) = -1*(z(i+1) - z(i-1))/(2*dx);            plot_s(i) = s(i);        end        i=Maxi;        s(i) = -1*(z(i) - z(i-1))/(dx);%               i=1;        cv(i) = -1*(s(i+1) - s(i))/dx;        for i = 2:Maxi-1            cv(i) = -1*(s(i+1) - s(i-1))/(2*dx);        end        %i=Maxi        %cv(i) = -1*(s(i) - s(i-1))/dx;%    if plt        figure(4)        clf%     plot (plot_s,cv,'m')%%%%%%%%%%%% Save to txt file initial slope and cv        hold on%     xlabel('local slope (m/m)')%     ylabel('local curvature')    end%% Initialize and write parameter outputs%Make directory to hold outputs, if it doesn't exist. out_root_points = fullfile(path_main, m_num);if ~exist(out_root_points)    mkdir (out_root_points)end% Make unique file type id in appropriate folder: fv = strcat(m_num,'_var');fp = strcat(m_num,'_in_vars'); % parameters used to run the modelfss = strcat(m_num, '_ss');% Full file names:  K:\Users\nvmille1\Classes\AdvGeomorphology\Hillslope% Exercise, FOLDER(01_01), FILENAMEfv_name = fullfile(out_root_points, strcat(fv, '.txt'));fp_name = fullfile(out_root_points, strcat(fp, '.mat'));fss_name =  fullfile(out_root_points, strcat(fss, '.txt'));%If files don't exist, write new ones, except for in_parameters file%(.mat).fnames = {fv_name, fss_name};for i=1:2     fn_temp = fnames{i};    if ~exist(fn_temp)        dlmwrite(fn_temp, 'header');    endend%Before big timeloop, print initial parameters as loaded. %   Horzcat wont' work bc vars are different sizes. save(fp_name,'n', 'm', 'timeyr', 'nplot', 'dx', 'bcflag', ...     'icflag', 'wflag', 'rflag', 'Sc', 'k', 'porosity', 'E','Wd', 'Ws',...     'i_soil_h', 'stabil', 'plt', 'debug', 'z', 'b', 'L' );  %Initialize an array to hold time dataT1 = ones(size(z));%%%% BEGIN BIG TIME LOOP%	for t = 1:nsteps                %% first calc qs(i); BC -- no flow over ridge (i=1)%		if wflag==1			i=1;			if m==0				qs(i) = k1.*(z(i+1) - z(i)).^n;                Smax = abs((z(i+1)-z(i))/dx);                if rflag==2                    qs(i) = k1.*(z(i+1) - z(i)).^n*(1/(1-(abs(z(i+1) - z(i))/(Scdx./2))^2));                    Smax = abs((z(i+1)-z(i))/dx);                end			else				qs(i) = k1xm1.*(z(i+1) - z(i)).^n;                Smax = abs((z(i+1)-z(i))/dx);			end            for i = 2:Maxi-1                if m==0                    if rflag==2                        qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n*(1/(1-(abs(z(i+1) - z(i-1))/Scdx)^2));                        Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                    else				        qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n;                        Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                    end                else                    qs(i) = k1xm(i).*(z(i+1) - z(i)).^n;                    Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                end			end			i = Maxi;            if rflag==2                qs(i) = k1xmm.*(z(i) - z(i-1)).^n*(1/(1-(abs(z(i) - z(i-1))/(Scdx./2))^2));                Smax = max(Smax,abs((z(i)-z(i-1))/dx));            else      		    qs(i) = k1xmm.*(z(i) - z(i-1)).^n;                Smax = max(Smax,abs((z(i)-z(i-1))/dx));            end%				elseif wflag==2			i=1;				W(i)=Ws.*exp(-1.*Wd.*h(i));				if m==0					qs(i) = k1.*(z(i+1) - z(i)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx);                    Smax = abs((z(i+1)-z(i))/dx);				else					qs(i) = k1xm1.*(z(i+1) - z(i)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx);                    Smax = abs((z(i+1)-z(i))/dx);				end%			for i = 2:Maxi-1					W(i)=Ws.*exp(-1.*Wd.*h(i));					qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx+qs(i-1));                    Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));			end%			i = Maxi;						W(i)=Ws.*exp(-1.*Wd.*h(i));						qs(i) = k1xmm.*(z(i) - z(i-1)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx+qs(i-1));                    Smax = max(Smax,abs((z(i)-z(i-1))/dx));		end% 					qs=abs(qs);%% now calc dz/dt based on qs(i), again with a no-flow BC at ridge (i=1)%		i=1;			tempz = z(i);			z(i) = z(i) - k3.*(qs(i));			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end			dzdt(t)= (tempz-z(i))/dt;            dzdti(i) = (tempz-z(i))/dt;			n_dzdt(t) = dzdt(t)/E;			time(t)=t*dt;%					for i = 2:Maxi-2            tempz=z(i);			z(i) = z(i) - (k3./2).*(qs(i+1) - qs(i-1));%            z(i) = z(i) - (k3).*(qs(i+1) - qs(i));            dzdti(i) = (tempz-z(i))/dt;			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end		end%		i=Maxi-1;            tempz=z(i);			z(i) = z(i) - k3.*(qs(i) - qs(i-1));            dzdti(i) = (tempz-z(i))/dt;			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end%% calc last point applying appropriate BC as specified by bcflag% note if bcflag = 1, z(Maxi) is constant, so do nothing%		i=Maxi;		if bcflag==2            tempz=z(i);			z(i) = z(i) - E.*dt;            dzdti(i) = (tempz-z(i))/dt;			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end		elseif bcflag==1            dzdti(i) = 0;			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end		elseif bcflag==3            tempz=z(i);			z(i) = z(i) + (k3./2).*(qs(i-1));            dzdti(i) = (tempz-z(i))/dt;			if wflag==2				b(i) = -1.*dt.*W(i) + b(i);				if z(i)<b(i)					i                    z(i)                    b(i)				end				h(i)=z(i)-b(i);			end      	end%% plot z, b, slope, curvature at appropriate times.  use "hold on" to avoid erasing previous plots%		if rem(t,tplot)==0 || t == 1%           % calc slope and curvature of each point, this time step    %            i=1;            s(i) = -1*(z(i+1) - z(i))/dx;            plot_s(i) = s(i);            for i = 2:Maxi-1                s(i) = -1*(z(i+1) - z(i-1))/(2*dx);                plot_s(i) = s(i);            end            i=Maxi;            s(i) = -1*(z(i) - z(i-1))/(dx);    %                   i=1;            cv(i) = -1*(s(i+1) - s(i))/dx;            for i = 2:Maxi-2                cv(i) = -1*(s(i+1) - s(i-1))/(2*dx);            end            i=Maxi-1;            cv(i) = -1*(s(i) - s(i-2))/(2*dx);    %            if plt                figure(4)                plot (plot_s,cv,'g')                xlabel('local slope (m/m)')                ylabel('local curvature')                title('Slope-curvature Plot')                hold on    %    			if wflag==1    				figure(1)                    plot (ax,z,'g')    			elseif wflag==2    				figure(1)                    plot (ax,z,'g',ax,b,'c')    				title (['Ws=',num2str(Ws),' Wd=',num2str(Wd),' timeyr=',num2str(timeyr),...                        ' m=',num2str(m),' n=',num2str(n),' k=',num2str(k),' bc=',num2str(bcflag),...                        ' E=',num2str(E)])                    figure(3)                    plot(h,dzdti,'g')                    hold on                    xlabel('soil thickness (m)')                    ylabel('dzdt')                    title('Soil thickness and erosion rate (curvature)')                    figure(5)                    plot(ax,h,'g')                end    		end                    %            %%            %IN LOOP            %Make Time column            T = T1*t;            %Horizontally concatenate them. May need to check sizes            if wflag == 1                if rflag ==1                FV_IN = horzcat(T',  ax', z', s', [nan;cv'], b',dzdti', h', qs');                elseif rflag ==2                SM = T1*Smax;                Keff_Array = T1 * Keff;                FV_IN = horzcat(T',ax',  z', s', cv', b',dzdti', h', qs', SM, Keff_Array);                end            elseif wflag ==2                FV_IN = horzcat(T',ax',  z', s', cv', b',dzdti', h', pro', qs');            end            dlmwrite(fv_name, FV_IN,'-append','delimiter',' ')        %End nplot/nwrite loop        end% end time loop -- repeat for all nsteps%end%% % Find T_eq... continue loop to convergence. %t = t;converge = 'n';while converge == 'n'    plt = false;%% first calc qs(i); BC -- no flow over ridge (i=1)%        if wflag==1            i=1;            if m==0                qs(i) = k1.*(z(i+1) - z(i)).^n;                Smax = abs((z(i+1)-z(i))/dx);                if rflag==2                    qs(i) = k1.*(z(i+1) - z(i)).^n*(1/(1-(abs(z(i+1) - z(i))/(Scdx./2))^2));                    Smax = abs((z(i+1)-z(i))/dx);                end            else                qs(i) = k1xm1.*(z(i+1) - z(i)).^n;                Smax = abs((z(i+1)-z(i))/dx);            end            for i = 2:Maxi-1                if m==0                    if rflag==2                        qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n*(1/(1-(abs(z(i+1) - z(i-1))/Scdx)^2));                        Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                    else                        qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n;                        Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                    end                else                    qs(i) = k1xm(i).*(z(i+1) - z(i)).^n;                    Smax = max(Smax,abs((z(i+1)-z(i-1))/(2*dx)));                end            end            i = Maxi;            if rflag==2                qs(i) = k1xmm.*(z(i) - z(i-1)).^n*(1/(1-(abs(z(i) - z(i-1))/(Scdx./2))^2));                Smax = max(Smax,abs((z(i)-z(i-1))/dx));            else                qs(i) = k1xmm.*(z(i) - z(i-1)).^n;                Smax = max(Smax,abs((z(i)-z(i-1))/dx));            end%               elseif wflag==2            i=1;                W(i)=Ws.*exp(-1.*Wd.*h(i));                if m==0                    qs(i) = k1.*(z(i+1) - z(i)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx);                else                    qs(i) = k1xm1.*(z(i+1) - z(i)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx);                end%            for i = 2:Maxi-1                    W(i)=Ws.*exp(-1.*Wd.*h(i));                    qs(i) = k1xm(i)./2.*(z(i+1) - z(i-1)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx+qs(i-1));            end%            i = Maxi;                       W(i)=Ws.*exp(-1.*Wd.*h(i));                     qs(i) = k1xmm.*(z(i) - z(i-1)).^n;                    qs(i) = min(qs(i),(W(i) + h(i)./dt).*dx+qs(i-1));           end%                   qs=abs(qs);%% now calc dz/dt based on qs(i), again with a no-flow BC at ridge (i=1)%        i=1;            tempz = z(i);            z(i) = z(i) - k3.*(qs(i));            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end            dzdt(t)= (tempz-z(i))/dt;            dzdti(i) = (tempz-z(i))/dt;            n_dzdt(t) = dzdt(t)/E;            time(t)=t*dt;%                   for i = 2:Maxi-2            tempz=z(i);            z(i) = z(i) - (k3./2).*(qs(i+1) - qs(i-1));%            z(i) = z(i) - (k3).*(qs(i+1) - qs(i));            dzdti(i) = (tempz-z(i))/dt;            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end        end%        i=Maxi-1;            tempz=z(i);            z(i) = z(i) - k3.*(qs(i) - qs(i-1));            dzdti(i) = (tempz-z(i))/dt;            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end%% calc last point applying appropriate BC as specified by bcflag% note if bcflag = 1, z(Maxi) is constant, so do nothing%        i=Maxi;        if bcflag==2            tempz=z(i);            z(i) = z(i) - E.*dt;            dzdti(i) = (tempz-z(i))/dt;            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end        elseif bcflag==1            dzdti(i) = 0;            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end        elseif bcflag==3            tempz=z(i);            z(i) = z(i) + (k3./2).*(qs(i-1));            dzdti(i) = (tempz-z(i))/dt;            if wflag==2                b(i) = -1.*dt.*W(i) + b(i);                h(i)=z(i)-b(i);            end        end        del = (dzdti - E)/E;        tolerance = max(abs(del));        if tolerance <= 0.01 & min_time < time(t)            converge = 'y';        else        t = t+1;        endend%%%% calculate steady state profile for comparison, linear diffusion case and% m=2, n=2 sheetwash case%    plot_ss = 0;    z_ss = zeros(size(z));    if m==0 & n==1 & bcflag==2            if debug            z0 = z(1)            else            z0 = z(1);            end        z_ss = z0 - E*ax.^2./(2*k);        z_ss = z_ss - (z_ss(Maxi)-z(Maxi));        z_ss(1);        plot_ss = 1;    elseif m==2 & n==2 & bcflag==2        z0=z(1);        z_ss = z0 - 2*sqrt(E/k).*ax.^0.5;        z_ss = z_ss - (z_ss(Maxi)-z(Maxi));        z_ss(1);        plot_ss = 1;    end    if plt          if plot_ss            figure(1)            hold on            plot (ax,z_ss,'k+')        end        figure(1)        plot(ax,z,'r')        if wflag==2            plot(ax,b,'Color',[0.4,0.4,0.4])        end    end%    % for Pierce and Colman test, calc effective diffusivity constant from Smax% -- which holds the maximum value from the last time step% using analytical Results in Pierce and Colman paper (assuming initial% scarp gradient = 0.8 = tan_alpha)%    if debug        years = max(time)        max_slope = Smax    else        years = max(time);        max_slope = Smax;    end    if rflag==2        Keff = (scarp_h/(4*sqrt(max(time))*Si*erfinv(Smax/Si)))^2;    end%% plot erosion rate at divide as a function of time in a second figure%    if plt	   figure(2)	   plot(time,n_dzdt,'k')	   xlabel('time in years (t * dt)')	   ylabel('dzdt/E ')	   title([ 'time to steady state: E =' num2str(E)])        if wflag == 2            figure(3)            plot(h,dzdti,'r')            spro=Ws*exp(-Wd*h);            plot(h,spro,'Color',[0.3,0.3,0.3])   %nvm changed spro            figure(5)            plot(ax,h,'r')            if plot_ss                h_ss = -(1/Wd)*log(E/Ws);                plot(ax,h_ss,'k+')                hold off                figure(3)                plot(h_ss,E,'k+')            end            hold off        end % % plot the final time step of curvature vs slope in red %                figure(4)        plot (plot_s,cv,'r')        if plot_ss            if m==0            cv_ss = -E/k            plot (plot_s,cv_ss,'k+')            end        end    end %	z=z;    %%%Calculate stuff that otherwise would only be plotted.   if wflag == 2    pro=Ws*exp(-Wd*h);    h_ss = -(1/Wd)*log(E/Ws);end    if m==0    cv_ss = -E/k;end%% % Out of time loop. Save Steady State valuesTeq_Array = T1* t;if wflag == 1    if m==0 & n==1 & bcflag==2        cv_ss_Array = T1*cv_ss;    %    if rflag ==1        FSS_IN = horzcat(Teq_Array',ax',  z_ss', cv_ss_Array');    %    elseif rflag ==2     %   SM = T1*Smax;    %    Keff_Array = T1 * Keff;    %    FV_IN = horzcat(T', ax',  z', s', cv', b', n_dzdt', dzdti', h', E', qs', SM, Keff_Array);    %    FSS_IN = horzcat(Teq_array',ax', z0', z_ss', s_ss', cv_ss', h_ss);    %    end        elseif m==2 & n==2 & bcflag==2        FSS_IN = horzcat(Teq_Array',ax',  z_ss');    endelseif wflag ==2    cv_ss_Array = T1*cv_ss;    FSS_IN = horzcat(Teq_Array',ax',  z_ss', cv_ss_Array', h_ss', b');enddlmwrite(fss_name, FSS_IN,'-append','delimiter',' ')%% % write final value dzdt/E to screen    if debug        norm_erosion_rate = n_dzdt(t)    else        norm_erosion_rate= n_dzdt(t);    end