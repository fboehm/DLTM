rm(list=ls())
library(ggplot2)

# User defined inputs
# all directories must end with /
MCMC_directory = "~/DLTM-master/MCMC_Samples/"   #directory for mcmc SAMPLES
output_directory = "~/DLTM-master/Figures/"      #directory for figures
nSim = 5  #number of different simulations run
K = 3     #number of topics
t.T = 5   #total number of time points
V = 1000  #size of the vocabulary
burnIn = 2000  #number of samples to discard as burn-in.  
nSamples = 6000  #total number of MCMC samples

# End of user defined inputs #######################################################

nSamples_wIn =nSamples - burnIn

Beta = list()
Prob_Beta = list()

for(init in 1:nSim){
Prob_Beta[[init]] = list()
ii = init + 0
TV_Beta_truth = matrix(nrow = K, ncol = K)
  for(k in 1:K){
    Beta[[k]]=list()
    Prob_Beta[[init]][[k]]=list()
    tmp = read.csv(paste(MCMC_directory,"Init_",ii,"/Beta_",k,".csv",sep=""),header=F,stringsAsFactors=F)
    for(t in 1:t.T){
      Beta[[k]][[t]] = matrix(0,nrow = nSamples,ncol = V)
      for(i in 1:nSamples){
        index_1 = (i-1)*V + 1
        index_2 = (i-1)*V + V
        Beta[[k]][[t]][i,] = tmp[index_1:index_2,(t+1)]
      }
    
      Prob_Beta[[init]][[k]][[t]] = exp(Beta[[k]][[t]])/apply(exp(Beta[[k]][[t]]),1,sum) 
    }
    
      if(init > 1) for(kk in 1:K) TV_Beta_truth[k,kk] = .5*sum( abs( Prob_Beta[[init]][[k]][[t]][nSamples,] - Prob_Beta[[1]][[kk]][[t]][nSamples,] ) )
  }
  
  if(init > 1){
    topic_matching = sapply(1:K, function(k) which(TV_Beta_truth[,k]==min(TV_Beta_truth[,k])) )
    tmp1 = Prob_Beta[[init]]
    for(s in 1:K) Prob_Beta[[init]][[s]] = tmp1[[ topic_matching[s] ]]
  }
}

TV_Beta = list() 
for(k in 1:K){
  TV_Beta[[k]] = matrix(nrow = (nSim-1), ncol = nSamples)
  rownames(TV_Beta[[k]]) = factor(2:5)
  for(j in 2:nSim ) TV_Beta[[k]][j-1,] = .5*apply(abs( Prob_Beta[[1]][[k]][[1]] - Prob_Beta[[j]][[k]][[1]]), 1, sum)
}


for(k in 1:K){
  pdf(paste(output_directory,"Across_Chain_TV_",k,".pdf",sep=""))
  sa <- stack(as.data.frame( t(TV_Beta[[k]]) ))
  names(sa)[2] = "Chain"
  sa$x <- rep(seq_len(ncol(TV_Beta[[k]])), nrow(TV_Beta[[k]]))
  g = qplot(x, values, data = sa, group = Chain, colour = Chain, geom = "line") + ylim(0,1) + xlab("MCMC Sample") + ylab("TV Distance") + theme(axis.text=element_text(size=20, color = "black"),axis.title=element_text(size=24,face="bold"),legend.text=element_text(size=20) )
  print(g)
  dev.off()
}

#Now compute the within Chain Total Variation distance for 1000 randomly selected ordered pairs or samples

c1 = sample(burnIn:nSamples,nSamples_wIn,replace=T)
c2 = sample(burnIn:nSamples,nSamples_wIn,replace=T)
init = 1
t = 1
TV_Beta_wIn = matrix(nrow = K, ncol = nSamples_wIn)
rownames(TV_Beta_wIn) = factor(1:3)
for(k in 1:K){
  TV_Beta_wIn[k,] = .5*apply(abs( Prob_Beta[[init]][[k]][[t]][c1,] - Prob_Beta[[init]][[k]][[t]][c2,]), 1, sum)
}

pdf(paste(output_directory,"TV_Beta_wIn.pdf",sep="") )
sa <- stack(as.data.frame( t(TV_Beta_wIn) ))
names(sa)[2] = "Topic"
sa$x <- rep(seq_len(ncol(TV_Beta_wIn)), nrow(TV_Beta_wIn))
qplot(x, values, data = sa, group = Topic, colour = Topic, geom = "line") + ylim(0,1) + xlab("MCMC Sample") + ylab("TV Distance") + theme(axis.text=element_text(size=20, color = "black"),axis.title=element_text(size=24,face="bold"), legend.text=element_text(size=20))
dev.off()
