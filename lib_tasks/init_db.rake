namespace :mycobrowser do

  desc "Init DB"
  task :init_db, [:version] do |t, args|
    
    require "#{Rails.root}/config/environment"
    require 'json'

    databases = {
      'leprae' => ['public', 3],
      'smegmatis' => ['public', 4],
      'marinum' => ['public', 5],
      'tuberculosis' => ['r27', 1],
      'bovis' => ['r01', 2]
    }

    table_to_obj = {'genes' => Gene,
      'bibliography' => Article, 'author' => Author,
      'category' => Category,
      'db_xref' => Xref,
      'genex' => GeneExp, 'genomic_object' => GenomicObject,
      'prediction' => Prediction, 'synogenes' => Synonym,
     'buf_bibl_gene' => GeneArticle,
     'buf_bibl_auth' => ArticleAuthor,
     'buff_categ_gene' => CategoriesGene
    }

#    cross_tables = {'buf_bibl_auth' => [Article, Author], 'buff_categ_gene' => [Category, Gene]}

    columns = {
      'genes' => {'id_gene' => 'locus', 'name' => 'name', 'fcn2' => 'fonction', 
        'evidence' => 'evidence', 'ec_number' => 'ec_number', 'product' => 'product', 
        'brief_descript' => 'description', 'brief_descript2' => 'description2', 
        'comments' => 'comments', 'comments2' => 'comments2', 'ispseudo' => 'ispseudo', 
        'seq_prot' => 'seq_prot', 'mol_weight' => 'mol_weight', 'isoelec_point' => 'isoelec_point',
        'length_prot' => 'length_prot' },
      'bibliography' => {'id_medline' => 'pmid', 'title' => 'title', 'title2' => 'title2',
        'source' => 'journal', 'volume' => 'volume', 'issue' => 'issue', 
        'pages' => 'pages', 'year' => 'year', 'abstract' => 'abstract'},
      'author' => {'id_author' => 'id_author', 'last_name' => 'last_name', 'initials' => 'initials'},
      'buf_bibl_auth' => {'id_medline' => 'pmid', 'id_author' => 'id_author', 'rank' => 'rank'},
      'buf_bibl_gene' => {'id_medline' => 'pmid', 'id_gene' => 'id_gene', 'relevance' => 'relevance'},
      'category' => {'code' => 'code', 'description' => 'description'},
      'buff_categ_gene' => {'id_gene' => 'id_gene', 'code'  => 'code'},
      'db_xref' => {'id_gene' => 'id_gene', 'acc' => 'acc', 'label' => 'label', 'goa' => 'goa'},
      'genex' => {'id_gene' => 'id_gene', 'proteomic2' => 'proteomic', 'transcriptome2' => 'transcriptome', 
        'mutant2' => 'mutant', 'changes' => 'change_info', 
        'regulon' => 'regulon', 'operon' => 'operon'},
      'genomic_object' => {'start' => 'start', 'last' => 'stop', 'direction' => 'strand', 
        'type' => 'feature', 'frame' => 'frame', 'id_gene' => 'id_gene'},
      'prediction' => {'id_gene' => 'id_gene', 'code_predict' => 'code_predict'},
      'synogenes' => {'id_gene' => 'id_gene',  'synonym' => 'name'}
      }
    
    new_tables = {
      'genes' => {'type' => [GeneType, 'name', 'gene_type_id']},
      'db_xref' => {'banque' => [Source, 'name', 'source_id']}
    }
    

    databases.each_key do |db_name|
      puts "Working on #{db_name}..." 
      schema =  databases[db_name][0]
      
      con = PG.connect :dbname => db_name
      
      
      table_to_obj.each_key do |old_table_name|
        puts "==> #{old_table_name}"
        obj = table_to_obj[old_table_name]
        
        list_cols = columns[old_table_name].keys
		all_list_cols = list_cols.dup
        if new_tables[old_table_name]          
          new_tables[old_table_name].keys.map{|col| all_list_cols.push(col) }
        end
        
        res = con.exec("SELECT 1
   		FROM   information_schema.tables 
   		WHERE  table_schema = '#{schema}'
   		AND    table_name = '#{old_table_name}'").values

        if res.size ==1 and res[0][0].to_i == 1

          	rs = con.exec "SELECT #{all_list_cols.join(", ")} from #{schema}.#{old_table_name}"
          
	  		count_existing = 0
          	count_new = 0
          	rs.each do |h_old|

	  		#puts h_old
         
            h = {}

            ### add in an external table if necessary
            
            if  new_tables[old_table_name] 
              tmp_h = new_tables[old_table_name]
              tmp_h.each_key do |old_column_name|
                tab = tmp_h[old_column_name]
                newObj = tab[0]
                new_source_column_name = tab[1]
                new_ref_column_name = tab[2]
                ext_h = {}
                ext_h[new_source_column_name] = h_old[old_column_name]
                #		puts h_old.to_json if  h_old[old_column_name] == nil
                #		puts [new_source_column_name, old_column_name, h_old[old_column_name]].to_json
                new_o = newObj.where(ext_h).first
                if !new_o and ext_h[new_source_column_name] and ext_h[new_source_column_name] != ''
                  new_o = newObj.new(ext_h)
                  new_o.save
                end
#		puts [new_source_column_name, old_column_name, h_old[old_column_name], new_ref_column_name, new_o.id].to_json
                h[new_ref_column_name]=new_o.id
               
                
              end
            end
           # puts h.to_json
            list_cols.each do |old_column_name|
            #  puts old_column_name
              new_column_name = columns[old_table_name][old_column_name]
              h[new_column_name] = h_old[old_column_name]
            end
            if old_table_name == 'genes'
              h['organism_id']= databases[db_name][1]
            end
            
         #   puts h.to_json
            if obj.where(h).count == 0
              new_o = obj.new(h) 
              new_o.save
              #              puts new_o.to_json
              count_new +=1
            else  
            count_existing +=1
            end
            
          end
          puts "#{count_existing} rows already found / #{count_new} added"
        end
        
      end

#      cross_tables.each_key do |old_table_name|
#        
#        res = con.exec("SELECT 1                                                                                                                          
#   FROM   information_schema.tables                                                                                                                     
#   WHERE  table_schema = '#{schema}'                                                                                                                    
#   AND    table_name = '#{old_table_name}'").values
#        
#        if res.size ==1 and res[0][0].to_i == 1
#          
#          rs = con.exec "SELECT #{list_cols.join(", ")} from #{schema}.#{old_table_name}"
#          
#          cross_tables[old_table_name].each do |ObjA, ObjB|
#        
#          
#
#        end
#    end
    
      
    end 
    
  end 
end 
