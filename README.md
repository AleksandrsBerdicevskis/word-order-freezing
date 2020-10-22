# word-order-freezing
This repository contains the files that are necessary to reproduce the study described in:

Berdicevskis, Aleksandrs and Alexander Piperski. 2020. Corpus evidence for word order freezing in Russian and German. In Proceedings of the Fourth Workshop on Universal Dependencies (UDW 2020).

## scripts
- analyzer.rb is the script that performs the rule-based analysis described in Section 3. It uses UD corpora as input (to recreate ours, use UD 2.6, concatenate all treebanks for Russian and HDT+GSD for German) and output file [language]_analyzed.csv)

- postanalyzer.rb extracts data provided in Table 1 (run ruby postanalyzer.rb language marking) and Table 2 (ruby postanalyzer.rb language wo6)

- bootstrap.rb performs the bootstrap tests described in Section 4

- regr.r performs the mixed-effects logistic regression analysis described in Section 4. Make sure that lmerTest package is installed

- boxplots.r creates Figure 1.

## data
- [language]_analyzed.csv is the output of analyzer.rb. It has the following columns: marked (whether the clause has morphological marking or not); sent_id; subj(ect); obj(ect); verb; subj_marked (whether the morphological marking on subject is enough to disambiguate the clause); criterion_subj (on the basis of which criterion does the algorithm make the decision, see description of the algorithm in the paper); obj_marked; criterion_obj; verb_marked; criterion_verb; wo (word order of S, V, O); sent_text; clause_type (main or subordinate); subclause_type (the relation which introduces the subordinate) clause; subj_pos; obj_pos; subj_anim (only for Russian); obj_anim (only for Russian); subj_case; obj_case; wo_so (word order of S and O); demoted_verb (in construction with auxiliary verb we are looking for the marking on the auxiliary, the lemma of the "demoted" main verb is listed here for information); verb_lemma

- Russian_analyzed_evaluation.csv, German_analyzed_evaluation.xlsx: manually evaluated random samples;

- Russian_wo6stats.csv, German_wo6stats.csv, Russian_markingmeans.csv, German_markingmeans.csv: outputs of postanalyzer.rb

- bsger.tsv, bsrus.tsv: outputs of bootstrap.rb (NB: this is a randomized test, so you will get different results if you rerun the script)