---
layout: post
title: Predictive Performance Metrics
categories: blog
tags: [ r, data science ]
date: 2016-05-01 00:00:00 -0300
highlight: [ r ]
---

In this posting I'll discuss a litle bit about some of the predictive performance metrics available. And be aware that for now I'll be focused in the particular context of **predictive modeling** for **binary target**.

When working with data modeling you must have a set of metrics in mind to help you decide if the model is performing well and which model is the "winner". Also, you must be aware about avoid overffiting. These performance metrics will guide you by giving you evidences if you're in the right path or not. If you're done with the modelling process or if you must continue digging and trying.

Before we start getting into more technical, I would like also to point that the choice of the metrics (or metrics!) to use sometimes depends of the context of your goals. Each performance metrics "focus" on (and measure) some particular charactheristic of the data. So you'll find out that your "winner model" could be different ones depending on which metric you want to use.

This is a R function I wrote to make my life easier during the work, with the code to calculate each metric. Hope it can help you too.

```
# Goodness of Fit Metrics (for prediction models with target [0;1])

funcGFMmetrics = 
function (var.target="", var.prediction="", var.df="")
{
    # Mandatory library
    library(reshape2) # upload 'reshape2' package
    
    # Dataframe preparation
    df = subset(eval(parse(text=var.df)), select=c(var.target, var.prediction))
    colnames(df)[1]="Target"
    colnames(df)[2]="Score"
    
    # Baisc sanity tests
    if (nrow(df)>=50)                  {san_test1="ok"} else {san_test1="nok"}
    if (length(unique(df$Target))==2 ) {san_test2="ok"} else {san_test2="nok"}
    
    if (san_test1=="ok" & san_test2=="ok")
    {
        # Dataframe preparation
        df = df[order(-df$Score), ]
        df$Percentile = round((floor(1:dim(df)[1] * 500 / (dim(df)[1]+1)) + 1) * (100/500), 0)
        df$Predicted = with(df, as.factor(ifelse(Score>=mean(Score), 1, 0)))
        
        # Precision, Recall, F1, Accuracy calculation
        confusionMatrix = c(table(df$Predicted, df$Target))
        TN = confusionMatrix[1]
        FP = confusionMatrix[2]
        FN = confusionMatrix[3]
        TP = confusionMatrix[4]
        
        # Accuracy and Error Rate calculation
        var.Accuracy = (TP + TN) / sum(confusionMatrix)
        var.ErrorRate = 1 - var.Accuracy
        
        # Kappa calculation (agreement level between prediction and true labels)
        pr_e = ((TN + FP) / sum(confusionMatrix)) * ((TN + FN) / sum(confusionMatrix)) +
               ((FN + TP) / sum(confusionMatrix)) * ((FP + TP) / sum(confusionMatrix))
        var.Kappa = (var.Accuracy - pr_e) / (1 - pr_e)
        
        # Precision, Recall and F1 calculation
        var.Precision = TP / (TP + FP) # equals 'predicted' hit rate   
        var.Recall = TP / (TP + FN)    # equals sensitivity = 'true' hit rate
        var.F1 = (2 * var.Precision * var.Recall) / (var.Precision + var.Recall) # harmonic mean
        
        # Logloss calculation (uncertainty of the probabilities of the model by comparing them to the true labels)
        pred1 = c(df$Score)
        pred2 = 1 - pred1
        pred <- cbind(pred1,pred2)
        
        act1 <- c(pred1 / pred1)
        act2 <- c(pred1 - pred1)
        act <- cbind(act1,act2)
    
        eps = 1e-15;
        nr = nrow(pred)
        pred = matrix(sapply( pred, function(x) max(eps,x)), nrow = nr)      
        pred = matrix(sapply( pred, function(x) min(1-eps,x)), nrow = nr)
        ll = sum(act*log(pred) + (1-act)*log(1-pred))
        var.LogLoss = ll * -1/(nrow(act))
        
        # Basic counts calculation for next metrics
        df = aggregate(. ~ Target + Percentile, data=df, function(x) length(x))
        colnames(df)[3]="Count"
        df = reshape2::dcast(df, Percentile ~ Target, value.var="Count")
        colnames(df)[2]="N_0"
        colnames(df)[3]="N_1"
        df$N_0 = ifelse(is.na(df$N_0), 0, df$N_0)
        df$N_1 = ifelse(is.na(df$N_1), 0, df$N_1)
    
        # KS calculation
        df$pctCol_1_acm = cumsum(df$N_1) / sum(df$N_1) # true-positive (Sensitivity)
        df$pctCol_0_acm = cumsum(df$N_0) / sum(df$N_0) # false-positive
        df$abs_dif = abs(df$pctCol_1_acm - df$pctCol_0_acm)      # temporary
        var.KS = max(df$abs_dif)
    
        # AUC and GINI calculation
        df$Xtime  = df$pctCol_0_acm # False Positive Rate
        df$Yvalue = df$pctCol_1_acm # Sensitivity
    
        df$LagTime  = c(rep(NA, 1), df$Xtime)[1:length(df$Xtime)]    # ~lag() function in R
        df$LagValue = c(rep(NA, 1), df$Yvalue)[1:length(df$Yvalue)]  # ~lag() function in R
    
        df$LagTime  = ifelse(is.na(df$LagTime), 0, df$LagTime)
        df$LagValue = ifelse(is.na(df$LagValue), 0, df$LagValue)
    
        df$LagTime  = ifelse(df$Xtime==0, 0, df$LagTime)
        df$LagValue = ifelse(df$Xtime==0, 0, df$LagValue)
    
        df$Trapezoid = (df$Xtime-df$LagTime)*(df$Yvalue+df$LagValue)/2
        df$SumTrapezoid = cumsum(df$Trapezoid)
    
        var.AUC  = max(df$SumTrapezoid)
        var.GINI = 2 * max(df$SumTrapezoid) - 1
        
        # Salve the performance metrics in a vector
        var.FitMetrics = c(var.AUC, var.KS, var.GINI, var.LogLoss, var.Kappa, var.F1, var.Accuracy, var.ErrorRate, var.Precision, var.Recall)
        var.FitMetrics = round(var.FitMetrics, 5)
        names(var.FitMetrics) = c("AUC", "KS", "GINI", "LogLoss", "Kappa", "F1", "Accuracy", "ErrorRate", "Precision", "Recall")
        return(var.FitMetrics)
        
    } else
    {
        cat("\nWARNING: data frame must have >= 50 rows AND target variable must be of length 2!\n")
    }
}
```

One important thing to mention is that for the metrics that requires a `predicted` flag for each row (usuall used as `score>0.5`), this function set the `predicted=1` flag for rows that satisfy `score>mean(score)`, otherwise `predicted=0`.

I'd rather this way since not all of my projects (or approaches) considers a 50/50 balanced response rates.

This is an example of a function call with the results saved in `metrics` object:

    metrics = funcGFMmetrics (var.target="target", var.prediction="prob", var.df="df")

A usually set the paramenters input of my function as a *text*, so it is easy to automate the call of a function in some procedures. As a result of the above line code you get a vector listing all of performance metrics:

        AUC        KS      GINI   LogLoss     Kappa        F1  Accuracy ErrorRate Precision    Recall 
    0.80267   0.44472   0.60534   0.73523   0.36063   0.79377   0.71722   0.28278   0.89089   0.71575

So `metrics` become an object in R session, and if needed you can extract a specific metric just passing its index. To call `KS` value, you do:

    > metrics[2]
         KS 
    0.44472

I'm supposing you're familiar with the definition of such metrics, so this is just a little hint of the meaning of these measures:

- AUC        = total area under the ROC Curve
- KS         = maximum distance between cumulative distributions frequencies of the target and no-target
- GINI       = measure the inequality level among values of the frequency distribution between target and no-target
- Logloss    = uncertainty of the probabilities of the model by comparing them to the true labels
- Kappa      = agreement level between prediction and true labels
- F1         = harmonic mean between Precision and Recall measures
- Accuracy   = overall accuracy of the model considering target and no-target predictions
- Error Rate = overall error of the model considering target and no-target predictions
- Precision  = 'predicted' hit rate
- Recall     = 'true' hit rate

That's all folks! ;-)
<br><br>
