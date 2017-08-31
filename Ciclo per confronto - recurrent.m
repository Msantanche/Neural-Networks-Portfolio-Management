%CICLO LM-GDS per confronto tra reti
xlsread('C:\Users\marco\Documents\Università\TESI\historyIndex.xls','A7:F1501')
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
P=GermRet(1:880);
T=GermRet(2:881);
P_Test=GermRet(881:1042);
T_Test=GermRet(882:1043);
dIn=0;
dIntern=2;
dOut=1;
ytest_LMd=zeros(162,3);
zy=zeros(162,3);
zyd=zeros(162,3);
%Rete
nn=[1 10 10 1];
err=zeros(100,1)
netd=CreateNN(nn,dIn,dIntern,dOut);
%Ciclo
for i=1:100
for j=1:880
    netLMd = train_LM(P(j),T(j),netd,100,1e-5);
end
for k=1:161
    ytest_LMd(k,1)=NNOut(P_Test(k),netLMd);
end
zyd(:,1)=zscore(-ytest_LMd(:,1))
%ERRORE
err(i)=sqrt(mean((zy(:,1)-T_Test).^2))
end
err_dest=err*std(ytest_LMd)+mean(ytest_LMd)
hist(err_dest(:,1))
mean(err_dest(:,1))
min(err_dest(:,1))
max(err_dest(:,1))
median(err_dest(:,1))