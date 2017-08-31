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
%Dati (preparazione)
%Ricorda di aggiungere la cartella pyrenn:
%Home - Environment - set path - seleziona la cartella "matlab" - save
P=GermRet(1:880);
T=GermRet(2:881);
P_Test=GermRet(881:1042);
T_Test=GermRet(882:1043);
dIn=0;
dIntern=2;
dOut=1;
ytest_LM=zeros(162,3);
ytest_LMd=zeros(162,3);
zy=zeros(162,3);
zyd=zeros(162,3);
%10 neuroni
nn=[1 10 10 1];
netd=CreateNN(nn,dIn,dIntern,dOut);
for i=1:880
    netLMd = train_LM(P(i),T(i),netd,100,1e-5);
end
for i=1:162
    ytest_LMd(i,1)=NNOut(P_Test(i),netLMd);
end
zyd(:,1)=zscore(ytest_LMd(:,1))
figure,plot(zyd(:,1))
hold on
plot(T_Test,'r')
hold off
title(['Performance di una rete con 10 neuroni'])

% 5 neuroni
nn=[1 10 5 1];
netd=CreateNN(nn,dIn,dIntern,dOut);
for i=1:880
    netLMd = train_LM(P(i),T(i),netd,100,1e-5);
end
for i=1:162
    ytest_LMd(i,2)=NNOut(P_Test(i),netLMd);
end
zyd(:,2)=zscore(ytest_LMd(:,2))
figure,plot(zyd(:,2))
hold on
plot((T_Test-mean(T_Test)),'r')
hold off
title(['Performance di una rete con 5 neuroni'])

%20 neuroni
nn=[1 10 20 1];
netd=CreateNN(nn,dIn,dIntern,dOut);
for i=1:880
    netLMd = train_LM(P(i),T(i),netd,100,1e-5);
end
for i=1:162
    ytest_LMd(i,3)=NNOut(P_Test(i),netLMd);
end
zyd(:,3)=zscore(ytest_LMd(:,3))
figure,plot(zyd(:,3))
hold on
plot(T_Test,'r')
hold off
title(['Performance di una rete con 20 neuroni'])
%ERRORI
err10=sqrt(mean((zy(:,1)-T_Test).^2))
err5=sqrt(mean((zy(:,2)-T_Test).^2))
err20=sqrt(mean((zy(:,3)-T_Test).^2))
err10_d=sqrt(mean((zyd(:,1)-T_Test).^2))
err5_d=sqrt(mean((zyd(:,2)-T_Test).^2))
err20_d=sqrt(mean((zyd(:,3)-T_Test).^2))