STDERR.puts "ruby postanalyzer.rb language analysis_type (marking, wo2, wo6 or argstats)"
language = ARGV[0]
analysis = ARGV[1] #argstats, marking, wo

f = File.open("#{language}_analyzed.csv","r:utf-8")

if analysis == "argstats"
    
    o = File.open("#{language}_argstats.csv","w:utf-8")
    o.puts "subj_proper\tobj_proper\tsubj_common\tobj_common\tsubj_anim\tobj_anim\tsubj_inan\tobj_inan"
    
    subj_proper = 0
    obj_proper = 0
    subj_common = 0
    obj_common = 0
    
    subj_anim = 0
    obj_anim = 0
    subj_inan = 0
    obj_inan = 0
    
    subj_prop_inan = 0
    subj_comm_inan = 0
    
    obj_prop_inan = 0
    obj_comm_inan = 0
    
    
    
    f.each_line.with_index do |line, index|
        if index > 0
            line1 = line.split("\t")
            if line1[15] == "PROPN"
                subj_proper += 1
            elsif line1[15] == "NOUN"
                subj_common += 1
            end
            if line1[16] == "PROPN"
                obj_proper += 1
            elsif line1[16] == "NOUN"
                obj_common += 1
            end
            if line1[17] == "Anim"
                subj_anim += 1
            elsif line1[17] == "Inan"
                subj_inan += 1
                if line1[15] == "PROPN"
                    subj_prop_inan += 1
                elsif line1[15] == "NOUN"
                    subj_comm_inan += 1
                end
            end
            
            if line1[18] == "Anim"
                obj_anim += 1
            elsif line1[18] == "Inan"
                obj_inan += 1
                if line1[16] == "PROPN"
                    obj_prop_inan += 1
                elsif line1[16] == "NOUN"
                    obj_comm_inan += 1
                end
            end
            
        end
    end
    o.puts "#{subj_proper}\t#{obj_proper}\t#{subj_common}\t#{obj_common}\t#{subj_anim}\t#{obj_anim}\t#{subj_inan}\t#{obj_inan}"
    o.puts "subj_anim\tobj_anim\tsubj_prop_inan\tobj_prop_inan\tsubj_comm_inan\tobj_comm_inan"
    o.puts "#{subj_anim}\t#{obj_anim}\t#{subj_prop_inan}\t#{obj_prop_inan}\t#{subj_comm_inan}\t#{obj_comm_inan}"
elsif analysis == "marking"
    o = File.open("#{language}_markingmeans.csv","w:utf-8")
    total = 0
    subjcase = 0
    objcase = 0
    verb_number = 0
    verb_gender = 0 #not very informative, since gender is only considered if number does not help
    
    argcase = 0
    verb = 0

    all_marking = Hash.new(0)
    all_marking2 = Hash.new(0)
    all_marking3 = Hash.new(0)

    f.each_line.with_index do |line, index|
        if index > 0
            total += 1
            marking = ["no", "no", "no", "no"] #subjcase, objcase, number, gender
            marking2 = ["no", "no"] #arguments, verb
            marking3 = ["no", "no", "no"] #subj, obj, verb
            line1 = line.split("\t")
            if line1[5] == "true"
                subjcase += 1
                marking[0] = "yes"
                marking3[0] = "yes"
            end
            if line1[7] == "true"
                objcase += 1
                marking[1] = "yes"
                marking3[1] = "yes"
            end
            if marking[0] == "yes" or marking[1] == "yes"
                argcase += 1
                marking2[0] = "yes"
            end

            if line1[9] == "true"
                verb += 1
                marking2[1] = "yes"
                marking3[2] = "yes"
                if line1[10].split(":")[0] == "Number"
                    verb_number += 1
                    marking[2] = "yes"
                elsif line1[10].split(":")[0] == "Gender"
                    verb_gender += 1
                    marking[3] = "yes"
                else 
                    STDERR.puts "Unknown marking!"
                end
                

            end
            all_marking[marking] += 1
            all_marking2[marking2] += 1
            all_marking3[marking3] += 1
        end
    end
    o.puts "argcase\tverb" 
    o.puts "#{argcase}\t#{verb}" 
    o.puts "subjcase\tobjcase\tverb_number\tverb_gender" 
    o.puts "#{subjcase}\t#{objcase}\t#{verb_number}\t#{verb_gender}" 
    
    o.puts ""
    o.puts "subjcase\tobjcase\tverb_number\tverb_gender\tcount" 
    all_marking.each_pair do |marking, count| 
        o.puts "#{marking.join("\t")}\t#{count}"
    end

    o.puts ""
    o.puts "argcase\tverb\tcount" 
    all_marking2.each_pair do |marking2, count| 
        o.puts "#{marking2.join("\t")}\t#{count}"
    end
    
    o.puts ""
    o.puts total

    o.puts ""
    o.puts "subject\tobject\tverb\tcount" 
    all_marking3.each_pair do |marking3, count| 
        o.puts "#{marking3.join("\t")}\t#{count}"
    end
    
    o.puts ""
    o.puts total
   

elsif analysis.include?("wo")
    o = File.open("#{language}_#{analysis}stats.csv","w:utf-8")
    wohash = Hash.new(0.0)
    two = 0.0
    marked_wohash = Hash.new(0.0)
    marked_two = 0.0
    nonmarked_wohash = Hash.new(0.0)
    nonmarked_two = 0.0
    if analysis[-1] == "2"
        woindex = 21
    elsif analysis[-1] == "6"
        woindex = 11
    end
    f.each_line.with_index do |line, index|
        if index > 0
            #STDERR.puts line
            line1 = line.split("\t")
        
            if line1[0] == "true"
                marked_wohash[line1[woindex]] += 1
                marked_two += 1
            elsif line1[0] == "false"
                nonmarked_wohash[line1[woindex]] += 1
                nonmarked_two += 1
            end
            wohash[line1[woindex]] += 1
            two += 1
        end
    end

    o.puts "marked"
    o.puts "wo\tcount\tproportion"
    marked_wohash.each_pair do |wo, count|
        o.puts "#{wo}\t#{count}\t#{(count/marked_two).round(4)}"
    end
    o.puts 
    o.puts "non-marked"
    o.puts "wo\tcount\tproportion"
    nonmarked_wohash.each_pair do |wo, count|
        o.puts "#{wo}\t#{count}\t#{(count/nonmarked_two).round(4)}"
    end

    o.puts 
    o.puts "all"
    o.puts "wo\tcount\tproportion"
    wohash.each_pair do |wo, count|
        o.puts "#{wo}\t#{count}\t#{(count/two).round(4)}"
    end

end

