//Gabriel Zohrob 300309391

package main

import (
    "fmt"
    "image"
    _ "image/jpeg"
    "log"
    "math"
    "os"
    "path/filepath"
    "sort"
    "sync"
    "time"
)

type Histo struct {
    Name string
    H    []float64
}

type ImageSimilarity struct {
    Name       string
    Similarity float64
}

// computeHistogram generates a histogram based on the color depth for a given image.
func computeHistogram(imagePath string, depth int) (Histo, error) {
    // Attempt to open the specified image file.
    file, err := os.Open(imagePath)
    if err != nil {
        return Histo{}, err // Return an empty Histo and the error if file can't be opened.
    }
    defer file.Close() // Ensure the file is closed after this function executes.

    // Decode the image from the file.
    img, _, err := image.Decode(file)
    if err != nil {
        return Histo{}, err // Return an error if the image can't be decoded.
    }

    bounds := img.Bounds() // Get the dimensions of the image.

    // Initialize the histogram structure for this image.
    h := Histo{Name: imagePath, H: make([]float64, int(math.Pow(2, float64(depth*3))))}
    // Iterate over each pixel to fill the histogram.
    for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
        for x := bounds.Min.X; x < bounds.Max.X; x++ {
            // Extract and normalize the RGBA values of the current pixel.
            red, green, blue, _ := img.At(x, y).RGBA()
            red, green, blue = red>>8, green>>8, blue>>8 // Shift to get 8-bit color depth.

            // Calculate the histogram bin index for this pixel.
            colourIndex := 0
            colourIndex += int(red) / (256 / depth) * depth * depth // Red component contribution.
            colourIndex += int(green) / (256 / depth) * depth       // Green component contribution.
            colourIndex += int(blue) / (256 / depth)                // Blue component contribution.
            h.H[colourIndex]++ // Increment the histogram bin.
        }
    }

    // Normalize the histogram by dividing each bin by the total number of pixels.
    totalPixels := float64(bounds.Dx() * bounds.Dy()) // Calculate total pixels.
    for i := range h.H {
        h.H[i] /= totalPixels
    }

    return h, nil // Return the filled histogram structure and no error.
}

// Processes images in parallel and computes their histograms
func computeHistograms(imagePaths []string, depth int, hChan chan<- Histo, wg *sync.WaitGroup) {
    defer wg.Done()
    for _, path := range imagePaths {
        histo, err := computeHistogram(path, depth)
        if err != nil {
            log.Printf("Error computing histogram for %s: %v\n", path, err)
            continue
        }
        hChan <- histo
    }
}

// Compares two histograms and calculates their similarity
func compareHistograms(h1 Histo, h2 Histo) float64 {
    similarity := 0.0
    for i, v := range h1.H {
        similarity += math.Min(v, h2.H[i])
    }
    // Scale similarity to a percentage
    similarityPercentage := (similarity / 1.0) * 100
    return similarityPercentage
}


func main() {
    start:= time.Now()
    if len(os.Args) != 3 {
        log.Fatalf("Usage: %s <queryImageFilename> <imageDatasetDirectory>\n", os.Args[0])
    }
    queryImageFilename := "queryImages/"+os.Args[1]
    imageDatasetDirectory := os.Args[2]

    depth := 4// Define color depth

    queryHisto, err := computeHistogram(queryImageFilename, depth)
    if err != nil {
        log.Fatalf("Failed to compute histogram for query image: %v", err)
    }

    files, err := filepath.Glob(filepath.Join(imageDatasetDirectory, "*.jpg"))
    if err != nil {
        log.Fatalf("Failed to list images in dataset directory: %v", err)
    }

    hChan := make(chan Histo)
    var wg sync.WaitGroup

    K := 1048 // Adjust this based on your needs
    for i := 0; i < K; i++ {
        start := i * len(files) / K
        end := (i + 1) * len(files) / K
        wg.Add(1)
        go computeHistograms(files[start:end], depth, hChan, &wg)
    }

    go func() {
        wg.Wait()
        close(hChan)
    }()

    var similarities []ImageSimilarity
    for histo := range hChan {
        similarity := compareHistograms(queryHisto, histo)
        // Adjust similarity calculation as needed
        similarities = append(similarities, ImageSimilarity{Name: histo.Name, Similarity: similarity})
    }

    // Sort and print top 5 similar images
    sort.Slice(similarities, func(i, j int) bool {
        return similarities[i].Similarity > similarities[j].Similarity
    })

    fmt.Println("Top 5 similar images:")
    for i, sim := range similarities[:5] {
        fmt.Printf("%d: %s (Similarity: %.2f)\n", i+1, filepath.Base(sim.Name), sim.Similarity)
    }

    elapsed:=time.Since(start)
    fmt.Printf("Runtime = %s", elapsed)

}
