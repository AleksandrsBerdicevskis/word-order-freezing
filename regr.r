library("lmerTest")

ds <- read.csv("Russian_analyzed.csv",sep="\t",header=TRUE,quote="",encoding="UTF-8")
ds$wo2 <- relevel(as.factor(ds$wo_so), ref="SO")
ds$marked2 <- relevel(as.factor(ds$marked),ref="true")
mdl <- glmer(as.factor(wo2) ~ marked2 + (1 + marked2|verb_lemma), data=ds, family=binomial)
summary(mdl)