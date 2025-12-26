function plot_step(gs, figurenum)
    t = 0:0.001:50;
    figure(figurenum); hold on; grid on;
    gs_step = step(gs,t);
    plot(t, gs_step);
    xlabel('Time(s)');
    title('Step Response');
end