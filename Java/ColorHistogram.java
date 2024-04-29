/*Gabriel Zohrob 300309391 */
import java.lang.Math;
import java.util.stream.IntStream;
import java.io.*;

public class ColorHistogram {
    // Class attributes for storing histogram data, dimension, associated image, and number of pixels
    double[] histogram;
    int d;
    ColorImage image;
    int numPixels;

    // Initializes a new histogram with a specified color depth
    public ColorHistogram(int d) {
        this.d = d;
        this.histogram = new double[(int) (Math.pow(2, d*3))];
    }

    // Initializes a histogram from a file, given a color depth and file path
    public ColorHistogram(int d, String file){
        this.d = d;
        this.histogram = new double[(int) (Math.pow(2, d*3))];

        try{
            FileReader fileReader = new FileReader(file);
            BufferedReader bufferedReader = new BufferedReader(fileReader);

            // Ignoring the first line as it doesn't contain relevant data for histogram initialization
            String line = bufferedReader.readLine();
            this.d = d;
            
            // Reading the histogram data from the file
            line = bufferedReader.readLine();
            String[] values = line.split(" ");

            // Parsing and storing histogram values, calculating total pixel count
            int totalPixels = 0;
            for (int i = 0; i < values.length; i++){
                this.histogram[i] = Double.parseDouble(values[i]);
                totalPixels += this.histogram[i];
            }
            this.numPixels = totalPixels;

            bufferedReader.close();
            
        } catch (IOException e) {
            e.printStackTrace();
        }
        
    }

    // Accessor methods for class attributes
    public double[] getHistogram() {
        return histogram;
    }

    public int getD() {
        return d;
    }

    public ColorImage getImage() {
        return image;
    }

    // Assigns an image to this histogram and computes the histogram based on the image's pixel data
    public void setImage(ColorImage image) {
        this.image = image;
        this.numPixels = image.getHeight() * image.getWidth();
        // Iterating over each pixel to determine its bin and increment the histogram count
        for (int i = 0; i < image.getHeight(); i++) {
            for (int j = 0; j < image.getWidth(); j++) {
                int index = (image.getPixel(j, i)[0] << (2 * d)) + (image.getPixel(j, i)[1] << d) + image.getPixel(j, i)[2];
                this.histogram[index]++;
            }
        }
    }

    // Normalizes the histogram so that each bin value represents a probability
    public void normalizeHistogram() {
        IntStream.range(0, histogram.length).forEach(i -> histogram[i] /= numPixels);
    }

    // Computes the similarity between this histogram and another, using the minimum value for each bin
    public double compare(ColorHistogram other) {
        return IntStream.range(0, this.histogram.length)
                .mapToDouble(i -> Math.min(this.histogram[i], other.histogram[i]))
                .sum();
    }
    
    // Writes the histogram data to a file specified by filename
    public void colorHistogram (String filename) {
        try (FileWriter fileWriter = new FileWriter(filename);
             PrintWriter printWriter = new PrintWriter(new BufferedWriter(fileWriter))) {
            // Writing the size of the histogram array to the file
            printWriter.println(histogram.length);
            // Iterating over the histogram and writing each bin value to the file
            for (double binValue : histogram) {
                printWriter.print(binValue + " ");
            }
        } catch (IOException ioException) {
            ioException.printStackTrace();
        }
    }
}

