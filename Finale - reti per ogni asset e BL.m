clear all
PREZZI=xlsread('C:\Users\marco\Documents\University\TESI\historyIndex.xls','A7:F1501')
[W_MN LABELS]=xlsread('C:\Users\marco\Documents\University\TESI\historyIndex.xls','B7:G7');
Germ=PREZZI(:,1);
It=PREZZI(:,2);
Jap=PREZZI(:,3);
NA=PREZZI(:,4);
UK=PREZZI(:,5);
GermRet=price2ret(Germ);
ItRet=price2ret(It);
JapRet=price2ret(Jap);
NARet=price2ret(NA);
UKRet=price2ret(UK);
DATASET=[GermRet ItRet JapRet NARet UKRet]*100;
%Dati (preparazione)
%Ricorda di aggiungere la cartella pyrenn:
%Home - Environment - set path - seleziona la cartella "matlab" - save
n=round(numel(GermRet)*0.85);
m=round(numel(GermRet)*0.15);
OMEGA=zeros(5,5);
RISK_FREE=0.0075;
LAMBDA=4.5;
R_Squared=zeros(1,5);
%Portafogli mercato dinamici
storewts_MN=zeros(1044,5);
for i = 1:1044
    Somma=Germ(i)+It(i)+Jap(i)+NA(i)+UK(i);
    storewts_MN(i,:) = [Germ(i)/Somma; It(i)/Somma; Jap(i)/Somma; NA(i)/Somma; UK(i)/Somma];
end
%RETE
%Per tutti i 156 giorni
T = tonndata(PREZZI(1:887,:),false,false);

trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation.

% Create a Nonlinear Autoregressive Network
feedbackDelays = 1:2;
hiddenLayerSize = 10;
net = narnet(feedbackDelays,hiddenLayerSize,'open',trainFcn);

[x,xi,ai,t] = preparets(net,{},{},T);

% Setup Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

% Train the Network
[net,tr] = train(net,x,t,xi,ai);
y=net(x);
y=cell2mat(y);
R_Squared=zeros(1,5);
for i=1:5
    r=corrcoef(y(i,:),PREZZI(1:885,i));
    R_Squared(:,i)=r(1,2)^2;
end
R_Squared
%Test the Network

nets = removedelay(net);
T=tonndata(PREZZI(886:1043,:),false,false);
[xs,xis,ais,ts] = preparets(nets,{},{},T);
ys = nets(xs,xis,ais);
ts=cell2mat(ts);
ys=cell2mat(ys);
ret=zeros(156,5);
%CONVERSIONE PREZZI IN RENDIMENTI
for i=1:5
    ret(:,i)=price2ret(ys(i,:))*100;
end
confret=price2ret(PREZZI(887:1043,:))*100;%Il suo primo elemento è l'887esimo rendimento,
                                           %ricavabile dall'888esimo prezzo.
%ERRORI
TAU=1/(886);
SIGMA=cov(DATASET(1:887,:));
TAU_SIGMA=TAU*SIGMA;
for j=1:156
W_MN=storewts_MN(j+886,:);
EXP_RET_MN=RISK_FREE+LAMBDA*SIGMA*W_MN';
REND_MN=W_MN*EXP_RET_MN;
SIGMA_PORT_MN=sqrt(W_MN*SIGMA*W_MN');
%Rendimenti BL
P_BL=[1;1;1;1;1];
Q=ret(j,:);
%MATRICE OMEGA
for i=1:5
    OMEGA(i,i)=var(DATASET(1:j+886,i))*(1-R_Squared(:,i));
end
REND_BL=inv(inv(TAU_SIGMA)+P_BL'*inv(OMEGA)*P_BL)*(inv(TAU_SIGMA)*EXP_RET_MN+P_BL'*inv(OMEGA)*Q');
%Ottimizzazione
p=Portfolio;
NumPorts=100000;
p = setAssetMoments(p, REND_BL, SIGMA);
p = setDefaultConstraints(p);
PortWts=estimateMaxSharpeRatio(p);
[PortRisk, PortReturn] = estimatePortMoments(p, PortWts);
storewts_BL(j,:)=PortWts;
end
%FINE OTTIMIZZAZIONE BL CON RETE
figure,area(storewts_BL)
xlim([0 156])
ylim([0 1])
title('Composizione portafogli Black-Litterman con rete')
legend(LABELS)
figure,area(storewts_MN)
xlim([0 156])
ylim([0 1])
%%%%%%%Confronto investimento
ret_store_mn=zeros(157,1);
ret_store_mn(1,1)=0;
ret_store_bl=zeros(157,1);
ret_store_bl(1,1)=0;
for i=1:m
    a=(storewts_BL(i,:)*DATASET(n+i,:).');
    b=(storewts_MN(n+i-2,:)*DATASET(n+i,:).');
    ret_store_bl(i+1)=a;
    ret_store_mn(i+1)=b;
end
C=100;
C_MN=100;
Cap_store=zeros(157,2);
for i=1:157
    C=C*exp(ret_store_bl(i)/100);
    C_MN=C_MN*exp(ret_store_mn(i)/100);
    Cap_store(i,1)=C;
    Cap_store(i,2)=C_MN;
end
plot(Cap_store(:,1))
hold on
plot(Cap_store(:,2),'r')
hold off
title('Performance investimento Black-Litterman con rete (fiducia massima) vs Market Neutral')
%%%%%%%%%%%%%%%%%%%%%%%%%%%ARIMA
CONFIDENCE=zeros(156,5);
pred_arima=zeros(157,5);
Mdl=arima(1,1,1);
for j=1:m
    for z=1:5
    P=DATASET(1:(j+n-1),z);
    EstMdl = estimate(Mdl, P);
    pred_arima(j,z)=forecast(EstMdl,1);
    h=forecast(EstMdl,2);
    pred_arima(j+1,z)=h(2,:);
    CONFIDENCE(j,z)=var(DATASET(:,z))/EstMdl.Variance;
    end
end
pred_arima(end,:)=pred_arima(end,:)/2;
dpred_arima=diff(pred_arima);
zpred_arima=zscore(dpred_arima);
zGermRet=zscore(GermRet);
%TRASFORMO IN NON NORMALIZZATI
for u=1:5
shakhtar=dpred_arima*1000*std(DATASET(:,u))+mean(DATASET(:,u));
end
donetsk=shakhtar-mean(shakhtar);
plot(donetsk(:,1))
hold on
plot(GermRet(n+1:end,:),'r')
hold off
title('Previsione dei rendimenti con metodo ARIMA')
%%%%%%%%%%%%%%%%%BLACK-LITTERMAN ARIMA
for j=1:m
SIGMA=cov(DATASET(1:(n-m+155+j),:));
TAU=1/(j+n-1);
TAU_SIGMA=TAU*SIGMA;
W_MN=storewts_MN(n-m+155+j,:);
EXP_RET_MN=RISK_FREE+LAMBDA*SIGMA*W_MN';
REND_MN=W_MN*EXP_RET_MN;
SIGMA_PORT_MN=sqrt(W_MN*SIGMA*W_MN');
for i=1:5
OMEGA(i,i)=(CONFIDENCE(j,i));
end
%Rendimenti BL
Q=transpose(donetsk(j,:));
REND_BL=inv(inv(TAU_SIGMA)+P_BL'*inv(OMEGA)*P_BL)*(inv(TAU_SIGMA)*EXP_RET_MN+P_BL'*inv(OMEGA)*Q);
%Ottimizzazione
p= Portfolio;
NumPorts=100;
p = setAssetMoments(p, REND_BL, SIGMA);
p = setDefaultConstraints(p);
PortWts = estimateFrontier(p, NumPorts);
[PortRisk, PortReturn] = estimatePortMoments(p, PortWts);
PortWts=estimateMaxSharpeRatio(p);
storewts_BL_arima(j,:)=PortWts;
end
%CONFRONTO FINALE
ret_store_arima=zeros(157,1);
ret_store_arima(1,1)=0;

for i=1:m
    c=(storewts_BL_arima(i,:)*DATASET(n+i,:).');
    ret_store_bl_arima(i+1)=c;
end
C_ARIMA=100;
for i=1:157
    C_ARIMA=C_ARIMA*exp(ret_store_bl_arima(i)/100);
    Cap_store(i,3)=C_ARIMA;
end
plot(Cap_store(:,1))
hold on
plot(Cap_store(:,3),'r')
hold off
title('Performance investimento Black-Litterman con ARIMA vs Market Neutral')
%GRAFICI
figure,area(storewts_BL_arima)
xlim([0 156])
ylim([0 1])
title('Composizione portafogli Black-Litterman con ARIMA')
legend(LABELS)
m=mean(storewts_BL);
for i=1:5
    if m(1,i)<0
        m(1,i)=0.01
    end
end
pie3(m)
legend(LABELS,'Location','southeast')
title('Composizione media portafogli Black-Litterman con rete')
pie3(mean(storewts_MN))
legend(LABELS,'Location','southeast')
title('Composizione media portafogli Market Neutral')
pie3(mean(storewts_BL_arima))
legend(LABELS,'Location','southeast')
title('Composizione media portafogli Black-Litterman con ARIMA')
plot(ret(:,1))
hold on
plot(confret(:,1))
hold off
title('Previsione dei rendimenti col metodo NAR')
%VaR dei tre metodi
VaR_store=ones(156,4);
HIST_RET=zeros(1043,1);
for i=1:m
    for j=2:(i+887)
        HIST_RET(j,1)=storewts_MN(j-1,:)*DATASET(j,:)';
    end
    HIST_RET(1,1)=0;
    SORTED=sort(HIST_RET);
    VaR_store(i)=SORTED(round(0.05*numel(SORTED)));
end
plot(ret_store_bl)
hold on
plot(VaR_store(:,1),'r')
hold off
title('Violazioni VaR - portafoglio con rete neurale')
plot(ret_store_mn)
hold on
plot(VaR_store(:,1),'r')
hold off
title('Violazioni VaR - portafoglio market neutral')
plot(ret_store_bl_arima)
hold on
plot(VaR_store(:,1),'r')
hold off
title('Violazioni VaR - portafoglio con ARIMA')
%GAP TRA PESI DEI PORTAFOGLI

GAP=mean(storewts_BL)-mean(storewts_MN);
figure(1)
subplot(2,2,1)
barh (mean(storewts_MN))
grid on
title('Pesi MN')
xlim([-0.6 0.6])
set(gca,'YTickLabel',LABELS)
subplot(2,2,2)
barh (mean(storewts_BL))
title('Pesi BL rete')
xlim([-0.6 0.6])
grid on
 set(gca,'YTickLabel',LABELS)
subplot(2,2,[3 4])
barh (GAP,'r')
title('DELTA pesi BL E MN')
xlim([-0.8 0.8])
grid on
set(gca,'YTickLabel',LABELS)
%Gap tra rendimenti BL ARIMA e portafogli di mercato
GAP=mean(storewts_BL_arima)-mean(storewts_MN);
figure(1)
subplot(2,2,1)
barh (mean(storewts_MN))
grid on
title('Pesi MN')
xlim([-0.6 0.6])
set(gca,'YTickLabel',LABELS)
subplot(2,2,2)
barh (mean(storewts_BL_arima))
title('Pesi BL ARIMA')
xlim([-0.6 0.6])
grid on
 set(gca,'YTickLabel',LABELS)
subplot(2,2,[3 4])
barh (GAP,'r')
title('DELTA pesi BL E MN')
grid on
set(gca,'YTickLabel',LABELS)
xlim([-0.8 0.8])