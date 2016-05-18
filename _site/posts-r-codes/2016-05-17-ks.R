

# Load data ----

    rootPath   = '/Users/andre_blazko/Documents/_Sleek-Data/projects/kaggle-03-bnp-paribas'

    library(data.table)
    library(dplyr)

    # Variables ID & TARGET
    v_var_ids = c("ID")
    v_var_target = c("target")

    # Load dataframes
    ds_features_metadata = readRDS(file=paste(rootPath, "data-work/ds_features_metadata.RDS", sep="/"))
    ds_train = readRDS(file=paste(rootPath, "data-work/ds_train.RDS", sep="/"))
    ds_train_d = readRDS(file=paste(rootPath, "data-work/ds_train_d.RDS", sep="/"))

# SCENARIO 02 :: 'LOGISTIC' ----
    
    # Get the predictors and the true levels (bins) of predictors (observed in 'training' set)
    tmp = summarise(
         group_by(ds_features_metadata[ds_features_metadata$sleekIndex>0.001,], varname)
    )
    v_candidates = paste0("dhr_", c(tmp$varname))
    
    # Parameters
    ds_ref = subset(ds_train_d, select=c(union(v_var_ids, union(v_var_target, v_candidates))))                   # dataframe of reference
    
    # Turning variables into factor variables
    for (k in v_var_target)
    {
        set( ds_ref, j=k, value=factor(ds_ref[[k]], levels=c(0,1)) )
    }
    rm(k)
    
    # Training the model
        
    # Sampling the training set
    set.seed(123)
    trainindex          = sample(1:nrow(ds_ref), trunc(0.70*nrow(ds_ref))) # 70/30 of train / valid
    
    tmp_train           = ds_ref[trainindex, ]
    tmp_train$Scenario  = "Train"
    
    tmp_valid           = ds_ref[-trainindex, ]
    tmp_valid$Scenario  = "Valid"
    
    # Get the indexes of the respective columns in the train dataset
    v_index_target     = match(v_var_target, colnames(tmp_train))
    v_index_candidates = match(v_candidates, colnames(tmp_train))
    
    # Calculate the propabilities
    Sys.time()
    set.seed(123)
    assign (
        "model"
       ,glm(  as.formula(
                     paste(colnames(tmp_train)[v_index_target], " ~ "
                    ,paste(colnames(tmp_train)[v_index_candidates], collapse=" + "), sep="")
                )
                ,data=tmp_train
                ,family="binomial"
        )
    )
    Sys.time()
    model
    
    # Scoring TRAIN
    tmp_train$pred = predict(model, newdata=tmp_train, type="response")
    funcGFMmetrics (var.target=v_var_target, var.prediction="pred", var.df="tmp_train")
    #     AUC        KS      GINI   LogLoss     Kappa        F1  Accuracy ErrorRate Precision    Recall 
    # 0.82913   0.48114   0.65826   0.77364   0.40113   0.81346   0.74074   0.25926   0.89988   0.74219 
    
    # Scoring VALID
    tmp_valid$pred = predict(model, newdata=tmp_valid, type="response")
    funcGFMmetrics (var.target=v_var_target, var.prediction="pred", var.df="tmp_valid")
    #     AUC        KS      GINI   LogLoss     Kappa        F1  Accuracy ErrorRate Precision    Recall 
    # 0.82547   0.47744   0.65095   0.76664   0.39905   0.81350   0.74053   0.25947   0.89661   0.74450
    
    tmp_all = rbind(tmp_train, tmp_valid)
    q1 = funcGFMplotKS(var.target=v_var_target, var.prediction="pred", var.df="tmp_train", var.fsize=3)
    q2 = funcGFMplotKS(var.target=v_var_target, var.prediction="pred", var.df="tmp_valid", var.fsize=3)
    
    # Save the plots
    outPath   = '/Users/andre_blazko/Documents/github/ablazko.github.io/posts-img'

    ggsave(plot=q1
       ,filename=paste0(outPath,"/2016-05-17-ks-curve-img1.png")
       ,width=10, height=6, units="in", dpi=100
    )
    
    ggsave(plot=q2
       ,filename=paste0(outPath,"/2016-05-17-ks-curve-img2.png")
       ,width=10, height=6, units="in", dpi=100
    )
    
    