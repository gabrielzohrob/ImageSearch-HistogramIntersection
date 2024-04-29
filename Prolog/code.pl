% dataset(DirectoryName)
% this is where the image dataset is located
dataset('C:/Users/gabri/OneDrive/Documents/UNI/2023-2024/winter/CSI2520/P3/imageDataset2_15_20/').
% directory_textfiles(DirectoryName, ListOfTextfiles)
% produces the list of text files in a directory
directory_textfiles(D,Textfiles):- directory_files(D,Files), include(isTextFile, Files, Textfiles).
isTextFile(Filename):-string_concat(_,'.txt',Filename).
% read_hist_file(Filename,ListOfNumbers)
% reads a histogram file and produces a list of numbers (bin values)
read_hist_file(Filename,Numbers):- open(Filename,read,Stream),read_line_to_string(Stream,_),
                                   read_line_to_string(Stream,String), close(Stream),
								   atomic_list_concat(List, ' ', String),atoms_numbers(List,Numbers).
								   
% similarity_search(QueryFile,SimilarImageList)
% returns the list of images similar to the query image
% similar images are specified as (ImageName, SimilarityScore)
% predicat dataset/1 provides the location of the image set
similarity_search(QueryFile,SimilarList) :- dataset(D), directory_textfiles(D,TxtFiles),
                                            similarity_search(QueryFile,D,TxtFiles,SimilarList).
											
% similarity_search(QueryFile, DatasetDirectory, HistoFileList, SimilarImageList)
similarity_search(QueryFile,DatasetDirectory, DatasetFiles,Best):- read_hist_file(QueryFile,QueryHisto), 
                                            compare_histograms(QueryHisto, DatasetDirectory, DatasetFiles, Scores), 
                                            sort(2,@>,Scores,Sorted),take(Sorted,5,Best).

% compare_histograms(+QueryHisto, +DatasetDirectory, +DatasetFiles, -Scores)
%
% Compares a query histogram with a list of histogram files within a given dataset directory,
% producing a list of tuples containing the filename and its similarity score relative to the
% query histogram. Each tuple is in the form (File, Score), where 'File' is the name of the
% dataset file and 'Score' is the similarity score obtained by comparing the query histogram
% with the dataset file's histogram.
%
% @param QueryHisto The histogram of the query image as a list of numbers.
% @param DatasetDirectory The directory path where the dataset histogram files are located.
% @param DatasetFiles A list of filenames (strings) representing the histogram files in the dataset.
% @param Scores The output list of tuples (File, Score) representing each dataset file's similarity score.
compare_histograms(QueryHisto, DatasetDirectory, DatasetFiles, Scores) :-
    findall((File, Score), (
        member(File, DatasetFiles),
        atomic_list_concat([DatasetDirectory, File], Path),
        read_hist_file(Path, Histo),
        histogram_intersection(QueryHisto, Histo, Score)
    ), Scores).

% histogram_intersection(+H1, +H2, -Score)
%
% Calculates the intersection similarity score between two histograms. The score is computed
% as twice the sum of the minimum values for corresponding bins in both histograms, divided by
% the sum of all bin values in both histograms. This score ranges from 0.0 to 1.0, where 1.0
% indicates identical histograms.
%
% @param H1 The first histogram as a list of numbers (bin values).
% @param H2 The second histogram as a list of numbers (bin values).
% @param Score The calculated intersection similarity score between H1 and H2.
histogram_intersection(H1, H2, Score) :-
    list_min_pairs(H1, H2, MinPairs),
    sum_list(MinPairs, MinSum),
    sum_list(H1, SumH1),
    sum_list(H2, SumH2),
    Score is 2 * MinSum / (SumH1 + SumH2).

% list_min_pairs(+List1, +List2, -MinPairs)
%
% Produces a list of the minimum values for each corresponding pair in two lists. This is
% used within the histogram_intersection predicate to find the minimum bin values between
% two histograms for calculating the intersection similarity score.
%
% @param List1 The first list of numbers.
% @param List2 The second list of numbers.
% @param MinPairs The output list containing the minimum value for each corresponding pair
%                 in List1 and List2.
list_min_pairs([], [], []).
list_min_pairs([H1|T1], [H2|T2], [MinH|MinT]) :-
    MinH is min(H1, H2),
    list_min_pairs(T1, T2, MinT).


% take(List,K,KList)
% extracts the K first items in a list
take(Src,N,L) :- findall(E, (nth1(I,Src,E), I =< N), L).
% atoms_numbers(ListOfAtoms,ListOfNumbers)
% converts a list of atoms into a list of numbers
atoms_numbers([],[]).
atoms_numbers([X|L],[Y|T]):- atom_number(X,Y), atoms_numbers(L,T).
atoms_numbers([X|L],T):- \+atom_number(X,_), atoms_numbers(L,T).
