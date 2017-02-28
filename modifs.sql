--merge comments1 and comments2 into column comments
alter table genes rename column comments to comments1;
alter table genes add column comments text;
update genes set comments=case when comments1 is null then comments2 when comments2 is null then comments1 else concat_ws(', ', comments1, comments2) end;

--merge description1 and description2 into column comments
alter table genes rename column description to description1;
alter table genes add column description text;
update genes set description=case when description1 is null then description2 when description2 is null then description1 else concat_ws(', ', description1, description2) end;

--correct four rows of table genomic_objects
update genomic_objects set gene_id=2655 where id=2729;
update genomic_objects set gene_id=16755, strand='+' where id =18160;
delete from genomic_objects where genomic_objects.id=17539;
update genomic_objects set gene_id=17867 where id=18547;

--delete two rows that can't be used in synonyms. If you want to check: 
-- select id, name, gene_id from synonyms where gene_id is null;
delete from synonyms where gene_id is null;

--suggestion afin d'éviter l'affichage de parenthèse vide sur le website
delete from synonyms where name is null;
--autre suggestion: copy synonyms.name to genes.name where genes.name is null


--link genes with bibliography
alter table gene_articles rename to articles_genes;
alter table article_authors rename to articles_authors;


