# -*- coding: utf-8 -*-

STDERR.puts "Usage: ruby analyzer.rb language [path_to_corpora]. If no path is given, the default one is used"

def entropy(hash,total)
    entr = 0.0
    #normalizer=hash.keys.length
    #if normalizer > 1
        hash.each_value do |v|
            if v > 0
            entr += (v/total)*Math.log2(v/total)
        end
        end
    
        entr = -entr#/Math.log2(normalizer) 
    #end
    return entr
end

def find_wo(v,s,o)
    if v < s
        if v < o
        if s < o
            order = "VSO"
        else
            order = "VOS"
        end
    else 
        order = "OVS"
    end
    else
        if s < o
        if v < o
            order = "SVO"
        else
            order = "SOV"
        end
    else
        order = "OSV"
    end
    end
    return order
end

# this method checks whether a single noun (subject or object) is marked by looking at its own properties and whether it has an adjectival modifier.
def marked(line2, sent_id, amodded, language, feats2)
    #STDERR.puts line2.join("\t")
    
    
    form = line2[1]
    lemma = line2[2]
    rel = line2[7]
    
    
    marked = "unknown"
    reason = ""

    if language.include?("Russian")
        marked = "true" 
        #by gender
        if feats2["Gender"] == "Masc"
            if feats2["Animacy"] == "Inan"
                marked = "false" 
                reason = "NP syncretism: Inan Masc"
            else
                if !"абвгджзйклмнпрстфхцчшщья".include?(lemma[-1])
                    marked = "false"
                    reason = "Indeclinable: Anim Masc: lemma ends in #{lemma[-1]}" 
                end 
            end
        elsif feats2["Gender"] == "Fem"
            if lemma[-1] == "ь" and !(feats2["Number"]=="Plur" and feats2["Animacy"]=="Anim")
                marked = "false"
                if feats2["Number"]=="Plur"
                    reason = "NP syncretism: Fem Nom=Acc (third declension, plural)"
                elsif feats2["Number"]=="Sing"
                    reason = "Nominal syncretism: Fem Nom=Acc (third declension, singular)"
                end
            elsif !"ая".include?(lemma[-1]) 
                marked = "false"
                reason = "Indeclinable: Fem Nom=Acc"
            elsif (feats2["Animacy"] == "Inan" and feats2["Number"]=="Plur")
                marked = "false"
                reason = "NP syncretism: Fem Nom=Acc (Inan Plur)"
            end
            
        elsif feats2["Gender"] == "Neut"
            if !(feats2["Animacy"] == "Anim" and feats2["Number"]=="Plur")
                marked = "false"
                reason = "NP syncretism: Neut Inan"
                #add checking by a dictionary list here?
                #OR OUTPUT FOR MANUAL CONTROL?
            end 
        else #данные, позывные, сша, g etc.
            #STDERR.puts "Unknown gender: #{lemma}!"
            marked = "false" 
            reason = "NP syncretism: Plur Tant"
        end
        
        #sanity check; not really used, since it's covered by the previous conditions
        if marked == "true" and rel == "obj"
            if feats2["Number"] == "Sing" 
                if lemma == form
                    marked = "false" 
                    reason = "Other: for object form = lemma"
                end
            end
        end    
        
        if marked == "false" #and ((feats2["Gender"] == "Fem" and feats2["Number"] == "Sing") or feats2["Animacy"] == "Anim")
             if !amodded[line2[0]].nil?
                 if reason.split(":")[0] == "Indeclinable" or reason.split(":")[0] == "Nominal syncretism"
                     if !["его", "её", "их"].include?(amodded[line2[0]][0][2])
                        marked = "true"
                        reason << ", but modifier helps"
                     else
                        reason << ", but modifier (possessive pronoun) does not help"
                     end
                 elsif reason.split(":")[0] == "NP syncretism" or reason.split(":")[0] == "Other"
                     reason << ", and modifier does not help"
                 end
             end
        end
    elsif language.include?("Latvian")
        marked = "true"
        declension = deklinacija(lemma, feats2["Gender"])
        
        if (declension >= 4 and feats2["Number"] == "Plur") or declension == 0
            marked = "false"
        end
        #this is a basic check. Add control for adjectives and complex tenses.
    elsif language.include?("German")
        marked = "false"
        #if feats2["Number"] == "Plur" or ((feats2["Number"] == "Sing" and (feats2["Gender"] == "Neut" or feats2["Gender"] == "Fem"))) or (feats2["Number"] == "Sing" and (feats2["Gender"] == "Masc" and amodded[line2[0]].nil?))
        #    marked = "false"
        #    reason = "NP syncretism: Plur or sg.neut or sg.fem or sg.masc and no modifier"
        #end
        if feats2["Number"] == "Sing" and feats2["Gender"] == "Masc" and !amodded[line2[0]].nil? 
            marked = "true"
            reason = "Masc Sing with modifier"
        end
    end

    return [marked, reason]
end

def deklinacija(lemma, gender) #determining the declension of a Latvian noun
    declension = 0 #this is for indeclinables: abbreviations, some foreign proper nouns (gender is not annotated), they can be considered as non-marked
    if ["mēness", "akmens", "asmens", "rudens", "ūdens", "zibens", "suns", "sāls"].include?(lemma)
        declension = 2
    elsif lemma == "ļaudis"
        declension = 6
    elsif gender == "Masc"
        if lemma[-2..-1] == "is"
            declension = 2
        elsif lemma[-2..-1] == "us"
            declension = 3
        elsif ["š","s"].include?(lemma[-1])
            declension = 1
        elsif lemma[-1] == "a"
            declension = 4
        elsif lemma[-1] == "e"
            declension = 5
        end
    elsif gender == "Fem"
        if lemma[-1] == "a"
            declension = 4
        elsif lemma[-1] == "e"
            declension = 5
        elsif lemma[-1] == "s"
            declension = 6
        end
    else
        STDOUT.puts "Unknown gender in Latvian: #{lemma}"
    end

    return declension
end

def feats_to_hash(feats)
    #STDERR.puts "Input feats: #{feats}"
    feats2 = {} #create a hash for features
    feats.split("|").each do |feat|
        feats2[feat.split("=")[0]] = feat.split("=")[1]
    end 
    #STDERR.puts "Output feats: #{feats2}"
    feats2
end


def check_argument_markedness(argument_info, sent_id, amodded, language, argument_feats, conjed, rel, dependents) #including checking conjuncts
    noun_suitable = check_noun(argument_info[3], feats_to_hash(argument_info[5]), rel, language, dependents[argument_info[0]])
    if noun_suitable == "true"
        marking, reason = marked(argument_info, sent_id, amodded, language, argument_feats) #check if subject is marked
    else
        marking = "filtered"
        reason = "First conjunct filtered out"
    end
    if (noun_suitable == "false" or (marking == "false" and noun_suitable != "false_for_all_conj")) and !conjed[argument_info[0]].nil?
        conjed[argument_info[0]].each do |conjunct|
            conj_suitable = check_noun(conjunct[3], feats_to_hash(conjunct[5]), rel, language, dependents[conjunct[0]])
            if conj_suitable
                conjmarked, conjreason = marked(conjunct, sent_id, amodded, language, feats_to_hash(conjunct[5]))
                marking = conjmarked
                if conjmarked == "true"
                    #marking = "true"
                    reason = "Conjunct helps #{conjunct[1]}"
                    break
                #else
                end
            end
        end
        if marking == "false" 
            reason << "; and conjuncts do not help"
        end
    end
    return [marking, reason]
end

#this method checks whether the whole SVO triple is marked (even if S and O individually are not marked), e.g. by verbal agreement
def triple_marked(subjinfo, objinfo, verbinfo, conjed, language, feats2_subj, feats2_obj, feats2_v)
    marked = "unknown"
    reason = ""
      
    form_subj = subjinfo[1]
    lemma_subj = subjinfo[2]
    rel_subj = subjinfo[7]
  
    form_obj = objinfo[1]
    lemma_obj = objinfo[2]
    rel_obj = objinfo[7]
    
   
    
    form_v = verbinfo[1]
    lemma_v = verbinfo[2]
    rel_v = verbinfo[7]
   
    if language.include?("Russian") or language.include?("German")
        marked = "false"
        
        if feats2_subj["Number"] != feats2_obj["Number"] and !(feats2_subj["Number"] == "Plur" and !conjed[objinfo[0]].nil?) and !(feats2_obj["Number"] == "Plur" and !conjed[subjinfo[0]].nil?)
            marked = "true"
            reason = "Number: different"
        elsif feats2_v["Number"] == "Sing"
            if feats2_subj["Number"] == "Sing" and feats2_obj["Number"] == "Sing"
                if !conjed[objinfo[0]].nil?
                    marked = "true"
                    reason = "Number: Verb in singular, whereas objects are coordinated"
                end
            end
        elsif feats2_v["Number"] == "Plur" and feats2_subj["Number"] == "Sing" and feats2_obj["Number"] == "Sing" 
            if !conjed[subjinfo[0]].nil? and conjed[objinfo[0]].nil?
                marked = "true"
                reason = "Number: Verb in plural due to coordinated subjects"
            end
        end

        if language.include?("Russian") and !language.include?("German")
            if marked == "false" and feats2_v["Tense"] == "Past" #Number of subject is indexed on the verb in the past (in singular, also gender)
                if feats2_v["Number"] == "Sing"
                    if feats2_subj["Gender"] != feats2_obj["Gender"]
                        marked = "true"
                        reason = "Gender: different (past tense)"
                    end
                end
            end 
        end


    elsif language.include?("Latvian")
        marked = "false" #this is a stub: add control for adjectives, verb number, complex tenses
    #elsif language.include?("German")
        #marked = "false" #this is a st
    end
    
    return [marked, reason]
end

def check_noun (pos, feats, rel, language, noun_dependents)
    result = "false"
    if pos == "NOUN" or pos == "PROPN" #looking only at nouns and proper nouns
        if language.include?("Russian") 
            if (feats["Case"] == "Nom" and rel == "nsubj") or (feats["Case"] == "Acc" and rel == "obj")
            #filtering out the case excludes the following: for subject: misannotations (Acc), dat-subjects (Dat), constructions with numerals (Gen), certain proper nouns and foreign words (no case at all, probably misannotations) (about 250 cases at the time of measuring); for object: Meaning-Text-style annotations of non-accusative objects as 1-compl (Dat, Ins: соответствовать чему, мешать кому, стать чем, закончиться чем, озаботиться чем), constructions with numerals (Gen), the construction друг друга (Nom), misannotations (Nom), certain proper nouns and foreign words (no case at all, probably misannotations). 
                result = "true"
            end
        elsif language.include?("Latvian") 
            result = "true"
        elsif language.include?("German")
            result = "true"
            if !noun_dependents.nil?
                noun_dependents.each do |dependent| #looping through CONLLU arrays
                    if feats_to_hash(dependent[5])["Case"] == "Dat"
                        result = "false_for_all_conj"
                        break
                    elsif feats_to_hash(dependent[5])["Case"] == "Acc" and feats_to_hash(dependent[5])["AdpType"] == "Prep"
                        result = "false"
                        break
                    end
                end
            end

        end
    end
    return result
end


language = ARGV[0]
path = ARGV[1]
if path.nil?
    path = "C:\\Sasha\\D\\DGU\\UD26langs"
end
filename = "#{path}\\#{language}.conllu"
STDERR.puts filename

markedness = File.new("#{language}_analyzed.csv","w:utf-8") #output file
markedness.puts "marked\tsent_id\tsubj\tobj\tverb\tsubj_marked\tcriterion_subj\tobj_marked\tcriterion_obj\tverb_marked\tcriterion_verb\two\tsent_text\tclause_type\tsubclause_type\tsubj_pos\tobj_pos\tsubj_anim\tobj_anim\tsubj_case\tobj_case\two_so\tdemoted_verb\tverb_lemma"

###UNIVERSAL:
#TODO: mention somewhere in the description that if POS != NOUN and PROPN, then it's because the first conjunct is not noun, but some latter conjuncts are nouns (and they are included)

#NOT-TODO: appositions (cf. Russian: его дочь Матильда; дочь is not marked, but Матильда is)
#NOT-TODO: shared arguments of coordinated verbs will not be included in the list (and good riddance?)
#NOT-TODO: include SV and VO
#NOT-TODO: include other POS apart from nouns
#NOT-TODO: include non-verbal predicates (e.g. nouns and adjectives without a copula in Russian)
#NOT-TODO: nouns coordinated with non-nouns (especially when the first conjunct is not a noun) are a bit tricky

###Language-specific:
#NOT-TODO-Russian: better control of indeclinable nouns?
#NOT-TODO-Russian: better control of amod? There are indeclinable adjectives etc.
#NOT-TODO-Russian: abbreviations
#NOT-TODO-Russian: infinitival constructions without a copula (Цель выступления -- показать поединок) are left as they are.

f = File.open(filename,"r:utf-8") #input file

#wo = {"SVO" => 0.0,"SOV" => 0.0,"OSV" => 0.0,"OVS" => 0.0,"VSO" => 0.0,"VOS" => 0.0} #hash for measuring entropy
wo2 = {"SVO" => "SO","SOV" => "SO","OSV" => "OS","OVS" => "OS","VSO" => "SO","VOS" => "OS"} #hash for measuring entropy

#total counts
#two = 0.0 
#tsvo = 0.0

#it's not really necessary to have hashes of arrays of arrays, simpler structures should be enough
amodded = {} #Hash of arrays for storing adjectival modifiers. Key: word id, value: array of modifiers, every modifier will be represented as a CONLLU array (i.e. Hash of Arrays of Arrays).
conjed = {} #Hash of arrays for storing conjuncts. Key: word id, value: array of modifiers, every conjunct will be represented as a CONLLU array (i.e. Hash of Arrays of Arrays). Right now the info from those arrays is not really used.
vafined = {} #Hash for storing auxiliary verbs for German. Note that this is hash of arrays, not hash of arrays of arrays, as the other two
dependents = {} #Hash of arrays for storing dependents. Key: word id, value: array of dependents. Can in principle reduce older hashes above

verbs = Hash.new{|hash, key| hash[key] = Array.new(14)} #key = verb id; 0 = subj id; 1 = dobj id; 2 = verb morph; 3 = subj morph (NOT IN USE); 4 = dobj morph (NOT IN USE); 5 = is the predicate a real verb? 6 = subject marked (NOT IN USE); 7 = object marked (NOT IN USE); 8 - subj info; 9 - obj info; 10 - verb info; 11 - subj feats; 12 - obj feats; 13 - verb feats; 14 - demoted main verb #somewhat of a legacy structure, can be optimized, but it's not really worth the effort #Use only 11 and 12 for feats, not 8 and 9. 

sent_id = ""
sent_text = "no text present"

f.each_line do |line|
    line1 = line.strip
    if line1[0]!="#" #if not a comment 
        if line1 != "" #if not end of sentence
            line2 = line1.split("\t") #create an array with data about the token
            if line2[3]=="VERB"
                verbs[line2[0]][5] = true #real verb?
                verbs[line2[0]][10] = line2 #store full info about the verb 
                verbs[line2[0]][13] = feats_to_hash(line2[5]) #store a hash of morphological features
            end
            if line2[7]=="nsubj" #and check_noun(line2[3], feats_to_hash(line2[5]), "nsubj", language) 
                verbs[line2[6]][11] = feats_to_hash(line2[5])
                verbs[line2[6]][0] = line2[0] #subject id
                verbs[line2[6]][8] = line2
                
            end
            if line2[7].include?("amod") or line2[7].include?("det") #include, not ==, in order to take care of det:poss etc.
                if amodded[line2[6]].nil?
                    amodded[line2[6]] = [line2]
                else
                    amodded[line2[6]] << line2 #see above
                end
            end
            if line2[7] == "conj" #if there are conjuncts
                if conjed[line2[6]].nil?
                    conjed[line2[6]] = [line2]
                else
                    conjed[line2[6]] << line2 #see above
                end
                #conjed[line2[6]] << line2 #see above
            end
            if ((line2[4] == "VAFIN" or line2[4] == "VMFIN") and language.include?("German")) or (line2[3] == "AUX" and line2[7] == "aux" and line2[2] == "быть" and language.include?("Russian"))
               vafined[line2[6]] = line2
            end
            if line2[7]=="obj" #and check_noun(line2[3], feats_to_hash(line2[5]), "obj", language) 
                verbs[line2[6]][12] = feats_to_hash(line2[5])
                verbs[line2[6]][1] = line2[0] #object id
                verbs[line2[6]][9] = line2
                
            end
            if dependents[line2[6]].nil?
                dependents[line2[6]] = [line2]
            else
                dependents[line2[6]] << line2 #see above
            end

        else #if end of sentence
            verbs.each_pair do |k, v|
                if v[0] and v[1] and v[5]
                    if language.include?("German")
                        if v[8][3] == "PROPN" and v[11]["Number"].to_s == ""
                            v[11]["Number"] = "Sing"
                        end
                        if v[9][3] == "PROPN" and v[12]["Number"].to_s == ""
                            v[12]["Number"] = "Sing"
                        end
                        
                        [v[0],v[1]].each do |arg|
                            if !conjed[arg].nil?
                                conjed[arg].each do |conjunct| #looping through CONLLU arrays
                                    if !dependents[conjunct[0]].nil?
                                        dependents[conjunct[0]].each do |dependent| #looping through CONLLU arrays
                                            if dependent[3] == "NUM"
                                                conjunct[5].gsub("Number=Sing","")
                                                conjunct[5] << "|Number=Plur"
                                                conjunct[5].gsub("||","|")
                                                break
                                            end
                                        end
                                    end
                                    if conjunct[3] == "PROPN" and feats_to_hash(conjunct[5])["Number"].to_s == ""
                                        conjunct[5] << "|Number=Sing"
                                        #conjunct[5].gsub("||","|")
                                    end
                                end
                            end
                        end

                        if !dependents[v[0]].nil?
                            dependents[v[0]].each do |dependent| #looping through CONLLU arrays
                                if dependent[3] == "NUM"
                                    v[11]["Number"] = "Plur"
                                    break
                                end
                            end
                        end
                        if !dependents[v[1]].nil?
                            dependents[v[1]].each do |dependent| #looping through CONLLU arrays
                                if dependent[3] == "NUM"
                                    v[12]["Number"] = "Plur"
                                    break
                                end
                            end
                        end
                    end #if lang == German end
                    #STDERR.puts amodded
                    smarked, sreason = check_argument_markedness(v[8], sent_id, amodded, language, v[11], conjed, "nsubj", dependents) #check if subject is marked
                    omarked, oreason = check_argument_markedness(v[9], sent_id, amodded, language, v[12], conjed, "obj", dependents) #check if object is marked
                    if smarked != "filtered" and omarked != "filtered" #if both are suitable nouns
                        demoted_verb = ""
                        if (language.include?("German") and !vafined[k].nil?) or (language.include?("Russian") and !vafined[k].nil? and v[13]["VerbForm"] == "Inf") #if what we are looking at is a main verb, not an auxiliary (inflected) one
                            verbinfo = vafined[k]
                            verb_feats = feats_to_hash(verbinfo[5])
                            demoted_verb = v[10][1]
                        else
                            verbinfo = v[10]
                            verb_feats = v[13]
                        end
                        #tmarked, treason = triple_marked(v[8],v[9],v[10], conjed, language, v[11], v[12], v[13]) #check if there is any marking on the verb
                        tmarked, treason = triple_marked(v[8],v[9],verbinfo, conjed, language, v[11], v[12], verb_feats) #check if there is any marking on the verb
                        
                        if smarked == "true" or omarked == "true" or tmarked == "true"
                            marking = "true"
                        elsif smarked == "unknown" or omarked == "unknown" or tmarked == "unknown"
                            marking = "unknown"
                        else
                            marking = "false"
                        end
                        if ["csubj", "ccomp", "xcomp", "advcl", "acl"].include?(v[10][7])
                            clause = "subordinate"
                            sub_type = v[10][7]
                        else
                            clause = "main"
                            sub_type = ""
                        end

                        if !(language.include?("German") and clause == "subordinate")
                        #worder = find_wo(k.to_i,v[0].to_i,v[1].to_i)
                            worder = find_wo(verbinfo[0].to_i,v[0].to_i,v[1].to_i)
                            #markedness.puts "marked\tsent_id\tsubj\tobj\tverb\tsubj_marked\tcriterion_subj\tobj_marked\tcriterion_obj\tverb_marked\tcriterion_verb\two\tsent_text\tclause_type\tsubclause_type\tsubj_pos\tobj_pos\tsubj_anim\tobj_anim\tsubj_case\tobj_case\two_so"
                            markedness.puts "#{marking}\t#{sent_id}\t#{v[8][1]}\t#{v[9][1]}\t#{verbinfo[1]}\t#{smarked}\t#{sreason}\t#{omarked}\t#{oreason}\t#{tmarked}\t#{treason}\t#{worder}\t#{sent_text}\t#{clause}\t#{sub_type}\t#{v[8][3]}\t#{v[9][3]}\t#{v[11]["Animacy"]}\t#{v[12]["Animacy"]}\t#{v[11]["Case"]}\t#{v[12]["Case"]}\t#{wo2[worder]}\t#{demoted_verb}\t#{verbinfo[2]}"
                            #markedness.puts "#{marking}\t#{sent_id}\t#{v[8][1]}\t#{v[9][1]}\t#{v[10][1]}\t#{smarked}\t#{sreason}\t#{omarked}\t#{oreason}\t#{tmarked}\t#{treason}\t#{worder}\t#{sent_text}\t#{clause}\t#{sub_type}\t#{v[8][3]}\t#{v[9][3]}\t#{v[11]["Animacy"]}\t#{v[12]["Animacy"]}\t#{v[11]["Case"]}\t#{v[12]["Case"]}\t#{wo2[worder]}"
                        end
                    end
                end 
            end #verbs loop end
            #resetting hashes
            verbs = Hash.new{|hash, key| hash[key] = Array.new(14)}
            amodded = {}
            conjed = {}
            vafined = {}
            dependents = {}
            #datives = {}
            #numerals = {}

        end #end of sentence end
    elsif line1.include?("sent_id")
        sent_id = line1.split(" = ")[1]
        #STDERR.puts sent_id
    elsif line1.include?("# text = ")
        sent_text = line1.split(" = ")[1]
    end# comment end
end #file end
f.close