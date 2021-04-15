close all;
clear all;

load acc;
acc_N=acc(:,1);
acc_S=acc(:,2);
acc_E=acc(:,3);
acc_W=acc(:,4);
acc_T=acc(:,5);

load integ;
integ_N=integ(:,1);
integ_S=integ(:,2);
integ_E=integ(:,3);
integ_W=integ(:,4);

load limit
limit_N=limit(:,1);
limit_S=limit(:,2);

nb_acc=acc_T(end);
m_N=acc_N(nb_acc);
m_S=acc_S(nb_acc);
m_E=acc_E(nb_acc);
m_W=acc_W(nb_acc);

figure;
data=[m_N, m_S, m_E, m_W];
bar(data/nb_acc);
ylim([0 6]);

figure;
hold on;
plot(integ_N);
plot(integ_S);
plot(integ_E);
plot(integ_W);
ylim([-1 6]);
legend ({"Nord", "Sud", "Est", "Ouest"});

figure
hold on;
plot(limit_N);
plot(limit_S, 'r');
legend ({"Nord", "Sud"});
