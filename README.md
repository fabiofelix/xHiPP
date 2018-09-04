# xHiPP

This code is a new design for Hierarchical Point Placement Strategy (HiPP), called
eXtend HiPP (xHiPP). xHiPP is a Multidimensional Projection capable of present several levels
of data details.

## Getting Started

These instructions will get you a copy of the project to run on your local machine for development and testing purposes. 

### Prerequisites

* [R](https://www.r-project.org/) - Download and install the R latest version
* [RStudio](https://www.rstudio.com/products/rstudio/download/) - Download and install the RStudio latest version
* [R packages](https://www.r-bloggers.com/installing-r-packages/) - Open RStudio and follow the previous link instructions to install these packages:  "jsonlite", "mp", "doParallel", "tm", "topicmodels", "SnowballC", "shiny", "mime", "stringr"

### Installing

```
After downloading and unzip xHiPP directory, copy from run/ directory files: run.R, 
RUN_SERVER and RUN_CLIENT

obs.: If you are using Windows, please take .bat files. If you are using Unix-like, take .sh ones
```

```
Edit xHIPP.PATH variable into run.R to your correspondent xHiPP directory path. 
```

```
Edit RUN_SERVER_PATH variable into RUN_SERVER to your correspondent run.R path.
```

```
If it is necessary, edit USE_CHROME and SERVER_TCP_PORT variables into RUN_CLIENT to your desired 
configuration.
```

## Running tests

First and foremost, execute the RUN_SERVER script. After this, just execute RUN_CLIENT to open your browse showing xHiPP.

### File format (csv)

It is possible to load .csv files. The files must contain a column named as 'name' (identification column) and a column named as 'group' (data labels). If data are not labeled,
all items in column 'group' will have the same value. Column 'group' accept any value type (integer, string, etc.)

If the column 'name' has values that indicate file names, the extension of files will define how data is presented by xHiPP. 

* .txt to text files;
* .png | .jpg | .jpeg to image files;
* .mp3 | .wav to audio files;

Other files types or data without information about extension will be presented as ordinary data.

obs.: CSV files of text dataset can contain columns named as 'name' and 'group' that are linked with text word frequency. Please, rename these columns to xHiPP correctly encounter 
columns 'name' and 'group' especified above. For instance,

| name  | word1 | word2 | name.1 | word3 | word4 | group.1 | word5 | group |
| ----- | ----- | ----- | ------ | ----- | ----- | ------- | ----- | ----- |
| file1.txt | 0.3 | 0.5 | 0.4 | 0.2 | 0.1 | 0 | 0 | news |

### File format (json)

It is possible to load .json files, that contains a preprocessed xHiPP structure. 

#TODO: Complete this topic
