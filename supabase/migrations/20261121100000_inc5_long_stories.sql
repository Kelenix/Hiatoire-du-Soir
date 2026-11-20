-- Inc-5 : une histoire de 10 minutes (≈ 1 300 mots) peut compter plus de 80 paragraphes.
alter table public.stories drop constraint stories_paragraphs_check;
alter table public.stories add constraint stories_paragraphs_check check (cardinality(paragraphs) between 1 and 200);
