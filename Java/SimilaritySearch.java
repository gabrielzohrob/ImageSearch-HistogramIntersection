/*Gabriel Zohrob 300309391 */
import java.util.*;
import java.io.*;

public class SimilaritySearch {
    public static void main(String[] args) {
        // Parsing command line arguments for image path and dataset directory
        String imagePath = "queryImages/" + args[0];
        String dataset = args[1];

        // Preprocessing the query image: reducing color depth, creating and normalizing its histogram
        ColorImage image = new ColorImage(imagePath);
        image.reduceColor(3); // Reduce color depth to simplify comparison
        ColorHistogram imageHistogram = new ColorHistogram(3); // Create histogram with reduced color depth
        imageHistogram.setImage(image); // Set the image for the histogram
        imageHistogram.normalizeHistogram(); // Normalize the histogram for comparison
        imageHistogram.colorHistogram("check.txt"); // Optional: Save the normalized histogram for debugging

        // Data structure to hold the similarity scores between the query image and dataset images
        Map<String, Double> imageDistance = new HashMap<>();

        // Iterating through each file in the dataset to compare with the query image
        File dir = new File(dataset);
        File[] directoryListing = dir.listFiles();
        Double distance;
        for (File child : directoryListing) {
            String fileName = child.getName();
            // Only process text files, assuming they contain histogram data
            if (fileName.contains(".txt")) {
                ColorHistogram other = new ColorHistogram(3, dataset + "/" + fileName); // Load each dataset image's histogram
                other.colorHistogram("check3.txt"); // Optional: Save histogram for debugging
                other.normalizeHistogram(); // Normalize the dataset image histogram for accurate comparison
                other.colorHistogram("check2.txt"); // Optional: Save the normalized histogram for debugging
                distance = imageHistogram.compare(other); // Compare the query image histogram with the dataset image histogram
                imageDistance.put(fileName, distance); // Store the similarity score
            }
        }

        // Sorting the similarity scores to find the closest images
        LinkedList<Map.Entry<String, Double>> list = new LinkedList<>(imageDistance.entrySet());
        Collections.sort(list, new Comparator<Map.Entry<String, Double>>() {
            public int compare(Map.Entry<String, Double> o1, Map.Entry<String, Double> o2) {
                return (o1.getValue()).compareTo(o2.getValue());
            }
        });

        // Displaying the top 5 closest images based on the similarity scores
        System.out.println("The 5 most similar images are:");
        int count = 1;
        // Iterate in reverse since we want the smallest distances (most similar) and they're at the end after sorting
        for (int i = list.size()-1; i >= list.size()-5; i--) {
            System.out.println(count + ": " + list.get(i).getKey() + " with a distance of " + list.get(i).getValue()*100+"%");
            count++;
        }
    }
}
