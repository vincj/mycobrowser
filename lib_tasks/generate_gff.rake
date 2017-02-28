namespace :mycobrowser do

	desc "Generate GFF"
	task :generate_gff, [:version] do |t, args|
    
    	require "#{Rails.root}/config/environment"
    	require 'json'

    	dir = './data/'

    	Organism.all.each do |organism|
    		#### one file by organism
    		file = File.open("#{dir}#{organism.name}_1.gff", "w")
    		#if File.exist?(file, 'w') do |f| #necessary ???
            organism.genes.all.each do |gene|
    			gene.genomic_objects.all.each do |go|
    				attributes = ["Locus=#{gene.locus}", "Name=#{gene.name}", "Synonym=#{gene.synonyms.name}", "Function=#{gene.fonction}", 
    					"Product=#{gene.product}", "Comments=#{gene.comments}", "Comments2=#{gene.comments2}","Mol_weight=#{gene.mol_weight}", 
    					"Isoelec_point=#{gene.isoelec_point}", "Length=#{gene.length}", "Proteomic=#{gene.gene_exps.map{|ge| ge.proteomic}.join(", ")}", 
    					"Transcriptome=#{gene.gene_exps.map{|ge| ge.transcriptome}.join(", ")}","Mutant=#{gene.gene_exps.map{|ge| ge.mutant}.join(", ")}", 
    					"Regulon=#{gene.gene_exps.map{|ge| ge.regulon}.join(", ")}", "Feature=#{gene.genomic_objects.map{|go| go.feature}.join(", ")}"]
    	    		l = [organism.name, 'MycoBrowser', gene.gene_type.name, go.start, go.stop, '.', go.strand, go.frame, attributes.join(";")]
    	    		file.write(l.join("\t") + "\n")
				end
    		end
		end	
	end 
end 





=begin
    Organism.all.each do |organism|
    	#### one file by organism
    	file = "#{dir}#{organism.name}.gff"
    	if File.exist?(file, 'w') do |f|
    		organism.genes.all.each do |gene|
    	    	gene.genomic_objects.each do |go|
    	    		l = [go.chr, go.start, go.stop, go.strand]
    	    		f.write(l.join("\t") + "\n")
   				end
			end

    	end
	end	

"Transcriptome=#{gene.gene_exps.transcriptome}","Mutant=#{gene.gene_exps.mutant}", "Regulon=#{gene.gene_exps.regulon}", "Feature=#{gene.genomic_objects.feature}"
=end

#Client.where("orders_count = ?", params[:orders])
# GenomicObject.where(:gene_id => gene.id).each
#gene_type = GeneType.find(gene.gene_type_id)
