close all
clc
clear

%%%part a
clearvars;

% =========================================================================
% SIMULATION
% =========================================================================

% load the initial pressure distribution from an image and scale
p0_magnitude = 2;
p0 = p0_magnitude * loadImage('EXAMPLE_source_two.bmp');

% assign the grid size and create the computational grid
PML_size = 20;              % size of the PML in grid points
Nx = 300;    % number of grid points in the x direction
Ny = 300;    % number of grid points in the y direction
x = 10e-3;                  % total grid size [m]
y = 10e-3;                  % total grid size [m]
dx = x / Nx;                % grid point spacing in the x direction [m]
dy = y / Ny;                % grid point spacing in the y direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% resize the input image to the desired number of grid points
p0 = resize(p0, [Nx, Ny]);

% smooth the initial pressure distribution and restore the magnitude
p0 = smooth(p0, true);

% assign to the source structure
source.p0 = p0;

% define the properties of the propagation medium
medium.sound_speed = 1480;   % [m/s]
medium.density = 1000;

% define a centered Cartesian circular sensor
sensor_radius = 4.5e-3;     % [m]
sensor_angle = 2*pi;      % [rad]
sensor_pos = [0, 0];        % [m]
num_sensor_points = 27;
cart_sensor_mask = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);

% assign to sensor structure
sensor.mask = cart_sensor_mask;

% create the time array
kgrid.makeTime(medium.sound_speed);

% set the input options
input_args = {'Smooth', false, 'PMLInside', false, 'PlotPML', false};

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});

% add noise to the recorded sensor data
signal_to_noise_ratio = 40;  % [dB]
sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');

% create a second computation grid for the reconstruction to avoid the
% inverse crime
Nx = 300;           % number of grid points in the x direction
Ny = 300;           % number of grid points in the y direction
x = 10e-3;                  % total grid size [m]
y = 10e-3;                  % total grid size [m]
dx = x / Nx;                % grid point spacing in the x direction [m]
dy = y / Ny;                % grid point spacing in the y direction [m]
kgrid_recon = kWaveGrid(Nx, dx, Ny, dy);

% use the same time array for the reconstruction
kgrid_recon.setTime(kgrid.Nt, kgrid.dt);

% reset the initial pressure
source.p0 = 0;

% assign the time reversal data
sensor.time_reversal_boundary_data = sensor_data;

% run the time-reversal reconstruction
p0_recon = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor, input_args{:});

% create a binary sensor mask of an equivalent continuous circle 
sensor_radius_grid_points = round(sensor_radius / kgrid_recon.dx);
binary_sensor_mask = makeCircle(kgrid_recon.Nx, kgrid_recon.Ny, kgrid_recon.Nx/2 + 1, kgrid_recon.Ny/2 + 1, sensor_radius_grid_points, sensor_angle);

% assign to sensor structure
sensor.mask = binary_sensor_mask;

% interpolate data to remove the gaps and assign to sensor structure
sensor.time_reversal_boundary_data = interpCartData(kgrid_recon, sensor_data, cart_sensor_mask, binary_sensor_mask);

% run the time-reversal reconstruction
p0_recon_interp = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor, input_args{:});

% =========================================================================
% VISUALISATION
% =========================================================================

% plot the initial pressure and sensor distribution
figure;
imagesc(kgrid.y_vec * 1e3, kgrid.x_vec * 1e3, p0 + cart2grid(kgrid, cart_sensor_mask), [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot the simulated sensor data
figure;
imagesc(sensor_data, [-1, 1]);
colormap(getColorMap);
ylabel('Sensor Position');
xlabel('Time Step');
colorbar;

% plot the reconstructed initial pressure 
figure;
imagesc(kgrid_recon.y_vec * 1e3, kgrid_recon.x_vec * 1e3, p0_recon, [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot the reconstructed initial pressure using the interpolated data
figure;
imagesc(kgrid_recon.y_vec * 1e3, kgrid_recon.x_vec * 1e3, p0_recon_interp, [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot a profile for comparison
slice_pos = 4.5e-3;  % [m] location of the slice from top of grid [m]
figure;
plot(kgrid.y_vec * 1e3, p0(round(slice_pos/kgrid.dx), :), 'k--', ...
     kgrid_recon.y_vec * 1e3, p0_recon(round(slice_pos/kgrid_recon.dx), :), 'r-', ...
     kgrid_recon.y_vec * 1e3, p0_recon_interp(round(slice_pos/kgrid_recon.dx), :), 'b-');
xlabel('y-position [mm]');
ylabel('Pressure');
legend('Initial Pressure', 'Point Reconstruction', 'Interpolated Reconstruction');
axis tight;
set(gca, 'YLim', [0 2.1]);



%%
%%%part b
close all
clc
clear

clearvars;

% =========================================================================
% SIMULATION
% =========================================================================

% load the initial pressure distribution from an image and scale
p0_magnitude = 2;
p0 = p0_magnitude * loadImage('EXAMPLE_source_two.bmp');

% assign the grid size and create the computational grid
PML_size = 20;              % size of the PML in grid points
Nx = 500;    % number of grid points in the x direction
Ny = 500;    % number of grid points in the y direction
x = 10e-3;                  % total grid size [m]
y = 10e-3;                  % total grid size [m]
dx = x / Nx;                % grid point spacing in the x direction [m]
dy = y / Ny;                % grid point spacing in the y direction [m]
%dx = 0.1e-3;
%dy = 0.1e-3;
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% resize the input image to the desired number of grid points
p0 = resize(p0, [Nx, Ny]);

% smooth the initial pressure distribution and restore the magnitude
p0 = smooth(p0, true);

% assign to the source structure
source.p0 = p0;

% define the properties of the propagation medium
medium.sound_speed = 1480;   % [m/s]
medium.density = 1000;

x_size = Nx*dx;
grid_size = [Nx , Ny];

% define a centered Cartesian circular sensor
sensor_radius = 4.5e-3;     % [m]
%sensor_angle = 2*pi;      % [rad]
sensor_pos = [1, 1] * x_size / 2;        % [m]
num_sensor_points = round(2*pi*sensor_radius/10/dx);
%arc_pos = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);
arc_pos = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos);

% convert the Cartesian arc positions to grid points
arc_pos             = round(arc_pos.'/dx);

% define element parameters
radius              = Inf;
diameter            = 7;
focus_pos           = [1, 1] * Nx/2;

% create arcs
cart_sensor_mask = makeMultiArc(grid_size, arc_pos, radius, diameter, focus_pos, 'Plot', true);

% assign to sensor structure
sensor.mask = cart_sensor_mask;

% create the time array
kgrid.makeTime(medium.sound_speed);

% set the input options
input_args = {'Smooth', false, 'PMLInside', false, 'PlotPML', false};

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});

% add noise to the recorded sensor data
signal_to_noise_ratio = 40;  % [dB]
sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');

% create a second computation grid for the reconstruction to avoid the
% inverse crime
%Nx = 300;           % number of grid points in the x direction
%Ny = 300;           % number of grid points in the y direction
%x = 10e-3;                  % total grid size [m]
%y = 10e-3;                  % total grid size [m]
%dx = x / Nx;                % grid point spacing in the x direction [m]
%dy = y / Ny;                % grid point spacing in the y direction [m]
kgrid_recon = kWaveGrid(Nx, dx, Ny, dy);

% use the same time array for the reconstruction
kgrid_recon.setTime(kgrid.Nt, kgrid.dt);

% reset the initial pressure
source.p0 = 0;

% assign the time reversal data
sensor.time_reversal_boundary_data = sensor_data;

% run the time-reversal reconstruction
p0_recon = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor.', input_args{:});

% create a binary sensor mask of an equivalent continuous circle 
sensor_radius_grid_points = round(sensor_radius / kgrid_recon.dx);
%binary_sensor_mask = makeCircle(kgrid_recon.Nx, kgrid_recon.Ny, kgrid_recon.Nx/2 + 1, kgrid_recon.Ny/2 + 1, sensor_radius_grid_points, sensor_angle);
binary_sensor_mask = makeCircle(kgrid_recon.Nx, kgrid_recon.Ny, kgrid_recon.Nx/2 + 1, kgrid_recon.Ny/2 + 1, sensor_radius_grid_points);

% assign to sensor structure
sensor.mask = binary_sensor_mask;

% interpolate data to remove the gaps and assign to sensor structure
sensor.time_reversal_boundary_data = interpCartData(kgrid_recon, sensor_data, cart_sensor_mask, binary_sensor_mask);

% run the time-reversal reconstruction
p0_recon_interp = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor, input_args{:});

% =========================================================================
% VISUALISATION
% =========================================================================

% plot the initial pressure and sensor distribution
figure;
imagesc(kgrid.y_vec * 1e3, kgrid.x_vec * 1e3, p0 + cart2grid(kgrid, cart_sensor_mask), [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot the simulated sensor data
figure;
imagesc(sensor_data, [-1, 1]);
colormap(getColorMap);
ylabel('Sensor Position');
xlabel('Time Step');
colorbar;

% plot the reconstructed initial pressure 
figure;
imagesc(kgrid_recon.y_vec * 1e3, kgrid_recon.x_vec * 1e3, p0_recon, [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot the reconstructed initial pressure using the interpolated data
figure;
imagesc(kgrid_recon.y_vec * 1e3, kgrid_recon.x_vec * 1e3, p0_recon_interp, [-1, 1]);
colormap(getColorMap);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;

% plot a profile for comparison
slice_pos = 4.5e-3;  % [m] location of the slice from top of grid [m]
figure;
plot(kgrid.y_vec * 1e3, p0(round(slice_pos/kgrid.dx), :), 'k--', ...
     kgrid_recon.y_vec * 1e3, p0_recon(round(slice_pos/kgrid_recon.dx), :), 'r-', ...
     kgrid_recon.y_vec * 1e3, p0_recon_interp(round(slice_pos/kgrid_recon.dx), :), 'b-');
xlabel('y-position [mm]');
ylabel('Pressure');
legend('Initial Pressure', 'Point Reconstruction', 'Interpolated Reconstruction');
axis tight;
set(gca, 'YLim', [0 2.1]);

















