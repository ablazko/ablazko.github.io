---
layout: post
title: Predictive Performance Metrics
categories: blog
tags: [ r, data science ]
date: 2016-05-01 00:00:00 -0300
highlight: [ r ]
---

In this posting I'll discuss a litle bit about some of the predictive performance metrics available. And be aware that for now I'll be focused in the particular context of **predictive modeling** for **binary target**.

When working with data modeling you must have a set of metrics in mind to help you decide if the model is performing well and which model is the "winner". Also, you must be aware about avoid overfiting. These performance metrics will guide you by giving you evidences if you're in the right path or not. If you're done with the modelling process or if you must continue digging and trying.

Before we start getting into more technical, I would like also to point that the choice of the metrics (or metrics!) to use sometimes depends of the context of your goals. Each performance metrics "focus" on (and measure) some particular charactheristic of the data. So you'll find out that your "winner model" could be different ones depending on which metric you want to use.

The R function I wrote to make my life easier during the work can be found <a href="https://github.com/ablazko/R-codes/blob/master/funcGFMmetrics.R" target="_blank">here</a>, with the code to calculate each metric. Hope it can help you too.

```r
# Goodness of Fit Metrics (for prediction models with target [0;1])

funcGFMmetrics = 
function (var.target="", var.prediction="", var.df="")
{
    ...
}
```

One important thing to mention is that for the metrics that requires a `predicted` flag for each row (usuall used as `score>0.5`), this function set the `predicted=1` flag for rows that satisfy `score>mean(score)`, otherwise `predicted=0`.

I'd rather this way since not all of my projects (or approaches) considers a 50/50 balanced response rates.

This is an example of a function call with the results saved in `metrics` object:

```r
metrics = funcGFMmetrics (var.target="target", var.prediction="prob", var.df="df")    
```

A usually set the paramenters input of my function as a *text*, so it is easy to automate the call of a function in some procedures. As a result of the above line of code you get a vector listing all of performance metrics:

```r
> metrics
    AUC        KS      GINI   LogLoss     Kappa        F1  Accuracy ErrorRate Precision    Recall 
0.80267   0.44472   0.60534   0.73523   0.36063   0.79377   0.71722   0.28278   0.89089   0.71575
```

So `metrics` become an object in R session, and if needed you can extract a specific metric just passing its index. To call `KS` value, you do:

```r
> metrics[2]
     KS 
0.44472
```

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
