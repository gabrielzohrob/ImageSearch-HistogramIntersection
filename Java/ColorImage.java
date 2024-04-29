/*Gabriel Zohrob 300309391 */
import java.io.*;
public class ColorImage {
    // Class fields to hold image dimensions, color depth, and pixel data
    int width;
    int height;
    int depth;
    int[][][] pixels; 

    // Constructor to initialize a ColorImage object from a file
    public ColorImage(String filename) {    
        // Attempting to load image data from a specified file
        try {
            // Initializing file reading tools
            FileReader fileReader = new FileReader(filename);
            BufferedReader bufferedReader = new BufferedReader(fileReader);

            // Skipping metadata lines to get to the image dimensions and color depth
            bufferedReader.readLine(); // Skip file type
            bufferedReader.readLine(); // Skip comment line

            // Reading image width, height, and color depth from the file
            String line = bufferedReader.readLine();
            String[] attributes = line.split(" ");
            this.width = Integer.parseInt(attributes[0]);
            this.height = Integer.parseInt(attributes[1]);

            line = bufferedReader.readLine();
            this.depth = Integer.parseInt(line);

            // Preparing the pixel array to store image data
            this.pixels = new int[height][width][3];

            // Reading pixel values from the file and storing them in the pixel array
            String[] linePixels;
            int counter = 0;
            int heightCounter = 0;
            while ((line = bufferedReader.readLine()) != null) {
                linePixels = line.split(" ");

                for (int j = 0; j < linePixels.length; j++) {
                    int[] pixel = new int[3];
                    pixel[0] = Integer.parseInt(linePixels[j]);
                    pixel[1] = Integer.parseInt(linePixels[++j]);
                    pixel[2] = Integer.parseInt(linePixels[++j]);

                    this.pixels[heightCounter][counter] = pixel;

                    // Increment counters for pixel positioning
                    if (counter == width-1) {
                        counter = 0;
                        heightCounter++;
                    } else {
                        counter++;
                    }
                }   
            }

            // Closing the file after reading is complete
            bufferedReader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // Getter methods for image properties
    public int getWidth() {
        return width;
    }

    public int getHeight() {
        return height;
    }

    public int getDepth() {
        return depth;
    }

    // Method to retrieve a specific pixel's RGB values
    public int[] getPixel(int x, int y) {
        return pixels[y][x];
    }

    // Method to reduce the color depth of the image
    public void reduceColor(int d) {
        for (int i = 0; i < this.height; i++) {
            for (int j = 0; j < this.width; j++) {
                // Calculating the number of bits to represent the current depth and adjusting each color component
                int bits = (int) Math.ceil(Math.log(depth) / Math.log(2));
                pixels[i][j][0] = pixels[i][j][0] >> (bits - d);
                pixels[i][j][1] = pixels[i][j][1] >> (bits - d);
                pixels[i][j][2] = pixels[i][j][2] >> (bits - d);
            }
        }
    }
}
