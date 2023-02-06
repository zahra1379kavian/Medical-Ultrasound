clearvars;
close all

% =========================================================================
% SIMULATION
% =========================================================================

% create the computational grid
Nx = 500;           % number of grid points in the x (row) direction
Ny = 800;           % number of grid points in the y (column) direction
dx = 0.1e-3;    	% grid point spacing in the x direction [m]
dy = dx;            % grid point spacing in the y direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% define the properties of the propagation medium
medium.sound_speed = 1480;  % [m/s]
medium.density = 1000;

% create the time array
kgrid.makeTime(medium.sound_speed);

%source.p_mask = makeCircle(Nx, Ny, cx, cy, radius, arc_angle);
n = round(10e-3/dx);
source.p_mask = zeros(Nx,Ny);
source.p_mask(Nx/2:Nx/2+n,10) = 1;

% define a time varying sinusoidal source
source_freq = 5e5;       % [Hz]
source_mag = 0.5;           % [Pa]
source.p = source_mag * sin(2 * pi * source_freq * kgrid.t_array);

% filter the source to remove high frequencies not supported by the grid
source.p = filterTimeSeries(kgrid, medium, source.p);

% create a display mask to display the transducer
display_mask = source.p_mask;

% create a sensor mask covering the entire computational domain using the
% opposing corners of a rectangle
sensor.mask = [1, 1, Nx, Ny].';

% set the record mode capture the final wave-field and the statistics at
% each sensor point 
sensor.record = {'p_final', 'p_max', 'p_rms'};

% assign the input options
input_args = {'DisplayMask', display_mask, 'PMLInside', false, 'PlotPML', false};

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});

% =========================================================================
% VISUALISATION
% =========================================================================

% add the source mask onto the recorded wave-field
sensor_data.p_final(source.p_mask ~= 0) = 1;
sensor_data.p_max(source.p_mask ~= 0) = 1;
sensor_data.p_rms(source.p_mask ~= 0) = 1;

% plot the final wave-field
figure;
%subplot(1, 3, 1);
imagesc(kgrid.y_vec * 1e3, kgrid.x_vec * 1e3, sensor_data.p_final, [-1 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;
title('Final Wave Field');

% plot the maximum recorded pressure
%subplot(1, 3, 2);
figure
imagesc(kgrid.y_vec * 1e3, kgrid.x_vec * 1e3, sensor_data.p_max, [-1 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;
title('Maximum Pressure');

% plot the rms recorded pressure
figure
%subplot(1, 3, 3);
imagesc(kgrid.y_vec * 1e3, kgrid.x_vec * 1e3, sensor_data.p_rms, [-1 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;
title('RMS Pressure');
scaleFig(2, 1);

%%
%%Directivity Function
%%%Near Field
A = (250-(1:500))./50;
teta = atand(A);
x = sind(teta);
figure
plot(x.',sensor_data.p_max(:,50))
title("Near Field")
xlabel("sin(degree)")
ylabel("p_max")

%%%Far Field
A = (250-(1:500))./300;
teta = atand(A);
x = sind(teta);
figure
plot(x.',sensor_data.p_max(:,300))
title("Far Field")
xlabel("sin(degree)")
ylabel("p_max")