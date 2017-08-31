library(nnet)
library(readxl)
library(RSNNS)
library(Rcpp)
library(minpack.lm)
historyIndex <- read_excel("~/Università/TESI/historyIndex.xls", 
                           skip = 5)
n=ncol(historyIndex)
data<-historyIndex[,2:n]
date<-labels(historyIndex[,1])
k=nrow(data)
my=ts(data[1:k,])
Germ<-my[,1]
Germdiff<-diff(Germ)
GermRet<-matrix(nrow=1043,ncol=1)
for (i in 1:1043){
  GermRet[i]<-(Germdiff[i]/Germ[i])*100
}
GermRet<-ts(normalizeData(GermRet))
plot(GermRet)


#Per addestramento rete:
trainset<-ts(GermRet[1:782],start=1)
traincont<-ts(GermRet[2:783],start=1)
#Per test rete:
testset<-ts(GermRet[784:1043],start=1)
inputsTest<-ts(GermRet[783:1042],start=1)
#rete:
model<-elman(trainset,traincont,size=10,maxit=100,initFunc="JE_Weights", learnFunc="JE_BP",
             learningFuncParams=c(0.001),updateFunc="BPTT_Order",inputsTest=inputsTest,
             targetsTest=testset,linOut=TRUE)
plot(ts(testset))
t<-ts(normalizeData(model$fittedTestValues),start=1)
lines(ts(-t, start=-1),col="red")
#errore rete:
tr<-ts(normalizeData(model$fitted.values))
train.mfe<-sqrt(mean((tr-traincont)^2))
train.mfe
mfe<-sqrt(mean((t-testset)^2))
mfe

#Confronto con GARCH
library(fGarch)
pred.garch<-matrix(nrow=260,ncol=1)
dati.garch<-GermRet
for (i in 1:261){
  dati<-dati.garch[1:(782+i)]
  garch.model = garchFit(~ garch(1,1), data =dati, trace = FALSE)
  garchf<-predict(garch.model,n.ahead=1)
  pred.garch[i]<-garchf$meanForecast
}
pred.garch<-normalizeData(diff(pred.garch))
plot(ts(pred.garch))
lines(testset,col='red')
garch.err<-sqrt(mean((pred.garch-testset)^2))
garch.err

#Errore medio, 100 simulazioni
errstore=matrix(nrow=100,ncol=1)
for (i in 1:100){
#rete:
model<-elman(trainset,traincont,size=10,maxit=100,initFunc="JE_Weights", learnFunc="JE_BP",
             learningFuncParams=c(0.001),updateFunc="BPTT_Order",inputsTest=inputsTest,
             targetsTest=testset,linOut=TRUE)
t<-ts(normalizeData(model$fittedTestValues),start=1)
#errore rete:
tr<-ts(normalizeData(model$fitted.values))
train.mfe<-sqrt(mean((tr-traincont)^2))
train.mfe
mfe<-sqrt(mean((t-testset)^2))
errstore[i,]=mfe
}
plot(hist(errstore))
max(errstore)
min(errstore)
mean(errstore)
median(errstore)
