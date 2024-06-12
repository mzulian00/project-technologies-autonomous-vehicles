%%
clc, clear all, close all

%% ---------------- Initialization ----------------
t_end_sim = 300; 
dt_sim = 1e-3;
model_name = 'path_tracking';

m = 1575;       %[kg] mass
a = 1.3;  
b = 1.5 ;       %[m] rear wheelbase       
L = a+b;        %[m] wheelbase
Jz=2875;        %[kg m^2] mass moment of inertia 
g = 9.81;       %[m/s^2]
Cf = 2*60000;   %Front axle cornering stiffness
Cr = 2*57000;   %Rear  axle cornering stiffness
max_delta = 25*2*pi/360;
V = 80/3.6;

A = [ 0 1 0 0;
      0 -(Cf+Cr)/(m*V) (Cf+Cr)/m (Cr*b-Cf*a)/(m*V);
      0 0 0 1;
      0 (Cr*b-Cf*a)/(Jz*V) (Cf*a-Cr*b)/Jz -(Cr*b^2+Cf*a^2)/(Jz*V)
];

B1 = [0; Cf/m; 0; Cf*a/Jz];
B2 = [0; (Cr*b-Cf*a)/(m*V)-V; 0; -(Cr*b^2+Cf*a^2)/(Jz*V)]; 
B = [B1, B2];
C = eye(4);
D = zeros(4,2);

% FEEDBACK POLE PLACEMENT
K_feedback_pole = place(A, B1, [-1, -0.5, -1.1, -0.6]*10);
% [eig(A), eig(A-B1*K)];

% FEEDBACK LQR
Q = diag([1, 1, 1, 1]);
R = 1;
K_feedback_LQR = lqr(A, B1, Q, R);

% FEEDFORWARD
K_feedforward = m*V^2/L * (b/Cf - a/Cr + a/Cr*K_feedback_LQR(3)) + L - b*K_feedback_LQR(3);

% INTEGRATIVE
K_integrative = [1 1]*0.1;

K_fb = K_feedback_LQR;
K_ff = K_feedforward;
K_i = K_integrative;
x0 = 0;
return;

%% ---------------- TEST 1 ----------------
e1v=[];e2v=[];e3v=[];e4v=[];u1v=[];u2v=[];N=0;


trajectory_type = 1;
x0 = 0;

K=zeros(1,4);
K_ff=0;

sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

K_fb = K_feedback_LQR;
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

% K_fb = K_feedback_pole;
% sim(model_name)
% [e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

close all
plot_leg = {'fb off','fb LQR', 'fb POLE'};
% PLOT_TRAJ(t, V, dt_sim, Kl, u1v, plot_leg)
PLOT_U(t, u1v, u2v, N, plot_leg)
PLOT_E(t, e1v, e2v, e3v, e4v, N, plot_leg)

%% ---------------- TEST 2 ----------------
e1v=[];e2v=[];e3v=[];e4v=[];u1v=[];u2v=[];N=0;

trajectory_type = 1;
x0 = 0;

K_fb=zeros(1,4);
K_ff=0;
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

K_ff=K_feedforward;
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

[v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

close all
plot_leg = {'ff off','ff on', 'fb LQR'};
% PLOT_TRAJ(t, V, dt_sim, Kl)
PLOT_U(t, u1v, u2v, N, plot_leg)
PLOT_E(t, e1v, e2v, e3v, e4v, N, plot_leg)

%% ---------------- TEST 3 ----------------
e1v=[];e2v=[];e3v=[];e4v=[];u1v=[];u2v=[];N=0;

trajectory_type = 1;

K_fb = K_feedback_LQR;
K_ff=K_feedforward;

K_i = [0 0];
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

K_integrative = [1 1] * 100;

K_i = K_integrative;
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);

K_ff = 0;
sim(model_name)
[e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N);


close all
plot_leg = {'integ off','integ on', 'ff off'};
PLOT_U(t, u1v, u2v, N, plot_leg)
PLOT_E(t, e1v, e2v, e3v, e4v, N, plot_leg)







%% ---------------------------- FUNCTIONS ---------------------------------
function [e1v, e2v, e3v, e4v, u1v, u2v, N] = take_res(e, u, e1v, e2v, e3v, e4v, u1v, u2v, N)
    N = N+1;
    e1v(:,N) = e(:,1);
    e2v(:,N) = e(:,2);
    e3v(:,N) = e(:,3);
    e4v(:,N) = e(:,4);
    u1v(:,N) = u(:,1);
    u2v(:,N) = u(:,2);
end

function PLOT(t, x, L, plotlegend, yaxis, nome_fig)
    linewidth = 1.4;
    plotcol = {'b','r','g','m','k'};
    if L == 1
        plot(t, x, plotcol{1},'LineWidth', linewidth);
    else
        for i = 1:L
            ppp = plot(t, x(:, i), 'Color', plotcol{i},'LineWidth', linewidth);
            ppp.Color(4) = 0.5;
            hold on
        end
    end
    grid on
    xlabel('time [s]');
    ylabel(yaxis);
    xlim([t(1), t(end)]);
    title(nome_fig)
    if isempty(plotlegend) == 0
        legend(plotlegend{1:L})
    end
    % saveas(gcf, strcat('imgs\', nome_fig, '.png'));  % Save as PNG file
end

function PLOT_E(t, e1v, e2v, e3v, e4v, N, plotlegend)
    figure('Name','State space','NumberTitle','off','PaperType','A4')
    set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    subplot(2,2,1)
    PLOT(t, e1v, N, plotlegend,'','e1 = y - y_{ref}')
    subplot(2,2,2)
    PLOT(t, e2v, N, plotlegend,'','e2')
    subplot(2,2,3)
    PLOT(t, e3v, N, plotlegend,'','e3 = \psi - \psi_{des}')
    subplot(2,2,4)
    PLOT(t, e4v, N, plotlegend,'','e4')
end

function PLOT_U(t, u1v, u2v, N, plotlegend)
    figure('Name','Input delta','NumberTitle','off','PaperType','A4')
    subplot(2,1,1)
    PLOT(t, u1v, N, plotlegend,'','u1 \delta')
    subplot(2,1,2)
    % figure('Name','Input psi','NumberTitle','off','PaperType','A4')
    PLOT(t, u2v, N, plotlegend,'','u2 \psi')
end

function PLOT_TRAJ(t, V, dt_sim, Kl, u1v, plotlegend)
    plotcol = {'b','r','g','m','k'};

    th = V*dt_sim*Kl;
    cum_th = cumsum(th);
    ds = V*dt_sim;
    x = ds * cos(cum_th);
    y = ds * sin(cum_th);
    cum_x = cumsum(x);
    cum_y = cumsum(y);
    
    figure('Name','Curvature','NumberTitle','off','PaperType','A4')
    plot(t, Kl, 'b')
    xlim([t(1), t(end)])
    
    figure('Name','Trajectory','NumberTitle','off','PaperType','A4')
    ppp = plot(cum_x, cum_y, plotcol{1});
    ppp.Color(4) = 0.5;
    N=length(u1v(1,:));
    for i=1:N
        cum_th = cumsum(u1v(:,i))/186;
        x = ds * cos(cum_th);
        y = ds * sin(cum_th);
        cum_x = cumsum(x);
        cum_y = cumsum(y);
        hold on
        ppp = plot(cum_x, cum_y, plotcol{i+1});
        ppp.Color(4) = 0.5;
    end
    plotlegend = {'Traj desired', plotlegend{1:N}};
    legend(plotlegend)
    xx = 10;
    yy = xx;


end