STDERR.puts "ruby bootstrap.rb language wo_order_type > output_file. wo_order_type: wo2 [for SO vs OS] or wo6 [as in the paper]; if no output file specified, the output will go to the screen"

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

language = ARGV[0]
wo_type = ARGV[1].to_i

markedindex = 0
wo6index = 11
wo2index = 21

if wo_type == 2
    woindex = wo2index
    basic_wo = "SO"
elsif wo_type == 6
    basic_wo = "SVO" #Change for German?
    woindex = wo6index
end

f = File.open("#{language}_analyzed.csv","r:utf-8") 
woarray = []

wo1 = Hash.new(0.0)
two1 = 0.0
wo2 = Hash.new(0.0)
two2 = 0.0
pbasic_prop1 = 0.0
pbasic_prop2 = 0.0

f.each_line.with_index do |line, index|
    if index > 0
        line1 = line.strip.split("\t")
        wo = line1[woindex]
        woarray << wo
        if line1[markedindex] == "false"
            wo1[wo] += 1
            two1 += 1
            if wo == basic_wo
                pbasic_prop1 += 1
            end
        elsif line1[markedindex] == "true"
            wo2[wo] += 1
            two2 += 1
            if wo == basic_wo
                pbasic_prop2 += 1
            end
        end
    end
end
pe1 = entropy(wo1,two1)
pe2 = entropy(wo2,two2)

pbasic_prop1 = pbasic_prop1/two1
pbasic_prop2 = pbasic_prop2/two2

baseline_entr = (pe2 - pe1).abs
baseline_bwo = (pbasic_prop1 - pbasic_prop2).abs
total = two1 + two2
samplesize = two1

#STDERR.puts baseline
#STDERR.puts samplesize
#STDERR.puts total

f.close

p_entr = 0.0
p_bwo = 0.0
iter = 10000

for j in 1..iter
    if j % 100 == 0
        STDERR.puts j
    end

    a = (0..total-1).to_a.sample(samplesize)
    wo1 = Hash.new(0.0)
    two1 = 0.0
    wo2 = Hash.new(0.0)
    two2 = 0.0
    basic_prop1 = 0.0
    basic_prop2 = 0.0


    woarray.each.with_index do |wo, index|
        if a.include?(index)
            wo1[wo] += 1
            two1 += 1
            if wo == basic_wo
                basic_prop1 += 1
            end
        else
            wo2[wo] += 1
            two2 += 1
            if wo == basic_wo
                basic_prop2 += 1
            end
            
        end
    end

    e1 = entropy(wo1,two1)
    e2 = entropy(wo2,two2)

    basic_prop1 = basic_prop1/two1
    basic_prop2 = basic_prop2/two2

    
    if (e2 - e1).abs >= baseline_entr
        p_entr += 1
    end
    if (basic_prop1 - basic_prop2).abs >= baseline_bwo
        p_bwo += 1
    end
    STDOUT.puts "#{(e2 - e1)}\t#{(basic_prop1 - basic_prop2)}"
end

STDERR.puts "#{language}; considering #{wo_type} possible word orders"
STDERR.puts "Unmarked: entropy #{pe1}; basic WO (#{basic_wo}) proportion #{pbasic_prop1}; Marked: entropy #{pe2}; basic WO (#{basic_wo}) proportion #{pbasic_prop2}" 
STDERR.puts "P-values: entropy #{p_entr/iter}; basic wo: #{p_bwo/iter}"

#p/iter