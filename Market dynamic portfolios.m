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
storewts=zeros(k,5);
for i = 1:k
    Somma=Germ(i)+It(i)+Jap(i)+NA(i)+UK(i);
    storewts(i,:) = [Germ(i)/Somma; It(i)/Somma; Jap(i)/Somma; NA(i)/Somma; UK(i)/Somma];
end
figure,area(storewts)
xlim([1 1044])
ylim([0 1])
title('Composizione portafogli Market Neutral dinamici')
legend(LABELS)