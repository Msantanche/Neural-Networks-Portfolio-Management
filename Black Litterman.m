xlsread('C:\Users\marco\Documents\University\TESI\historyIndex.xls','A7:F1501')
Germ=ans(:,1);
It=ans(:,2);
Jap=ans(:,3);
NA=ans(:,4);
UK=ans(:,5);
GermRet=price2ret(Germ)*100;
ItRet=price2ret(It)*100;
JapRet=price2ret(Jap)*100;
NARet=price2ret(NA)*100;
UKRet=price2ret(UK)*100;
[W_MN LABELS]=xlsread('C:\Users\marco\Documents\University\TESI\historyIndex.xls','B7:G7');
DATASET=[GermRet ItRet JapRet NARet UKRet];
%Pesi Market Neutral
k=numel(Germ);
Somma=Germ(k)+It(k)+Jap(k)+NA(k)+UK(k);
W_MN=[Germ(k)/Somma; It(k)/Somma; Jap(k)/Somma; NA(k)/Somma; UK(k)/Somma];
figure,pie3(W_MN,LABELS')
title('Composizione portafoglio Market Neutral')


SIGMA=cov(DATASET);
RISK_FREE=0.0075



LAMBDA=3


% Stima dei rendimenti attesi market neutral
EXP_RET_MN=RISK_FREE+LAMBDA*SIGMA*W_MN
REND_MN=W_MN'*EXP_RET_MN
SIGMA_PORT_MN=sqrt(W_MN'*SIGMA*W_MN)
TAU=1/(numel(GermRet)-1);
TAU_SIGMA=TAU*SIGMA;

%GIAPPONE NEGATIVO
P=[0 0 1 0 0]
Q=[-0.15]
C=[0.25]
OMEGA=zeros(1,1);
for f=1:1

OMEGA(f,f)=((1/C(f,1)-1)*P(f,:)*(TAU_SIGMA)*P(f,:)')
end


REND_BL=inv(inv(TAU_SIGMA)+P'*inv(OMEGA)*P)*(inv(TAU_SIGMA)*EXP_RET_MN+P'*inv(OMEGA)*Q)

%Ottimizzazione
p= Portfolio;
NumPorts=100;
p = setAssetMoments(p, REND_BL, SIGMA);
p = setDefaultConstraints(p);
PortWts = estimateFrontier(p, NumPorts);
[PortRisk, PortReturn] = estimatePortMoments(p, PortWts);
PortWts=estimateMaxSharpeRatio(p)
figure,pie3(PortWts,LABELS')
title('Composizione portafoglio Black-Litterman')
[risk, ret] = estimatePortMoments(p, PortWts);
figure,plotFrontier(p, NumPorts);
hold on
plot(risk,ret,'*r');
hold off

%Grafico dei pesi


GAP=PortWts-W_MN;
figure(1)
subplot(2,2,1)
barh (W_MN)
grid on
title('Pesi MN')
set(gca,'YTickLabel',LABELS)
subplot(2,2,2)
barh (PortWts)
title('Pesi BL')
grid on
 set(gca,'YTickLabel',LABELS)
subplot(2,2,[3 4])
barh (GAP,'r')
title('DELTA pesi BL E MN')
xlim([-0.4 0.4])
grid on
set(gca,'YTickLabel',LABELS)
CONFRONTO=[EXP_RET_MN REND_BL]
